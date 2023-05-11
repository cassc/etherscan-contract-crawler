// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {UtilsWrapperInterface} from "./UtilsWrapperInterface.sol";

interface MarginRequirementsWrapperInterface {
    function checkWithdrawCollateral(
        address _account,
        uint256 _notional,
        uint256 _withdrawAmount,
        address _otokenAddress,
        uint256 _vaultID,
        UtilsWrapperInterface.Vault memory _vault
    ) external view returns (bool);

    function checkMintCollateral(
        address _account,
        uint256 _notional,
        address _underlyingAsset,
        bool isPut,
        uint256 _collateralAmount,
        address _collateralAsset
    ) external view returns (bool);
}