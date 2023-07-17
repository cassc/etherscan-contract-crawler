// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SpaceArk is Ownable, ERC721A, ReentrancyGuard {
    bool publicSale = true;
    uint256 nbFree = 500;

    constructor() ERC721A("Space Ark", "PET", 20, 5001) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setFree(uint256 nb) external onlyOwner {
        nbFree = nb;
    }

    function freeMint(uint256 quantity) external callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(totalSupply() + quantity <= nbFree, "Reached max free supply");
        require(quantity <= 20, "can not mint this many free at a time");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(publicSale, "Public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= 20, "can not mint this many at a time");
        require(
            0.02 ether * quantity <= msg.value,
            "Ether value sent is not correct"
        );

        _safeMint(msg.sender, quantity);
    }

    // metadata URI
    string private _baseTokenURI =
        "ipfs://QmYE6AHeGGQQ4vy84rdVLvdA9bWtzHswkQoWQGCpQiV2TU/";

    function initMint() external onlyOwner {
        _safeMint(msg.sender, 1); // As the collection starts at 0, this first mint is for the deployer ...
    }

    
    function setSaleState(bool state) external onlyOwner {
        publicSale = state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setOwnersExplicit(uint256 quantity)
        external
        onlyOwner
        nonReentrant
    {
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