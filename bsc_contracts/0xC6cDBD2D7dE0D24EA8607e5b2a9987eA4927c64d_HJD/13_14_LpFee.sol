// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./DexBaseUSDT.sol";
import "./ERC20.sol";

abstract contract LpFee is Owned, DexBaseUSDT, ERC20 {
    uint256 private constant lpFee = 20;
    mapping(address => bool) private isDividendExempt;
    mapping(address => bool) private isInShareholders;
    uint256 private minPeriod = 5 minutes;
    uint256 private lastLPFeefenhongTime;
    address private fromAddress;
    address private toAddress;
    uint256 private distributorGas = 500000;
    address[] private shareholders;
    uint256 private currentIndex;
    mapping(address => uint256) private shareholderIndexes;
    uint256 private minDistribution;

    constructor(uint256 _minDistribution) {
        minDistribution = _minDistribution;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(0xdead)] = true;
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
        uint256 lpAmount = (amount * lpFee) / 1000;
        super._transfer(sender, address(distributor), lpAmount);
        return lpAmount;
    }

    function dividendToUsers(address sender, address recipient) internal {
        if (fromAddress == address(0)) fromAddress = sender;
        if (toAddress == address(0)) toAddress = recipient;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2PairAddress)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2PairAddress)
            setShare(toAddress);
        fromAddress = sender;
        toAddress = recipient;

        if (
            balanceOf[address(distributor)] >= minDistribution &&
            sender != address(this) &&
            lastLPFeefenhongTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeefenhongTime = block.timestamp;
        }
    }

    function setShare(address shareholder) private {
        if (isInShareholders[shareholder]) {
            if (IERC20(uniswapV2PairAddress).balanceOf(shareholder) == 0)
                quitShare(shareholder);
        } else {
            if (IERC20(uniswapV2PairAddress).balanceOf(shareholder) == 0) return;
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
        uint256 nowbanance = balanceOf[address(distributor)];
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
            if (amount > 0 && balanceOf[address(distributor)] >= amount) {
                super._transfer(address(distributor), theHolder, amount);
            }
            unchecked {
                ++currentIndex;
                ++iterations;
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
            }
        }
    }
}