// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./DexBaseUSDT.sol";
import "./ERC20.sol";
import "./IERC20.sol";

abstract contract LpFee is Owned, DexBaseUSDT, ERC20 {
    uint256 private constant lpFee = 15;
    mapping(address => bool) internal isDividendExempt;
    mapping(address => bool) internal isInShareholders;
    uint256 private minPeriod = 5 minutes;
    uint256 private lastLPFeefenhongTime;
    address private fromAddress;
    address private toAddress;
    uint256 private distributorGas = 500000;
    address[] internal shareholders;
    uint256 private currentIndex;
    mapping(address => uint256) internal shareholderIndexes;
    uint256 private minDistribution;
    address private usdtAddress;
    uint256 private totalLpAmount;

    constructor(address _usdtAddress, uint256 _minDistribution) {
        usdtAddress = _usdtAddress;
        minDistribution = _minDistribution;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(0xdead)] = true;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
    }

    function excludeFromDividend(address account) internal onlyOwner {
        isDividendExempt[account] = true;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) internal onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function _takelpFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 lpAmount = (amount * 1e8 * lpFee) / 1000 / 1e8;
        super._transfer(sender, address(this), lpAmount);
        totalLpAmount = totalLpAmount + lpAmount;
        return lpAmount;
    }

    function _lpFeeToUsdt(address sender) internal {
        uint256 contractTokenBalance = balanceOf[address(this)];
        if (
            totalLpAmount > 0 &&
            contractTokenBalance >= totalLpAmount &&
            sender != uniswapV2PairAddress
        ) {
            _swapUsdtForTokens(totalLpAmount);
            totalLpAmount = 0;
        }
    }

    function dividendToUsers(address sender, address recipient) internal {
        if (fromAddress == address(0)) {
            fromAddress = sender;
        }
        if (toAddress == address(0)) {
            toAddress = recipient;
        }
        if (
            !isDividendExempt[fromAddress] &&
            fromAddress != uniswapV2PairAddress
        ) {
            setShare(fromAddress);
        }
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2PairAddress) {
            setShare(toAddress);
        }
        fromAddress = sender;
        toAddress = recipient;
        if (
            IERC20(usdtAddress).balanceOf(address(distributor)) >=
            minDistribution &&
            sender != address(this) &&
            lastLPFeefenhongTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeefenhongTime = block.timestamp;
        }
    }

    function setShare(address shareholder) private {
        if (isInShareholders[shareholder]) {
            if (IERC20(uniswapV2PairAddress).balanceOf(shareholder) == 0) {
                quitShare(shareholder);
            }
        } else {
            if (IERC20(uniswapV2PairAddress).balanceOf(shareholder) == 0) {
                return;
            }
            addShareholder(shareholder);
            isInShareholders[shareholder] = true;
        }
    }

    function addShareholder(address shareholder) private {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        address lastLPHolder = shareholders[shareholders.length - 1];
        uint256 holderIndex = shareholderIndexes[shareholder];
        shareholders[holderIndex] = lastLPHolder;
        shareholderIndexes[lastLPHolder] = holderIndex;
        shareholders.pop();
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        isInShareholders[shareholder] = false;
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) return;
        uint256 nowbanance = IERC20(usdtAddress).balanceOf(
            address(distributor)
        );
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 theLpTotalSupply = IERC20(uniswapV2PairAddress).totalSupply();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            address theHolder = shareholders[currentIndex];
            uint256 amount;
            unchecked {
                amount =
                    (nowbanance *
                        (IERC20(uniswapV2PairAddress).balanceOf(theHolder))) /
                    theLpTotalSupply;
            }
            if (
                amount > 0 &&
                IERC20(usdtAddress).balanceOf(address(distributor)) >= amount
            ) {
                // super._transfer(address(distributor), theHolder, amount);
                distributor.transferUSDT(usdtAddress, theHolder, amount);
            }
            unchecked {
                ++currentIndex;
                ++iterations;
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
            }
        }
    }

    function _swapUsdtForTokens(uint256 tokenAmount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdtAddress);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(distributor),
            block.timestamp
        );
    }
}
