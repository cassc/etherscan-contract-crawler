// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArbitraEdge_V1 is Ownable {
	using SafeERC20 for IERC20;

	address constant private _BNB_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	uint constant private _MAX_INT_ = 2**256 - 1;


	mapping(address => bool) private _tokenList;
	mapping(address => mapping(address => bool)) private _spenderTokenList;
	mapping(address => bool) public _whitelist;
	mapping(address => bool) public _admins;
	

	// Multicall errors
	error TargetsEqualDataLength(string _message);
	error AmountEqualToValue(string _message);
	error ArbitrageFailed(bytes _result);
	error NoProfitsArbitrage();


	modifier onlyWhitelisted {
		require(
			_whitelist[msg.sender],
			"NEEDS_WHITELIST_USER"
		);
		_;
	}
	modifier onlyAdmin {
		require(
			_admins[msg.sender],
			"NEEDS_ADMIN_USER"
		);
		_;
	}


	constructor() {
	}


	// Receive tokens function
	receive() external payable {}


	// Check if Token is already approved on Arbitarge Bot
	function checkApprovedToken(address _token) external view returns (bool) {
		return _tokenList[_token];
	}


	// Check if Token is already approved on OpenOcean Proxy
	function checkOOapprovedToken(address _token, address _spender) external view returns (bool) {
		return _spenderTokenList[_token][_spender];
	}


	// Approve Arbitrage Bot
	function approveArbitrageBot(address _token) external onlyAdmin {
		require(_tokenList[_token] == false, "ALREADY_APPROVED");
		IERC20(_token).safeApprove(address(this), _MAX_INT_);
		_tokenList[_token] = true;
	}


	// Approve OpenOcean
	function approveMaxOpenOcean(address _token, address _spender, uint _amount) external onlyAdmin {
		bool mappedAllowance = _spenderTokenList[_token][_spender];
		require(mappedAllowance == false, "ALREADY_APPROVED");
		uint allowance = IERC20(_token).allowance(address(this), _spender);
		if (allowance < _amount) {
			if (allowance > 0) {
				IERC20(_token).safeApprove(_spender, 0);
			}
			IERC20(_token).safeApprove(_spender, _MAX_INT_);
		}
		mappedAllowance = true;
	}


	// Internal transfer function
	function _transfer(
		address _token,
		address payable _to,
		uint _amount
	) internal {
		if (_amount > 0) {
			if (_token == _BNB_ADDRESS_) {
				_to.transfer(_amount);
			} else {
				IERC20(_token).safeTransfer(_to, _amount);
			}
		}
	}


	// Recover funds
	function transfer(
		address _token,
		address payable _to,
		uint _amount
	) external onlyOwner {
		uint value = _amount * 1e18;
		if (value > 0) {
			if (_token == _BNB_ADDRESS_) {
				_to.transfer(value);
			} else {
				IERC20(_token).safeTransfer(_to, value);
			}
		}
	}


	// Arbitrage Multicall
	function multicallArbitrage(
		address[] calldata _targets, // Target address
		bytes[] calldata _data, // Call data
		address _fromToken, // "from" token address
		address _toToken, // "to" token address
		uint _amount // Swap amount with decimals
	) external payable onlyWhitelisted {
		if (_targets.length != _data.length) revert TargetsEqualDataLength("TL_DIFFERS_DL");

		uint fromAmount = _amount;
		address bnbAddress = _BNB_ADDRESS_;

		if (_fromToken != bnbAddress) {
			IERC20(_fromToken).transferFrom(
				msg.sender,
				address(this),
				fromAmount
			);
		} else {
			if (fromAmount == msg.value) revert AmountEqualToValue("INVALID_AMOUNT");
		}

		uint targetsLength = _targets.length;
		for (uint i; i < targetsLength;) {
			(bool success, bytes memory result) = _targets[i].call{
				value: _fromToken == bnbAddress ? fromAmount : 0
			}(_data[i]);
			if(!success) revert ArbitrageFailed(result);
			unchecked {
        ++i;
    	}
		}

		uint returnAmount = balanceOf(_toToken, address(this));

		if (returnAmount < _amount) revert NoProfitsArbitrage();

		_transfer(_toToken, payable(msg.sender), returnAmount);
	}


	// Check BNB or ERC20 Balance of the Contract
	function balanceOf(address _token, address _address)
		public
		view
		onlyWhitelisted
		returns (uint)
	{
		if (_token == _BNB_ADDRESS_) {
			return _address.balance;
		} else {
			return IERC20(_token).balanceOf(_address);
		}
	}


	// Add new user to whitelist
	function setWhitelist(address _address, bool _access) public onlyAdmin {
		_whitelist[_address] = _access;
	}


	// Add new admin
	function setAdmin(address _address, bool _access) public onlyOwner {
		_admins[_address] = _access;
	}
}