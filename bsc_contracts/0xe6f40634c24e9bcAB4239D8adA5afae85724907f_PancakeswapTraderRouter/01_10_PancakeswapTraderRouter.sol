// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./interfaces/IPancakeRouter02.sol";
import "../../utils/PaybleMulticall.sol";

contract PancakeswapTraderRouter is Ownable, Multicall, PaybleMulticall, IPancakeRouter02WithoutLpTokens {
    using SafeERC20 for IERC20;
    IPancakeRouter02WithoutLpTokens public constant pancakeswapRouter =
        IPancakeRouter02WithoutLpTokens(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 public constant FEE_DIVISOR = 100000; // Constant divisor for calculating fees
    uint256 public limitGasPrice;
    uint256 public feePercent; // Fee percentage as an integer, e.g. 1% = 1000

    event FeePercentSet(uint256 newFeePercent);
    event SetGasPriceLimit(uint256 newGasPriceLimit);

    /**
     * @dev Sets feePercent and  limitGasPrice for this contract.
     * @param _feePercent The fee percentage as an integer, e.g. 1% = 1000.
     * @param _limitGasPrice Limit of gas price, if gas price > limit then we don't take fee
     */
    constructor(uint256 _feePercent, uint256 _limitGasPrice) {
        require(_feePercent <= FEE_DIVISOR, "Fee percentage must be less than or equal to 100");
        feePercent = _feePercent;
        limitGasPrice = _limitGasPrice;
    }

    /**
     * @dev Sets the fee percentage for this contract.
     * @param percent The fee percentage as an integer, e.g. 1% = 1000.
     */
    function setFeePercent(uint256 percent) external onlyOwner {
        require(percent <= FEE_DIVISOR, "Fee percentage must be less than or equal to 100");
        feePercent = percent;
        emit FeePercentSet(feePercent);
    }

    /**
     * @dev Sets the gas limit for this contract.
     * @param _limitGasPrice Limit of gas price, if gas price > limit then we don't take fee
     */
    function setGasPriceLimit(uint256 _limitGasPrice) external onlyOwner {
        limitGasPrice = _limitGasPrice;
        emit SetGasPriceLimit(_limitGasPrice);
    }

    /**
     * @dev Send all amount of token to recipient
     * @param token Address of token that will be transfered to recipient
     * @param recipient Address of account, that get token
     */
    function transferToken(address token, address recipient) external onlyOwner {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @dev Send all amount of ether to recipient
     * @param recipient Address of account, that get token
     */
    function transferEther(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}

    /**
     * @notice Approve token for PancakeswapRouter
     * @param token  Address of Token that is approved
     */
    function approveTokenForPancakeswapRouter(address token) external {
        (IERC20(token).approve(address(pancakeswapRouter), type(uint256).max));
    }

    /**
     * @dev Calculates the amount after subtracting a fee from a token amount.
     * The fee is calculated based on the current fee percentage.
     * @param tokenAmount The amount of tokens to subtract the fee from.
     * @return The amount of tokens remaining after the fee has been subtracted.
     */
    function calculateAmountMinusFee(uint256 tokenAmount) public view returns (uint256) {
        uint256 fee = (tokenAmount * feePercent) / FEE_DIVISOR; // calculate the fee as a percentage of the token amount
        uint256 amountMinusFee = tokenAmount - fee;
        return amountMinusFee;
    }

    /**
     * @dev Calculates fee.
     * @param tokenAmount The amount of tokens to calculate the fee from.
     * @return The fee is calculated based on the current fee percentage.
     */
    function calculateFee(uint256 tokenAmount) public override view returns (uint256) {
        return (tokenAmount * feePercent) / FEE_DIVISOR; // calculate the fee as a percentage of the token amount
    }

    /**
     * @notice Receive an as many output tokens as possible for an exact amount of input tokens.
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        return
            pancakeswapRouter.swapExactTokensForTokens(
                limitGasPrice < tx.gasprice ? amountIn : calculateAmountMinusFee(amountIn),
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param amountOut Payable amount of input tokens.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        if (limitGasPrice < tx.gasprice) {
            amounts = pancakeswapRouter.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
            IERC20(path[0]).transfer(msg.sender, amountInMax - amounts[0]);
        } else {
            amountInMax = calculateAmountMinusFee(amountInMax);
            amounts = pancakeswapRouter.swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
            IERC20(path[0]).transfer(msg.sender, amountInMax - amounts[0]);
        }
    }

    /**
     * @notice Receive as many output tokens as possible for an exact amount of BNB.
     * @param amountOutMin 	The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        return
            pancakeswapRouter.swapExactETHForTokens{
                value: limitGasPrice < tx.gasprice ? msg.value : calculateAmountMinusFee(msg.value)
            }(amountOutMin, path, to, deadline);
    }

    /**
     * @notice Receive an exact amount of output tokens for as few input tokens as possible.
     * @param amountOut Payable BNB amount.
     * @param amountInMax The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountInMax);
        if (limitGasPrice < tx.gasprice) {
            amounts = pancakeswapRouter.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
        } else {
            amountInMax = calculateAmountMinusFee(amountInMax);
            amounts = pancakeswapRouter.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
            IERC20(path[0]).transfer(msg.sender, amountInMax - amounts[0]);
        }
    }

    /**
     * @notice Receive as much BNB as possible for an exact amount of input tokens.
     * @param amountIn Payable amount of input tokens.
     * @param amountOutMin The maximum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external override returns (uint256[] memory amounts) {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        return
            pancakeswapRouter.swapExactTokensForETH(
                limitGasPrice < tx.gasprice ? amountIn : calculateAmountMinusFee(amountIn),
                amountOutMin,
                path,
                to,
                deadline
            );
    }

    /**
     * @notice Receive an exact amount of output tokens for as little BNB as possible.
     * @param amountOut The amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        if (limitGasPrice < tx.gasprice) {
            amounts = pancakeswapRouter.swapETHForExactTokens{value: msg.value}(amountOut, path, to, deadline);
            payable(msg.sender).transfer(msg.value - amounts[0]);
        } else {
            uint256 msgValueMinusFee = calculateAmountMinusFee(msg.value);
            amounts = pancakeswapRouter.swapETHForExactTokens{value: msgValueMinusFee}(amountOut, path, to, deadline);
            payable(msg.sender).transfer(msgValueMinusFee - amounts[0]);
        }
    }

    /**
     * @notice Receive as many output tokens as possible for an exact amount of input tokens. Supports tokens that take a fee on transfer.
     * @param amountIn TPayable amount of input tokens.
     * @param amountOutMin The minimum amount tokens to receive.
     * @param path (address[]) An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        pancakeswapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            limitGasPrice < tx.gasprice ? amountIn : calculateAmountMinusFee(amountIn),
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    /**
     * @notice Receive as many output tokens as possible for an exact amount of BNB. Supports tokens that take a fee on transfer.
     * @param amountOutMin 	The minimum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        return
            pancakeswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: limitGasPrice < tx.gasprice ? msg.value : calculateAmountMinusFee(msg.value)
            }(amountOutMin, path, to, deadline);
    }

    /**
     * @notice Receive as much BNB as possible for an exact amount of input tokens.
     * @param amountIn Payable amount of input tokens.
     * @param amountOutMin The maximum amount tokens to input.
     * @param path (address[]) An array of token addresses. path.length must be >= 2.
     * Pools for each consecutive pair of addresses must exist and have liquidity.
     * @param deadline Unix timestamp deadline by which the transaction must confirm.
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        return
            pancakeswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                limitGasPrice < tx.gasprice ? amountIn : calculateAmountMinusFee(amountIn),
                amountOutMin,
                path,
                to,
                deadline
            );
    }
}