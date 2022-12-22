pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRDNRegistry} from "./RDNRegistry.sol";

interface IRDNDepositary {
    
    event TokensLocked(address indexed userAddress, uint indexed userId, uint amount, uint unlockAfter);

    event TokensUnlocked(address indexed userADDRESS, uint indexed userId, uint amount);

    function getLockedAmount(uint _userId) external view returns(uint);

    function getTotalLockedAmount() external view returns(uint);

}

contract RDNDepositary is Context, AccessControlEnumerable {
    bytes32 public constant WITHDRAW_OVERAGE_ROLE = keccak256("WITHDRAW_OVERAGE_ROLE");
    bytes32 public constant PAUSE_LOCKING_ROLE = keccak256("PAUSE_LOCKING_ROLE");
    bytes32 public constant LOCK_PERIOD_ROLE = keccak256("LOCK_PERIOD_ROLE");
    
    mapping (uint => uint) balances;
    mapping (uint => uint) unlockAfter;
    uint public totalLocked;
    uint public lockPeriod;
    bool public lockingPaused;

    IERC20 public token;
    IRDNRegistry registry;

    event TokensLocked(address indexed userAddress, uint indexed userId, uint amount, uint unlockAfter);

    event TokensUnlocked(address indexed userADDRESS, uint indexed userId, uint amount);

    constructor (address _tokenAddress, address _registryAddress, uint _lockPeriod) {
        token = IERC20(_tokenAddress);
        registry = IRDNRegistry(_registryAddress);
        lockPeriod = _lockPeriod;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAW_OVERAGE_ROLE, _msgSender());
        _setupRole(PAUSE_LOCKING_ROLE, _msgSender());
    }
    
    function lockTokens(uint _amount) public {
        require(lockingPaused == false, "Locking is paused");
        uint userId = registry.getUserIdByAddress(_msgSender());
        require(userId > 0, "Sender address is not registered");
        token.transferFrom(_msgSender(), address(this), _amount);
        balances[userId] += _amount;
        totalLocked += _amount;
        unlockAfter[userId] = block.timestamp + lockPeriod;
        emit TokensLocked(_msgSender(), userId, _amount, unlockAfter[userId]);
    }
    
    function unlockTokens() public {
        uint userId = registry.getUserIdByAddress(_msgSender());
        uint balance = balances[userId];
        require(userId > 0, "Sender address is not registered");
        require(balance > 0, "Balance is empty");
        require(unlockAfter[userId] < block.timestamp);
        token.transfer(_msgSender(), balance);
        balances[userId]  = 0;
        totalLocked -= balance;
        emit TokensUnlocked(_msgSender(), userId, balance);
    }

    function withdrawOverage(address _recipient) public onlyRole(WITHDRAW_OVERAGE_ROLE) {
        uint realBalance = token.balanceOf(address(this));
        uint overage = realBalance - totalLocked;
        require(overage > 0, "Nothing to withdraw");
        token.transfer(_recipient, overage);
    }

    function pauseLocking() public onlyRole(PAUSE_LOCKING_ROLE) {
        require(lockingPaused == false, "Locking is already paused");
        lockingPaused = true;
    }

    function unpauseLocking() public  onlyRole(PAUSE_LOCKING_ROLE){
        require(lockingPaused == true, "Locking is not paused");
        lockingPaused = false;
    }

    function setupLockPeriod(uint _lockPeriod) public onlyRole(LOCK_PERIOD_ROLE) {
        lockPeriod = _lockPeriod;
    }

    function getLockedAmount(uint _userId) public view returns(uint) {
        return balances[_userId];
    }

    function getTotalLockedAmount() public view returns(uint) {
        return totalLocked;
    }

}