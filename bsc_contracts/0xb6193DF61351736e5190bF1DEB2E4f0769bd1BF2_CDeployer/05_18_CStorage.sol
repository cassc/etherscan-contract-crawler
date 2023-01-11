pragma solidity =0.5.16;


contract CStorage {
	address public borrowable0;
	address public borrowable1;
	address public tarotPriceOracle;
	uint public safetyMarginSqrt = 1.41421356e18; //safetyMargin: 200%
	uint public liquidationIncentive = 1.02e18; //102%
	uint public liquidationFee = 0.01e18; //1%

	function liquidationPenalty() public view returns (uint) {
		return liquidationIncentive + liquidationFee;
	}
}