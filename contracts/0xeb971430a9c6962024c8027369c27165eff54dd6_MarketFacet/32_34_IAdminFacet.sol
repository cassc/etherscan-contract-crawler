// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative priviledges
 * @dev Use it to configure various core parameters
 */
interface IAdminFacet {
    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external;

    /**
     * @notice Update policy commission basis points configuration.
     * @param _policyCommissions policy commissions configuration to set
     */
    function setPolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata _policyCommissions) external;

    /**
     * @notice Update trading commission basis points configuration.
     * @param _tradingCommissions trading commissions configuration to set
     */
    function setTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata _tradingCommissions) external;

    /**
     * @notice Get the max dividend denominations value
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8);

    /**
     * @notice Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
     * @param _tokenId token address converted to bytes32
     * @return whether token issupported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     */
    function addSupportedExternalToken(address _tokenAddress) external;

    /**
     * @notice Get the supported tokens list as an array
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory);

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32);

    /**
     * @notice Check if object can be tokenized
     * @param _objectId ID of the object
     */
    function isObjectTokenizable(bytes32 _objectId) external returns (bool);

    /**
     * @notice System Admin can lock a function
     * @dev This toggles FunctionLockedStorage.lock to true
     * @param functionSelector the bytes4 function selector
     */
    function lockFunction(bytes4 functionSelector) external;

    /**
     * @notice System Admin can unlock a function
     * @dev This toggles FunctionLockedStorage.lock to false
     * @param functionSelector the bytes4 function selector
     */
    function unlockFunction(bytes4 functionSelector) external;

    /**
     * @notice Check if a function has been locked by a system admin
     * @dev This views FunctionLockedStorage.lock
     * @param functionSelector the bytes4 function selector
     */
    function isFunctionLocked(bytes4 functionSelector) external view returns (bool);

    /**
     * @notice Lock all contract methods involving fund transfers
     */
    function lockAllFundTransferFunctions() external;

    /**
     * @notice Unlock all contract methods involving fund transfers
     */
    function unlockAllFundTransferFunctions() external;
}