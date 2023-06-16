//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRewardsDistributor {
    function register1155(address receipt) external;
    function receiptCheckpoint(
        address receipt,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
    
    function feeManager() external view returns (address);
}