// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "IERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";

abstract contract IERC20Extented is IERC20 {
    function decimals() public view virtual returns (uint8);
}

contract LiquidityPool is Ownable {
    using SafeERC20 for IERC20Extented;

    address public usdtToken;
    address public usdiToken;

    constructor(address _usdtToken, address _usdiToken) {
        usdtToken = _usdtToken;
        usdiToken = _usdiToken;
    }

    function getLiquidity(address _token) public view returns (uint256) {
        require(_token == usdtToken || _token == usdiToken, "Invalid token");
        return IERC20(_token).balanceOf(address(this));
    }

    function withdraw(address _token, uint256 _amountOut) public onlyOwner {
        IERC20Extented(_token).safeTransfer(msg.sender, _amountOut);
    }

    function exchange(address _fromToken, uint _amountIn) public {
        require(_amountIn > 0, "Invalid amount");
        require(_fromToken == usdtToken || _fromToken == usdiToken, "Invalid token");

        IERC20Extented fromToken = IERC20Extented(_fromToken);
        require(
            fromToken.allowance(msg.sender, address(this)) >= _amountIn,
            "Allowance is insufficient"
        );

        IERC20Extented toToken;
        uint256 amountOut = 0;

        if (_fromToken == usdtToken) {
            toToken = IERC20Extented(usdiToken);
            amountOut = _amountIn * 10 ** 12;
        } else {
            toToken = IERC20Extented(usdtToken);
            amountOut = _amountIn / 10 ** 12;
        }

        uint256 fromTokenBalance = fromToken.balanceOf(msg.sender);
        require(fromTokenBalance >= _amountIn, "Insufficient balance.");

        uint256 toTokenBalance = toToken.balanceOf(address(this));
        require(toTokenBalance >= amountOut, "Insufficient liquidity.");

        fromToken.safeTransferFrom(msg.sender, address(this), _amountIn);
        toToken.safeTransfer(msg.sender, amountOut);
    }
}