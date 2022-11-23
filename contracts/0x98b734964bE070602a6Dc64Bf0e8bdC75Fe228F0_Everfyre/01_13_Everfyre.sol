// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Everfyre is Ownable, ERC721A, ReentrancyGuard {

    uint256 public immutable collectionSize;
    address withdrawWallet = 0x9Fe9d7B49307E3f74d0b53355E74088d4359a63f;

    constructor(
        uint256 collectionSize_
    ) ERC721A("Everfyre", "EF", collectionSize_) {
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function bulkMintMap(address[] memory who, uint256[] memory quantityList) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) internalMint(who[i], quantityList[i]);
    }

    function internalMint(address to, uint256 quantity) internal virtual {
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        _safeMint(to, quantity);
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawWallet).transfer(balance);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}