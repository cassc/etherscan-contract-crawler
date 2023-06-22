// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import {LibCollateralSwap} from "../libraries/LibCollateralSwap.sol";

interface IWidoCollateralSwap {
    /// @notice Performs a collateral swap
    /// @param existingCollateral The collateral currently locked in the Comet contract
    /// @param finalCollateral The final collateral desired collateral
    /// @param sigs The required signatures to allow and revoke permission to this contract
    /// @param swap The necessary data to swap one collateral for the other
    /// @param comet The address of the Comet contract to interact with
    function swapCollateral(
        LibCollateralSwap.Collateral calldata existingCollateral,
        LibCollateralSwap.Collateral calldata finalCollateral,
        LibCollateralSwap.Signatures calldata sigs,
        LibCollateralSwap.WidoSwap calldata swap,
        address comet
    ) external;
}