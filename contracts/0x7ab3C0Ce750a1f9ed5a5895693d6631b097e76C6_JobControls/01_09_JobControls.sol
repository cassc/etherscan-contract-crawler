// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Job Controls v1.0
 *
 * Updates to job functions, with new timestamp storage location
 * 
 * - after deployment:
 *      + On Jobs, give this contract's address a MINTER role 
 *      + On this contract, give TransferFunction contract a MINTER role     
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface RegularsInterface {
    function ownerOf(uint _tokenId) external returns (address);
}

interface JobsInterface {
    function ownerOf(uint _jobId) external returns (address);
    function setRegId(uint _jobId, uint _regId) external;
    function setJobByRegId(uint _regId, uint _jobId) external;
    function getJobByRegId(uint _regId) external view returns (uint);
    function getRegId(uint _jobId) external view returns (uint);
}

interface TimestampsInterface {
    function set(uint _jobId, uint32 _timestamp) external;  
}

contract JobControls is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE    = keccak256("MINTER_ROLE");
    address public constant jobsAddr       = 0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15;   // Mainnet
    address public constant regularAddr    = 0x6d0de90CDc47047982238fcF69944555D27Ecb25;   // Mainnet + Rinkeby
    address public          timestampsAddr = 0x9a63c292d9B930Dd088576A8079B99921953E65b;   // Mainnet
    JobsInterface jobs; 
    TimestampsInterface timestamps;
    RegularsInterface regulars;

    event Reset (uint indexed jobId);
    event RegularIdChange (uint256 indexed jobId, uint regId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        jobs = JobsInterface(jobsAddr);
        timestamps = TimestampsInterface(timestampsAddr);
        regulars = RegularsInterface(regularAddr);
    }

// Set ID

    function setRegularId_v2(uint _jobId, uint _regId) public whenNotPaused {
        require(jobs.ownerOf(_jobId) == msg.sender,     "Not owner of this job.");
        require(regulars.ownerOf(_regId) == msg.sender, "Not owner of Regular");
        require(jobs.getRegId(_jobId) != _regId,        "This reg already assigned to this job"); 
        require(jobs.getJobByRegId(_regId) == 0,        "This reg already working another job");
        uint _oldRegId = jobs.getRegId(_jobId); 
        if (_oldRegId != 10000)                 // If Job has a Regular assigned 
            jobs.setJobByRegId(_oldRegId,0);    // Clear it
        jobs.setRegId(_jobId, _regId);      
        jobs.setJobByRegId(_regId,_jobId);  
        timestamps.set(_jobId, uint32(block.timestamp));                            
        emit RegularIdChange(_jobId, _regId);
    }

// Reset + Unassign

    function reset_v2(uint _jobId) public whenNotPaused onlyRole(MINTER_ROLE) { 
        uint _oldRegId = jobs.getRegId(_jobId);
        jobs.setRegId(_jobId, 10000);           // There is no #10,000
        jobs.setJobByRegId(_oldRegId,0);        // There is no Job 0
        timestamps.set(_jobId, uint32(block.timestamp));
        emit Reset(_jobId);
    }

    function unassignRegularId_v2(uint _jobId) public whenNotPaused {
        require(jobs.ownerOf(_jobId) == msg.sender, "Not owner of this job.");
        reset_v2(_jobId);
    }

// Other admin functions

    function setTimestampsAddr(address _addr) public onlyRole(MINTER_ROLE) {
        timestamps = TimestampsInterface(_addr);
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

}