// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConstantRateExchange {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN_A;
    IERC20 public immutable TOKEN_B;
    uint256 public immutable PRICE_A;
    uint256 public immutable PRICE_B;

    constructor (IERC20 _tokenA, IERC20 _tokenB, uint256 _priceA, uint256 _priceB) {
        require(_priceA != 0 && _priceB != 0, "Price cannot be zero.");

        TOKEN_A = _tokenA;
        TOKEN_B = _tokenB;
        PRICE_A = _priceA;
        PRICE_B = _priceB;
    }

    function swapAB(uint256 _amountA) external {
        uint256 amountB = _amountA * PRICE_A / PRICE_B; // multiplication can overflow, should use mulmod

        TOKEN_A.safeTransferFrom(msg.sender, address(this), _amountA);
        TOKEN_B.safeTransfer(msg.sender, amountB);
    }

    function swapBA(uint256 _amountB) external {
        uint256 amountA = _amountB * PRICE_B / PRICE_A; // multiplication can overflow, should use mulmod

        TOKEN_B.safeTransferFrom(msg.sender, address(this), _amountB);
        TOKEN_A.safeTransfer(msg.sender, amountA);
    }
}