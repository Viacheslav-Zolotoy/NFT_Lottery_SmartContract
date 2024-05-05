//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./Collection.sol";

contract Lottery is Ownable, Collection {
    address public _owner;
    IERC20 private _usdtToken;
    uint256 lotteryId;
    uint256 public countParsipiants;
    uint256 public rewardForBurnNFT;
    address private constant addressUSDT =
        0x1531BC5dE10618c511349f8007C08966E45Ce8ef;

    // Mapping для зберігання учасників кожної лотереї
    mapping(uint256 => mapping(uint256 => address)) public _participants;

    mapping(uint256 => mapping(address => bool)) internal verifyingParticipants;
    // Час закінчення лотереї
    uint256 private _lotteryEndTime;

    // Структура для зберігання даних про переможців
    struct Winner {
        address addr;
        uint256 reward;
    }
    struct Winners {
        Winner _jackpotWinners;
        Winner[] _level1Winners;
        Winner[] _level2Winners;
        Winner[] _level3Winners;
    }

    mapping(uint256 => Winners) public winners;

    event RewardPaid(address recipient, uint256 amount);
    event NFTBurned(address ownerNFT, uint256 nftId, uint256 revardAmount);
    mapping(address => bool) public isCollectionAdded;

    constructor(address initialOwner) Collection(initialOwner) {
        _owner = msg.sender;
        countParsipiants = 1;
        lotteryId = 1;
    }

    function setRewardForBurning(uint256 _reward) external onlyOwner {
        rewardForBurnNFT = _reward;
    }

    function burnNFT(uint256 tokenId) external {
        require(
            Collection.balance(msg.sender) > 0,
            "You don't have the required NFT"
        );

        // Спалення NFT
        Collection.burn(tokenId);
        // Отримуємо винагороду у USDT
        require(
            _usdtToken.balanceOf(address(this)) >= rewardForBurnNFT,
            "Contract doesn't have enough USDT"
        );
        require(
            _usdtToken.transfer(msg.sender, rewardForBurnNFT),
            "Failed to transfer USDT"
        );

        emit NFTBurned(msg.sender, tokenId, rewardForBurnNFT);
    }

    function startNewLottery(uint256 endTime) external onlyOwner {
        // Очищення списків учасників
        for (uint256 i = 0; i < countParsipiants; i++) {
            delete _participants[lotteryId][i];
        }

        // Очищення списку перевірок учасників
        for (uint256 i = 0; i < countParsipiants; i++) {
            delete verifyingParticipants[lotteryId][
                _participants[lotteryId][i]
            ];
        }

        // Оновлення значення лотереї
        _lotteryEndTime = endTime;
        countParsipiants = 1;
        lotteryId++;
    }

    function addCollectionFromLottery(
        address collectionAddress
    ) external onlyOwner {
        require(block.timestamp < _lotteryEndTime, "The lottery is over.");
        require(
            !isCollectionAdded[collectionAddress],
            "Collection already joined this lottery"
        );
        Collection collection = Collection(collectionAddress);
        address[] memory participantsFromCollection = collection
            .getFakeOwners();

        for (uint256 i = 0; i < participantsFromCollection.length; ++i) {
            _participants[lotteryId][
                countParsipiants
            ] = participantsFromCollection[i];
            verifyingParticipants[lotteryId][
                participantsFromCollection[i]
            ] = true;
            ++countParsipiants;
        }
        isCollectionAdded[collectionAddress] = true;
    }

    // Додавання учасника до лотереї
    function _addParticipants(address _ownerNFT) public {
        require(block.timestamp < _lotteryEndTime, "The lottery is over.");

        require(
            Collection.balance(_ownerNFT) > 0,
            "You don't have the required nft "
        );
        require(
            !verifyingParticipants[lotteryId][_ownerNFT],
            "Participant already joined this lottery"
        );

        _participants[lotteryId][countParsipiants] = _ownerNFT;
    }

    function setLotteryEndTime(uint256 endTime) external onlyOwner {
        _lotteryEndTime = endTime;
    }

    function getParticipantCount() external view returns (uint256) {
        return countParsipiants;
    }

    function getParticipant(uint id) public view returns (address) {
        return _participants[lotteryId][id];
    }

    function shuffleParticipants() internal {
        for (uint256 i = 0; i < countParsipiants; ++i) {
            uint256 j = i +
                (uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, block.prevrandao, i)
                    )
                ) % (countParsipiants - i));
            (_participants[lotteryId][i], _participants[lotteryId][j]) = (
                _participants[lotteryId][j],
                _participants[lotteryId][i]
            );
        }
    }

    function determineWinners(
        uint256 jackpotReward,
        uint256 level1Reward,
        uint256 level2Reward,
        uint256 level3Reward
    ) external onlyOwner {
        require(block.timestamp >= _lotteryEndTime, "Lottery is still ongoing");

        // Перемішуємо список учасників перед визначенням переможців
        shuffleParticipants();

        // Визначення переможців для рівнів jackpot, 1, 2, 3
        uint256 totalParticipants = countParsipiants;
        uint256 level1WinnersCount = totalParticipants / 100; // 0.1% всіх учасників
        uint256 level2WinnersCount = totalParticipants / 50; // 1% всіх учасників
        uint256 level3WinnersCount = totalParticipants / 10; // 10% всіх учасників
        uint256 level1PerWinner = level1Reward / level1WinnersCount;
        uint256 level2PerWinner = level2Reward / level2WinnersCount;
        uint256 level3PerWinner = level3Reward / level3WinnersCount;
        uint256 countWinners;

        uint256 jackpotWinnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
        ) % countParsipiants;
        Winner memory jackpotWinner = Winner(
            _participants[lotteryId][jackpotWinnerIndex],
            jackpotReward
        );
        winners[lotteryId]._jackpotWinners = jackpotWinner;
        emit RewardPaid(
            winners[lotteryId]._jackpotWinners.addr,
            winners[lotteryId]._jackpotWinners.reward
        );

        // Визначення переможців на рівні 1
        for (uint256 i = 0; i < level1WinnersCount; ++i) {
            countWinners = 0;
            Winner memory newWinner = Winner(
                _participants[lotteryId][i],
                level1PerWinner
            );

            winners[lotteryId]._level1Winners.push(newWinner);
            emit RewardPaid(
                winners[lotteryId]._level1Winners[countWinners].addr,
                winners[lotteryId]._level1Winners[countWinners].reward
            );
            ++countWinners;
        }

        // Визначення переможців на рівні 2
        for (
            uint256 i = level1WinnersCount;
            i < level1WinnersCount + level2WinnersCount;
            ++i
        ) {
            countWinners = 0;
            Winner memory newWinner = Winner(
                _participants[lotteryId][i],
                level2PerWinner
            );
            winners[lotteryId]._level2Winners.push(newWinner);
            emit RewardPaid(
                winners[lotteryId]._level2Winners[countWinners].addr,
                winners[lotteryId]._level2Winners[countWinners].reward
            );
            ++countWinners;
        }

        // Визначення переможців на рівні 3
        for (
            uint256 i = level1WinnersCount + level2WinnersCount;
            i < level1WinnersCount + level2WinnersCount + level3WinnersCount;
            ++i
        ) {
            countWinners = 0;
            Winner memory newWinner = Winner(
                _participants[lotteryId][i],
                level3PerWinner
            );
            winners[lotteryId]._level3Winners.push(newWinner);
            emit RewardPaid(
                winners[lotteryId]._level3Winners[countWinners].addr,
                winners[lotteryId]._level3Winners[countWinners].reward
            );
            ++countWinners;
        }
    }

    // Очищення списків переможців
    function cleanListWinners(uint256 _lotteryId) external onlyOwner {
        delete winners[_lotteryId];
    }

    function getWinners(
        uint256 _lotteryId
    )
        external
        view
        returns (
            Winner memory _jackpotWinners,
            Winner[] memory _level1Winners,
            Winner[] memory _level2Winners,
            Winner[] memory _level3Winners
        )
    {
        return (
            winners[_lotteryId]._jackpotWinners,
            winners[_lotteryId]._level1Winners,
            winners[_lotteryId]._level2Winners,
            winners[_lotteryId]._level3Winners
        );
    }
}
