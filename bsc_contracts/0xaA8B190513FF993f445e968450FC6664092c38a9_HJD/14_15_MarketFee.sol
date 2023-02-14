// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./DexBaseUSDT.sol";
import "./IERC20.sol";
import "./ERC20.sol";

abstract contract MarketFee is Owned, DexBaseUSDT, ERC20 {
    uint256 private constant marketFee = 15;
    address private marketAddress;
    address private usdtAddress;
    uint256 private totalMarketAmount;

    constructor(address _usdtAddress, address _marketAddress) {
        usdtAddress = _usdtAddress;
        marketAddress = _marketAddress;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
    }

    function _takeMarketFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 marketAmount = (amount * 1e8 * marketFee) / 1000 / 1e8;
        super._transfer(sender, address(this), marketAmount);
        totalMarketAmount = totalMarketAmount + marketAmount;
        return marketAmount;
    }

    function _sendMarketFee(address sender) internal {
        uint256 contractTokenBalance = balanceOf[address(this)];
        if (
            totalMarketAmount > 0 &&
            contractTokenBalance >= totalMarketAmount &&
            sender != uniswapV2PairAddress
        ) {
            _swapUsdtForTokensAtMarketFee(totalMarketAmount);
            totalMarketAmount = 0;
        }
    }

    function _swapUsdtForTokensAtMarketFee(uint256 _tokenAmount)
        internal
        lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            marketAddress,
            block.timestamp
        );
    }
}
