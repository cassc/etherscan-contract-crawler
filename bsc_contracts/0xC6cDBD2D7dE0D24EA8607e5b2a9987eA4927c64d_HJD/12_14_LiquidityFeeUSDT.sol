// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Owned.sol";
import "./DexBaseUSDT.sol";
import "./ERC20.sol";

abstract contract LiquidityFeeUSDT is Owned, DexBaseUSDT, ERC20 {
    uint256 private constant liquidityFee = 5;
    bool private swapAndLiquifyEnabled = false;
    uint256 internal numTokensSellToAddToLiquidity =2*1e18;
    address private usdtAddress;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        address _usdtAddress,
        uint256 _numTokensSellToAddToLiquidity,
        bool _swapAndLiquifyEnabled
    ) {
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
        usdtAddress = _usdtAddress;
    }

    function _takeliquidityFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 liquidityAmount = (amount * liquidityFee) / 1000;
        super._transfer(sender, address(this), liquidityAmount);
        return liquidityAmount;
    }

    function shouldSwapAndLiquify(address sender) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf[address(this)];
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2PairAddress &&
            swapAndLiquifyEnabled
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));
        swapTokensForTokens(half);
        uint256 newBalance = IERC20(usdtAddress).balanceOf(address(this)) -
            initialBalance;
        addLiquidity(otherHalf, newBalance);
    }

    function swapTokensForTokens(uint256 tokenAmount) internal {
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
        uint256 amount = IERC20(usdtAddress).balanceOf(address(distributor));
        distributor.transferUSDT(usdtAddress, address(this), amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        IERC20(usdtAddress).approve(address(uniswapV2Router), usdtAmount);
        uniswapV2Router.addLiquidity(
            address(this),
            address(usdtAddress),
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 _num) internal onlyOwner {
        numTokensSellToAddToLiquidity = _num;
    }

    function setSwapAndLiquifyEnabled(bool _n) internal onlyOwner {
        swapAndLiquifyEnabled = _n;
    }
}
