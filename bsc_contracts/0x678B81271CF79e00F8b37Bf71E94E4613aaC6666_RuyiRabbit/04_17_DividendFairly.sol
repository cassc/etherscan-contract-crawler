// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Rates.sol";

abstract contract DividendFairly is Rates {

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => bool) public holderMap;
    uint256 public currentIndex;
    mapping(address => bool) public isDividendExempt;

    uint256 public distributorGas = 500000;
    uint256 public currentDividendPrice;
    uint256 public magnitude = 1e40;

    address public holdToken;
    uint256 public holdToken4RewardCondition;
    uint256 public dividendAtUSDT;
    uint256 public feeDividend;

    function __DividendFairly_init(uint256 _feeDividend, address _holdToken, uint256 _holdToken4RewardCondition, uint256 _dividendAtUSDT, address[] memory _defaultHolders) internal {
        _setFeeDividend(_feeDividend);
        addShareholder(_msgSender());
        holdToken = _holdToken;
        holdToken4RewardCondition = _holdToken4RewardCondition;
        dividendAtUSDT = _dividendAtUSDT;
        for (uint i = 0; i < _defaultHolders.length; i++) {
            addShareholder(_defaultHolders[i]);
        }
    }

    function setDividendExempt(address adr, bool b) public onlyOwner {isDividendExempt[adr] = b;}
    function setDistributorGas(uint256 num) public onlyOwner {distributorGas = num;}
    function setDividendAtUSDT(uint256 num) public onlyOwner {dividendAtUSDT = num;}
    function setHoldToken4RewardCondition(uint256 num) public onlyOwner {holdToken4RewardCondition = num;}
    function _setFeeDividend(uint256 num) private {
        feeDividend = num;
        increaseRatesTotal(num);
    }
    function setFeeDividendOnly(uint256 num) public onlyOwner {
        feeDividend = num;
    }
    function setFeeDividendAndUpdateTotalFees(uint256 num) public onlyOwner {
        _setFeeDividend(num);
    }

    function processFeeDividend(uint256 _amount) internal {
        if (feeDividend > 0) {
            uint256 amount = _amount * feeDividend / _feeTotal;
            super.swapAndSend2fee(amount, _TokenStation);
        }
    }

    function processDividend(address from, address to) internal {
        if(!isDividendExempt[from]) setShare(from);
        if(!isDividendExempt[to]) setShare(to);
        IERC20 USDT = IERC20(_sellPath[1]);
        IERC20 Token = IERC20(holdToken);
        uint256 amountUSDT = USDT.balanceOf(_TokenStation);
        if (amountUSDT >= dividendAtUSDT && currentDividendPrice == 0) {
            uint256 totalHolderToken = Token.totalSupply() - Token.balanceOf(pair) - Token.balanceOf(address(this)) - Token.balanceOf(address(0x0)) - Token.balanceOf(address(0xdead));
            if (totalHolderToken > 0) {
                currentDividendPrice = amountUSDT * magnitude / totalHolderToken;
                USDT.transferFrom(_TokenStation, address(this), amountUSDT);
            }
        }
        if (currentDividendPrice != 0) process(distributorGas);
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;

        IERC20 USDT = IERC20(_sellPath[1]);
        IERC20 Token = IERC20(holdToken);

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
                currentDividendPrice = 0;
                return;
            }
            uint256 amount = Token.balanceOf(shareholders[currentIndex]) * currentDividendPrice / magnitude;
            if (USDT.balanceOf(address(this)) < amount)
            {
                currentIndex = 0;
                currentDividendPrice = 0;
                return;
            }

            USDT.transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) private {
        IERC20 Token = IERC20(holdToken);
        if (holderMap[shareholder]) {
            if (Token.balanceOf(shareholder) < holdToken4RewardCondition) quitShare(shareholder);
            return;
        }
        if (Token.balanceOf(shareholder) < holdToken4RewardCondition) return;
        addShareholder(shareholder);
        holderMap[shareholder] = true;

    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        holderMap[shareholder] = false;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}