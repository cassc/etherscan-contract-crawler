// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

interface WOCInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract MenOfCrypto is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    bool public isMintActive = false;
    string private _baseURIextended;
    address public immutable WOC_CONTRACT;
    mapping(uint256 => bool) public isClaimed;

    constructor(address woc) ERC721A("Men of Crypto", "MOC") {
        WOC_CONTRACT = woc;
    }

    function mint(uint256[] calldata tokenIDs) public nonReentrant {
        require(msg.sender == tx.origin, "Cant mint from another contract");
        require(isMintActive, "Mint is not active");

        uint256 counter;
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            address owner = ownerOfWoc(tokenIDs[i]);
            require(owner == msg.sender, "Not the owner");
            if (!isClaimed[tokenIDs[i]]) {
                counter++;
                isClaimed[tokenIDs[i]] = true;
            }
        }
        require(counter != 0, "You have no claimable Women Of Crypto");
        require(totalSupply() + counter <= 8888, "Exceeds total supply");
        _safeMint(msg.sender, counter);
    }

    function ownerOfWoc(uint256 tokenID) public view returns (address) {
        return WOCInterface(WOC_CONTRACT).ownerOf(tokenID);
    }

    function toggleIsMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(bytes(baseURI_).length != 0, "Can't update to an empty value");
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }
}