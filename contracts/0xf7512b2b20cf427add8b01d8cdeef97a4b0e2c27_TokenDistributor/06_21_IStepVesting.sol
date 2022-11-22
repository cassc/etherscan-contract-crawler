// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021

pragma solidity ^0.8.10;

import {IGearToken} from "./IGearToken.sol";

interface IStepVesting {
    function receiver() external view returns (address);

    function initialize(
        IGearToken _token,
        uint256 _started,
        uint256 _cliffDuration,
        uint256 _stepDuration,
        uint256 _cliffAmount,
        uint256 _stepAmount,
        uint256 _numOfSteps,
        address _receiver
    ) external;

    function setReceiver(address) external;

    function cliffDuration() external view returns (uint256);

    function stepDuration() external view returns (uint256);

    function cliffAmount() external view returns (uint256);

    function stepAmount() external view returns (uint256);

    function numOfSteps() external view returns (uint256);

    function claimed() external view returns (uint256);
}