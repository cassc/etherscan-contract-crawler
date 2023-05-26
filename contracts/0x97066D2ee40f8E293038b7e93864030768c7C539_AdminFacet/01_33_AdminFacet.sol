// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Modifiers } from "../Modifiers.sol";
import { LibAdmin } from "../libs/LibAdmin.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibFeeRouter } from "../libs/LibFeeRouter.sol";
import { PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints } from "../interfaces/FreeStructs.sol";
import { IAdminFacet } from "../interfaces/IAdminFacet.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative privileges
 * @dev Use it to configure various core parameters
 */
contract AdminFacet is IAdminFacet, Modifiers {
    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external assertSysAdmin {
        LibAdmin._updateMaxDividendDenominations(_newMax);
    }

    /**
     * @notice Update policy commission basis points configuration.
     * @param _policyCommissions policy commissions configuration to set
     */
    function setPolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata _policyCommissions) external assertSysAdmin {
        LibFeeRouter._updatePolicyCommissionsBasisPoints(_policyCommissions);
    }

    /**
     * @notice Update trading commission basis points configuration.
     * @param _tradingCommissions trading commissions configuration to set
     */
    function setTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata _tradingCommissions) external assertSysAdmin {
        LibFeeRouter._updateTradingCommissionsBasisPoints(_tradingCommissions);
    }

    /**
     * @notice Get the max dividend denominations value
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    /**
     * @notice Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
     * @param _tokenId token address converted to bytes32
     * @return whether token is supported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool) {
        return LibAdmin._isSupportedExternalToken(_tokenId);
    }

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     */
    function addSupportedExternalToken(address _tokenAddress) external assertSysAdmin {
        LibAdmin._addSupportedExternalToken(_tokenAddress);
    }

    /**
     * @notice Get the supported tokens list as an array
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory) {
        return LibAdmin._getSupportedExternalTokens();
    }

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32) {
        return LibAdmin._getSystemId();
    }

    function isObjectTokenizable(bytes32 _objectId) external view returns (bool) {
        return LibObject._isObjectTokenizable(_objectId);
    }

    function lockFunction(bytes4 functionSelector) external assertSysAdmin {
        LibAdmin._lockFunction(functionSelector);
    }

    function unlockFunction(bytes4 functionSelector) external assertSysAdmin {
        LibAdmin._unlockFunction(functionSelector);
    }

    function isFunctionLocked(bytes4 functionSelector) external view returns (bool) {
        return LibAdmin._isFunctionLocked(functionSelector);
    }

    function lockAllFundTransferFunctions() external assertSysAdmin {
        LibAdmin._lockAllFundTransferFunctions();
    }

    function unlockAllFundTransferFunctions() external assertSysAdmin {
        LibAdmin._unlockAllFundTransferFunctions();
    }
}