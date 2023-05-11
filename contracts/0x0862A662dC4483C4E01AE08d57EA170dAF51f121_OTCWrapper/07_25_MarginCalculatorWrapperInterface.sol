// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import {UtilsWrapperInterface} from "./UtilsWrapperInterface.sol";

interface MarginCalculatorWrapperInterface {
    function getExcessCollateral(UtilsWrapperInterface.Vault calldata _vault, uint256 _vaultType)
        external
        view
        returns (uint256 netValue, bool isExcess);
}