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
    address jobsAddress;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, msg.sender);
        jobsAddress = msg.sender;
    }

    function getCount() public view returns (uint) {
        return count;
    }

    function jobTransfer(address from, address to, uint256 tokenId) public onlyRole(MINTER_ROLE) { 
        count++;
        JobsInterface(jobsAddress).resetJob(tokenId);
    }

}