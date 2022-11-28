// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IContractAllowListProxy {
    // --------------------------------------------------------------------------
    // For user
    // --------------------------------------------------------------------------
    function isAllowed(address transferer,uint256 level)
        external
        view
        returns (bool);
}