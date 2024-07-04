// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Collection.sol";

contract MockCollection is Collection {
    constructor(address _owner) Collection(_owner) {}

    function generateRandomOwners(uint256 numOwners) public {
        for (uint256 i = 0; i < numOwners; i++) {
            owners.push(
                address(
                    uint160(
                        uint256(keccak256(abi.encodePacked(block.timestamp, i)))
                    )
                )
            );
        }
    }

    function generateRandomNFTs(uint256 numNFTs) public {
        for (uint256 i = 0; i < numNFTs; i++) {
            nfts.push(uint256(keccak256(abi.encodePacked(block.timestamp, i))));
        }
    }
}
