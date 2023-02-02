pragma solidity =0.5.16;


contract CStorage {
	address public borrowable0;
	address public borrowable1;
	address public tarotPriceOracle;
	uint public safetyMargin = 1.08e18; // safetyMargin: 108%
	uint public mTolerance = 1e8;
	uint public liquidationIncentive = 1.01e18; // 101%
	uint public liquidationFee = 0.005e18; // 0.5%
	
	function liquidationPenalty() public view returns (uint) {
		return liquidationIncentive + liquidationFee;
	}
}