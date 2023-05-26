/*
 ** GLITCH WAS HERE
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@metacrypt/contracts/src/erc721/ERC721EnumerableSupply.sol";

/// @title ERC721 Contract for Lazy Cubs
/// @author Akshat Mittal
contract LazyCubs is ERC721, ERC721EnumerableSupply, Pausable, AccessControl {
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    string private baseURIStorage = "https://metadata.lazylionsnft.com/api/lazycubs/";

    constructor() ERC721("Lazy Cubs", "CUBS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONTROLLER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIStorage;
    }

    function setBaseURI(string calldata newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURIStorage = newBaseURI;
    }

    function approveController(address controller) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CONTROLLER_ROLE, controller);
    }

    function pause() public onlyRole(CONTROLLER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(CONTROLLER_ROLE) {
        _unpause();
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(CONTROLLER_ROLE) {
        require(tokenId <= 32_014, "Exceeds token limit.");
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}