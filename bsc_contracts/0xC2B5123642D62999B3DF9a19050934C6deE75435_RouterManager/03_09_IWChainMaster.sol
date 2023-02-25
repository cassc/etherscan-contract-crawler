// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

interface IWChainMaster {
    function nextAddress() external view returns (address);
    function execute(bytes calldata input, address sender, address beneficiary, uint256 exchangeProfitShare) external;
}