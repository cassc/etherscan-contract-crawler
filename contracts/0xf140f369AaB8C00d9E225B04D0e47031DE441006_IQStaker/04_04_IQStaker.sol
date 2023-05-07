pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IQStaker is Ownable {
	IERC20 public iqToken;
	uint256 public constant STAKING_DURATION = 30 days;
	uint256 public constant PENALTY_PERCENTAGE = 10;

	struct Stake {
		uint256 amount;
		uint256 startTime;
	}

	mapping(address => Stake) public stakes;
	mapping(address => bool) public hasStaked;
	address[] public stakingAddresses;
	uint256 public totalPenalty;

	constructor(IERC20 _iqToken) {
		iqToken = _iqToken;
	}

	function stake(uint256 _amount) external {
		require(_amount > 0, "Amount must be greater than 0");

		require(iqToken.transferFrom(msg.sender, address(this), _amount) == true, "Transfer failed");

		if (stakes[msg.sender].amount == 0 && hasStaked[msg.sender] == false) {
			stakingAddresses.push(msg.sender);
			hasStaked[msg.sender] = true;
		}

		stakes[msg.sender].amount += _amount;
		stakes[msg.sender].startTime = block.timestamp;
	}

	function unstake() external {
		require(stakes[msg.sender].amount > 0, "No stake to withdraw");

		uint256 stakeAmount = stakes[msg.sender].amount;
		uint256 penalty = 0;

		if (block.timestamp < stakes[msg.sender].startTime + STAKING_DURATION) {
			penalty = (stakeAmount * PENALTY_PERCENTAGE) / 100;
			totalPenalty += penalty;
		}

		stakes[msg.sender].amount = 0;
		iqToken.transfer(msg.sender, stakeAmount - penalty);
	}

	function withdrawPenalty() external onlyOwner {
		require(totalPenalty > 0, "No penalty to withdraw");

		uint256 penalty = totalPenalty;
		totalPenalty = 0;
		iqToken.transfer(msg.sender, penalty);
	}

	function getStakingAddresses() external view returns (address[] memory) {
		return stakingAddresses;
	}
}