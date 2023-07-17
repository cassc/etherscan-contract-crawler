// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IBurnCrosschainMinter {
    struct ContractMintInfo {
        string secretPasscode;
    }

    function isAdmin(address target, address user) external view returns (bool);

    function initializeWithData(address target, bytes calldata data) external;

    function purchase(
        address target,
        bytes calldata data
    ) external payable returns (uint256);

    function calculateDiscountedPrice(
        address target,
        uint256 burnQuantity
    ) external view returns (uint256);

    function withdraw(address target) external;
}