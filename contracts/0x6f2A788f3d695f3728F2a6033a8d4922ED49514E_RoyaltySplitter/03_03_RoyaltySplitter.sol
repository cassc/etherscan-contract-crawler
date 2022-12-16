//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// This contract receive ethers and split them according to each address share
contract RoyaltySplitter is Ownable {

	uint constant SHARE_MAX = 10000; // means 100%. A share of 100 means 1%, 1 means 0.01%

	uint _totalAmount; 		// total received
	uint _computedAmount;	// amount spread

	//Shares for each address
	mapping (uint256 => address) _addresses;
	mapping (uint256 => uint256) _shares;
	uint _totalHolders;

	//Pending withdrawals
	mapping (address => uint256) _pendingWithdrawals;


	//Constructor
	constructor() {
		_totalAmount = 0;
		_computedAmount = 0;
		
		_totalHolders = 0;
	}
		
    //Default receive
    receive() external payable {
	
		//Check overflow
		require (_totalAmount + msg.value > _totalAmount, "too many ethers sent");
	
        _totalAmount += msg.value;
    }
	
		
	//Init shares
	function setShares(address[] memory addresses, uint256[] memory shares) public onlyOwner {
		
		//Check sizes
		require (addresses.length == shares.length, "array sizes mismatch");
		require (addresses.length > 0, "empty array");
		
		//Check total shares
		uint totalShares = 0;
		for(uint i = 0; i < shares.length; i++) {
			require (totalShares + shares[i] > totalShares, "wrong share value");
			totalShares += shares[i];
		}
		
		require (totalShares == SHARE_MAX, "shares total value is not SHARE_MAX");
		
		//Spread current amount
		this.spreadAmount();
		
		//Store new holders and their shares
		_totalHolders = addresses.length;
		for(uint i = 0; i < _totalHolders; i++) {
			_addresses[i] = addresses[i];
			_shares[i] = shares[i];
		}
	}

	//Spread amount received since the last spread
	function spreadAmount() public {
	
		if (_totalHolders == 0) return;
	
		uint amountToSpread = _totalAmount - _computedAmount;
		if (amountToSpread < SHARE_MAX) return;
		
		amountToSpread /= SHARE_MAX; // minimum 1
		
		for(uint i = 0; i < _totalHolders; i++) {
			_pendingWithdrawals[_addresses[i]] += amountToSpread * _shares[i];
		}
	
		_computedAmount += amountToSpread * SHARE_MAX;
	}
	
	//Withdraw
	function withdraw() public {
	
		//Spread current amount
		this.spreadAmount();
		
		//Get receiver
		address payable receiver = payable(msg.sender);

		//Transfer
		uint amount = _pendingWithdrawals[receiver];
		_pendingWithdrawals[receiver] = 0;
		receiver.transfer(amount);
	}

	function availableToWithdraw() public view returns (uint256) {
		return _pendingWithdrawals[msg.sender];
	}
}