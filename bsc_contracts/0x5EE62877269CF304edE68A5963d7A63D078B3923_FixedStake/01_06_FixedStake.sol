// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract FixedStake is Ownable, Pausable {
	using SafeMath for uint256;
	struct Stake {
		address user;
		uint256 amount;
		uint256 withdrawTime;
		bool isStop;
	}

	address public STAKE_TOKEN = 0x54850603B8B24fA876dfE9D0843ca872d95d6A38;
	address public RECEIVER = 0x09b8C6EF5837a613594083724FE36f4f4418528a;

	Stake[] public stakeInfo;

	event STAKING_TOKEN_EVENT(address indexed user, uint256 amount, uint256 id);
	event UNLOCK_EVENT(address indexed user, uint256 amount, uint256 id);

	function stakingToken(uint256 _amount) public whenNotPaused {
		require(
			IERC20(STAKE_TOKEN).balanceOf(msg.sender) >= _amount,
			"FixedStake: your balance not enough to execute the order"
		);
		require(_amount > 0, "FixedStake: amount greater than zero");
		uint256 id = stakeInfo.length;

		stakeInfo.push(Stake(msg.sender, _amount, block.timestamp + 31536000, false));
		IERC20(STAKE_TOKEN).transferFrom(msg.sender, RECEIVER, _amount);

		emit STAKING_TOKEN_EVENT(msg.sender, _amount, id);
	}

	function unlockStake(uint256 _id) public {
		Stake storage stakeDetail = stakeInfo[_id];
		require(
			!stakeDetail.isStop,
			"FixedStake: you have unlocked this stake"
		);
		require(
			stakeDetail.withdrawTime < block.timestamp,
			"FixedStake: you have unlocked this stake right now"
		);
		IERC20(STAKE_TOKEN).transfer(stakeDetail.user, stakeDetail.amount);
		stakeDetail.isStop = true;

		emit UNLOCK_EVENT(stakeDetail.user, stakeDetail.amount, _id);
	}

	function stakeLength() public view returns (uint256) {
		return stakeInfo.length;
	}

	function setStakeToken(address _newAddress) public onlyOwner {
		STAKE_TOKEN = _newAddress;
	}

	function setReceiver(address _receiver) public onlyOwner {
		RECEIVER = _receiver;
	}

	function clearUnknownToken(address _tokenAddress) public onlyOwner {
		uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
			address(this)
		);
		IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}
}