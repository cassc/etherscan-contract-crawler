// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IEIP2981} from "../../royalties/IEIP2981.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Custom Errors
//////////////////////////////////////////////////////////////////////////*/

/// @dev error if the recipient is set to address(0)
error ZeroAddressError();

/// @dev error if the royalty percentage is greater than to 100%
error MaxRoyaltyError();

/*//////////////////////////////////////////////////////////////////////////
                            EIP2981TL
//////////////////////////////////////////////////////////////////////////*/

/// @title EIP2981TLUpgradeable.sol
/// @notice abstract contract to define a default royalty spec
///         while allowing for specific token overrides
/// @dev follows EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981)
/// @author transientlabs.xyz
/// @custom:version 2.2.0
abstract contract EIP2981TLUpgradeable is IEIP2981, Initializable, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Struct
    //////////////////////////////////////////////////////////////////////////*/

    struct RoyaltySpec {
        address recipient;
        uint256 percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    address private _defaultRecipient;
    uint256 private _defaultPercentage;
    mapping(uint256 => RoyaltySpec) private _tokenOverrides;

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to initialize the contract
    /// @param defaultRecipient - the default royalty payout address
    /// @param defaultPercentage - the deafult royalty percentage, out of 10,000
    function __EIP2981TL_init(address defaultRecipient, uint256 defaultPercentage) internal onlyInitializing {
        __EIP2981TL_init_unchained(defaultRecipient, defaultPercentage);
    }

    /// @notice unchained function to initialize the contract
    /// @param defaultRecipient - the default royalty payout address
    /// @param defaultPercentage - the deafult royalty percentage, out of 10,000
    function __EIP2981TL_init_unchained(address defaultRecipient, uint256 defaultPercentage)
        internal
        onlyInitializing
    {
        _setDefaultRoyaltyInfo(defaultRecipient, defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Changing Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice function to set default royalty info
    /// @param newRecipient - the new default royalty payout address
    /// @param newPercentage - the new default royalty percentage, out of 10,000
    function _setDefaultRoyaltyInfo(address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        _defaultRecipient = newRecipient;
        _defaultPercentage = newPercentage;
    }

    /// @notice function to override royalty spec on a specific token
    /// @param tokenId - the token id to override royalty for
    /// @param newRecipient - the new royalty payout address
    /// @param newPercentage - the new royalty percentage, out of 10,000
    function _overrideTokenRoyaltyInfo(uint256 tokenId, address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        _tokenOverrides[tokenId].recipient = newRecipient;
        _tokenOverrides[tokenId].percentage = newPercentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Info
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEIP2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        address recipient = _defaultRecipient;
        uint256 percentage = _defaultPercentage;
        if (_tokenOverrides[tokenId].recipient != address(0)) {
            recipient = _tokenOverrides[tokenId].recipient;
            percentage = _tokenOverrides[tokenId].percentage;
        }
        return (recipient, salePrice / 10_000 * percentage); // divide first to avoid overflow
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Override
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Query the default royalty receiver and percentage.
    /// @return Tuple containing the default royalty recipient and percentage out of 10_000
    function getDefaultRoyaltyRecipientAndPercentage() external view returns (address, uint256) {
        return (_defaultRecipient, _defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}