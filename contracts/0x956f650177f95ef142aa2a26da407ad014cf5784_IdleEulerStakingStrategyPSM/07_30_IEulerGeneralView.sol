// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IEulerGeneralView {
    function computeAPYs(uint borrowSPY, uint totalBorrows, uint totalBalancesUnderlying, uint32 reserveFee) external pure returns (uint borrowAPY, uint supplyAPY);
    function computeSPY(address eulerContract, address underlying, uint totalBorrows, uint totalBalancesUnderlying) external view returns (uint borrowSPY);
}