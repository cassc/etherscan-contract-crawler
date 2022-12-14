// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {WrappedExternalBribe} from 'contracts/WrappedExternalBribe.sol';

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract WrappedExternalBribeFactoryUpgradeable is OwnableUpgradeable{
    address public voter;
    mapping(address => address) public oldBribeToNew;
    address public last_bribe;

    constructor() {}
    function initialize(address _voter) initializer  public {
        __Ownable_init();
        voter = _voter;
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = _voter;
    }

    function createBribe(address existing_bribe) external returns (address) {
        require(
            oldBribeToNew[existing_bribe] == address(0),
            "Wrapped bribe already created"
        );
        last_bribe = address(new WrappedExternalBribe(voter, existing_bribe));
        oldBribeToNew[existing_bribe] = last_bribe;
        return last_bribe;
    }
    
}