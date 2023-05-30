// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IEtherCollateral
/// @notice Interface for interacting with the EtherCollateral Contract
interface IEtherCollateral {

    /**
     * @dev Sets the assetClosed indicator if loan opening is allowed or not
     * Called by the Conjure contract if the asset price reaches 0.
    */
    function setAssetClosed(bool) external;

    /**
     * @dev Gets the assetClosed indicator
    */
    function getAssetClosed() external view returns (bool);
}