// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ICommissionActivation {
    function activateCommissions(uint256, address) external;

    function getCommissionActivation(address, uint256) external view returns (bool);
}