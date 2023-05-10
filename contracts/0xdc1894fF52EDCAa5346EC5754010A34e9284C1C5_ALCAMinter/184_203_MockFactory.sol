// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/DeterministicAddress.sol";
import "contracts/libraries/proxy/ProxyUpgrader.sol";

contract MockFactory is DeterministicAddress, ProxyUpgrader {
    /**
    @dev owner role for priveledged access to functions
    */
    address private _owner;

    /**
    @dev delegator role for priveledged access to delegateCallAny
    */
    address private _delegator;

    /**
    @dev array to store list of contract salts
    */
    bytes32[] private _contracts;

    /**
    @dev slot for storing implementation address
    */
    address private _implementation;

    function setOwner(address new_) public {
        _owner = new_;
    }
}