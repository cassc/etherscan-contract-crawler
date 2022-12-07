pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Governable is Ownable {
    mapping(address => bool) public governanceContracts;

    event GovernanceContractAdded(address addr);
    event GovernanceContractRemoved(address addr);

    constructor(){
        addGovernor(msg.sender);
    }

    modifier onlyGovernance() {
        require(governanceContracts[msg.sender], "Isn't governance address");
        _;
    }

    function addGovernor(address addr) public onlyOwner returns (bool success) {
        if (!governanceContracts[addr]) {
            governanceContracts[addr] = true;
            emit GovernanceContractAdded(addr);
            success = true;
        }
    }

    function removeGovernor(address addr)
    public
    onlyOwner
    returns (bool success)
    {
        if (governanceContracts[addr]) {
            delete  governanceContracts[addr];
            emit GovernanceContractRemoved(addr);
            success = true;
        }
    }
}