// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SwapToUSDC.sol";


abstract contract ERC20Buyable is ERC20, Ownable, SwapToUSDC {
    uint256 immutable private _rate;

    constructor(uint256 rate_) {
        _rate = rate_;
    }

    function _deposit(address receiver_, uint256 amountIn_, uint256 amountOutMinimum_, uint256 amountOutMax_, bytes memory path_) internal virtual returns (uint256) {
        uint256 received = _swap(owner(), amountIn_, amountOutMinimum_, amountOutMax_, path_);
        uint256 amount   = conversion(received);
        _mint(receiver_, amount);
        return amount;
    }

    function conversion(uint256 received_) public view virtual returns (uint256) {
        // 30 = 18 (this.decimals) + 18 (rate denominator) - 6 (USDC.decimals)
        return received_ * (10 ** 30) / _rate;
    }

    function cost(uint256 output_) public view virtual returns (uint256) {
        return output_ * _rate / (10 ** 30);
    }
}