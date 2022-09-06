// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title SalaryDept v1.1
 *  
 *  This contract determines salaries + pay schedule
 *  
 * @dev
 * - Upon deployment
 *   - In Jobs contract, set FinanceDept address as MINTER role 
 *   - In FinanceDept contract, set Jobs address as MINTER role
 *   - In ERC20 contract, add FinaceDept address as MINTER role
 *   - In Jobs contract, update address for FinanceDept
 *   - In FinanceDept contract, update address for Jobs
 *   - In FinanceDept contract, update address for Salaries
 *   - In FinanceDept contract, update Regular Token address
 */

import "./Salaries.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface JobsInterface {
    function setTimestamp(uint _jobId, uint _timestamp) external;
    function sameOwner(uint _jobId) external view returns (bool);
    function getTimestamp(uint _jobId) external view returns (uint);
    function getCompanyId(uint _jobId) external view returns (uint);
    function getRegId(uint _jobId) external view returns (uint);
    function isUnassigned(uint _jobId) external view returns (bool);
    function getCapacity(uint _companyId) external view returns (uint);
    function ownerOfReg(uint _regId) external view returns (address);
    function ownerOf(uint _jobId) external view returns (address);
}

interface RegularTokenInterface {
        function mint(address to, uint256 amount) external; 
}

contract FinanceDept is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public payDuration = 1 weeks;
    uint public maxClaimTime = 24 weeks;
	RegularTokenInterface regularsToken;
    JobsInterface jobs;
    Salaries salaries;

    event Claimed (address wallet, uint amount);

    constructor() { 
        // reset roles to tx.origin when deploying jobs
	    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, msg.sender);
        regularsToken = RegularTokenInterface(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5);  
        setJobsByAddr(0x878ADc4eF1948180434005D6f2Eb91f0AF3E0d15);
        setSalariesByAddr(0x215CcC4805B49079BFa5e2d10622A29db3Dc2017); 
        // regularsToken = RegularTokenInterface(0xf29170447b21baE0f940Ed27629DB4Cc9b81Fbde);   // rinkeby
        // setJobsByAddr(0x3bbc725Bd91C086Ef31a3BAF0621FAA94cF53bC9);                           // rinkeby
        // setSalariesByAddr(0x7E9f3138d209b275B29458552A1Bf4D1bBcaf741);                       // rinkeby
    }

// View Functions

    function unclaimedDuration(uint _jobId) public view returns (uint) {
        uint _duration = block.timestamp - jobs.getTimestamp(_jobId);
        return Math.min(_duration, maxClaimTime);
    }

    function unclaimedByJob(uint _jobId) public view returns (uint) {
        return salaries.salary(_jobId) * unclaimedDuration(_jobId) / payDuration;
    } 

    // Accepts a 2D array, with the first element of each sub-array being the companyId -- in numerical order
    function salariesWithBonus(uint[][] memory _sortedIds) public view returns (uint,uint) {
        uint _numCompanies = _sortedIds.length;
        uint _salaries = 0;
        uint _salariesWithBonus;
        for (uint i = 0; i < _numCompanies; i++) {
            uint _companyId = _sortedIds[i][0];
            uint _companySalaries = 0;
            require(i == 0 || _sortedIds[i-1][0] < _sortedIds[i][0], "Company IDs must be sequential");
            for (uint j = 1; j < _sortedIds[i].length; j++) {
                uint _jobId = _sortedIds[i][j];
                require(j == 1 || _sortedIds[i][j-1] < _sortedIds[i][j], "Ids must be sequential");
                require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
                require(!jobs.isUnassigned(_jobId),"No reg working the job");
                _companySalaries += salaries.salary(_jobId);
            }
            _salaries += _companySalaries;
            _salariesWithBonus += salaries.teamworkBonus(_companySalaries, _sortedIds[i].length - 1, jobs.getCapacity(_companyId));
        }
        return (_salaries, _salariesWithBonus);
    }

    // Accepts a 2D array, with the first element of each sub-array being the companyId -- in numerical order
    function unclaimedWithBonus(uint[][] memory _sortedIds) public view returns (uint,uint) {
        uint _numCompanies = _sortedIds.length;
        uint _unclaimed = 0;
        uint _unclaimedWithBonus = 0;
        for (uint i = 0; i < _numCompanies; i++) {
            uint _companyId = _sortedIds[i][0];
            uint _companyUnclaimed = 0;
            require(i == 0 || _sortedIds[i-1][0] < _sortedIds[i][0], "Company IDs must be sequential");
            for (uint j = 1; j < _sortedIds[i].length; j++) {
                uint _jobId = _sortedIds[i][j];
                require(j == 1 || _sortedIds[i][j-1] < _sortedIds[i][j], "Ids must be sequential");
                require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
                require(!jobs.isUnassigned(_jobId),"No reg working the job");
                _companyUnclaimed += unclaimedByJob(_jobId);
            }
            _unclaimed += _companyUnclaimed;
            _unclaimedWithBonus += salaries.teamworkBonus(_companyUnclaimed, _sortedIds[i].length - 1, jobs.getCapacity(_companyId));
        }
        return (_unclaimed, _unclaimedWithBonus);
    }

// CLAIM

    function claimByJob(uint _jobId) public whenNotPaused {
        require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
        require(!jobs.isUnassigned(_jobId),"No reg working the job");
        require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
        uint _amount = unclaimedByJob(_jobId);
        jobs.setTimestamp(_jobId, block.timestamp);
        regularsToken.mint(msg.sender,_amount); // SEND THE TOKENS!
        emit Claimed(msg.sender, _amount);
    }

    // Accepts a 2D array, with the first element of each sub-array being the companyId -- in numerical order
    function claim(uint[][] memory _sortedIds) public whenNotPaused {
        uint _numCompanies = _sortedIds.length;
        uint _unclaimedWithBonus = 0;
        for (uint i = 0; i < _numCompanies; i++) {
            uint _companyId = _sortedIds[i][0];
            uint _companyUnclaimed = 0;
            require(i == 0 || _sortedIds[i-1][0] < _sortedIds[i][0], "Company IDs must be sequential");
            for (uint j = 1; j < _sortedIds[i].length; j++) {
                uint _jobId = _sortedIds[i][j];
                require(j == 1 || _sortedIds[i][j-1] < _sortedIds[i][j], "Ids must be sequential");
                require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
                require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
                require(!jobs.isUnassigned(_jobId),"No reg working the job");
                require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
                _companyUnclaimed += unclaimedByJob(_jobId);
                jobs.setTimestamp(_jobId, block.timestamp); 
            }
            _unclaimedWithBonus += salaries.teamworkBonus(_companyUnclaimed, _sortedIds[i].length - 1, jobs.getCapacity(_companyId));
        }
        regularsToken.mint(msg.sender,_unclaimedWithBonus); // SEND THE TOKENS!
        emit Claimed(msg.sender, _unclaimedWithBonus);
    }

// ADMIN

    function setMaxClaimTime(uint _maxClaimTime) public onlyRole(MINTER_ROLE) {
        maxClaimTime = _maxClaimTime;
    }

    function setPayDuration(uint _payDuration) public onlyRole(MINTER_ROLE) {
        payDuration = _payDuration;
    }

    function pause() public onlyRole(MINTER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MINTER_ROLE) {
        _unpause();
    }

// CONTRACT MANAGEMENT

    // set

    function setJobsByAddr(address _addr) public onlyRole(MINTER_ROLE){
        jobs = JobsInterface(_addr);
    }

    function setSalariesByAddr(address _addr) public onlyRole(MINTER_ROLE){
        salaries = Salaries(_addr);
    }

    function setRegularsTokenAddr(address _addr) public onlyRole(MINTER_ROLE) {
        regularsToken = RegularTokenInterface(_addr);
    }

    // get

    function getRegularsTokenAddr() public view returns (address) {
        return address(regularsToken);
    }

    function getSalariesAddr() public view returns (address) {
        return address(salaries);
    }

    function getJobsAddr() public view returns (address) {
        return address(jobs);
    }
}