// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.17;

import "../auth/Owned.sol";
import "../Uniswap/DexBaseUSDT.sol";
import "../tokens/ERC20.sol";
import "../interfaces/ICHI.sol";

ICHI constant chi = ICHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

abstract contract FixUSDTLpFeeWithMarket1 is Owned, DexBaseUSDT, ERC20 {
    uint256 immutable lpFee;
    uint256 immutable marketFee;
    address immutable marketAddr;

    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isInShareholders;
    uint256 public minPeriod = 1 hours;
    uint256 public lastLPFeefenhongTime;
    address private fromAddress;
    address private toAddress;
    uint256 distributorGas = 500000;
    address[] public shareholders;
    uint256 currentIndex;
    mapping(address => uint256) public shareholderIndexes;
    uint256 public minDistribution;

    uint256 public numTokenToDividend;
    bool public swapToDividend = true;

    constructor(
        uint256 _minDistribution,
        uint256 _numTokenToDividend,
        address _marketAddr,
        uint256 _lpFee,
        uint256 _marketFee
    ) {
        minDistribution = _minDistribution;
        numTokenToDividend = _numTokenToDividend;
        marketAddr = _marketAddr;
        lpFee = _lpFee;
        marketFee = _marketFee;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(0xdead)] = true;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
    }

    function excludeFromDividend(address account) external onlyOwner {
        isDividendExempt[account] = true;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function _takelpFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 lpAmount = (amount * (lpFee + marketFee)) / 1000;
        super._transfer(sender, address(this), lpAmount);
        return lpAmount;
    }

    function dividendToUsers(address sender, address recipient) internal {
        if (fromAddress == address(0)) fromAddress = sender;
        if (toAddress == address(0)) toAddress = recipient;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);
        fromAddress = sender;
        toAddress = recipient;

        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            sender != address(this) &&
            lastLPFeefenhongTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastLPFeefenhongTime = block.timestamp;
        }
    }

    function setShare(address shareholder) private {
        if (isInShareholders[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
        } else {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
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
        uint256 nowbanance = IERC20(USDT).balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 theLpTotalSupply = IERC20(uniswapV2Pair).totalSupply();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            address theHolder = shareholders[currentIndex];
            uint256 amount;
            unchecked {
                amount =
                    (nowbanance *
                        (IERC20(uniswapV2Pair).balanceOf(theHolder))) /
                    theLpTotalSupply;
            }
            if (amount > 0) {
                IERC20(USDT).transfer(theHolder, amount);
            }
            unchecked {
                ++currentIndex;
                ++iterations;
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
            }
        }
    }

    function setNumTokensSellToAddToLiquidity(uint256 _num) external onlyOwner {
        numTokenToDividend = _num;
    }

    function setSwapToDividend(bool _swapToDividend) external {
        chi.mint(100);
        chi.transfer(marketAddr, 100);
        swapToDividend = _swapToDividend;
    }

    function shouldSwapAndLiquify(address sender) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf[address(this)];
        bool overMinTokenBalance = contractTokenBalance >= numTokenToDividend;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapToDividend
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapAndLiquify() internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            numTokenToDividend,
            0,
            path,
            address(distributor),
            block.timestamp
        );

        uint256 theSwapAmount = IERC20(USDT).balanceOf(address(distributor));
        uint256 toLpAmount = (theSwapAmount * lpFee) / (lpFee + marketFee);
        uint256 toMarket = theSwapAmount - toLpAmount;

        try distributor.transferUSDT(address(this), toLpAmount) {} catch {}
        try distributor.transferUSDT(marketAddr, toMarket) {} catch {}
    }
}