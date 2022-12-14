// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ISpot {
    function ilks(bytes32) external view returns (address, uint256);
}