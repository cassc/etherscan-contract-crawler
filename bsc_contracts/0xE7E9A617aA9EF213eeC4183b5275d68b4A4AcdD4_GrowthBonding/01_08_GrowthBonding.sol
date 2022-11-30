// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
Bonding Deposit Contract xGRO

30/60/90 Day option (pays out in xGRO and xPERPs)
(Mild, Wild, Full throttle)

30 day - 6% deposit fee 6% withdrawal fee of deposited token
1% Mgmt
1% Boosted Stakers
4% Pool
Pool pays out proportionally to stakers at the end of the bond, 30 days in this case.. (if someone withdraws early, they get charged the fee and get nothing at the end of the Bonding period..)

60 day - 16% deposit fee 16% withdrawal fee of deposited token
1.5% Mgmt
1.5% Boosted Stakers
13% Pool
Pool pays out proportionally to stakers at the end of the bond, 60 days in this case.. (if someone withdraws early, they get charged the fee and get nothing at the end of the Bonding period..)

90 day - 33% Deposit fee 33% withdrawal fee of deposited token
3% Mgmt
3% Boosted Stakers
27% Pool
Pool pays out proportionally to stakers at the end of the bond, 90 days in this case.. (if someone withdraws early, they get charged the fee and get nothing at the end of the Bonding period..)

*From the 20% claim tax on xGRO single stake farm: 
*15% of xPERPs goes to 30 day pool
*30% of xPERPs goes to 60 day pool
*55%, of xPERPs goes to 90 day pool

xPERPs Boosted position and sidepot

Deposit xPERPs to gain a boosted position in either the 30,60, or 90 day Bonds. 60% of the deposited xPERPs is burnt, 40% goes to a sidepot, from which positions 1,2, and 3 will split up the Pot at the end of the Bond..

1st Place will receive 55% of the sidepot
2nd Place will receive 30% 
3rd Place will recieve 15%
*/
contract GrowthBonding is Initializable, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct RoundInfo {
		uint256 startTime;
		uint256 endTime;
		uint256 amount; // total xGRO staked balance
		uint256 boost; // total xGRO accumulated for the extra payout for burners
		uint256 payout; // total xGRO accumulated for the payout
		uint256 reward; // total xPERPS reward balance
		uint256 burned; // total xPERPS burned balance
		uint256 prize; // XPERPS accumulated as prize for top burners
		address[3] top3; // top 3 xPERPS burners
		uint256 weight; // total time-weighted xGRO balance

		uint256 reserved0; // unused
		uint256 reserved1; // unused
		uint256 reserved2; // unused
	}

	struct AccountInfo {
		bool exists; // flag to index account
		uint256 round; // account round
		uint256 amount; // xGRO deposited
		uint256 burned; // xPERPS burned
		uint256 weight; // time-weighted xGRO balance

		uint256 reserved0; // unused
		uint256 reserved1; // unused
		uint256 reserved2; // unused
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d; // multisig

	address public reserveToken; // xGRO
	address public rewardToken; // xPERPS
	address public burnToken; // xPERPS

	uint256 public bankrollFee; // percentage of deposits/withdrawals towards the bankroll
	uint256 public boostFee; // percentage of deposits/withdrawals towards the boost pool
	uint256 public payoutFee; // percentage of deposits/withdrawals towards the payout pool

	uint256 public roundLength; // 30 days
	uint256 public roundInterval; // 7 days

	address public bankroll = DEFAULT_BANKROLL;

	uint256 public totalReserve = 0; // total xGRO balance
	uint256 public totalReward = 0; // total xPERPS balance

	RoundInfo[] public roundInfo;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	function roundInfoLength() external view returns (uint256 _roundInfoLength)
	{
		return roundInfo.length;
	}

	function roundInfoTop3(uint256 _index) external view returns (address[3] memory _top3)
	{
		return roundInfo[_index].top3;
	}

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	constructor(address _reserveToken, address _rewardToken, uint256 _bankrollFee, uint256 _boostFee, uint256 _payoutFee, uint256 _launchTime, uint256 _roundLength, uint256 _roundInterval)
	{
		initialize(msg.sender, _reserveToken, _rewardToken, _bankrollFee, _boostFee, _payoutFee, _launchTime, _roundLength, _roundInterval);
	}

	function initialize(address _owner, address _reserveToken, address _rewardToken, uint256 _bankrollFee, uint256 _boostFee, uint256 _payoutFee, uint256 _launchTime, uint256 _roundLength, uint256 _roundInterval) public initializer
	{
		_transferOwnership(_owner);

		bankroll = DEFAULT_BANKROLL;

		totalReserve = 0; // total xGRO balance
		totalReward = 0; // total xPERPS balance

		require(_launchTime >= block.timestamp, "invalid time");
		uint256 _startTime = _launchTime;
		uint256 _endTime = _startTime + _roundLength;
		roundInfo.push(RoundInfo({
			startTime: _startTime,
			endTime: _endTime,
			amount: 0,
			boost: 0,
			payout: 0,
			reward: 0,
			burned: 0,
			prize: 0,
			top3: [address(0), address(0), address(0)],
			weight: 0,

			reserved0: 0,
			reserved1: 0,
			reserved2: 0
		}));

		require(_rewardToken != _reserveToken, "invalid token");
		reserveToken = _reserveToken;
		rewardToken = _rewardToken;
		burnToken = _rewardToken;

		require(_bankrollFee + _boostFee + _payoutFee <= 100e16, "invalid rate");
		bankrollFee = _bankrollFee;
		boostFee = _boostFee;
		payoutFee = _payoutFee;

		require(_roundLength > 0, "invalid length");
		roundLength = _roundLength;
		roundInterval = _roundInterval;
	}

	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	function recoverFunds(address _token) external onlyOwner nonReentrant
	{
		uint256 _amount = IERC20(_token).balanceOf(address(this));
		if (_token == reserveToken) _amount -= totalReserve;
		else
		if (_token == rewardToken) _amount -= totalReward;
		require(_amount > 0, "no balance");
		IERC20(_token).safeTransfer(msg.sender, _amount);
	}

	function burn(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateRound();

		uint256 _currentRound = roundInfo.length - 1;

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			accountIndex.push(msg.sender);
		}
		if (_accountInfo.amount == 0 && _accountInfo.burned == 0) {
			_accountInfo.round = _currentRound;
		}
		require(_accountInfo.round == _currentRound, "pending redemption");

		RoundInfo storage _roundInfo = roundInfo[_accountInfo.round];
		require(block.timestamp >= _roundInfo.startTime, "not available");

		uint256 _prizeAmount = _amount * 40e16 / 100e16; // 40%
		uint256 _burnAmount = _amount - _prizeAmount;

		_accountInfo.burned += _amount;

		_roundInfo.burned += _amount;
		_roundInfo.prize += _prizeAmount;

		// updates ranking
		if (msg.sender != _roundInfo.top3[0] && msg.sender != _roundInfo.top3[1] && _accountInfo.burned > accountInfo[_roundInfo.top3[2]].burned) {
			_roundInfo.top3[2] = msg.sender;
		}
		if (accountInfo[_roundInfo.top3[2]].burned > accountInfo[_roundInfo.top3[1]].burned) {
			(_roundInfo.top3[1], _roundInfo.top3[2]) = (_roundInfo.top3[2], _roundInfo.top3[1]);
		}
		if (accountInfo[_roundInfo.top3[1]].burned > accountInfo[_roundInfo.top3[0]].burned) {
			(_roundInfo.top3[0], _roundInfo.top3[1]) = (_roundInfo.top3[1], _roundInfo.top3[0]);
		}

		totalReward += _prizeAmount;

		IERC20(burnToken).safeTransferFrom(msg.sender, FURNACE, _burnAmount);
		IERC20(burnToken).safeTransferFrom(msg.sender, address(this), _prizeAmount);

		emit Burn(msg.sender, burnToken, _amount, _currentRound);
	}

	function deposit(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateRound();

		uint256 _currentRound = roundInfo.length - 1;

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			accountIndex.push(msg.sender);
		}
		if (_accountInfo.amount == 0 && _accountInfo.burned == 0) {
			_accountInfo.round = _currentRound;
		}
		require(_accountInfo.round == _currentRound, "pending redemption");

		RoundInfo storage _roundInfo = roundInfo[_accountInfo.round];
		require(block.timestamp >= _roundInfo.startTime, "not available");
		uint256 _timeLeft = _roundInfo.endTime - block.timestamp;

		uint256 _feeAmount = _amount * bankrollFee / 100e16;
		uint256 _boostedAmount = _amount * boostFee / 100e16;
		uint256 _payoutAmount = _amount * payoutFee / 100e16;
		uint256 _netAmount = _amount - (_feeAmount + _boostedAmount + _payoutAmount);
		uint256 _transferAmount = _netAmount + _payoutAmount + _boostedAmount;

		uint256 _weight = _netAmount * _timeLeft;

		_accountInfo.amount += _netAmount;
		_accountInfo.weight += _weight;

		_roundInfo.amount += _netAmount;
		_roundInfo.boost += _boostedAmount;
		_roundInfo.payout += _payoutAmount;
		_roundInfo.weight += _weight;

		totalReserve += _transferAmount;

		IERC20(reserveToken).safeTransferFrom(msg.sender, bankroll, _feeAmount);
		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _transferAmount);

		emit Deposit(msg.sender, reserveToken, _amount, _currentRound);
	}

	function withdraw(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateRound();

		uint256 _currentRound = roundInfo.length - 1;

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_accountInfo.round == _currentRound, "not available");
		require(_amount <= _accountInfo.amount, "insufficient balance");

		RoundInfo storage _roundInfo = roundInfo[_accountInfo.round];

		uint256 _feeAmount = _amount * bankrollFee / 100e16;
		uint256 _boostedAmount = _amount * boostFee / 100e16;
		uint256 _payoutAmount = _amount * payoutFee / 100e16;
		uint256 _netAmount = _amount - (_feeAmount + _boostedAmount + _payoutAmount);
		uint256 _transferAmount = _feeAmount + _netAmount;

		uint256 _weight = _amount * _accountInfo.weight / _accountInfo.amount;

		_accountInfo.amount -= _amount;
		_accountInfo.weight -= _weight;

		_roundInfo.amount -= _amount;
		_roundInfo.boost += _boostedAmount;
		_roundInfo.payout += _payoutAmount;
		_roundInfo.weight -= _weight;

		totalReserve -= _transferAmount;

		IERC20(reserveToken).safeTransfer(bankroll, _feeAmount);
		IERC20(reserveToken).safeTransfer(msg.sender, _netAmount);

		emit Withdraw(msg.sender, reserveToken, _amount, _currentRound);
	}

	function estimateRedemption(address _account) public view returns (uint256 _amount, uint256 _boostAmount, uint256 _payoutAmount, uint256 _weightedPayoutAmount, uint256 _divsAmount, uint256 _weightedDivsAmount, uint256 _prizeAmount, bool _available)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];

		RoundInfo storage _roundInfo = roundInfo[_accountInfo.round];

		uint256 _halfPayout = _roundInfo.payout / 2;
		uint256 _halfReward = _roundInfo.reward / 2;

		_amount = _accountInfo.amount;
		_boostAmount = _accountInfo.burned == 0 ? 0 : _accountInfo.burned * _roundInfo.boost / _roundInfo.burned;
		_payoutAmount = _accountInfo.amount == 0 ? 0 : _accountInfo.amount * _halfPayout / _roundInfo.amount;
		_weightedPayoutAmount = _accountInfo.weight == 0 ? 0 : _accountInfo.weight * _halfPayout / _roundInfo.weight;

		_divsAmount = _accountInfo.amount == 0 ? 0 : _accountInfo.amount * _halfReward / _roundInfo.amount;
		_weightedDivsAmount = _accountInfo.weight == 0 ? 0 : _accountInfo.weight * _halfReward / _roundInfo.weight;
		_prizeAmount = 0;
		if (msg.sender == _roundInfo.top3[0]) {
			_prizeAmount = _roundInfo.prize * 55e16 / 100e16; // 55% 1st place
		}
		else
		if (msg.sender == _roundInfo.top3[1]) {
			_prizeAmount = _roundInfo.prize * 30e16 / 100e16; // 30% 2nd place
		}
		else
		if (msg.sender == _roundInfo.top3[2]) {
			_prizeAmount = _roundInfo.prize * 15e16 / 100e16; // 15% 3rd place
		}
		_available = block.timestamp >= _roundInfo.endTime;

		return (_amount, _boostAmount, _payoutAmount, _weightedPayoutAmount, _divsAmount, _weightedDivsAmount, _prizeAmount, _available);
	}

	function redeem() external nonReentrant
	{
		_updateRound();

		uint256 _currentRound = roundInfo.length - 1;

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_accountInfo.amount > 0 || _accountInfo.burned > 0, "no balance");
		uint256 _accountRound = _accountInfo.round;
		require(_accountRound < _currentRound, "open round");

		(uint256 _amount, uint256 _boostAmount, uint256 _payoutAmount, uint256 _weightedPayoutAmount, uint256 _divsAmount, uint256 _weightedDivsAmount, uint256 _prizeAmount, bool _available) = estimateRedemption(msg.sender);
		require(_available, "not available"); // should never happen

		uint256 _reserveAmount = _amount + _boostAmount + _payoutAmount + _weightedPayoutAmount;
		uint256 _rewardAmount = _divsAmount + _weightedDivsAmount + _prizeAmount;

		_accountInfo.round = _currentRound;
		_accountInfo.amount = 0;
		_accountInfo.burned = 0;
		_accountInfo.weight = 0;

		totalReserve -= _reserveAmount;
		totalReward -= _rewardAmount;

		IERC20(reserveToken).safeTransfer(msg.sender, _reserveAmount);
		IERC20(rewardToken).safeTransfer(msg.sender, _rewardAmount);

		emit Redeem(msg.sender, reserveToken, _reserveAmount, rewardToken, _rewardAmount, _accountRound);
	}

	function reward(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateRound();

		uint256 _currentRound = roundInfo.length - 1;

		RoundInfo storage _roundInfo = roundInfo[_currentRound];

		_roundInfo.reward += _amount;

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit Reward(msg.sender, rewardToken, _amount, _currentRound);
	}

	function updateRound() external
	{
		_updateRound();
	}

	function _updateRound() internal
	{
		RoundInfo storage _roundInfo = roundInfo[roundInfo.length - 1];
		if (block.timestamp < _roundInfo.endTime) return;
		uint256 _roundIntervalPlusLength = roundInterval + roundLength;
		uint256 _skippedRounds = (block.timestamp - _roundInfo.endTime) / _roundIntervalPlusLength;
		uint256 _startTime = _roundInfo.endTime + _skippedRounds * _roundIntervalPlusLength + roundInterval;
		uint256 _endTime = _startTime + roundLength;
		roundInfo.push(RoundInfo({
			startTime: _startTime,
			endTime: _endTime,
			amount: 0,
			boost: 0,
			payout: 0,
			reward: 0,
			burned: 0,
			prize: 0,
			top3: [address(0), address(0), address(0)],
			weight: 0,

			reserved0: 0,
			reserved1: 0,
			reserved2: 0
		}));
	}

	event Burn(address indexed _account, address _burnToken, uint256 _amount, uint256 indexed _round);
	event Deposit(address indexed _account, address _reserveToken, uint256 _amount, uint256 indexed _round);
	event Withdraw(address indexed _account, address _reserveToken, uint256 _amount, uint256 indexed _round);
	event Redeem(address indexed _account, address _reserveToken, uint256 _reserveAmount, address _rewardToken, uint256 _rewardAmount, uint256 indexed _round);
	event Reward(address indexed _account, address _rewardToken, uint256 _amount, uint256 indexed _round);
}