// SPDX-License-Identifier: UNLICENSED
// Created by: Ryojin Team
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract RAMENFT is ERC721A, ERC2981, Ownable, Pausable, ReentrancyGuard {
    // States
    string baseURI;
    mapping(address => bool) public claimed;

    // Constants
    uint16 public constant MAX_SUPPLY = 1000;

    // Errors
    error AlreadyMinted();
    error ExceedMaxSupply();

    modifier canMint() {
        uint256 supply = totalSupply();
        if (supply + 1 > MAX_SUPPLY) revert ExceedMaxSupply();
        if (claimed[msg.sender]) revert AlreadyMinted();
        _;
    }

    constructor(string memory uri) ERC721A("RAMENFT", "RAMEN") {
        baseURI = uri;
        _setDefaultRoyalty(msg.sender, 1000);
        _safeMint(msg.sender, 10);
    }

    function freeMint() external canMint whenNotPaused nonReentrant {
        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    // Essentials
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) return "";

        return string(abi.encodePacked(baseURI, "/", _toString(tokenId), ".json"));
    }

    // Phases
    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }
    
    function setRoyalty(address _receiver, uint96 _fraction) external onlyOwner {
        _setDefaultRoyalty(_receiver, _fraction);
    }

    // Base URI setter
    function setTokenURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId)
            || ERC2981.supportsInterface(interfaceId);
    }
}