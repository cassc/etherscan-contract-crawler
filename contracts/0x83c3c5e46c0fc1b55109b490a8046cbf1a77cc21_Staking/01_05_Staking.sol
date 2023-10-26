// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking is Ownable {
	struct Share {
		uint depositTime;
		uint initialDeposit;
		uint sumETH;
	}

	mapping(address => Share) public shares;
	IERC20 public token;
	uint public sumETH;
	uint private constant PRECISION = 1e18;
	address private _taxWallet;
	uint public totalETH;

	modifier onlyToken() {
		assert(msg.sender == address(token));
		_;
	}

	constructor() {
		_taxWallet = msg.sender;
	}

	function setToken(IERC20 token_) external onlyOwner {
		token = token_;
		super.renounceOwnership();
	}

	function deposit(address who, uint amount) external onlyToken {
		require(amount > 0, "Amount must be greater than zero");
		Share memory share = shares[who];
		_payoutGainsUpdateShare(who, share, share.initialDeposit + amount, true);
	}

	function withdraw() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		require(share.depositTime + 1 weeks < block.timestamp, "withdraw after one week");
		token.transfer(msg.sender, share.initialDeposit);
		_payoutGainsUpdateShare(msg.sender, share, 0, true);
	}

	function claim() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		_payoutGainsUpdateShare(msg.sender, share, share.initialDeposit, false);
	}

	function _payoutGainsUpdateShare(address who, Share memory share, uint newAmount, bool resetTimer) private {
		uint gains;
		if (share.initialDeposit != 0) gains = share.initialDeposit * (sumETH - share.sumETH) / PRECISION;

		if (newAmount == 0) delete shares[who];
		else if (resetTimer) shares[who] = Share(block.timestamp, newAmount, sumETH);
		else shares[who] = Share(share.depositTime, newAmount, sumETH);

		if (gains > 0) Address.sendValue(payable(who), gains);
	}

	function pending(address who) external view returns (uint) {
		Share memory share = shares[who];
		return share.initialDeposit * (sumETH - share.sumETH) / PRECISION;
	}

	receive() external payable {
		if (msg.value == 0) return;

		uint balance = token.balanceOf(address(this));
		if (balance == 0) return Address.sendValue(payable(_taxWallet), msg.value);

		uint amount = msg.value / 2;
		uint gpus = amount * PRECISION / balance;
		sumETH += gpus;
		totalETH += amount;

		uint taxAmount = msg.value - amount;
		if (taxAmount > 0) Address.sendValue(payable(_taxWallet), taxAmount);
	}
}