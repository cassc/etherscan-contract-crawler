// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolEventsAndErrors} from "./IPoolEventsAndErrors.sol";

interface IPool is IPoolEventsAndErrors {
    function initialize(address _collection) external;

    function deposit(uint256[] calldata ids) external;

    function withdraw(uint256[] calldata ids) external payable;

    function swap(uint256[] calldata depositIDs, uint256[] calldata withdrawIDs) external payable;

    function fee() external returns (uint256);

    function paymentReceiver() external returns (address);
}