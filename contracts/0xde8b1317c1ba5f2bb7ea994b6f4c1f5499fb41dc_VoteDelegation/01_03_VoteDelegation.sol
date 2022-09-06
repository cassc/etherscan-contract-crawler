// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VoteDelegation is Initializable{
    address public collectiveAddress;
   
    struct Delegation {
        address delegatee;
        string command;
        uint256 maxValue;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _collectiveAddress) public initializer {
        collectiveAddress = _collectiveAddress; 
    }

    mapping (address => Delegation[]) public delegationsMap;
    
    event GrantDelegations(address delegator, Delegation[] delegationGrants);
    event DeleteDelegations(address delegator);
    
    function grantDelegates(address[] calldata addresses, string[] calldata commands, uint256[] calldata maxValues) external {
        if (delegationsMap[msg.sender].length > 0) {
            delete delegationsMap[msg.sender];
        }

        for (uint256 i=0; i < addresses.length; i++) { 
            delegationsMap[msg.sender].push(Delegation(addresses[i], commands[i], maxValues[i]));
        }

        emit GrantDelegations(msg.sender, delegationsMap[msg.sender]);
    }

    function removeDelegates() public {
        if (delegationsMap[msg.sender].length > 0) {
            delete delegationsMap[msg.sender];
        }

        emit DeleteDelegations(msg.sender);
    }
  
    function getDelegations(address delegator) public view returns(Delegation[] memory delegations) {
        return delegationsMap[delegator];
    }
     
}