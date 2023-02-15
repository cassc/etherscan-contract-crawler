// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMTPClient {
    event SetMTPWallet(address[] indexed oldWallets, address[] indexed newWallets);

    function setMTPWallet(address[] calldata newWallest) external;

    function mtpWallet() external returns (address[] memory);
}