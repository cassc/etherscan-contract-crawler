// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";


abstract contract SoulboundBurnable is
    ERC721URIStorage,
    ERC721Burnable
{
    
    error TokenIsSoulbound();

    /**
     * Disallows approval setting for soulbound functionality
     */
    function approve(address, uint256)
        public
        pure
        override(ERC721)
    {
        revert TokenIsSoulbound();
    }

    /**
     * Disallows transfer for soulbound functionality
     */
    function safeTransferFrom(address, address, uint256)
        public
        pure
        override(ERC721)
    {
        revert TokenIsSoulbound();
    }

    /**
     * Disallows transfer for soulbound functionality
     */
    function safeTransferFrom(address, address, uint256, bytes memory)
        public
        pure
        override(ERC721)
    {
        revert TokenIsSoulbound();
    }

    /**
     * Disallows approval setting for soulbound functionality
     */
    function setApprovalForAll(address, bool)
        public
        pure
        override(ERC721)
    {
        revert TokenIsSoulbound();
    }

    /**
     * Disallows transfer for soulbound functionality
     */
    function transferFrom(address, address, uint256)
        public
        pure
        override(ERC721)
    {
        revert TokenIsSoulbound();
    }

    /**
    * The following functions are overrides required by Solidity.
    */
    
    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId, 
        uint256 batchSize
    )
        internal override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}