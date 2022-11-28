// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../Defii.sol";


contract SampleDefiiImplementation is Defii {
    function _enter() internal override {  
    }

    function _exit() internal override {
    }
    function _harvest() internal override {
    }

    function _withdrawFunds() internal override {
    }

    function hasAllocation() external view override returns (bool) {
        return true;
    }
}