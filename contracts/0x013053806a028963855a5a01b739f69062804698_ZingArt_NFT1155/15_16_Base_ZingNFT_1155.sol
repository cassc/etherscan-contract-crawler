// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

error InvalidCreatorAddress();
error InvalidAddress();
error InvalidPlatformAddress();
error InvalidPaymentToken();
error InvalidExpirationTime();
error InvalidQuantity();
error InvalidRoyalty();
error RoyaltyAlreadySet();

/// @custom:security-contact <security email address>
abstract contract Base_ZingNFT_1155 is IERC2981, Ownable, ERC1155, Pausable {
    using Strings for uint256;

    address private _recipient;
    address private _trustedForwarder;

    /// @notice Token ID -> Minter
    mapping(uint256 => address) public tokenCreators;

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

    // EIP2981 standard royalties return.
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        address minter = tokenCreators[_tokenId];
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
        if (royalties[_tokenId] > 0) revert RoyaltyAlreadySet();
        if (_royalty > 10000) revert InvalidRoyalty();
        royalties[_tokenId] = _royalty;
    }
}