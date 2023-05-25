// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract TeamVesting is Ownable {
    using SafeMath for uint256;
    // Factory public factory;
    // address payable public marketAddress;
    ERC20 private ernToken;
    address public tokenAddress;
    bool public debug;
    uint public timestamp;  // seteable timestamp for debugging;
    uint256 public totalLocked;  // total ERN committed

    struct Account {
        address accountAddress;
        uint startTime;  // start vesting
        uint vestingDays;  // total vesting days, e.g. 365 for 1 year
        uint256 allocation;  // total tokens allocation
        uint256 withdrew;  // total tokens withdrew
        bool paused; // if allowed to withdraw or not
    }
    mapping(address => Account) public accounts;  // make private on mainnet

    event AccountAdded(address indexed _address);
    event AccountWithdrew(address indexed claimer, uint256 amount);

    /// @notice Constructor
    /// @param _tokenAddress Token address
    constructor(address _tokenAddress, bool _debug) {
        tokenAddress = _tokenAddress;
        ernToken = ERC20(tokenAddress);
        debug = _debug;
    }

    /// @notice Add account
    /// @param _address Account address
    /// @param _startTime Start vesting time in epoch seconds
    /// @param _vestingDays Total vesting days
    /// @param _allocation Total ERN allocation 
    function addAccount(address _address, uint _startTime, uint _vestingDays, uint256 _allocation) external onlyOwner {
        require(_allocation <= ERNBalance() - totalLocked, "Not enough ERN left for this allocation");
        require(accounts[_address].accountAddress == address(0), "Account already exists. Please remove account first");
        Account memory _account = Account({
            accountAddress: _address,
            startTime: _startTime,
            vestingDays: _vestingDays,
            allocation: _allocation,
            withdrew: 0,
            paused: false
        });
        accounts[_address] = _account;
        totalLocked += _allocation;
        emit AccountAdded(_address);
    }

    /// @notice Pause account - temporarily pause an account from withrdrawing
    /// @param _address Account address
    function pauseAccount(address _address) external onlyOwner {
        accounts[_address].paused = true;
    }

    /// @notice UnPause account - reenable an account from withrdrawing
    /// @param _address Team member address
    function unpauseAccount(address _address) external onlyOwner {
        accounts[_address].paused = false;
    }

    /// @notice Remove account - if an account needs to be redone.
    /// @param _address Account address
    function removeAccount(address _address) external onlyOwner {
        totalLocked -= (accounts[_address].allocation - accounts[_address].withdrew);
        delete(accounts[_address]);
    }

    /// @notice Compute allowed withdrawal
    /// @param _address Account address
    function allowance(address _address) public view returns (uint256) {
        uint _ts = timeNow();
        Account memory _account = accounts[_address];
        if (
            _account.allocation == 0 || _account.vestingDays == 0 || _account.startTime >= _ts
        ) {
            return 0;
        }
        // Calculate daily allowance
        uint256 _dailyAllowance = _account.allocation / _account.vestingDays;
        // Calculate days that passed
        uint _secondsPassed = _ts - _account.startTime;
        uint _daysPassed = _secondsPassed / 86400;
        if (_daysPassed > _account.vestingDays) {
            _daysPassed = _account.vestingDays;
        }
        // Total allowance
        uint256 _allowance = _dailyAllowance * _daysPassed;
        // Substract already withdrawn
        uint256 _allowed = _allowance - _account.withdrew;
        return _allowed;
    }

    /// @notice Returns total token balance
    function ERNBalance() public view returns (uint256) {
        return ernToken.balanceOf(address(this));
    }

    /// @notice Account withdrawal
    function withdraw() public {
        Account storage _account = accounts[msg.sender];
        uint _ts = timeNow();
        uint256 _allowance = allowance(msg.sender);
        require(_ts > _account.startTime, "Vesting hasn't started yet");
        require(_account.paused == false, "Your withdrawals have been paused. Please contact admin");
        require(_allowance <= ERNBalance(), "Not enough funds");
        require(_allowance <= _account.allocation, "Cannot withdraw more than allocated");
        require(_allowance > 0, "No allowance available to withdraw");
        // Update and send:
        _account.withdrew += _allowance;
        totalLocked -= _allowance; // When withdrawing, the locked ERN are released
        ernToken.transfer(msg.sender, _allowance);
        emit AccountWithdrew(msg.sender, _allowance);
    }

    /// @notice Timestamp function for debugging
    function timeNow() public view returns (uint) {
        if (debug) {
            return timestamp;
        } else {
            return block.timestamp;
        }
    }

    /// @notice Set timestamp for debugging
    /// @param _timestamp Epoch time in seconds
    function setNow(uint _timestamp) public onlyOwner {
        timestamp = _timestamp;
    }

    /// @notice Emergency withdrawal from admin
    /// @param _address Where to withdraw to
    /// @param _amount Amount to withdraw
    function adminWithdraw(address _address, uint256 _amount) external onlyOwner {
        require(_amount <= ERNBalance() - totalLocked, "Cannot withdraw more than balance minus commited lock");
        ernToken.transfer(_address, _amount);
    }

}