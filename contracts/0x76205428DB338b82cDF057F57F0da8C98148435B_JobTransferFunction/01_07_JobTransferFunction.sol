// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/**
 * @title Transfer Function v1.1
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

// This function is called when a Job NFT is transferred

interface JobsInterface {
    function resetJob(uint _jobId) external;
}

contract JobTransferFunction is AccessControl {

    uint public lastTokenId = 0;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public jobsAddress = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 

    event ProcessedJob (address from, address to, uint256 indexed jobId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, jobsAddress);
    }

    function jobTransfer(address from, address to, uint256 tokenId) public onlyRole(MINTER_ROLE) { 
        lastTokenId = tokenId;
        JobsInterface(jobsAddress).resetJob(tokenId);
        emit ProcessedJob(from, to, tokenId);
    }

    function setJobsContract(address _addr) public onlyRole(MINTER_ROLE) {
        jobsAddress = _addr;
    }

    function testCallJobs(uint tokenId) public onlyRole(MINTER_ROLE) {
        JobsInterface(jobsAddress).resetJob(tokenId);
    }

}