// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "./IMultiTransactorV1.sol";

interface IMultiTransactorV2 is IMultiTransactorV1 {
    function initialize() external;
}