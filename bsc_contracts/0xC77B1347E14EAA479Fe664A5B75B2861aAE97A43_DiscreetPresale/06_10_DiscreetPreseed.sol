pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";
import {Context} from "./Context.sol";
import {Ownable} from "./Ownable.sol";
import {Discreet} from "./Discreet.sol";

contract DiscreetPreseed is Context, Ownable {
	using SafeMath for uint256;
	using Address for address;
	mapping (address => uint256) private _purchases;
	mapping (address => bool) private _functionWhitelist;

	uint256 public totalPreseedTokensToSell = 0;
	Discreet _Discreet;

	uint256 private _preseedRate;
	uint256 public _minTokenBuy = 5 * 10**16;
	uint256 public _maxTokenBuy = 100 * 10**18;

	uint256 public preseedStartDate = 0;
	uint256 public preseedEndDate = 0;
	bool public preseedLaunched = false;

	bool public _replicateState = false;

	event TokenSaleBuy(address indexed buyer, uint256 amount);

	modifier onlyWhitelist() {
		require(_functionWhitelist[_msgSender()] == true, "Address must be whitelisted to perform this");
		_;
	}

	constructor (address _discreet) public {
		_Discreet = Discreet(_discreet);
		totalPreseedTokensToSell = _Discreet.getPreseedTokenSupply();
		_functionWhitelist[_msgSender()] = true;
	}

	function addFunctionWhitelist(address addressToWhitelist) public onlyOwner() {
		_functionWhitelist[addressToWhitelist] = true;
	}

	function removeFunctionWhitelist(address addressToWhitelist) public onlyOwner() {
		_functionWhitelist[addressToWhitelist] = false;
	}

	function isFunctionWhitelisted(address addr) public view returns (bool) {
		return _functionWhitelist[addr];
	}

	function initReplicateState() public onlyOwner() {
		_replicateState = true;
	}

	function endReplicateState() public onlyOwner() {
		_replicateState = false;
	}

	function batchReplicateState(address[] memory to, uint256[] memory amount) public onlyWhitelist() {
		require(preseedLaunched == false, "Cannot replicate state after preseed launch");
		require(_replicateState == true, "Cannot replicate state without init");
		require (to.length == amount.length, "array length mismatch");
		
		for (uint256 i = 0; i < to.length; i++) {
			require(_Discreet.balanceOf(to[i]) == 0, "State for this address has been replicated"); 
			_Discreet.transfer(to[i], amount[i]);
			totalPreseedTokensToSell = totalPreseedTokensToSell.sub(amount[i]);
		}
	}

	function beginPreseed(uint256 numDays, uint256 _rate) public onlyOwner() {
		require(preseedLaunched == false, "Preseed already began");
		require(_replicateState == false, "Still replicating state");
		preseedStartDate = now;
		preseedEndDate = now + numDays * 1 days;
		_preseedRate = _rate;
		preseedLaunched = true;
	}

	function extendPreseed(uint256 numDays) public onlyWhitelist() {
		preseedEndDate += numDays * 1 days;
	}

	function changePreseedRate(uint256 _rate) public onlyWhitelist() {
		_preseedRate = _rate;
	}

	function preseedRate() public view returns (uint256) {
		return _preseedRate;
	}

	function minTokenBuy() public view returns (uint256) {
		return _minTokenBuy;
	}

	function maxTokenBuy() public view returns (uint256) {
		return _maxTokenBuy;
	}

	function changeMinTokenBuy(uint256 newMin) public onlyWhitelist() {
		_minTokenBuy = newMin;
	}

	function changeMaxTokenBuy(uint256 newMax) public onlyWhitelist() {
		_maxTokenBuy = newMax;
	}

	function tokenSaleBuy() public payable {
		require(now >= preseedStartDate);
		require(now < preseedEndDate);
		require(msg.value >= _minTokenBuy, "TokenSaleBuy: Value must be at least minimum amount");
		require(msg.value <= _maxTokenBuy, "TokenSaleBuy: Value must be no more than maximum amount");
		require(_purchases[_msgSender()] <= _maxTokenBuy, "TokenSaleBuy: Value and total purchased thus far exceeds maximum");
		
		uint256 tokensToGive = _preseedRate * msg.value;
		uint256 _val = msg.value;

		if (_purchases[_msgSender()] + msg.value > _maxTokenBuy) {
			_val = _maxTokenBuy - _purchases[_msgSender()];
			_msgSender().transfer(msg.value.sub(_val));
			tokensToGive = _preseedRate * _val;
		}

		bool isSoldOut = false;

		if (tokensToGive > totalPreseedTokensToSell) {
			_val = totalPreseedTokensToSell.sub(totalPreseedTokensToSell % _preseedRate).div(_preseedRate);
			_msgSender().transfer(msg.value.sub(_val));
			tokensToGive = totalPreseedTokensToSell;
			isSoldOut = true;
		}

		_Discreet.transfer(_msgSender(), tokensToGive);
		emit TokenSaleBuy(_msgSender(), tokensToGive);

		totalPreseedTokensToSell = totalPreseedTokensToSell.sub(tokensToGive);

		payable(owner()).transfer(_val);
	}

	receive() external payable {
		tokenSaleBuy();
	}

	function drainTokens() public onlyOwner() {
		if (_Discreet.balanceOf(address(this)) > 0) {
			_Discreet.transfer(_msgSender(), _Discreet.balanceOf(address(this)));
		}
	}

	function endPreseed() public onlyOwner() {
		require(preseedLaunched == true, "Preseed hasn't been launched yet");
		require(now > preseedEndDate, "Preseed hasn't reached end date");
		drainTokens(); // return tokens to owner
	}
}
