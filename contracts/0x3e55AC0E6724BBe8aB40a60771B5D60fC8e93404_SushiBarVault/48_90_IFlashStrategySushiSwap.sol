// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./IFlashStrategy.sol";

interface IFlashStrategySushiSwap is IFlashStrategy {
    error Forbidden();
    error InvalidVault();
    error AmountTooLow();
    error InsufficientYield();
    error InsufficientTotalSupply();

    function factory() external view returns (address);

    function flashProtocol() external view returns (address);

    function fToken() external view returns (address);

    function sushi() external view returns (address);

    function flpToken() external view returns (address);

    function initialize(address _flashProtocol, address _flpToken) external;
}