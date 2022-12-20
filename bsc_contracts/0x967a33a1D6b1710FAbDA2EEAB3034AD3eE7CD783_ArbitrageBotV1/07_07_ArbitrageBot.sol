// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArbitrageBotV1 is Ownable {
	using SafeERC20 for IERC20;

	address constant private _BNB_ADDRESS_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
	address private _OOApprove_ = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;
	uint constant private _MAX_INT_ = 2**256 - 1;


	mapping(address => bool) private _tokenList;
	mapping(address => bool) private _OOtokenList;
	mapping(address => bool) private _whitelist;
	mapping(address => bool) private _admins;
	

	// Multicall errors
	error TargetsEqualDataLength(string _message);
	error AmountEqualToValue(string _message);
	error ArbitrageFailed(bytes _result);
	error NoProfitsArbitrage();


	modifier onlyWhitelisted {
		require(
			_whitelist[msg.sender] || _admins[msg.sender] || owner() == msg.sender,
			"User not whitelisted"
		);
		_;
	}
	modifier onlyAdmin {
		require(
			_admins[msg.sender] || owner() == msg.sender,
			"User is not an Admin"
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
	function checkOOapprovedToken(address _token) external view returns (bool) {
		return _OOtokenList[_token];
	}


	// Approve Arbitrage Bot
	function approveArbitrageBot(address _token) external onlyAdmin {
		require(_tokenList[_token] == false, "Token already approved");
		IERC20(_token).safeApprove(address(this), _MAX_INT_);
		_tokenList[_token] = true;
	}


	// Approve OpenOcean
	function approveMaxOpenOcean(address _token, uint _amount) external onlyAdmin {
		require(_OOtokenList[_token] == false, "Token already approved");
		address OOAddress = _OOApprove_;
		uint allowance = IERC20(_token).allowance(address(this), OOAddress);
		if (allowance < _amount) {
			if (allowance > 0) {
				IERC20(_token).safeApprove(OOAddress, 0);
			}
			IERC20(_token).safeApprove(OOAddress, _MAX_INT_);
		}
		_OOtokenList[_token] = true;
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


	// Transfer ETH or ERC20 function to Owner specified destination
	function transfer(
		address _token,
		address payable _to,
		uint _amount
	) external onlyWhitelisted {
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
		address[] calldata _targets, // OpenOcean address
		bytes[] calldata _data, // OOApiData = data param from swap_quote API
		address _fromToken, // fromTokenaddress
		address _toToken, // toTokenaddress
		uint _amount // inAmount with decimals
	) external payable onlyWhitelisted {
		if (_targets.length != _data.length) revert TargetsEqualDataLength("TL != DL");

		uint fromAmount = _amount;
		address bnbAddress = _BNB_ADDRESS_;

		if (_fromToken != bnbAddress) {
			IERC20(_fromToken).transferFrom(
				msg.sender,
				address(this),
				fromAmount
			);
		} else {
			if (fromAmount == msg.value) revert AmountEqualToValue("Amount must match msg.value");
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
	

	// Change OO Contract Address
	function change00address(address _address) public onlyOwner {
		_OOApprove_ = _address;
	}
}