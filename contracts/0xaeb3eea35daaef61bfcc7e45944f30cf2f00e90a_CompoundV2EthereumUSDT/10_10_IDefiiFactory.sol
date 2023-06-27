// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Info {
    address wallet;
    address defii;
    bool hasAllocation;
    address incentiveVault;
}

struct Balance {
    address wallet;
    BalanceItem[] balance;
}

struct BalanceItem {
    address token;
    uint256 decimals;
    uint256 balance;
    uint256 incentiveVaultBalance;
}

interface IDefiiFactory {
    function executor() external view returns (address executor);

    function getDefiiFor(address wallet) external view returns (address defii);

    function getAllWallets() external view returns (address[] memory);

    function getAllDefiis() external view returns (address[] memory);

    function getAllAllocations() external view returns (bool[] memory);

    function getAllInfos() external view returns (Info[] memory);

    function getAllBalances(address[] calldata tokens)
        external
        returns (Balance[] memory);

    function createDefii() external;

    function createDefiiFor(address owner, address incentiveVault) external;
}