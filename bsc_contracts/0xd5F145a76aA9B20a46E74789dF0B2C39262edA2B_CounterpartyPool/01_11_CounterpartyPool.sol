// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IMockSynth } from "./IMockSynth.sol";

contract CounterpartyPool is Initializable, ERC20, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		uint256 lastDepositTime;
		uint256 openWithdrawalFee;
		uint256 lastingWithdrawalFee;
	}

	address constant DEFAULT_FEE_RECIPIENT = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d;

	uint256 constant MAXIMUM_PERFORMANCE_FEE = 100e16; // 100%
	uint256 constant DEFAULT_PERFORMANCE_FEE = 30e16; // 30%

	uint256 constant MAXIMUM_WITHDRAWAL_FEE = 50e16; // 50%
	uint256 constant DEFAULT_OPEN_WITHDRAWAL_FEE = 5e16; // 5%
	uint256 constant DEFAULT_LASTING_WITHDRAWAL_FEE = 2e16; // 2%

	uint256 constant WITHDRAWAL_FEE_DECAY_PERIOD = 30 days;

	uint256 constant MINIMUM_DAILY_WITHDRAWAL_QUOTA = 1e16; // 1%
	uint256 constant DEFAULT_DAILY_WITHDRAWAL_QUOTA = 20e16; // 20%

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 23 hours; // UTC-1

	address public reserveToken; // BUSD

	address public mockSynth;

	address public feeRecipient = DEFAULT_FEE_RECIPIENT;
	uint256 public performanceFee = DEFAULT_PERFORMANCE_FEE;

	uint256 public openWithdrawalFee = DEFAULT_OPEN_WITHDRAWAL_FEE;
	uint256 public lastingWithdrawalFee = DEFAULT_LASTING_WITHDRAWAL_FEE;

	uint256 public dailyWithdrawalQuota = DEFAULT_DAILY_WITHDRAWAL_QUOTA;

	uint64 public day = today();
	uint256 public dailyWithdrawalQuotaLeftAmount = 0;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	mapping(address => bool) public whitelist;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	function withdrawalFee(address _account) public view returns (uint256 _withdrawalFee)
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		uint256 _lastDepositTime = _accountInfo.lastDepositTime;
		uint256 _openWithdrawalFee = _accountInfo.openWithdrawalFee;
		uint256 _lastingWithdrawalFee = _accountInfo.lastingWithdrawalFee;
		uint256 _period = WITHDRAWAL_FEE_DECAY_PERIOD;
		uint256 _ellapsed = block.timestamp - _lastDepositTime;
		if (_ellapsed > _period) _ellapsed = _period;
		return _lastingWithdrawalFee + (_openWithdrawalFee - _lastingWithdrawalFee) * (_period - _ellapsed) / _period;
	}

	constructor(address _reserveToken, address _mockSynth)
		ERC20("", "")
	{
		initialize(msg.sender, _reserveToken, _mockSynth);
	}

	function name() public pure override returns (string memory _name)
	{
		return "Counterparty Pool Shares";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "CPS";
	}

	function initialize(address _owner, address _reserveToken, address _mockSynth) public initializer
	{
		_transferOwnership(_owner);

		feeRecipient = DEFAULT_FEE_RECIPIENT;
		performanceFee = DEFAULT_PERFORMANCE_FEE;

		openWithdrawalFee = DEFAULT_OPEN_WITHDRAWAL_FEE;
		lastingWithdrawalFee = DEFAULT_LASTING_WITHDRAWAL_FEE;

		dailyWithdrawalQuota = DEFAULT_DAILY_WITHDRAWAL_QUOTA;

		day = today();
		dailyWithdrawalQuotaLeftAmount = 0;

		reserveToken = _reserveToken;
		mockSynth = _mockSynth;
	}

	function setMockSynth(address _mockSynth) external onlyOwner
	{
		require(_mockSynth != address(0), "invalid address");
		mockSynth = _mockSynth;
	}

	function setFeeRecipient(address _feeRecipient) external onlyOwner
	{
		require(_feeRecipient != address(0), "invalid address");
		feeRecipient = _feeRecipient;
	}

	function setPerformanceFee(uint256 _performanceFee) external onlyOwner
	{
		require(_performanceFee <= MAXIMUM_PERFORMANCE_FEE, "invalid rate");
		performanceFee = _performanceFee;
		emit PerformanceFeeUpdate(_performanceFee);
	}

	function setWithdrawalFee(uint256 _openWithdrawalFee, uint256 _lastingWithdrawalFee) external onlyOwner
	{
		require(_openWithdrawalFee <= MAXIMUM_WITHDRAWAL_FEE && _lastingWithdrawalFee <= _openWithdrawalFee, "invalid rate");
		openWithdrawalFee = _openWithdrawalFee;
		lastingWithdrawalFee = _lastingWithdrawalFee;
		emit WithdrawalFeeUpdate(_openWithdrawalFee, _lastingWithdrawalFee);
	}

	function setDailyWithdrawalQuota(uint256 _dailyWithdrawalQuota) external onlyOwner
	{
		require(MINIMUM_DAILY_WITHDRAWAL_QUOTA <= _dailyWithdrawalQuota && _dailyWithdrawalQuota <= 100e16, "invalid rate");
		dailyWithdrawalQuota = _dailyWithdrawalQuota;
		emit DailyWithdrawalQuotaUpdate(_dailyWithdrawalQuota);
	}

	function updateWhitelist(address[] calldata _accounts, bool _whitelisted) external onlyOwner
	{
		for (uint256 _i; _i < _accounts.length; _i++) {
			whitelist[_accounts[_i]] = _whitelisted;
		}
	}

	function totalReserve() public view returns (int256 _totalReserve)
	{
		uint256 _fund = IMockSynth(mockSynth).fund();
		uint256 _debt = IMockSynth(mockSynth).debt();
		return _fund >= _debt ? int256(_fund - _debt) : -int256(_debt - _fund);
	}

	function _collectFees() internal returns (uint256 _totalReserve, uint256 _totalSupply)
	{
		int256 _signedTotalReserve = totalReserve();
		require(_signedTotalReserve >= 0, "underwater");

		_totalReserve = uint256(_signedTotalReserve);
		_totalSupply = totalSupply();

		uint256 _amount = IMockSynth(mockSynth).balanceOf(address(this));
		if (_amount > 0) {
			uint256 _shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
			uint256 _fee = _shares * performanceFee / 100e16;

			IMockSynth(mockSynth).withdraw(address(this), _amount);
			IERC20(reserveToken).safeApprove(mockSynth, _amount);
			IMockSynth(mockSynth).donate(_amount);

			if (_fee > 0) {
				_mint(feeRecipient, _fee);
			}

			_totalReserve += _amount;
			_totalSupply += _fee;
		}

		return (_totalReserve, _totalSupply);
	}

	function deposit(uint256 _amount, uint256 _minShares) external returns (uint256 _shares)
	{
		return depositOnBehalfOf(_amount, _minShares, msg.sender);
	}

	function depositOnBehalfOf(uint256 _amount, uint256 _minShares, address _account) public nonReentrant returns (uint256 _shares)
	{
		require(msg.sender == _account || whitelist[msg.sender], "access denied");

		(uint256 _totalReserve, uint256 _totalSupply) = _collectFees();
		_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
		require(_shares >= _minShares, "high slippage");

		_updateDay(_totalReserve);

		AccountInfo storage _accountInfo = accountInfo[_account];
		if (_accountInfo.lastDepositTime == 0) {
			accountIndex.push(_account);
		}
		_accountInfo.lastDepositTime = block.timestamp;
		_accountInfo.openWithdrawalFee = openWithdrawalFee;
		_accountInfo.lastingWithdrawalFee = lastingWithdrawalFee;

		_mint(_account, _shares);

		IERC20(reserveToken).safeTransferFrom(msg.sender, address(this), _amount);
		IERC20(reserveToken).safeApprove(mockSynth, _amount);
		IMockSynth(mockSynth).donate(_amount);

		emit Deposit(_account, _amount, _shares);

		return _shares;
	}

	function withdraw(uint256 _shares, uint256 _minAmount) external nonReentrant returns (uint256 _amount)
	{
		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_accountInfo.lastDepositTime > 0, "unknown account");

		(uint256 _totalReserve, uint256 _totalSupply) = _collectFees();
		uint256 _fee;
		(_amount, _fee) = _calcAmountFromShares(_totalReserve, _totalSupply, _shares, withdrawalFee(msg.sender));
		require(_amount >= _minAmount, "high slippage");

		_updateDay(_totalReserve);

		require(_amount <= dailyWithdrawalQuotaLeftAmount, "insufficient quota");
		dailyWithdrawalQuotaLeftAmount -= _amount;

		_mint(feeRecipient, _fee / 2);

		_burn(msg.sender, _shares);

		IMockSynth(mockSynth).collect(_amount);
		IERC20(reserveToken).safeTransfer(msg.sender, _amount);

		emit Withdrawal(msg.sender, _amount, _shares);

		return _amount;
	}

	function updateDay() external nonReentrant
	{
		(uint256 _totalReserve,) = _collectFees();
		_updateDay(_totalReserve);
	}

	function _updateDay(uint256 _totalReserve) internal
	{
		uint64 _today = today();

		if (day == _today) return;

		day = _today;
		dailyWithdrawalQuotaLeftAmount = _totalReserve * dailyWithdrawalQuota / 100e16;
	}

	function _calcSharesFromAmount(uint256 _totalReserve, uint256 _totalSupply, uint256 _amount) internal pure returns (uint256 _shares)
	{
		if (_totalReserve == 0) return _amount;
		return _amount * _totalSupply / _totalReserve;
	}

	function _calcAmountFromShares(uint256 _totalReserve, uint256 _totalSupply, uint256 _shares, uint256 _withdrawalFee) internal pure returns (uint256 _amount, uint256 _fee)
	{
		if (_totalSupply == 0) return (_totalReserve, 0);
		_fee = _shares * _withdrawalFee / 100e16;
		_amount = (_shares - _fee) * _totalReserve / _totalSupply;
		return (_amount, _fee);
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override
	{
		if (_from == address(0) || _to == address(0)) return; // mint/burn
		require(whitelist[msg.sender] && (_from == msg.sender || _to == msg.sender), "forbidden");
		if (_amount == 0) return;
		AccountInfo storage _accountInfo = accountInfo[_to];
		if (_accountInfo.lastDepositTime == 0) {
			accountIndex.push(_to);
			_accountInfo.lastDepositTime = block.timestamp;
			_accountInfo.openWithdrawalFee = openWithdrawalFee;
			_accountInfo.lastingWithdrawalFee = lastingWithdrawalFee;
		}
	}

	event PerformanceFeeUpdate(uint256 _performanceFee);
	event WithdrawalFeeUpdate(uint256 _openWithdrawalFee, uint256 _lastingWithdrawalFee);
	event DailyWithdrawalQuotaUpdate(uint256 _dailyWithdrawalQuota);
	event Deposit(address indexed _account, uint256 _amount, uint256 _shares);
	event Withdrawal(address indexed _account, uint256 _amount, uint256 _shares);
}