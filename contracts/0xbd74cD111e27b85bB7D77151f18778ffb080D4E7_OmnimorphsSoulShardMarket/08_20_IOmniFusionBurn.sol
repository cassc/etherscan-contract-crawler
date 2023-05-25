// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOmniFusionBurn {
    function burn(address sender, uint id, uint amount) external;
}