// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Transfer Function v1.0 
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

// This function is called when a Job NFT is transferred


interface JobsInterface {
    function resetJob(uint _jobId) external;
}

contract JobTransferFunction is AccessControl {

    uint count = 0;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address jobsAddress = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, jobsAddress);
        // jobsAddress = msg.sender;  TURN ON WHEN DEPLOYED WITH JOBS
    }

    function getCount() public view returns (uint) {
        return count;
    }

    function jobTransfer(address from, address to, uint256 tokenId) public onlyRole(MINTER_ROLE) { 
        count++;
        JobsInterface(jobsAddress).resetJob(tokenId);
    }

    function setJobsContract(address _addr) public onlyRole(MINTER_ROLE) {
        jobsAddress = _addr;
    }

}