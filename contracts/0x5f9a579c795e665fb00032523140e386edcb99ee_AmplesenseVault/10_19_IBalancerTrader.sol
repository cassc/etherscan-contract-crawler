// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

interface IBalancerTrader {
    event Sale_EEFI(uint256 ampl_amount, uint256 eefi_amount);
    event Sale_ETH(uint256 ampl_amount, uint256 eth_amount);

    function sellAMPLForEth(uint256 amount, uint256 minimalExpectedAmount) external returns (uint256);
    function sellAMPLForEEFI(uint256 amount, uint256 minimalExpectedAmount) external returns (uint256);
}