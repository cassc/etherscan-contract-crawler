// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "./IERC721Auctionable.sol";
import "../ERC721OperatorFilter.sol";
import "../constants/MessageConstants.sol";

/**
 * @dev This implements an optional extension of {ERC721A} defined in the EIP.
 */
abstract contract ERC721Airdroppable is
    ERC721OperatorFilter,
    IERC721Auctionable
{
    // A token receiver
    struct Receiver {
        address to;
        uint256 quantity;
    }

    /**
     * @notice ERC721 Airdrop constructor.
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

    /**
     * @notice Return total quantity of tokens from an array of receivers.
     *
     * @return uint256 - the total quantity within the receivers array
     */
    function _totalQuantity(Receiver[] memory receivers)
        private
        pure
        returns (uint256)
    {
        uint256 totalQuantity = 0;

        for (uint256 i = 0; i < receivers.length; i++) {
            totalQuantity += receivers[i].quantity;
        }

        return totalQuantity;
    }

    /**
     * @notice Airdrop to multiple receivers.
     *
     * @param receivers - the receiver tuple with to address and quantity.
     */
    function airDrop(Receiver[] memory receivers) external onlyOwner {
        uint256 amount = _totalQuantity(receivers);
        require(
            totalSupply() + amount <= _maxSupply,
            MessageConstants.MAX_SUPPLY
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _internalMint(receivers[i].to, receivers[i].quantity);
        }
    }
}