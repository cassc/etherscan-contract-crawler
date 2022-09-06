// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title SalaryDept v1.0
 *  
 *  This contract determines salaries + pay schedule
 *  
 * @dev
 * - Upon deployment
 *   - constructor requires address of Jobs contract
 *   - Set minter role to Jobs contract for FinanceDept address
 *   - Set minter role to RegularToken ERC20 contract for FinaceDept address
 */

import "./RegularToken.sol";
import "./Jobs.sol";
import "./Salaries.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract FinanceDept is AccessControl, Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint public payDuration = 1 weeks;
    uint public maxClaimTime = 10 weeks;
	RegularToken regularsToken;
    Jobs jobs;
    Salaries salaries;

    event ClaimedSalary (address wallet, uint amount);
    event ClaimedSalaries (address wallet, uint amount);

    constructor() { 
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        regularsToken = RegularToken(0x78b5C6149C87c82EDCffC73C230395abbc56DdD5); // Regulars Token on Rinkeby
    }

// GET SALARIES

    function unclaimedDuration(uint _jobId) public view returns (uint) {
        uint _duration = block.timestamp - jobs.getTimestamp(_jobId);
        return Math.min(_duration, maxClaimTime);
    }

    function unclaimedByJob(uint _jobId) public view returns (uint) {
        return salaries.salary(_jobId) * unclaimedDuration(_jobId) / payDuration;
    } 

    function unclaimedByCompany(uint[] memory _jobIds) public view returns (uint) {
        uint _companyId = jobs.getCompanyId(_jobIds[0]); 
        uint _combinedSalaries = 0; 
        uint i;
        for (i = 0; i < _jobIds.length;i++){
            uint _jobId = _jobIds[i];
            require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
            _combinedSalaries += unclaimedByJob(_jobId);
        }
        return salaries.teamworkBonus(_combinedSalaries, _jobIds.length, jobs.getCapacity(_companyId));
    }

    function unclaimedAll(uint[] memory _jobIds) public view returns (uint) {
        return 100;
    }

// CLAIM

    // function claimByJob(uint _jobId) public whenNotPaused {
    //     require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
    //     require(!jobs.isUnassigned(_jobId),"No reg working the job");
    //     require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
    //     uint _amount = unclaimedByJob(_jobId);
    //     jobs.setTimestamp(_jobId, block.timestamp);
    //     regularsToken.mint(msg.sender,_amount); // SEND THE TOKENS!
    //     emit ClaimedSalary(msg.sender, _amount);
    // }

    // function claimByCompany(uint[] memory _jobIds) public whenNotPaused { // must be in same company
    //     uint _companyId = jobs.getCompanyId(_jobIds[0]);
    //     uint _combinedSalaries = 0;
    //     for (uint i = 0; i < _jobIds.length;i++){
    //         uint _jobId = _jobIds[i];
    //         require(jobs.getCompanyId(_jobId) == _companyId, "Not all same company id");
    //         require(jobs.ownerOf(_jobId) == msg.sender, "Not the owner of this job");
    //         require(!jobs.isUnassigned(_jobId),"No reg working the job");
    //         require(jobs.ownerOfReg(jobs.getRegId(_jobId)) == msg.sender,"You don't own assigned reg");
    //         _combinedSalaries += unclaimedByJob(_jobId);
    //         jobs.setTimestamp(_jobId, block.timestamp);
    //     }
    //     // for every 1% of the company that you own, you get 10% bonus
    //     uint _grandTotal = salaries.teamworkBonus(_combinedSalaries, _jobIds.length, jobs.getCapacity(_companyId));
    //     regularsToken.mint(msg.sender,_grandTotal); // SEND THE TOKENS!
    //     emit ClaimedSalaries(msg.sender, _grandTotal);
    // }

    // function claimAll(uint[][] memory _jobIdsByCompany) public whenNotPaused {
    //     // to-do
    // }

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
        jobs = Jobs(_addr);
    }

    function setSalariesByAddr(address _addr) public onlyRole(MINTER_ROLE){
        salaries = Salaries(_addr);
    }

    function setRegularsToken(address _addr) public onlyRole(MINTER_ROLE) {
        regularsToken = RegularToken(_addr);
    }

    // get

    function getRegularsTokenAddress() public view returns (address) {
        return address(regularsToken);
    }

    function getJobsTokenAddress() public view returns (address) {
        return address(jobs);
    }
}