// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracle {
    function nextEpochPoint() external view returns (uint256);

    function update() external;

    function epochConsult() external view returns (uint256);

    function consult() external view returns (uint256);

    function consultTrue() external view returns (uint256);
}