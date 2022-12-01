// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

contract FeeControl {
	uint256 public constant SYSTEM_PRECISION = 10_000; // 100%
	uint256 public fee = 100; // i.e. 1%

	address payable public treasury;

	function setFee(uint256 _fee) external {
		require(_fee <= SYSTEM_PRECISION, "Wrong fee set");
		fee = _fee;
	}

	function setTreasury(address payable _treasury) external {
		treasury = _treasury;
	}

	function calcFee(uint256 _amountIn) public view returns (uint256 _amountOut, uint256 _fee) {
		if (fee != 0 && treasury != address(0)) {
			_amountOut = _amountIn * fee / SYSTEM_PRECISION;
			_fee = _amountIn - _amountOut;
		} else {
			_amountOut = _amountIn;
		}
	}
}