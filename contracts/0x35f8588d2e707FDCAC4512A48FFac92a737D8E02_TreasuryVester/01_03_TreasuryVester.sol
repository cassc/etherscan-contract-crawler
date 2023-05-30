// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TreasuryVester {
	using SafeMath for uint256;

	address public erp; //  0x0a0e3bfD5a8cE610E735D4469Bc1b3b130402267  ETH MAINNET
	address public recipient;

	uint256 public vestingAmount; 
	uint256 public vestingBegin;  // 1632141600
	uint256 public vestingCliff;  // 1635645600
	uint256 public vestingEnd;  // 1667181600

	uint256 public lastUpdate;

	constructor(
		address erp_,
		address recipient_,
		uint256 vestingAmount_,
		uint256 vestingBegin_,
		uint256 vestingCliff_,
		uint256 vestingEnd_
	) {
		require(erp_ != address(0), "TreasuryVester::constructor: rep token zero address");
		require(recipient_ != address(0), "TreasuryVester::constructor: recipient zero address");
 		require(vestingBegin_ < block.timestamp, "TreasuryVester::constructor: vesting begin too late");
		require(vestingCliff_ > vestingBegin_, "TreasuryVester::constructor: cliff is too early");
		require(vestingEnd_ > vestingCliff_, "TreasuryVester::constructor: end is too early");

		erp = erp_;
		recipient = recipient_;

		vestingAmount = vestingAmount_;
		vestingBegin = vestingBegin_;
		vestingCliff = vestingCliff_;
		vestingEnd = vestingEnd_;

		lastUpdate = vestingBegin;
	}

	function setRecipient(address recipient_) public {
		require(msg.sender == recipient, "TreasuryVester::setRecipient: unauthorized");
		recipient = recipient_;
	}

	function claim() public {
		require(block.timestamp >= vestingCliff, "TreasuryVester::claim: not time yet");
		uint256 amount;
		if (block.timestamp >= vestingEnd) {
			amount = IERC20(erp).balanceOf(address(this));
		} else {
			amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
			lastUpdate = block.timestamp;
		}
		IERC20(erp).transfer(recipient, amount);
	}
}