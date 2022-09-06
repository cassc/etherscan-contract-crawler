// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Transfer Function v1.2
 *
 * This function is called when a Job NFT is transferred
 * 
 * - after deployment:
 *      + set MINTER roles on Jobs for JobTransferContract
 *      + set MINTER role on JobTransferContract for Jobs
 *      + set contract address on Jobs to JobTransfer Contract
 *      + set contract address on JobTransfer Contract for Jobs
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface _JobsInterface {
    function resetJob(uint _jobId) external;
}

contract JobTransferFunction is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public jobsAddress = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 

    event TransferHook (address from, address to, uint256 indexed jobId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, jobsAddress);
    }

    function jobTransfer(address from, address to, uint256 tokenId) public onlyRole(MINTER_ROLE) { 
        _JobsInterface(jobsAddress).resetJob(tokenId);
        emit TransferHook(from, to, tokenId);
    }

    function setJobsContract(address _addr) public onlyRole(MINTER_ROLE) {
        jobsAddress = _addr;
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

}