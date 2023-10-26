// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStaker.sol";
import "./IZap.sol";

contract Staking {
	struct Share {
		uint depositTime;
		uint initialDeposit;
		uint sumETH;
	}

	mapping(address => Share) public shares;
	address private immutable taxWallet;
	uint public sumETH;
	uint private constant PRECISION = 1e18;
	uint public totalETH;
	uint public totalLP;
	uint public immutable delay;
	IStaker public immutable staker;
	IZap public immutable zap;
	uint private isZapping = 2;

	constructor(IStaker staker_, IZap zap_, uint delay_) {
		taxWallet = msg.sender;
		staker = staker_;
		zap = zap_;
		delay = delay_;
	}

	receive() external payable {
		if (msg.sender == address(staker)) _distribute();
		else if (isZapping == 2) _deposit();
	}

	function _distribute() internal {
		if (msg.value == 0) return;

		uint totalLPCached = totalLP;
		if (totalLPCached == 0) return Address.sendValue(payable(taxWallet), msg.value);

		uint gpus = msg.value * PRECISION / totalLPCached;
		sumETH += gpus;
		totalETH += msg.value;
	}

	function _deposit() internal {
		require(msg.value > 0, "Amount must be greater than zero");
		Share memory share = shares[msg.sender];

		isZapping = 1;
		(uint amountLP, uint amountETH) = zap.zapInETH{value: msg.value}(address(staker));
		isZapping = 2;

		if (share.initialDeposit == 0) staker.increaseDepositNb();
		uint gains = _computeGainsUpdateShare(msg.sender, share, share.initialDeposit + amountLP, true, false);
		_sendETH(msg.sender, gains + amountETH);
	}

	function withdraw() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		require(share.depositTime + delay < block.timestamp, "withdraw too soon");

		staker.withdraw(msg.sender, share.initialDeposit);
		staker.decreaseDepositNb();
		uint gains = _computeGainsUpdateShare(msg.sender, share, 0, true, true);
		_sendETH(msg.sender, gains);
	}

	function claim() external {
		Share memory share = shares[msg.sender];
		require(share.initialDeposit > 0, "No initial deposit");
		uint gains = _computeGainsUpdateShare(msg.sender, share, share.initialDeposit, false, false);
		_sendETH(msg.sender, gains);
	}

	function _sendETH(address to, uint amount) private {
		if (amount > 0) Address.sendValue(payable(to), amount);
	}

	function _computeGainsUpdateShare(address who, Share memory share, uint newAmount, bool resetTimer, bool withdrawn) 
		private 
		returns (uint gains)
	{
		staker.distribute();

		if (share.initialDeposit != 0) gains = share.initialDeposit * (sumETH - share.sumETH) / PRECISION;

		if (newAmount == 0) delete shares[who];
		else if (resetTimer) shares[who] = Share(block.timestamp, newAmount, sumETH);
		else shares[who] = Share(share.depositTime, newAmount, sumETH);

		if (withdrawn) totalLP -= share.initialDeposit;
		else if (newAmount != share.initialDeposit) totalLP += (newAmount - share.initialDeposit);
	}

	function pending(address who) external view returns (uint) {
		Share memory share = shares[who];
		uint sumETHUpdated = sumETH + staker.pending(address(this)) * PRECISION / totalLP;
		return share.initialDeposit * (sumETHUpdated - share.sumETH) / PRECISION;
	}
}