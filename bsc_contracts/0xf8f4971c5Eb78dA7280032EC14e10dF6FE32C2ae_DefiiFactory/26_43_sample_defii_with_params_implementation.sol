// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../DefiiWithParams.sol";


contract SampleDefiiWithParamsImplementation is DefiiWithParams {
    function _enterWithParams(bytes memory params) internal override {}
    function _exit() internal override {}
    function _harvest() internal override {}
    function _withdrawFunds() internal override {}
    function hasAllocation() external view override returns (bool) {
        return true;
    }
}