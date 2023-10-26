// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolFactoryEventsAndErrors} from "./IPoolFactoryEventsAndErrors.sol";

interface IPoolFactory is IPoolFactoryEventsAndErrors {
    function fee() external view returns (uint256);
    function sznsDao() external view returns (address);

    function createPool(address collection) external returns (address pool);
}