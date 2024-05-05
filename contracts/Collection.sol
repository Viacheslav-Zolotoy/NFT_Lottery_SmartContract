//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract Collection is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    address[] public owners;
                        mapping(address => uint256) public tokenIds;


    constructor(
        address initialOwner
    ) ERC721("GoldenToken", "GTK") Ownable(initialOwner) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        tokenIds[to] = tokenId;
    }

    function burn(uint256 tokenId) public override {
        super._burn(tokenId);
    }
    
    function balance(address owner_) public view returns (uint256) {
      return  balanceOf(owner_);
    }

function getTokenId(address owner_) external view returns(uint) {
    return tokenIds[owner_];
}

    // Функція для генерації випадкових NFT
    function generateRandomNFTs() internal {

        for (uint256 i = 0; i < owners.length; ++i) {
            // Генеруємо випадковий token ID
            uint256 tokenId = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, i)
                )
            );
            tokenIds[owners[i]] = tokenId;
            // Додаємо NFT до колекції
            _mint(owners[i], tokenId);
        }
    }

    // Функція для генерації випадкових власників
    function generateRandomOwners(
        uint256 count
    ) public returns (address[] memory) {
        uint256 nonce;
        owners = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            // Генеруємо випадкового власника (адресу)
            address _owner = address(
                uint160(
                    uint(
                        keccak256(
                            abi.encodePacked(nonce, blockhash(block.number))
                        )
                    )
                )
            );
            nonce++;
            owners[i] = _owner;
        }
        generateRandomNFTs();
        return owners;
    }

    function getFakeOwners() public view returns (address[] memory) {
        return owners;
    }
}
