// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../utils/AddressListPolicyMixin.sol";
import "./utils/PreBuySharesValidatePolicyBase.sol";

/// @title InvestorWhitelist Contract
/// @author Enzyme Council <[email protected]>
/// @notice A policy that only allows a configurable whitelist of investors to buy shares in a fund
contract InvestorWhitelist is PreBuySharesValidatePolicyBase, AddressListPolicyMixin {
    constructor(address _policyManager) public PolicyBase(_policyManager) {}

    /// @notice Adds the initial policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addFundSettings(address _comptrollerProxy, bytes calldata _encodedSettings)
        external
        override
        onlyPolicyManager
    {
        __updateList(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier() external pure override returns (string memory identifier_) {
        return "INVESTOR_WHITELIST";
    }

    /// @notice Updates the policy settings for a fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateFundSettings(
        address _comptrollerProxy,
        address,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
        __updateList(_comptrollerProxy, _encodedSettings);
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _investor The investor for which to check the rule
    /// @return isValid_ True if the rule passes
    function passesRule(address _comptrollerProxy, address _investor)
        public
        view
        returns (bool isValid_)
    {
        return isInList(_comptrollerProxy, _investor);
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _comptrollerProxy The fund's ComptrollerProxy address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    function validateRule(
        address _comptrollerProxy,
        address,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external override returns (bool isValid_) {
        (address buyer, , , ) = __decodeRuleArgs(_encodedArgs);

        return passesRule(_comptrollerProxy, buyer);
    }

    /// @dev Helper to update the investor whitelist by adding and/or removing addresses
    function __updateList(address _comptrollerProxy, bytes memory _settingsData) private {
        (address[] memory itemsToAdd, address[] memory itemsToRemove) = abi.decode(
            _settingsData,
            (address[], address[])
        );

        // If an address is in both add and remove arrays, they will not be in the final list.
        // We do not check for uniqueness between the two arrays for efficiency.
        if (itemsToAdd.length > 0) {
            __addToList(_comptrollerProxy, itemsToAdd);
        }
        if (itemsToRemove.length > 0) {
            __removeFromList(_comptrollerProxy, itemsToRemove);
        }
    }
}