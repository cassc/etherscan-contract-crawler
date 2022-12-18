// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegateOwnership {
    function owners(address _user) external view returns (bool);
    function delegated_layer(address _user) external view returns (uint256);
}