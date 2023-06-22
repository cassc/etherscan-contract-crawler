// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IMarginEngineCash, IMarginEnginePhysical} from "./IMarginEngine.sol";
import {Collateral} from "../config/types.sol";

interface IAuctionVault {
    /// @notice verifies the options are allowed to be minted
    /// @param _options to mint
    function verifyOptions(uint256[] calldata _options) external view;
}

interface IAuctionVaultCash is IAuctionVault {
    function marginEngine() external view returns (IMarginEngineCash);

    function getCollaterals() external view returns (Collateral[] memory);
}

interface IAuctionVaultPhysical is IAuctionVault {
    function marginEngine() external view returns (IMarginEnginePhysical);

    function getCollaterals() external view returns (Collateral[] memory);
}