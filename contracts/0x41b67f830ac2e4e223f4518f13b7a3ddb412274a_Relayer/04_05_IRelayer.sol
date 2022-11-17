// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRelayer {
    enum RelayerType {
        DiscountRate,
        SpotPrice,
        COUNT
    }

    function execute() external returns (bool);

    function executeWithRevert() external;
}