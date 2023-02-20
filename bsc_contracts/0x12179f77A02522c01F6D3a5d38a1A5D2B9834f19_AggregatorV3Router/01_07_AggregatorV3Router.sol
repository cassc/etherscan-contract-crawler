// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/TransferHelper.sol";

/// @notice AggregatorV3Router
contract AggregatorV3Router is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public name;

    string public symbol;

    address private _swap_cross;


    /// @notice Swap's log.
    /// @param fromToken token's address.
    /// @param toToken Type of target currency, such as'usdt (matic)
    /// @param sender Who swap
    /// @param destination Receiving address of target currency
    /// @param fromAmount Input amount.
    /// @param minReturnAmount Minimum received quantity of target currency expected by user
    event Swap(
        address fromToken,
        string toToken,
        address sender,
        string destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    );

    /// @notice SwapEth's log.
    /// @param toToken Type of target currency, such as'usdt (matic)
    /// @param sender Who swap
    /// @param destination Receiving address of target currency
    /// @param fromAmount Input amount.
    /// @param minReturnAmount Minimum received quantity of target currency expected by user
    event SwapEth(
        string toToken,
        address sender,
        string destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    );

    event WithdrawETH(uint256 amount);

    event ChangeSwapCross(address oldSwap,address newSwap);

    event Withdtraw(address token, uint256 amount);

    constructor( address swapCross_) {
        name = "Aggregator V3 Router";
        symbol = "AGGREGATOR-V3-Router";
        _swap_cross = swapCross_;
    }

    function swapCross() external view returns (address) {
        return _swap_cross;
    }

    function changeSwapCross(address newSwap) external onlyOwner {
        address oldSwap = _swap_cross;
        _swap_cross = newSwap;
        emit ChangeSwapCross(oldSwap, newSwap);
    }
    /// @notice Excute transactions. transactions. The handling fee is deducted from the transferred currency.
    /// @param fromToken token's address. Contract address of source currency
    /// @param toToken Type of target currency, such as'usdt (matic)'
    /// @param destination Receiving address of target currency
    /// @param fromAmount Contract address of source currency
    /// @param minReturnAmount Minimum received quantity of target currency expected by user
    function swap(
        address fromToken,
        string memory toToken,
        string memory destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    ) external nonReentrant {
        require(fromToken != address(0), "FROMTOKEN_CANT_T_BE_0"); // 源币地址不能为0
        require(fromAmount > 0, "FROM_TOKEN_AMOUNT_MUST_BE_MORE_THAN_0");
        uint256 _inputAmount;
        uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(address(this));
        _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
        require(_inputAmount >= fromAmount, "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT");
        emit Swap(fromToken, toToken, msg.sender, destination, fromAmount, minReturnAmount);
    }

    /// @notice Excute transactions. The handling fee is deducted from the transferred currency.
    /// @param toToken  Type of target currency, such as' usdt (matic) '
    /// @param destination Receiving address of target currency
    /// @param minReturnAmount Minimum received quantity of target currency expected by user
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

    function cossSwapETH(bytes calldata data) external payable nonReentrant {
        uint256 _ethAmount = msg.value;
        require(_ethAmount > 0, "ETH_AMOUNT_MUST_BE_MORE_THAN_0");
        (bool success,) = _swap_cross.call{value:_ethAmount}(data);
        require(success, "SWAP_CROSS_FAILED");
    }

    function cossSwap(address fromToken, uint256 amount,bytes calldata data) external  nonReentrant {
        require(amount > 0, "FROM_TOKEN_AMOUNT_MUST_BE_MORE_THAN_0");
        uint256 _fromTokenBalanceOrigin = IERC20(fromToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(fromToken,msg.sender,address(this),amount);
        uint256 _fromTokenBalanceNew = IERC20(fromToken).balanceOf(address(this));
        uint256 _inputAmount = _fromTokenBalanceNew.sub(_fromTokenBalanceOrigin);
        require(_inputAmount >= amount, "NO_FROM_TOKEN_TRANSFER_TO_THIS_CONTRACT");
        TransferHelper.safeApprove(fromToken,_swap_cross,amount);
        (bool success,) = _swap_cross.call(data);
        require(success, "SWAP_CROSS_FAILED");
    }


}