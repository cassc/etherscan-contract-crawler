// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface IGameFiProfileVaultV2 {
    event Call(address indexed owner, address indexed target, bytes data, uint256 value, uint256 timestamp);

    event MultiCall(address indexed owner, address[] target, bytes[] data, uint256[] value, uint256 timestamp);

    function call(
        address target,
        bytes memory data,
        uint256 value
    ) external returns (bytes memory result);

    function multiCall(
        address[] memory target,
        bytes[] memory data,
        uint256[] memory value
    ) external returns (bytes[] memory results);

    function gameFiCore() external view returns (address);

    function initialize(address gameFiCore) external;
}