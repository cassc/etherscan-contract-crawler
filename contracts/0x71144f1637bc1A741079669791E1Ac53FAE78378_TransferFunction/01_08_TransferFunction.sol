// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Transfer Function v1.0
 *
 * Jobs are reset after the job or Regular is transferred.
 * 
 * - after deployment:
 *      + On Jobs, give MINTER roles for this TransferContract
 *      + On Jobs, update JobTransferAddress address to this TransferContract
 */

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface JobControlsInterface {
    function reset_v2(uint _jobId) external;
}

contract TransferFunction is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public constant jobsAddr = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15; 
    address public constant regularAddr = 0x6d0de90CDc47047982238fcF69944555D27Ecb25; 
    address public jobControlsAddr; 

    event JobTransfered (uint indexed jobId);
    event RegTransfered (uint regId, uint indexed jobId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, jobsAddr);
        _grantRole(MINTER_ROLE, regularAddr);
    }

    function jobTransfer(address from, address to, uint256 jobId) public whenNotPaused onlyRole(MINTER_ROLE) { 
        JobControlsInterface(jobControlsAddr).reset_v2(jobId);
        emit JobTransfered(jobId);
    }

    function regularTransfer(uint regId, uint jobId) public whenNotPaused onlyRole(MINTER_ROLE) { 
        JobControlsInterface(jobControlsAddr).reset_v2(jobId);
        emit RegTransfered(regId, jobId);
    }

    function setJobControlsAddr(address _addr) public onlyRole(MINTER_ROLE) {
        jobControlsAddr = _addr;
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

}