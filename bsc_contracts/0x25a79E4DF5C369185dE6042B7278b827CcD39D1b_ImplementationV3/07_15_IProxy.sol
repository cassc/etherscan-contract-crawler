// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function collection721() external view returns (address);

    function collection1155() external view returns (address);

    function invalidSaleOrder(bytes calldata saleOrderSignature)
        external
        view
        returns (bool);

    function isSigner(address account) external view returns (bool);

    function isAdmin(address account) external view returns (bool);

    function soldQuantityBySaleOrder(bytes calldata saleOrderSignature)
        external
        view
        returns (uint256);

    function proxyOwner() external view returns (address);
}