// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./ContextMixin.sol";

error InvalidCreatorAddress();
error InvalidAddress();
error InvalidPlatformAddress();
error InvalidPaymentToken();
error ActiveAuction();
error InvalidExpirationTime();
error InvalidQuantity();
error InvalidRoyalty();
error RoyaltyAlreadySet();

/// @custom:security-contact <security email address>
abstract contract Base_ZingNFT_721 is
    IERC2981,
    Ownable,
    Pausable,
    ERC721Enumerable,
    ERC2771Context,
    ContextMixin
{
    using Strings for uint256;

    address private _recipient;
    address private _trustedForwarder;

    /// @notice Token ID -> Minter
    mapping(uint256 => address) internal minters;

    /// @notice Token ID -> Royalty
    mapping(uint256 => uint256) private royalties;

    constructor() {
        _recipient = owner();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /** @dev EIP2981 royalties implementation. */

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        address minter = minters[_tokenId];
        if (minter == address(0) || royalties[_tokenId] == 0) {
            return (address(0), 0);
        }
        uint256 royaltyFee = (_salePrice * royalties[_tokenId]) / 10000;
        return (minter, royaltyFee);
    }

    /// @notice Update Royalty for NFT Token
    /// @param _tokenId TokenId
    /// @param _royalty Royalty
    function _updateRoyalty(uint256 _tokenId, uint16 _royalty) internal {
        if (_royalty > 10000) revert InvalidRoyalty();

        if (minters[_tokenId] != address(0)) revert RoyaltyAlreadySet();
        minters[_tokenId] = _msgSender();
        royalties[_tokenId] = _royalty;
    }

    /**
     @notice View method for checking whether a token has been minted
     @param _tokenId ID of the token being checked
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by Marketplace.
     */
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}