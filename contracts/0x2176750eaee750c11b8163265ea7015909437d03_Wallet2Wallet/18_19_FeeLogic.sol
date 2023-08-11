// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import './SafeERC20.sol';

library FeeLogic {
    using SafeERC20 for IERC20;

    ERC20Burnable constant internal KTN = ERC20Burnable(0x491E136FF7FF03E6aB097E54734697Bb5802FC1C);
    IERC20 constant internal WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IUniswapV2Router02 constant internal ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory constant internal FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function buybackWithUniswap(
        IERC20 _token,
        uint _amountToSwap,
        address[] memory _feeSwapPath,
        uint _feeOutMin,
        address _forwardContract
    ) internal returns(bool) {
        if (KTN == _token) {
            _token.safeTransfer(_forwardContract, _amountToSwap, 'W2W:FL:');
            return true;
        }

        if (_feeSwapPath.length < 2) {
            return false;
        }

        uint feeOut = ROUTER.getAmountsOut(_amountToSwap, _feeSwapPath)[_feeSwapPath.length - 1];

        if (feeOut < _feeOutMin) {
            return false;
        }

        if (_token == ETH) {
            (bool result, ) = payable(address(WETH)).call{value: _amountToSwap}('');
            if (!result) {
                return false;
            }
            _token = WETH;
        }

        _token.safeApprove(address(ROUTER), _amountToSwap, 'W2W:FL:');
        ROUTER.swapExactTokensForTokens(_amountToSwap, feeOut, _feeSwapPath, _forwardContract, block.timestamp);
        return true;
    }
}