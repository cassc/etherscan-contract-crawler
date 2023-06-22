// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IParameterControl {
    function get(string memory key) external view returns (string memory value);

    function set(string memory key, string memory value) external;

    function getInt(string memory key) external view returns (int value);

    function setInt(string memory key, int value) external;

    function getUInt256(string memory key) external view returns (uint256 value);

    function setUInt256(string memory key, uint256 value) external;
}