// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFlashStrategySushiSwapFactory {
    error InvalidFee();
    error InvalidFeeRecipient();
    error FlashStrategySushiSwapCreated();

    event UpdateStakeFeeBPS(uint256 fee);
    event UpdateFlashStakeFeeBPS(uint256 fee);
    event UpdateFeeRecipient(address feeRecipient);
    event CreateFlashStrategySushiSwap(uint256 pid, address strategy);

    function flashProtocol() external view returns (address);

    function flpTokenFactory() external view returns (address);

    function feeRecipient() external view returns (address);

    function getFlashStrategySushiSwap(uint256 pid) external view returns (address);

    function predictFlashStrategySushiSwapAddress(uint256 pid) external view returns (address strategy);

    function updateFeeRecipient(address _feeRecipient) external;

    function createFlashStrategySushiSwap(uint256 pid) external returns (address strategy);
}