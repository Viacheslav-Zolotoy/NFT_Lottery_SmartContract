//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract Collection is ERC721, ERC721Burnable, Ownable {
    uint256 private _nextTokenId;
    address[] public owners;
    uint256[] public nfts;
    mapping(address => uint256) public tokenIds;

    constructor(address _owner) ERC721("GoldenToken", "GTK") Ownable(_owner) {
        transferOwnership(_owner);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        tokenIds[to] = tokenId;
    }

    function burn(uint256 tokenId) public override {
        super._burn(tokenId);
    }

    function balance(address owner_) public view returns (uint256) {
        return balanceOf(owner_);
    }

    function getTokenId(address owner_) external view returns (uint256) {
        return tokenIds[owner_];
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getNFTs() public view returns (uint256[] memory) {
        return nfts;
    }

    function addOwner(address _owner) public {
        owners.push(_owner);
    }

    function addNFT(uint256 _nft) public {
        nfts.push(_nft);
    }
}
