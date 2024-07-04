//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Collection.sol";

contract Lottery is Ownable, Collection {
    using SafeERC20 for IERC20;

    IERC20 private rewardToken;
    uint256 private lotteryId;
    uint256 private countParticipants;
    uint256 public rewardForBurnNFT;
    uint256 private lotteryEndTime;

    struct Winner {
        address addr;
        uint256 reward;
    }
    struct Winners {
        Winner jackpotWinner;
        Winner[] level1Winners;
        Winner[] level2Winners;
        Winner[] level3Winners;
    }

    mapping(uint256 => mapping(uint256 => address)) public participants;
    mapping(uint256 => mapping(address => bool)) internal verifyingParticipants;
    mapping(uint256 => Winners) public winners;
    mapping(address => bool) public isCollectionAdded;

    event RewardPaid(address recipient, uint256 amount);
    event NFTBurned(address ownerNFT, uint256 nftId, uint256 rewardAmount);

    constructor(address rewardTokenAddress, address _owner) Collection(_owner) {
        rewardToken = IERC20(rewardTokenAddress);
        lotteryId = 1;
        countParticipants = 1;
    }

    function setRewardForBurning(uint256 _reward) external onlyOwner {
        rewardForBurnNFT = _reward;
    }

    function burnNFT(address collectionAddress, uint256 tokenId) external {
        IERC721 collection = IERC721(collectionAddress);
        require(
            collection.ownerOf(tokenId) == msg.sender,
            "You don't own the required NFT"
        );

        ERC721Burnable(address(collection)).burn(tokenId);
        require(
            rewardToken.balanceOf(address(this)) >= rewardForBurnNFT,
            "Contract doesn't have enough reward tokens"
        );
        rewardToken.safeTransfer(msg.sender, rewardForBurnNFT);

        emit NFTBurned(msg.sender, tokenId, rewardForBurnNFT);
    }

    function startNewLottery(uint256 endTime) external onlyOwner {
        for (uint256 i = 0; i < countParticipants; i++) {
            delete participants[lotteryId][i];
        }
        for (uint256 i = 0; i < countParticipants; i++) {
            delete verifyingParticipants[lotteryId][participants[lotteryId][i]];
        }

        lotteryEndTime = endTime;
        countParticipants = 1;
        lotteryId++;
    }

    function addCollectionToLottery(
        address collectionAddress
    ) external onlyOwner {
        require(block.timestamp < lotteryEndTime, "The lottery is over.");
        require(
            !isCollectionAdded[collectionAddress],
            "Collection already joined this lottery"
        );

        Collection collection = Collection(collectionAddress);
        address[] memory participantsFromCollection = collection.getOwners();

        for (uint256 i = 0; i < participantsFromCollection.length; ++i) {
            participants[lotteryId][
                countParticipants
            ] = participantsFromCollection[i];
            verifyingParticipants[lotteryId][
                participantsFromCollection[i]
            ] = true;
            ++countParticipants;
        }
        isCollectionAdded[collectionAddress] = true;
    }

    function setLotteryEndTime(uint256 endTime) external onlyOwner {
        lotteryEndTime = endTime;
    }

    function getParticipantCount() external view returns (uint256) {
        return countParticipants;
    }

    function getParticipant(uint256 id) public view returns (address) {
        return participants[lotteryId][id];
    }

    function shuffleParticipants() internal {
        for (uint256 i = 0; i < countParticipants; ++i) {
            uint256 j = i +
                (uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.prevrandao, i)
                    )
                ) % (countParticipants - i));
            (participants[lotteryId][i], participants[lotteryId][j]) = (
                participants[lotteryId][j],
                participants[lotteryId][i]
            );
        }
    }

    function determineWinners(
        uint256 jackpotReward,
        uint256 level1Reward,
        uint256 level2Reward,
        uint256 level3Reward
    ) external onlyOwner {
        require(block.timestamp >= lotteryEndTime, "Lottery is still ongoing");

        shuffleParticipants();

        uint256 totalParticipants = countParticipants;
        uint256 level1WinnersCount = totalParticipants / 100;
        uint256 level2WinnersCount = totalParticipants / 50;
        uint256 level3WinnersCount = totalParticipants / 10;

        uint256 level1PerWinner = level1Reward / level1WinnersCount;
        uint256 level2PerWinner = level2Reward / level2WinnersCount;
        uint256 level3PerWinner = level3Reward / level3WinnersCount;

        uint256 jackpotWinnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % countParticipants;
        Winner memory jackpotWinner = Winner(
            participants[lotteryId][jackpotWinnerIndex],
            jackpotReward
        );
        winners[lotteryId].jackpotWinner = jackpotWinner;
        emit RewardPaid(jackpotWinner.addr, jackpotWinner.reward);
        rewardToken.safeTransfer(jackpotWinner.addr, jackpotWinner.reward);

        addLevelWinners(
            level1WinnersCount,
            level1PerWinner,
            winners[lotteryId].level1Winners
        );
        addLevelWinners(
            level2WinnersCount,
            level2PerWinner,
            winners[lotteryId].level2Winners
        );
        addLevelWinners(
            level3WinnersCount,
            level3PerWinner,
            winners[lotteryId].level3Winners
        );
    }

    function addLevelWinners(
        uint256 count,
        uint256 reward,
        Winner[] storage levelWinners
    ) internal {
        for (uint256 i = 0; i < count; ++i) {
            Winner memory newWinner = Winner(
                participants[lotteryId][i],
                reward
            );
            levelWinners.push(newWinner);
            emit RewardPaid(newWinner.addr, newWinner.reward);
            rewardToken.safeTransfer(newWinner.addr, newWinner.reward);
        }
    }

    function cleanListWinners(uint256 _lotteryId) external onlyOwner {
        delete winners[_lotteryId];
    }

    function getWinners(
        uint256 _lotteryId
    )
        external
        view
        returns (
            Winner memory jackpotWinner,
            Winner[] memory level1Winners,
            Winner[] memory level2Winners,
            Winner[] memory level3Winners
        )
    {
        Winners storage w = winners[_lotteryId];
        return (
            w.jackpotWinner,
            w.level1Winners,
            w.level2Winners,
            w.level3Winners
        );
    }
}
