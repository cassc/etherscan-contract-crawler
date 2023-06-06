//
// EntitiesDAO token
// $NTTZ
// https://entities.wtf
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface MGEX0 {
	function balanceOG(address _user) external view returns(uint256);
}

contract NTTZToken is ERC20("EntitiesDAO Token", "NTTZ"), Ownable {
    
	using SafeMath for uint256;
	bool public hasClaimingStarted = false;
	uint256 constant public BASE_RATE = 10 ether; 
	uint256 constant public INITIAL_ISSUANCE = 1800 ether;
	uint256 constant public END = 1951230000; //Friday, October 31, 2031 4:20:00 PM (GMT)
	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;
	mapping(address => uint256) public rates; // Contributor wallet daily rate
	mapping(address => uint256) public ends; // Contributor wallet vesting end

	MGEX0 public metaGeckosContract;

	event RewardPaid(address indexed user, uint256 reward);
	event RewardBal(address indexed user, uint256 reward);
	event RewardCreated(uint256 rewards);
	
	function createInitialReward(address _user, uint256 _initial) public onlyOwner {
		_initial = _initial * 10**uint(decimals());
		setInitialReward(_user, _initial);
	}
	
    function setInitialReward(address _user, uint256 _amount) internal {
        // Update the value at this address
        rewards[_user] = rewards[_user] + _amount;
        emit RewardCreated(rewards[_user]);
    }
	
	function createDailyReward(address _user, uint256 _rates, uint256 _ends) public onlyOwner {
	    _rates = _rates * 10**uint(decimals());
		setDailyReward(_user, _rates, _ends);
	}
	
	function setDailyReward(address _user, uint256 _amount, uint256 _ends) internal {
        // Update the value at this address
        ends[_user] = _ends;
        rates[_user] = _amount;
        emit RewardCreated(rewards[_user]);
    }
    
    function resetDailyContribReward(address _user)public onlyOwner{
        ends[_user] = 0;
        rates[_user] = 0;
    }
    
    function resetAllContribReward(address _user)public onlyOwner{
        ends[_user] = 0;
        rates[_user] = 0;
        rewards[_user] = 0;
    }
	
    //NTTZ Claiming controller START
	function startClaiming() public onlyOwner {
        hasClaimingStarted = true;
    }
    
    //NTTZ Claiming controller PAUSE
    function pauseClaiming() public onlyOwner {
        hasClaimingStarted = false;
    }

	constructor(address _mgex0) {
		metaGeckosContract = MGEX0(_mgex0);
	}
	
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	// Called when minting genesis metageckos
	// 10 $NTTZ per genesis metagecko per day for 10 years
	// + 1800 $NTTZ initial reward per genesis metagecko minted
	function updateRewardOnMint(address _user, uint256 _amount) external {
		require(msg.sender == address(metaGeckosContract), "Can't call this");
		uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
		if (timerUser > 0)
			rewards[_user] = rewards[_user].add(metaGeckosContract.balanceOG(_user).mul(BASE_RATE.mul((time.sub(timerUser)))).div(86400)
			.add(_amount.mul(INITIAL_ISSUANCE)));
		else 
			rewards[_user] = rewards[_user].add(_amount.mul(INITIAL_ISSUANCE));
		    lastUpdate[_user] = time;
	}
	
	// called on transfers
	function updateReward(address _from, address _to, uint256 _tokenId) external {
		require(msg.sender == address(metaGeckosContract));
		if (_tokenId < 4000) {
			uint256 time = min(block.timestamp, END);
			uint256 timerFrom = lastUpdate[_from];
			if (timerFrom > 0)
				rewards[_from] += metaGeckosContract.balanceOG(_from).mul(BASE_RATE.mul((time.sub(timerFrom)))).div(86400);
			if (timerFrom != END)
				lastUpdate[_from] = time;
			if (_to != address(0)) {
				uint256 timerTo = lastUpdate[_to];
				if (timerTo > 0)
					rewards[_to] += metaGeckosContract.balanceOG(_to).mul(BASE_RATE.mul((time.sub(timerTo)))).div(86400);
				if (timerTo != END)
					lastUpdate[_to] = time;
			}
		}
	}
	
	// contributor reward update
	function updateContribReward(address _from) external {
// 		require(msg.sender == address(metaGeckosContract));
			uint256 time = min(block.timestamp, ends[_from]);
			uint256 timerFrom = lastUpdate[_from];
			if (timerFrom > 0)
				rewards[_from] += rates[_from].mul((time.sub(timerFrom))).div(86400);
			if (timerFrom != ends[_from])
				lastUpdate[_from] = time;
		}

	function getReward(address _to) external {
		require(msg.sender == address(metaGeckosContract));
	    require(hasClaimingStarted == true, "NTTZ claiming is paused");
		uint256 reward = rewards[_to];
		if (reward > 0) {
        	rewards[_to] = 0;
        	_mint(_to, reward);
        	emit RewardPaid(_to, reward);
		}
	}
	
	function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(metaGeckosContract));
		_burn(_from, _amount);
	}

	function getTotalClaimable(address _user) external view returns(uint256) {
		uint256 time = min(block.timestamp, END);
		uint256 pending = metaGeckosContract.balanceOG(_user).mul(BASE_RATE.mul((time.sub(lastUpdate[_user])))).div(86400);
		return rewards[_user] + pending;
	}
	
}