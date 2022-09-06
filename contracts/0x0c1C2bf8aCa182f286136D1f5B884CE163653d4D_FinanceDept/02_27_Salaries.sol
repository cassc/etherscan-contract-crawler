// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 * @title Regular Salaries v1.1
 */

import "./Jobs.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Salaries is AccessControl {
    uint public constant RANDOM_SEED = 69;
    uint public constant SALARY_DECIMALS = 2;
    uint public constant MAX_TEAMWORK_BONUS = 300;
    uint public SALARY_MULTIPLIER = 100;  // basis points
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Jobs jobs;

	constructor(address _addr) {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
	    _grantRole(MINTER_ROLE, msg.sender);
	    _grantRole(MINTER_ROLE, tx.origin);
        jobs = Jobs(_addr);
	}

    function basepay(uint _jobId, uint _companyBase, uint _companySpread) public view returns (uint) {
        uint _baseSalary = _companyBase * 10 ** 18 * SALARY_MULTIPLIER / 100;
        uint _spread = _baseSalary * _companySpread / 100;                       // Spread value before randomization
        uint _r = uint(keccak256(abi.encodePacked(_jobId, RANDOM_SEED))) % 100;  // Random integer 0-100
        uint _result = _baseSalary + (_r * _spread / 100) - (_spread / 2);
        // return (_result / 10 ** SALARY_DECIMALS);            // NOT ROUNDED
        return (_result * 4 / 10 ** 20) * 100 / 4 * 10 ** 16;   // ROUNDED
    }

    function basepay(uint _jobId) public view returns (uint) {
        uint _companyId = jobs.getCompanyId(_jobId);
        return basepay(_jobId, companyBase(_companyId), companySpread(_companyId)); 
    }

    function seniorityBonus(uint _level, uint _basePay) public pure returns (uint) {
        uint _bonusPercent = 0;
        if (_level > 0)
            _bonusPercent = (2 ** (_level - 1) * 10); 
        return _bonusPercent * _basePay / 100; 
    }

    function seniorityBonus(uint _jobId) public view returns (uint) {
        uint _seniorityLevel = jobs.getSeniorityLevel(_jobId);
        uint _basepay = basepay(_jobId);
        return seniorityBonus(_seniorityLevel, _basepay);
    }

    function salary(uint _jobId) public view returns (uint) {
        uint _basepay = basepay(_jobId);
        uint _seniorityLevel = jobs.getSeniorityLevel(_jobId);
        uint _seniorityBonus = seniorityBonus(_seniorityLevel, _basepay);
        uint _result = _basepay + _seniorityBonus;
        return _result;
    }    

    function teamworkBonus(uint _numOwned, uint _capacity) public pure returns (uint) { 
        // 10% bonus for every 1% of the company that you own .. total jobs owned must be > 1
        // returns a percent
        uint _result = 0;
        if (_numOwned > 1)
          _result = (_numOwned * 100 / _capacity) * 10;
        return Math.min(_result, MAX_TEAMWORK_BONUS);
    }

    function teamworkBonus(uint _totalSalaries, uint _numOwned, uint _capacity) public pure returns (uint) { 
        return _totalSalaries + (_totalSalaries * teamworkBonus(_numOwned, _capacity) / 100);
    }

    // from Jobs contract

    function companyBase(uint _companyId) public view returns (uint) {
        return jobs.getBaseSalary(_companyId);
    }

    function companySpread(uint _companyId) public view returns (uint) {
        return jobs.getSpread(_companyId);
    }

    // Admin

    function setJobsAddr(address _addr) public onlyRole(MINTER_ROLE) {
        jobs = Jobs(_addr);
    }

    function setSalaryMultiplier(uint _points) public onlyRole(MINTER_ROLE) {
        SALARY_MULTIPLIER = _points;
    }
}