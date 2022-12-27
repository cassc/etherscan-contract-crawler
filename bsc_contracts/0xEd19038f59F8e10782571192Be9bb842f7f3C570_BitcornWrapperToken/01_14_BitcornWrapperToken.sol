// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { MasterChef } from "./MasterChef.sol";

interface Bitcorn
{
	function rewardToken() external view returns (address _rewardToken);

	function claim() external;
}

contract BitcornWrapperToken is Initializable, ReentrancyGuard, ERC20
{
	using SafeERC20 for IERC20;

	struct AccountInfo {
		bool exists;
		uint256 shares;
		uint256 rewardDebt;
		uint256 unclaimedReward;
	}

	uint256 constant BITCORN_PID = 72;

	address constant MASTER_CHEF = 0x8BAB23A24430E82C9D384F2996e1671f3e64869a;
	address constant WRAPPER_TOKEN_BRIDGE = 0x0DC52B853030E587eb10b11cfF7d5FDdFA594E71;

	address public token;
	address public rewardToken;

	uint256 public totalReward = 0;
	uint256 public accRewardPerShare = 0;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	constructor(address _token)
		ERC20("", "")
	{
		initialize(_token);
	}

	function name() public pure override returns (string memory _name)
	{
		return "Bitcorn Wrapper Token";
	}

	function symbol() public pure override returns (string memory _symbol)
	{
		return "BWT";
	}

	function initialize(address _token) public initializer
	{
		totalReward = 0;
		accRewardPerShare = 0;

		token = _token;
		rewardToken = Bitcorn(_token).rewardToken();
	}

	function migrate() external
	{
		require(accRewardPerShare == 0, "invalid state");
		for (uint256 _i = 0; _i < accountIndex.length; _i++) {
			require(accountInfo[accountIndex[_i]].unclaimedReward == 0, "invalid state");
		}
		accountInfo[0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d].unclaimedReward = 18194796958017793;
		accountInfo[0x8871eE0752C9099698e78a2A065d42D295bcf23E].unclaimedReward = 1060924996772507;
		accountInfo[0x2165fa4a32B9c228cD55713f77d2e977297D03e8].unclaimedReward = 1074231811623614178;
		accountInfo[0x0834D8A1241CA9112D23a44D4365786253C0641E].unclaimedReward = 1431847566495114;
		accountInfo[0xe742B245cd5A8874aB71c5C004b5B9F877EDf0c0].unclaimedReward = 87511209882890068;
		accountInfo[0x3b1c8DebbF7B7A81e9aD9B94BE4E866253E97209].unclaimedReward = 121343052300313765;
		accountInfo[0xc92a565131D9461705293A4FAFbBa6516F3410C4].unclaimedReward = 152749659202178893;
		accountInfo[0xeDeC8F06b7D446ab4da9729DB2E1078C012A8935].unclaimedReward = 92433961555709546;
		accountInfo[0xfC3bC5c1a6Af3544B67834E13f11BD125dBa03EB].unclaimedReward = 183477482703323679;
		accountInfo[0x9379E1B64A3eC16C37253FE989cD1c3B806817d1].unclaimedReward = 55383947761690727;
		accountInfo[0xbd071de4D984F91330d4fAb66c323DC94D38C220].unclaimedReward = 98136833585715966;
		accountInfo[0xAa494862645e7b3345191cd3DC01b81Af54b1e33].unclaimedReward = 1131779558871150;
		accountInfo[0x562eD81E568d860d2B7Ce395a6ae364398e2A100].unclaimedReward = 227564981801747169;
		accountInfo[0xd31Ec37A948CE8af492e6070d97EbA9fC81a3be7].unclaimedReward = 234669519051633325;
		accountInfo[0x69391Db3458a3Afc67A0575A7891a4C694E174AC].unclaimedReward = 378146887587362769;
		accountInfo[0xfA0A1dB3DF4c58EF1DBD90a09CE64550754bD650].unclaimedReward = 93867807620653325;
		accountInfo[0x97dd1517A04Ea91939E7Ee433220215Fd17277a0].unclaimedReward = 8318968132774309;
		accountInfo[0x426F1Cd2A2c53b08187790f21f0d12a043404679].unclaimedReward = 18158282142210872;
		accountInfo[0x3F8c3700E1D843E395ad1BE072b694c74Ea73B2a].unclaimedReward = 13792632294491514;
		accountInfo[0xF19D7D43e44561792E5B4408C954B9626348dEE5].unclaimedReward = 59578441926183442;
		accountInfo[0x0b6A611cBd852d25Bcd02b455527cDb4Bf78e6B0].unclaimedReward = 21700033195540198;
		accountInfo[0x649799eC70421fC37Bb870441A7371615A6938C7].unclaimedReward = 11733475952581659;
		accountInfo[0xef2Efb5419f065bc927CCD051FCBa215A3336336].unclaimedReward = 92210190306501235;
		accountInfo[0xBD9b82B88404a6e456Caf851F9433f7eC63c9A95].unclaimedReward = 7360480289603192;
		accountInfo[0x75D235f5720A257A09c52FeBCc2bC03094e9F941].unclaimedReward = 43948782436110359;
		accountInfo[0x8eb1b6Eb4064E02F2c01495f9AF326D8ce333bd5].unclaimedReward = 110121960623601440;
		accountInfo[0x29926ba5bb8c05A26AB5117DadbA11269f658143].unclaimedReward = 202175006747785470;
		accountInfo[0x908Aa88a3aec195Ee8510a60ad6dE30e0eFCfB55].unclaimedReward = 202175006747785470;
		accountInfo[0x5d09E86351864669a69Fe60E29171E9E9DF3D394].unclaimedReward = 128213288183614412;
		accountInfo[0x9C299fa124BdfEC5e5fDbb2Cf480AC7D914691C6].unclaimedReward = 10856312575569597;
		accountInfo[0x14Bd5Ef948d97b0017f6F99DC44926DAafafb6da].unclaimedReward = 2984200904105494;
		accountInfo[0x13aDD563cA9C7dff59d6204E20f92895e17a1DAC].unclaimedReward = 20194325677235056;
		accountInfo[0x6Bc11574D0DbDD8252B522d34E7a91eBa5e8BF03].unclaimedReward = 45489376518251727;
		accountInfo[0x84dB2FEcEbEF74c28978801C7d7Fd982405b4e2E].unclaimedReward = 2386979278413383;
		accountInfo[0x742E265019E8C03451F0cCA8C218Eba1b3E2ce94].unclaimedReward = 1327674186065885;
		accountInfo[0xFEAb70797e50496C8e8193Cab424f950e463B675].unclaimedReward = 81112241867617856;
		accountInfo[0x7930ee9492a690404e67b97630a5Fc5B55cCab0B].unclaimedReward = 74751660825182545;
		uint256 _totalReward = 0;
		for (uint256 _i = 0; _i < accountIndex.length; _i++) {
			_totalReward += accountInfo[accountIndex[_i]].unclaimedReward;
		}
		require(_totalReward <= totalReward, "insufficient reward");
		accRewardPerShare = (totalReward - _totalReward) * 1e18 / totalSupply();
	}

	function totalReserve() public view returns (uint256 _totalReserve)
	{
		return IERC20(token).balanceOf(address(this));
	}

	function deposit(uint256 _amount) external returns (uint256 _shares)
	{
		return deposit(_amount, msg.sender);
	}

	function deposit(uint256 _amount, address _account) public nonReentrant returns (uint256 _shares)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			uint256 _newTotalReserve = totalReserve();
			_amount = _newTotalReserve - _totalReserve;
			_shares = _calcSharesFromAmount(_totalReserve, _totalSupply, _amount);
			_mint(msg.sender, _shares);
		}
		_updateAccount(_account, int256(_shares));
		emit Deposit(_account, _shares);
		return _shares;
	}

	function withdraw(uint256 _shares) external returns (uint256 _amount)
	{
		return withdraw(_shares, msg.sender);
	}

	function withdraw(uint256 _shares, address _account) public nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		{
			uint256 _totalSupply = totalSupply();
			uint256 _totalReserve = totalReserve();
			_amount = _calcAmountFromShares(_totalReserve, _totalSupply, _shares);
			_burn(msg.sender, _shares);
			IERC20(token).safeTransfer(msg.sender, _amount);
		}
		_updateAccount(_account, -int256(_shares));
		_sync(_account);
		emit Withdraw(_account, _shares);
		return _amount;
	}

	function claim() external returns (uint256 _rewardAmount)
	{
		return claim(msg.sender);
	}

	function claim(address _account) public nonReentrant returns (uint256 _rewardAmount)
	{
		require(msg.sender == _account || msg.sender == WRAPPER_TOKEN_BRIDGE, "access denied");
		_claimRewards();
		_updateAccount(_account, 0);
		{
			AccountInfo storage _accountInfo = accountInfo[_account];
			_rewardAmount = _accountInfo.unclaimedReward;
			_accountInfo.unclaimedReward = 0;
		}
		if (_rewardAmount > 0) {
			totalReward -= _rewardAmount;
			IERC20(rewardToken).safeTransfer(_account, _rewardAmount);
		}
		emit Claim(_account, _rewardAmount);
		return _rewardAmount;
	}

	function _beforeTokenTransfer(address _from, address _to, uint256 _shares) internal override
	{
		if (_from == address(0) || _to == address(0)) return;
		if (msg.sender == MASTER_CHEF && (_from == MASTER_CHEF || _to == MASTER_CHEF || _from == WRAPPER_TOKEN_BRIDGE || _to == WRAPPER_TOKEN_BRIDGE)) return;
		_claimRewards();
		_updateAccount(_from, -int256(_shares));
		_updateAccount(_to, int256(_shares));
	}

	function syncAll() external nonReentrant
	{
		_claimRewards();
		for (uint256 _i = 0; _i < accountIndex.length; _i++) {
			_sync(accountIndex[_i]);
		}
	}

	function _sync(address _account) internal
	{
		address _bankroll = MasterChef(MASTER_CHEF).bankroll();
		if (_account == _bankroll) return;
		uint256 _balance = balanceOf(_account);
		(uint256 _stake,,) = MasterChef(MASTER_CHEF).userInfo(BITCORN_PID, _account);
		uint256 _shares = _balance + _stake;
		if (accountInfo[_account].shares <= _shares) return;
		uint256 _excess = accountInfo[_account].shares - _shares;
		if (_excess == 0) return;
		_updateAccount(_account, -int256(_excess));
		_updateAccount(_bankroll, int256(_excess));
	}

	function _updateAccount(address _account, int256 _shares) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		if (!_accountInfo.exists) {
			_accountInfo.exists = true;
			accountIndex.push(_account);
		}
		if (_accountInfo.shares > 0) {
			_accountInfo.unclaimedReward += _accountInfo.shares * accRewardPerShare / 1e18 - _accountInfo.rewardDebt;
		}
		if (_shares > 0) {
			_accountInfo.shares += uint256(_shares);
		}
		else
		if (_shares < 0) {
			_accountInfo.shares -= uint256(-_shares);
		}
		_accountInfo.rewardDebt = _accountInfo.shares * accRewardPerShare / 1e18;
	}

	function _calcSharesFromAmount(uint256 _totalReserve, uint256 _totalSupply, uint256 _amount) internal pure virtual returns (uint256 _shares)
	{
		if (_totalReserve == 0) return _amount;
		return _amount * _totalSupply / _totalReserve;
	}

	function _calcAmountFromShares(uint256 _totalReserve, uint256 _totalSupply, uint256 _shares) internal pure virtual returns (uint256 _amount)
	{
		if (_totalSupply == 0) return _totalReserve;
		return _shares * _totalReserve / _totalSupply;
	}

	function _claimRewards() internal
	{
		uint256 _totalSupply = totalSupply();
		if (_totalSupply > 0) {
			Bitcorn(token).claim();
			uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this)) - totalReward;
			if (_rewardAmount > 0) {
				totalReward += _rewardAmount;
				accRewardPerShare += _rewardAmount * 1e18 / _totalSupply;
			}
		}
	}

	event Deposit(address indexed _account, uint256 _shares);
	event Withdraw(address indexed _account, uint256 _shares);
	event Claim(address indexed _account, uint256 _rewardToken);
}