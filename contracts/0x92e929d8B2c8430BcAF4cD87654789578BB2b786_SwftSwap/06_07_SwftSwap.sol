// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

contract SwftSwap is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;

    string public symbol;

    event Swap(
        address fromToken,
        string toToken,
        address sender,
        string destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    );

    event SwapEth(
        string toToken,
        address sender,
        string destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    );

    event WithdrawETH(uint256 amount);

    event Withdtraw(address token, uint256 amount);

    constructor() {
        name = "SWFT Swap1.1";
        symbol = "SSwap";
    }

    function swap(
        address fromToken,
        string memory toToken,
        string memory destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    ) external nonReentrant {
        require(fromToken != address(0), "FROMTOKEN_CANT_T_BE_0");
        require(fromAmount > 0, "FROM_TOKEN_AMOUNT_MUST_BE_MORE_THAN_0");
        uint256 _inputAmount;
        uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(address(this));
        _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
        require(_inputAmount > 0, "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT");
        emit Swap(fromToken, toToken, msg.sender, destination, fromAmount, minReturnAmount);
    }

    function swapEth(string memory toToken, string memory destination, uint256 minReturnAmount
    ) external payable nonReentrant {
        uint256 _ethAmount = msg.value;
        require(_ethAmount > 0, "ETH_AMOUNT_MUST_BE_MORE_THAN_0");
        emit SwapEth(toToken, msg.sender, destination, _ethAmount, minReturnAmount);
    }

    function withdrawETH(address destination, uint256 amount) external onlyOwner {
        require(destination != address(0), "DESTINATION_CANNT_BE_0_ADDRESS");
        uint256 balance = address(this).balance;
        require(balance >= amount, "AMOUNT_CANNT_MORE_THAN_BALANCE");
        TransferHelper.safeTransferETH(destination, amount);
        emit WithdrawETH(amount);
    }

    function withdraw(address token, address destination, uint256 amount) external onlyOwner {
        require(destination != address(0), "DESTINATION_CANNT_BE_0_ADDRESS");
        require(token != address(0), "TOKEN_MUST_NOT_BE_0");
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "AMOUNT_CANNT_MORE_THAN_BALANCE");
        TransferHelper.safeTransfer(token, destination, amount);
        emit Withdtraw(token, amount);
    }

    receive() external payable {}
}
