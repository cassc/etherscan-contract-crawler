// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

interface IVaultTracker {
    function addNotional(address, uint256) external returns (bool);

    function removeNotional(address, uint256) external returns (bool);

    function redeemInterest(address) external returns (uint256);

    function matureVault(uint256) external returns (bool);

    function transferNotionalFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transferNotionalFee(address, uint256) external returns (bool);

    function rates() external returns (uint256, uint256);

    function balancesOf(address) external view returns (uint256, uint256);
}