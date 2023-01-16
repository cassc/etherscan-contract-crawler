// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./UniSwapPoolUSDT.sol";
import "./TokenStation.sol";

abstract contract Rates is UniSwapPoolUSDT, Ownable {
    uint256 public _feeBuys;
    uint256 public _feeSells;
    uint256 public _feeTotal;
    address public _TokenStation;

//    uint256 internal _feeDividend;
    uint256 internal _feeLP;
    uint256[] internal _feeMarketing;
    address internal _feeLPTo;

    function __Rates_init(address _feeLPTo_) internal {
//        _feeDividend = 400;
        _feeLP = 50;
        _feeMarketing.push(1300);
        _feeMarketing.push(550);

        _feeBuys = 300;
        _feeSells = 1600;
        _feeTotal = _feeBuys+_feeSells;

        _feeLPTo = _feeLPTo_;
        _TokenStation = address(new TokenStation(_sellPath[1]));
    }
    
    function updateFeeBuyAndSell(uint256 _feeBuys_, uint256 _feeSells_) internal {
        _feeBuys = _feeBuys_;
        _feeSells = _feeSells_;
        _feeTotal = _feeBuys+_feeSells;
    }

    function resetRates() public onlyOwner {
        _feeSells = 600;
        _feeTotal = _feeBuys+_feeSells;
        _feeMarketing[0] = 300;
        _feeMarketing[1] = 150;
    }

//    function setRates(uint256 _feeDividend_, uint256 _feeLP_, uint256 _feeBuys_, uint256 _feeSells_, uint256 _feeMarketing_) public onlyOwner {
    function setRatesOnly(uint256 _feeLP_, uint256[] memory _feeMarketing_, uint256 _feeBuys_, uint256 _feeSells_) public onlyOwner {
//        _feeDividend = _feeDividend_;
        _feeLP = _feeLP_;
        _feeMarketing = _feeMarketing_;

        _feeBuys = _feeBuys_;
        _feeSells = _feeSells_;
    }
    function setRatesAndUpdateTotalFees(uint256 _feeLP_, uint256[] memory _feeMarketing_, uint256 _feeBuys_, uint256 _feeSells_) public onlyOwner {
        setRatesOnly(_feeLP_, _feeMarketing_, _feeBuys_, _feeSells_);
        _feeTotal = _feeBuys+_feeSells;
    }
    function setRatesTotal(uint256 _feeTotal_) public onlyOwner {
        _feeTotal = _feeTotal_;
    }
    function increaseRatesTotal(uint256 _feeTotalExtra) internal {
        _feeTotal += _feeTotalExtra;
    }


    function handFeeBuys(address from, uint256 amount) internal returns (uint256 fee) {
        fee = amount * _feeBuys / divBase;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function handFeeSells(address from, uint256 amount) internal returns (uint256 fee) {
        fee = amount * _feeSells / divBase;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }
    
    function processFeeLP(uint256 _amount) internal {
        if (_feeLP > 0) {
            uint256 amount = _amount * _feeLP / _feeTotal;
            super.addLiquidity(amount, _feeLPTo, _TokenStation);
        }
    }

    function processFeeMarketing(uint256 _amount) internal {
        if (_feeMarketing.length == 0) return;
        for (uint i=0;i<_feeMarketing.length;i++) {
            if (_feeMarketing[i] > 0) {
                uint256 amount = _amount * _feeMarketing[i] / _feeTotal;
                super.swapAndSend2fee(amount, _marks[i]);
            }
        }
    }
}