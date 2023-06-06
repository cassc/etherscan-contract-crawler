// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {MessengerProtocol} from "./IBridge.sol";

interface IRouter {
    function canSwap() external view returns (uint8);

    function swap(uint amount, bytes32 token, bytes32 receiveToken, address recipient, uint receiveAmountMin) external;
}