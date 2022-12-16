// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.2;

interface IGasPriceConsumer {
    function getLatestGasPrice() external view returns (int);
}