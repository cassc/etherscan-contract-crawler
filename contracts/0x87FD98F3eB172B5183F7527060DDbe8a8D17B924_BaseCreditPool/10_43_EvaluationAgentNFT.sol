// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Errors.sol";

contract EvaluationAgentNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NFTGenerated(uint256 tokenId, address recipient);
    event SetURI(uint256 tokenId, string tokenURI);

    constructor() ERC721("EvaluationAgentNFT", "EANFT") {}

    /**
     * @notice  Minting an NFT only gets a placeholder for an EA
     * the NFT has attributes such as "status" that can only be updated by
     * Huma to indicate whether the corresponding EA is approved or not.
     * Merely owning an EANFT does NOT mean the owner has any authority
     */
    function mintNFT(address recipient) external returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        emit NFTGenerated(newItemId, recipient);
        return newItemId;
    }

    function burn(uint256 tokenId) external returns (uint256) {
        if (msg.sender != ownerOf(tokenId)) revert Errors.notNFTOwner();
        _burn(tokenId);
        return tokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // Intentionally disable transfer by doing nothing.
    }

    function setTokenURI(uint256 tokenId, string memory uri) external onlyOwner {
        emit SetURI(tokenId, uri);
        _setTokenURI(tokenId, uri);
    }
}