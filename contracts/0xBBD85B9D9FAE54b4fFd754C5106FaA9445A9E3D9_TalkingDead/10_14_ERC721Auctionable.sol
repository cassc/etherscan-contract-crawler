// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./IERC721Auctionable.sol";
import "../ERC721Comet.sol";
import "../constants/MessageConstants.sol";

/**
 * @dev This implements an optional extension of {ERC721A} defined in the EIP.
 */
contract ERC721Auctionable is ERC721Comet, IERC721Auctionable, IERC2981 {
    /**
     * @notice ERC721 Auctionable constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol)
        ERC721Comet(name, symbol)
    {}

    /**
     * @notice Mint next available token(s) to addres using ERC721A _safeMint
     *
     * @param to The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function _internalMint(address to, uint256 quantity) private {
        require(
            totalSupply() + quantity <= _maxSupply,
            MessageConstants.MAX_SUPPLY
        );

        _safeMint(to, quantity);
    }

    /**
     * @notice Owner can mint to specified address
     *
     * @param to The address to mint to.
     * @param quantity The number of tokens to mint.
     */
    function ownerMint(address to, uint256 quantity) public onlyOwner {
        _internalMint(to, quantity);
    }

    /**
     * @notice Supporting ERC721, IER165
     *         https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        // Silence solc unused parameter warning.
        // All tokens have the same royalty.
        _tokenId;
        royaltyAmount = (_salePrice / 100) * _royaltyPercent;

        return (_royalties, royaltyAmount);
    }
}