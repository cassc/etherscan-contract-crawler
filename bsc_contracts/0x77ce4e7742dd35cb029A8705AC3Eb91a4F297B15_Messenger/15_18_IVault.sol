// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVault {
    function useCollateral(address collateral, uint256 amount) external;
}