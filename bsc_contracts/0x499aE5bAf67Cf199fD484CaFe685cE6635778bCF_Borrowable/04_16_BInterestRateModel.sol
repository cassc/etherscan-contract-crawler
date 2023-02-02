pragma solidity =0.5.16;

import "./BStorage.sol";
import "./PoolToken.sol";

contract BInterestRateModel is PoolToken, BStorage {

	// When utilization is 100% borrowRate is kinkBorrowRate * KINK_MULTIPLIER
	// kinkBorrowRate relative adjustment per second belongs to [1-adjustSpeed, 1+adjustSpeed*(KINK_MULTIPLIER-1)]
	uint public constant KINK_MULTIPLIER = 3;
	uint public constant KINK_BORROW_RATE_MAX = 281.582952e9; //888% per year
	uint public constant KINK_BORROW_RATE_MIN = 0.31709792e9; //1% per year

	event AccrueInterest(uint interestAccumulated, uint borrowIndex, uint totalBorrows);
	event CalculateKinkBorrowRate(uint kinkBorrowRate);
	event CalculateBorrowRate(uint borrowRate);
		
	function _calculateBorrowRate() internal {
		uint _kinkUtilizationRate = kinkUtilizationRate;		
		uint _adjustSpeed = adjustSpeed;
		uint _borrowRate = borrowRate;	
		uint _kinkBorrowRate = kinkBorrowRate;
		uint32 _rateUpdateTimestamp = rateUpdateTimestamp;		
	
		// update kinkBorrowRate using previous borrowRate
		uint32 timeElapsed = getBlockTimestamp() - _rateUpdateTimestamp; // underflow is desired
		if(timeElapsed > 0) {
			rateUpdateTimestamp = getBlockTimestamp();
			uint adjustFactor;
			
			if (_borrowRate < _kinkBorrowRate) {
				// never overflows, _kinkBorrowRate is never 0
				uint tmp = (_kinkBorrowRate - _borrowRate) * 1e18 / _kinkBorrowRate * _adjustSpeed * timeElapsed / 1e18;
				adjustFactor = tmp > 1e18 ? 0 : 1e18 - tmp;
			} else {
				// never overflows, _kinkBorrowRate is never 0
				uint tmp = (_borrowRate - _kinkBorrowRate) * 1e18 / _kinkBorrowRate * _adjustSpeed * timeElapsed / 1e18;
				adjustFactor = tmp + 1e18;
			}
			
			// never overflows
			_kinkBorrowRate = _kinkBorrowRate * adjustFactor / 1e18;
			if(_kinkBorrowRate > KINK_BORROW_RATE_MAX) _kinkBorrowRate = KINK_BORROW_RATE_MAX;
			if(_kinkBorrowRate < KINK_BORROW_RATE_MIN) _kinkBorrowRate = KINK_BORROW_RATE_MIN;

			kinkBorrowRate = uint48(_kinkBorrowRate);
			emit CalculateKinkBorrowRate(_kinkBorrowRate);
		}
		
		uint _utilizationRate;
		{ // avoid stack to deep
		uint _totalBorrows = totalBorrows; // gas savings
		uint _actualBalance = totalBalance.add(_totalBorrows);
		_utilizationRate = (_actualBalance == 0) ? 0 : _totalBorrows * 1e18 / _actualBalance;
		}
		
		// update borrowRate using the new kinkBorrowRate	
		if(_utilizationRate <= _kinkUtilizationRate) {
			// never overflows, _kinkUtilizationRate is never 0
			_borrowRate = _kinkBorrowRate * _utilizationRate / _kinkUtilizationRate;
		} else {
			// never overflows, _kinkUtilizationRate is always < 1e18
			uint overUtilization = (_utilizationRate - _kinkUtilizationRate) * 1e18 / (1e18 - _kinkUtilizationRate);
			// never overflows
			_borrowRate = ((KINK_MULTIPLIER - 1) * overUtilization + 1e18) * _kinkBorrowRate / 1e18;
		}
		borrowRate = uint48(_borrowRate);
		emit CalculateBorrowRate(_borrowRate);
	}
	
	// applies accrued interest to total borrows and reserves
	function accrueInterest() public {
		uint _borrowIndex = borrowIndex;
		uint _totalBorrows = totalBorrows;
		uint32 _accrualTimestamp = accrualTimestamp;
		
		uint32 blockTimestamp = getBlockTimestamp();
		if (_accrualTimestamp == blockTimestamp) return;
		uint32 timeElapsed = blockTimestamp - _accrualTimestamp; // underflow is desired
		accrualTimestamp = blockTimestamp;
		
		uint interestFactor = uint(borrowRate).mul(timeElapsed);	
		uint interestAccumulated = interestFactor.mul(_totalBorrows).div(1e18);
		_totalBorrows = _totalBorrows.add( interestAccumulated );
		_borrowIndex = _borrowIndex.add( interestFactor.mul(_borrowIndex).div(1e18) );
	
		borrowIndex = safe112(_borrowIndex);
		totalBorrows = safe112(_totalBorrows);
		emit AccrueInterest(interestAccumulated, _borrowIndex, _totalBorrows);
	}
		
	function getBlockTimestamp() public view returns (uint32) {
		return uint32(block.timestamp % 2**32);
	}
}