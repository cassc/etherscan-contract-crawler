// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEngine} from "./IMarginEngine.sol";
import {Collateral} from "../config/types.sol";

/**
 * @notice Interface for the abstract auction vault contract which handles both cash and physical settlement
 *         used only in the settlement contracts to provide compatibility between the vault interfaces
 */

interface IAuctionVault {
    /// @notice verifies the options are allowed to be minted
    /// @param _options to mint
    function verifyOptions(uint256[] calldata _options) external view;

    function marginEngine() external view returns (IMarginEngine);

    function getCollaterals() external view returns (Collateral[] memory);
}