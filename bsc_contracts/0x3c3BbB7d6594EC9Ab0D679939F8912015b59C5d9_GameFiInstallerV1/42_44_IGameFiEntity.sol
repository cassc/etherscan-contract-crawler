// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface IGameFiEntity {
    function name() external pure returns (string memory);
    function version() external pure returns (string memory);
}