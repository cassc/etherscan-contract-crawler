// SPDX-License-Identifier: MIT
// Holdings.sol - j0zf 2021-03-14

pragma solidity >=0.6.0 <0.8.0;
import "./SafeMath.sol"; // import "@openzeppelin/contracts/math/SafeMath.sol";

library Holdings {
	using SafeMath for uint256;

	// 0:Null 1:Royalties 2:Sales 3:General 4:Bonuses 5:Refunds 6:Bids Escrow 7:Trades Escrow 8:Auction Escrow 9:Tax Escrow 10:Withdrawal Escrow
	uint32 constant _Royalties_ = 1;
	uint32 constant _Sales_ = 2;
	uint32 constant _General_ = 3;
	uint32 constant _Bonuses_ = 4;
	uint32 constant _Refunds_ = 5;
	uint32 constant _Bids_Escrow_ = 6;
	uint32 constant _Trades_Escrow_ = 7;
	uint32 constant _Auctions_Escrow_ = 8;
	uint32 constant _Tax_Escrow_ = 9;
	uint32 constant _Withdrawal_Escrow_ = 10;

	// pools poolType 0:Null 1:House Pool 2:Bonus Pool 3:Tax Pool 4:Withdrawal Pool
	uint32 constant _House_Pool_ = 1;
	uint32 constant _Bonus_Pool_ = 2;
	uint32 constant _Tax_Pool_ = 3;
	uint32 constant _Withdrawal_Pool_ = 4;

	struct HoldingsTable {
		mapping(uint32 => mapping(address => uint256)) _holdings; // holdings[accountType][address] => balance;
		mapping(uint32 => uint256) _holdingsTotals; // holdingsTotals[accountType] => total; (accounts for _holdings)
		mapping(uint32 => uint256) _pools; // pools[poolType] => balance;
	}

	function creditAccount(HoldingsTable storage holdingsTable, uint32 accountType, address account, uint256 amount) internal {
		require(accountType > 0 && account != address(0), "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._holdings[accountType][account];
		uint256 total = holdingsTable._holdingsTotals[accountType];
		balance = balance.add(amount);
		total = total.add(amount);
		holdingsTable._holdings[accountType][account] = balance;
		holdingsTable._holdingsTotals[accountType] = total;
		emit AccountCredited(accountType, account, amount, balance);
	}
	event AccountCredited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);

	function debitAccount(HoldingsTable storage holdingsTable, uint32 accountType, address account, uint256 amount) internal {
		require(accountType > 0 && account != address(0), "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._holdings[accountType][account];
		uint256 total = holdingsTable._holdingsTotals[accountType];
		require(balance >= amount && total >= amount, "NOT_ENOUGH");
		balance = balance.sub(amount);
		total = total.sub(amount);
		holdingsTable._holdings[accountType][account] = balance;
		holdingsTable._holdingsTotals[accountType] = total;
		emit AccountDebited(accountType, account, amount, balance);
	}
	event AccountDebited(uint32 indexed accountType, address indexed account, uint256 amount, uint256 balance);

	function transferAmount(HoldingsTable storage holdingsTable, uint32 fromAccountType, address fromAccount, uint32 toAccountType, address toAccount, uint256 amount) internal {
		Holdings.debitAccount(holdingsTable, fromAccountType, fromAccount, amount);
		Holdings.creditAccount(holdingsTable, toAccountType, toAccount, amount);
	}
	function transferPoolAmount(HoldingsTable storage holdingsTable, uint32 fromPoolType, uint32 toAccountType, address toAccount, uint256 amount) internal {
		Holdings.debitPool(holdingsTable, fromPoolType, amount);
		Holdings.creditAccount(holdingsTable, toAccountType, toAccount, amount);
	}

	function getAccountBalance(HoldingsTable storage holdingsTable, uint32 accountType, address account) internal view returns (uint256) {
		require(accountType > 0 && account != address(0), "BAD_INPUT");
		return holdingsTable._holdings[accountType][account];
	}

	function getHoldingsTotal(HoldingsTable storage holdingsTable, uint32 accountType) internal view returns (uint256) {
		// @returns totals of all accounts for each accountType in the holdingsTable
		require(accountType > 0, "BAD_INPUT");
		return holdingsTable._holdingsTotals[accountType];
	}

	function creditPool(HoldingsTable storage holdingsTable, uint32 poolType, uint256 amount) internal {
		require(poolType > 0, "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._pools[poolType];
		balance = balance.add(amount);
		holdingsTable._pools[poolType] = balance;
		emit PoolCredited(poolType, amount, balance);
	}
	event PoolCredited(uint32 poolType, uint256 amount, uint256 balance);

	function debitPool(HoldingsTable storage holdingsTable, uint32 poolType, uint256 amount) internal {
		require(poolType > 0, "BAD_INPUT"); // allowing amount of 0
		if (amount == 0) return;
		uint256 balance = holdingsTable._pools[poolType];
		require(balance >= amount, "NOT_ENOUGH");
		balance = balance.sub(amount);
		holdingsTable._pools[poolType] = balance;
		emit PoolDebited(poolType, amount, balance);
	}
	event PoolDebited(uint32 indexed poolType, uint256 amount, uint256 balance);

	function getPoolBalance(HoldingsTable storage holdingsTable, uint32 poolType) internal view returns (uint256) {
		require(poolType > 0, "BAD_INPUT");
		return holdingsTable._pools[poolType];
	}

}
