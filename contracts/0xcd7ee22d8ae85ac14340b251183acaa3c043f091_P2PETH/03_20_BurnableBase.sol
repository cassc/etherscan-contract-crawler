// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IBeneficiaryBase.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

abstract contract BurnableBase {
    using SafeERC20 for IERC20;
    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    event Burned(address indexed tokenIn, address indexed tokenOut, uint256 amount);

    modifier validate(address[] memory path) {
        require(path.length >= 2, "INVALID_PATH");
        _;
    }

    function VOLT() public pure virtual returns (address) {
        return 0x7db5af2B9624e1b3B4Bb69D6DeBd9aD1016A58Ac;
    }

    function WETH() public view virtual returns (address);

    function beneficiary() public view virtual returns (address);

    function UNISWAP_V2_ROUTER() internal pure virtual returns (IUniswapV2Router02);

    function UNISWAP_FACTORY() internal pure virtual returns (IUniswapV2Factory);

    /// @dev convert ETH to WETH if fee is in ETH before calling this function
    function _burn(uint256 _feeAmount, address[] memory _path) internal virtual {
        address tokenIn = _path[0];
        address tokenOut = _path[_path.length - 1];
        bool whitelistIn = tokenIn == WETH() ? true : IBeneficiaryBase(beneficiary()).tokenWhitelist(tokenIn);
        bool whitelistOut = tokenOut == WETH() ? true : IBeneficiaryBase(beneficiary()).tokenWhitelist(tokenOut);
        if (whitelistIn && whitelistOut) {
            if (tokenIn == WETH()) {
                IERC20(WETH()).safeTransfer(beneficiary(), _feeAmount);
            } else {
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to beneficiary to buy-back and burn 0.5% VOLT
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _feeAmount,
                        0,
                        wethPath,
                        beneficiary(),
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(beneficiary(), _feeAmount);
                }
            }
        } else if (whitelistOut) {
            if (tokenIn == VOLT()) {
                IERC20(tokenIn).safeTransfer(deadAddress, _feeAmount);
            } else {
                uint256 _firstFeeAmount = _feeAmount / 2;
                // burn 0.25% of input token
                IERC20(tokenIn).safeTransfer(deadAddress, _firstFeeAmount);
                uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
                address[] memory wethPath = _getWETHPath(_path);
                if (wethPath.length >= 2) {
                    // buy ETH and send to beneficiary to buy-back and burn 0.25% VOLT
                    UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _secondFeeAmount,
                        0,
                        wethPath,
                        beneficiary(),
                        block.timestamp
                    );
                } else {
                    IERC20(tokenIn).safeTransfer(beneficiary(), _secondFeeAmount);
                }
            }
        } else {
            uint256 _firstFeeAmount = _feeAmount / 2;
            uint256 _secondFeeAmount = _feeAmount - _firstFeeAmount;
            UNISWAP_V2_ROUTER().swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _firstFeeAmount,
                0,
                _path,
                deadAddress,
                block.timestamp
            );
            address[] memory wethPath = _getWETHPath(_path);
            if (wethPath.length >= 2) {
                // buy ETH and send to beneficiary to buy-back and burn 0.25% VOLT
                UNISWAP_V2_ROUTER().swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _secondFeeAmount,
                    0,
                    wethPath,
                    beneficiary(),
                    block.timestamp
                );
            } else {
                IERC20(tokenIn).safeTransfer(beneficiary(), _secondFeeAmount);
            }
        }
        emit Burned(tokenIn, tokenOut, _feeAmount);
    }

    function _getWETHPath(address[] memory _path) internal view returns (address[] memory wethPath) {
        uint256 index = 0;
        for (uint256 i = 0; i < _path.length; i++) {
            if (_path[i] == WETH()) {
                index = i + 1;
                break;
            }
        }
        wethPath = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            wethPath[i] = _path[i];
        }
    }
}