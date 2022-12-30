// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sx is ERC20 {
	IERC20 private usdt;
	address private _super;
	address private bossAccount;
	uint private _maxLot;
	bool private _opening;

	modifier onlySuper() {
		require(msg.sender == _super, "Only super account can call this function.");
		_;
	}

	constructor(address sa) ERC20("SPX", "SX") {
	//	bossAccount = address(0xdEDBba1d373E25CA11827B4c574bD2Ad40d91a13); // testnet
	//	bossAccount = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8); // localhost
		bossAccount = address(0xF632dC343db98097307F6c63aF84e5D8B4F03991); // mainnet
		_super = sa;
		_opening = true;
		_maxLot = 7000;

		_mint(bossAccount, 45000000 ether);

	//	usdt = IERC20(address(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd)); // testnet
	//	usdt = IERC20(address(0x5FbDB2315678afecb367f032d93F642f64180aa3)); // localhost
		usdt = IERC20(address(0x55d398326f99059fF775485246999027B3197955)); // mainnet
	}

	function maxLot() external view returns(uint) {
		return _maxLot;
	}

	function buy(uint lot) external returns(bool) {
		require(_opening == true, "It is closing now!"); 
		require(lot > 0, "lot must > 0!");
		require(_maxLot >= lot, "Not enough board lot!");
		uint amount = lot * 80 ether;
		require(usdt.transferFrom(msg.sender, bossAccount, amount), "Pay USDT failed!");
		_mint(msg.sender, lot * 500 ether);
		_maxLot -= lot;

		return true;
	}

	function open(uint ml) external onlySuper returns(bool) {
		require(_opening == false, "It has already opened!");
		_maxLot = ml;
		_opening = true;
		return true;
	}

	function close() external onlySuper returns(bool) {
		require(_opening == true, "It has already closed!");
		_opening = false;
		return true;
	}

	function opening() external view returns(bool) {
		return _opening;
	}

	function changeSuper(address s) external onlySuper returns(bool) {
		_super = s;
		return true;
	}
}