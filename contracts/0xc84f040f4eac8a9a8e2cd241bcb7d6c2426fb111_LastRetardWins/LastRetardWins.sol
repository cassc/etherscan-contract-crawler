/**
 *Submitted for verification at Etherscan.io on 2023-07-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ERC20 {
	function allowance(address, address) external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract LastRetardWins {

	ERC20 constant public USDC = ERC20(0x9abC68B33961268A3Ea4116214d7039226de01E1);

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private MAX_TIME = 24 hours;
	uint256 constant private INCREASE_PER_SHARE = 30 seconds;
	uint256 constant private INITIAL_PRICE = 1e23; // 100k
	uint256 constant private INCREMENT = 1e20; // 100

	struct RoundPlayer {
		uint256 shares;
		int256 scaledPayout;
	}

	struct Round {
		uint256 targetTimestamp;
		uint256 jackpotValue;
		uint256 totalShares;
		uint256 scaledCumulativeRewards;
		mapping(address => RoundPlayer) roundPlayers;
		address lastPlayer;
	}

	struct Info {
		uint256 totalRounds;
		mapping(uint256 => Round) rounds;
	}
	Info private info;


	event BuyShares(address indexed player, uint256 indexed round, uint256 amount, uint256 cost);
	event RoundStarted(uint256 indexed round);
	event RoundEnded(uint256 indexed round, uint256 endTime, uint256 jackpotValue, uint256 totalShares, address lastPlayer);
	event Withdraw(address indexed player, uint256 indexed round, uint256 amount);


	modifier _checkRound {
		uint256 _round = currentRoundIndex();
		uint256 _target = roundTargetTimestamp(_round);
		if (_target <= block.timestamp) {
			uint256 _shares = roundTotalShares(_round);
			uint256 _jackpot = roundJackpotValue(_round);
			if (_shares > 0) {
				info.rounds[_round].scaledCumulativeRewards += _jackpot * FLOAT_SCALAR / _shares;
			}
			emit RoundEnded(_round, _target, _jackpot, _shares, roundLastPlayer(_round));
			_newRound();
		}
		_;
	}


	constructor() {
		_newRound();
	}

	function buyShares(uint256 _amount, uint256 _maxSpend) external _checkRound {
		require(_amount > 0);
		uint256 _cost = currentRoundCalculateCost(_amount);
		require(_cost <= _maxSpend);
		USDC.transferFrom(msg.sender, address(this), _cost);
		Round storage _currentRound = info.rounds[currentRoundIndex()];
		_currentRound.totalShares += _amount;
		_currentRound.roundPlayers[msg.sender].shares += _amount;
		_currentRound.roundPlayers[msg.sender].scaledPayout += int256(_amount * _currentRound.scaledCumulativeRewards);
		_currentRound.lastPlayer = msg.sender;
		uint256 _newTarget = _currentRound.targetTimestamp + _amount * INCREASE_PER_SHARE;
		_currentRound.targetTimestamp = _newTarget < block.timestamp + MAX_TIME ? _newTarget : block.timestamp + MAX_TIME;
		_currentRound.jackpotValue += 2 * _cost / 3;
		_currentRound.scaledCumulativeRewards += _cost * FLOAT_SCALAR / _currentRound.totalShares / 3;
		emit BuyShares(msg.sender, currentRoundIndex(), _amount, _cost);
	}

	function donateToJackpot(uint256 _amount) external _checkRound {
		require(_amount > 0);
		USDC.transferFrom(msg.sender, address(this), _amount);
		info.rounds[currentRoundIndex()].jackpotValue += _amount;
	}

	function withdrawRound(uint256 _round) public returns (uint256) {
		uint256 _withdrawable = roundRewardsOf(msg.sender, _round);
		if (_withdrawable > 0) {
			info.rounds[_round].roundPlayers[msg.sender].scaledPayout += int256(_withdrawable * FLOAT_SCALAR);
		}
		if (_round != currentRoundIndex() && roundLastPlayer(_round) == msg.sender) {
			_withdrawable += roundJackpotValue(_round);
			info.rounds[_round].lastPlayer = address(0x0);
		}
		if (_withdrawable > 0) {
			USDC.transfer(msg.sender, _withdrawable);
			emit Withdraw(msg.sender, _round, _withdrawable);
		}
		return _withdrawable;
	}

	function withdrawCurrent() external returns (uint256) {
		return withdrawRound(currentRoundIndex());
	}

	function withdrawAll() external _checkRound returns (uint256) {
		uint256 _withdrawn = 0;
		for (uint256 i = 0; i < info.totalRounds; i++) {
			_withdrawn += withdrawRound(i);
		}
		return _withdrawn;
	}


	function currentRoundIndex() public view returns (uint256) {
		return info.totalRounds - 1;
	}

	function roundTargetTimestamp(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].targetTimestamp;
	}

	function roundJackpotValue(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].jackpotValue / 2;
	}

	function roundTotalShares(uint256 _round) public view returns (uint256) {
		return info.rounds[_round].totalShares;
	}

	function roundLastPlayer(uint256 _round) public view returns (address) {
		return info.rounds[_round].lastPlayer;
	}

	function roundSharesOf(address _player, uint256 _round) public view returns (uint256) {
		return info.rounds[_round].roundPlayers[_player].shares;
	}

	function roundCurrentPrice(uint256 _round) public view returns (uint256) {
		return INITIAL_PRICE + INCREMENT * roundTotalShares(_round);
	}

	function roundCalculateCost(uint256 _amount, uint256 _round) public view returns (uint256) {
		return roundCurrentPrice(_round) * _amount + INCREMENT * _amount * (_amount + 1) / 2;
	}

	function currentRoundCalculateCost(uint256 _amount) public view returns (uint256) {
		return roundCalculateCost(_amount, currentRoundIndex());
	}

	function roundRewardsOf(address _player, uint256 _round) public view returns (uint256) {
		return uint256(int256(info.rounds[_round].scaledCumulativeRewards * roundSharesOf(_player, _round)) - info.rounds[_round].roundPlayers[_player].scaledPayout) / FLOAT_SCALAR;
	}

	function roundWithdrawableOf(address _player, uint256 _round) public view returns (uint256) {
		uint256 _withdrawable = roundRewardsOf(_player, _round);
		if (_round != currentRoundIndex() && roundLastPlayer(_round) == _player) {
			_withdrawable += roundJackpotValue(_round);
		}
		return _withdrawable;
	}

	function allWithdrawableOf(address _player) public view returns (uint256) {
		uint256 _withdrawable = 0;
		for (uint256 i = 0; i < info.totalRounds; i++) {
			_withdrawable += roundWithdrawableOf(_player, i);
		}
		return _withdrawable;
	}

	function allRoundInfoFor(address _player, uint256 _round) public view returns (uint256[4] memory compressedRoundInfo, address roundLast, uint256 playerBalance, uint256 playerAllowance, uint256[3] memory compressedPlayerRoundInfo) {
		return (_compressedRoundInfo(_round), roundLastPlayer(_round), USDC.balanceOf(_player), USDC.allowance(_player, address(this)), _compressedPlayerRoundInfo(_player, _round));
	}

	function allCurrentInfoFor(address _player) public view returns (uint256[4] memory compressedInfo, address lastPlayer, uint256 playerBalance, uint256 playerAllowance, uint256[3] memory compressedPlayerRoundInfo, uint256 round) {
		round = currentRoundIndex();
		(compressedInfo, lastPlayer, playerBalance, playerAllowance, compressedPlayerRoundInfo) = allRoundInfoFor(_player, round);
	}


	function _newRound() internal {
		Round storage _round = info.rounds[info.totalRounds++];
		_round.targetTimestamp = block.timestamp + MAX_TIME;
		emit RoundStarted(currentRoundIndex());
	}


	function _compressedRoundInfo(uint256 _round) internal view returns (uint256[4] memory data) {
		data[0] = block.number;
		data[1] = roundTargetTimestamp(_round);
		data[2] = roundJackpotValue(_round);
		data[3] = roundTotalShares(_round);
	}

	function _compressedPlayerRoundInfo(address _player, uint256 _round) internal view returns (uint256[3] memory data) {
		data[0] = roundSharesOf(_player, _round);
		data[1] = roundWithdrawableOf(_player, _round);
		data[2] = allWithdrawableOf(_player);
	}
}