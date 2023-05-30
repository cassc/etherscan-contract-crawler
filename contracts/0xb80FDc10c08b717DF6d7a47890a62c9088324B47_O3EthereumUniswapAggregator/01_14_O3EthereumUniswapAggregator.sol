// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../../swap/interfaces/IPool.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../../assets/interfaces/IWETH.sol";
import "./libs/EthereumUniswapV2Library.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../../crossChain/interfaces/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract O3EthereumUniswapAggregator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LOG_AGG_SWAP (
        uint256 amountOut,
        uint256 fee
    );

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public O3Wrapper = 0xeCF2B548e5c21028B0b60363207700fA421B6EcB;
    address public feeCollector;

    uint256 public aggregatorFee = 3 * 10 ** 7;
    uint256 public constant FEE_DENOMINATOR = 10 ** 10;
    uint256 private constant MAX_AGGREGATOR_FEE = 5 * 10**8;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'O3Aggregator: EXPIRED');
        _;
    }

    constructor (address _feeCollector) {
        feeCollector = _feeCollector;
    }

    receive() external payable { }

    function setWETH(address _weth) external onlyOwner {
        WETH = _weth;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    function setO3Wrapper(address _wrapper) external onlyOwner {
        O3Wrapper = _wrapper;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function setAggregatorFee(uint _fee) external onlyOwner {
        require(_fee < MAX_AGGREGATOR_FEE, "aggregator fee exceeds maximum");
        aggregatorFee = _fee;
    }

    function rescueFund(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (tokenAddress == WETH && address(this).balance > 0) {
            (bool success,) = _msgSender().call{value: address(this).balance}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        }
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function swapExactPTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        address poolAddress,
        uint poolAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint aggSwapAmountOutMin,
        bool unwrapETH
    ) external virtual ensure(deadline) {
        if (amountIn == 0) {
            amountIn = IERC20(path[0]).allowance(_msgSender(), address(this));
        }

        require(amountIn != 0, 'O3Aggregator: ZERO_AMOUNT_IN');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        {
            IERC20(path[0]).safeApprove(poolAddress, amountIn);
            address underlyingToken = address(IPool(poolAddress).coins(0));

            uint256 balanceBefore = IERC20(underlyingToken).balanceOf(address(this));
            IPool(poolAddress).swap(1, 0, amountIn, poolAmountOutMin, deadline);
            amountIn = IERC20(underlyingToken).balanceOf(address(this)) - balanceBefore;

            require(address(underlyingToken) == path[1], "O3Aggregator: INVALID_PATH");
        }

        uint amountOut = _swapExactTokensForTokensSupportingFeeOnTransferTokens(false, amountIn, aggSwapAmountOutMin, path[1:]);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        if (unwrapETH) {
            require(path[path.length - 1] == WETH, "O3Aggregator: INVALID_PATH");
            IWETH(WETH).withdraw(amountOut);
            _sendETH(feeCollector, feeAmount);
            _sendETH(to, amountOut.sub(feeAmount));
        } else {
            IERC20(path[path.length-1]).safeTransfer(feeCollector, feeAmount);
            IERC20(path[path.length-1]).safeTransfer(to, amountOut.sub(feeAmount));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        uint amountOut = _swapExactTokensForTokensSupportingFeeOnTransferTokens(true, amountIn, swapAmountOutMin, path);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IERC20(path[path.length-1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[path.length-1]).safeTransfer(to, amountOut.sub(feeAmount));
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensCrossChain(
        uint amountIn, uint swapAmountOutMin, address[] calldata path,         // args for dex
        address poolAddress, address tokenTo, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData        // args for wrapper
    ) external virtual payable ensure(deadline) returns (bool) {
        (uint swapperAmountIn, address tokenFrom) = _swapExactTokensForTokensSupportingFeeOnTransferTokensCrossChain(amountIn, swapAmountOutMin, path);

        IERC20(tokenFrom).safeApprove(O3Wrapper, swapperAmountIn);

        return IWrapper(O3Wrapper).swapAndBridgeOut{value: msg.value}(
            poolAddress, tokenFrom, tokenTo, swapperAmountIn, minDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function _swapExactTokensForTokensSupportingFeeOnTransferTokensCrossChain(
        uint amountIn, uint swapAmountOutMin, address[] calldata path
    ) internal returns (uint256, address) {
        uint amountOut = _swapExactTokensForTokensSupportingFeeOnTransferTokens(true, amountIn, swapAmountOutMin, path);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        IERC20(path[path.length-1]).safeTransfer(feeCollector, feeAmount);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        return (amountOut.sub(feeAmount), path[path.length-1]);
    }

    function _swapExactTokensForTokensSupportingFeeOnTransferTokens(
        bool pull,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) internal virtual returns (uint) {
        if (pull) {
            IERC20(path[0]).safeTransferFrom(
                msg.sender, EthereumUniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
            );
        } else {
            IERC20(path[0]).safeTransfer(EthereumUniswapV2Library.pairFor(factory, path[0], path[1]), amountIn);
        }

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= amountOutMin, 'O3Aggregator: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) {
        uint amountOut = _swapExactETHForTokensSupportingFeeOnTransferTokens(swapAmountOutMin, path, 0);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IERC20(path[path.length-1]).safeTransfer(feeCollector, feeAmount);
        IERC20(path[path.length - 1]).safeTransfer(to, amountOut.sub(feeAmount));
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokensCrossChain(
        uint swapAmountOutMin, address[] calldata path, uint fee,              // args for dex
        address poolAddress, address tokenTo, uint256 minDy, uint256 deadline, // args for swap
        uint64 toChainId, bytes memory toAddress, bytes memory callData        // args for wrapper
    ) external virtual payable ensure(deadline) returns (bool) {
        (uint swapperAmountIn, address tokenFrom) = _swapExactETHForTokensSupportingFeeOnTransferTokensCrossChain(swapAmountOutMin, path, fee);

        IERC20(tokenFrom).safeApprove(O3Wrapper, swapperAmountIn);

        return IWrapper(O3Wrapper).swapAndBridgeOut{value: fee}(
            poolAddress, tokenFrom, tokenTo, swapperAmountIn, minDy, deadline,
            toChainId, toAddress, callData
        );
    }

    function _swapExactETHForTokensSupportingFeeOnTransferTokensCrossChain(
        uint swapAmountOutMin, address[] calldata path, uint fee
    ) internal returns (uint, address) {
        uint amountOut = _swapExactETHForTokensSupportingFeeOnTransferTokens(swapAmountOutMin, path, fee);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        IERC20(path[path.length-1]).safeTransfer(feeCollector, feeAmount);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        return (amountOut.sub(feeAmount), path[path.length-1]);
    }

    function _swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint swapAmountOutMin,
        address[] calldata path,
        uint fee
    ) internal virtual returns (uint) {
        require(path[0] == WETH, 'O3Aggregator: INVALID_PATH');
        uint amountIn = msg.value.sub(fee);
        require(amountIn > 0, 'O3Aggregator: INSUFFICIENT_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(EthereumUniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(path[path.length - 1]).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= swapAmountOutMin, 'O3Aggregator: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) {
        uint amountOut = _swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, swapAmountOutMin, path);
        uint feeAmount = amountOut.mul(aggregatorFee).div(FEE_DENOMINATOR);
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        IWETH(WETH).withdraw(amountOut);

        _sendETH(feeCollector, feeAmount);
        _sendETH(to, amountOut.sub(feeAmount));
    }

    function _swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint swapAmountOutMin,
        address[] calldata path
    ) internal virtual returns (uint) {
        require(path[path.length - 1] == WETH, 'O3Aggregator: INVALID_PATH');
        IERC20(path[0]).safeTransferFrom(
            msg.sender, EthereumUniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(WETH).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this)).sub(balanceBefore);
        require(amountOut >= swapAmountOutMin, 'O3Aggregator: INSUFFICIENT_OUTPUT_AMOUNT');
        return amountOut;
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value:amount}(new bytes(0));
        require(success, 'O3Aggregator: ETH_TRANSFER_FAILED');
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = EthereumUniswapV2Library.sortTokens(input, output);
            require(IUniswapV2Factory(factory).getPair(input, output) != address(0), "O3Aggregator: PAIR_NOT_EXIST");
            IUniswapV2Pair pair = IUniswapV2Pair(EthereumUniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = EthereumUniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? EthereumUniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}