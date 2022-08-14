// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Transfer Function v1.0
 *
 * This function is called when a Regular NFT is transferred
 * 
 * - after deployment:
 *      + set MINTER role on Regular NFT contract for this contract
 *      + set MINTER role on Jobs contract for this contract
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface _JobsInterface {
    function resetJob(uint _jobId) external;
}

contract RegularTransferFunction is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // address public jobsAddress = 0x3bbc725Bd91C086Ef31a3BAF0621FAA94cF53bC9; // rinkeby
    address public jobsAddress = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; // mainnet
    address public regularAddress = 0x6d0de90CDc47047982238fcF69944555D27Ecb25; 

    event TransferHook (uint regId, uint indexed jobId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, jobsAddress);
        _grantRole(MINTER_ROLE, regularAddress);
    }

// admin

    function regularTransfer(uint regId, uint jobId) public onlyRole(MINTER_ROLE) { 
        _JobsInterface(jobsAddress).resetJob(jobId);
        emit TransferHook(regId, jobId);
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