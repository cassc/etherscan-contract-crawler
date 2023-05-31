// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

interface BadFaceBots {
	function botsBalance(address _user) external view returns(uint256);
}

contract Trash is ERC20("Trash", "TRASH"), ReentrancyGuard, AccessControl {
using SafeMath for uint256;

	bytes32 public constant EARNER_ROLE = keccak256("EARNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

	uint256 constant public BASE_RATE = 10 ether;
	// March 14, 2032 23:59:59 GMT+0000
	uint256 public END = 1962921599;
	uint256 public START = 1647302400;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

	BadFaceBots public botsContract;

	event RewardReceived(address indexed user, uint256 reward);
	event EarnReward(address indexed user, uint256 amount);
	event Burned(address indexed user, uint256 amount);
	modifier onlyAdmin() {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),"Restricted to admins");
		_;
	}

	constructor(address tokenAddress) {
		botsContract = BadFaceBots(tokenAddress);
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(EARNER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

		_setRoleAdmin(EARNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	// called on transfers
	function transferTokens(address _from, address _to) external {
		require(msg.sender == address(botsContract));
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = lastUpdate[_from];
			if(timerFrom <= 0){
				timerFrom = START;
			}
			if (timerFrom > 0)
				rewards[_from] += botsContract.botsBalance(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
			if (timerFrom != END)
				lastUpdate[_from] = time;
			if (_to != address(0)) {
				uint256 timerTo = lastUpdate[_to];
                if(timerTo <= 0){
                    timerTo = START;
                }
				if (timerTo > 0)
					rewards[_to] += botsContract.botsBalance(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
				if (timerTo != END)
					lastUpdate[_to] = time;
			}
	}

	// called on transfers
	function updateReward(address _from) internal {
		require(msg.sender == _from);
		uint256 time = min(block.timestamp, END);
		uint256 timerFrom = lastUpdate[_from];
		if(timerFrom <= 0){
			timerFrom = START;
		}
		if (timerFrom > 0)
			rewards[_from] += botsContract.botsBalance(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
		if (timerFrom != END)
			lastUpdate[_from] = time;
	}

	function getReward(address _user) external nonReentrant {
		require(msg.sender == _user);
		updateReward(_user);
		uint256 reward = rewards[_user];
		if (reward > 0) {
			rewards[_user] = 0;
			_mint(_user, reward);
			emit RewardReceived(_user, reward);
		}
	}

	function earnReward(address _user, uint256 _amount) external {
		require(hasRole(EARNER_ROLE, msg.sender), "Caller is not a earner");
		rewards[_user] += _amount;
		emit EarnReward(_user, _amount);
	}

	function burn(address _user, uint256 _amount) external {
		require(msg.sender == _user);
		_burn(_user, _amount);
		emit Burned(_user, _amount);
	}

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 timerFrom = lastUpdate[_user];
		if(timerFrom <= 0){
			timerFrom = START;
		}
		uint256 pending = botsContract.botsBalance(_user).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
		return rewards[_user] + pending;
	}

	//emergency usage
    function reserve(uint256 amount) public onlyAdmin {
        _mint(msg.sender, amount);
    }

    function setEndTime(uint256 time) public onlyAdmin {
        END = time;
    }
}