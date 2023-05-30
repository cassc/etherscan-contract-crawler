// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../../swap/interfaces/IPool.sol";
import "../../assets/interfaces/IWETH.sol";
import "../interfaces/IUniswapV3SwapRouter.sol";
import "../../crossChain/interfaces/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract O3EthereumUniswapV3Aggregator is Ownable {
    using SafeERC20 for IERC20;

    event LOG_AGG_SWAP (
        uint256 amountOut,
        uint256 fee
    );

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public O3Wrapper = 0xeCF2B548e5c21028B0b60363207700fA421B6EcB;
    address public feeCollector;

    constructor (address _feeCollector) {
        require(_feeCollector != address(0), 'feeCollector address cannot be zero');
        feeCollector = _feeCollector;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'O3Aggregator: EXPIRED');
        _;
    }

    receive() external payable { }

    function setWETH(address _weth) external onlyOwner {
        require(_weth != address(0), 'WETH address cannot be zero');
        WETH = _weth;
    }

    function setRouter(address _router) external onlyOwner {
        require(_router != address(0), 'router address cannot be zero');
        router = _router;
    }

    function setO3Wrapper(address _wrapper) external onlyOwner {
        require(_wrapper != address(0), 'wrapper address cannot be zero');
        O3Wrapper = _wrapper;
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), 'feeCollector address cannot be zero');
        feeCollector = _feeCollector;
    }

    function rescueFund(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (tokenAddress == WETH && address(this).balance > 0) {
            (bool success,) = _msgSender().call{value: address(this).balance}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        }
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }

    function exactInputSinglePToken(
        uint256 amountIn,
        address poolAddress,
        uint poolAmountOutMin,
        address[] calldata path,
        uint24 v3PoolFee,
        address to,
        uint deadline,
        uint aggSwapAmountOutMin,
        bool unwrapETH
    ) external ensure(deadline) {
        if (amountIn == 0) {
            amountIn = IERC20(path[0]).allowance(_msgSender(), address(this));
        }

        require(amountIn != 0, 'O3Aggregator: ZERO_AMOUNT_IN');
        IERC20(path[0]).safeTransferFrom(_msgSender(), address(this), amountIn);

        {
            IERC20(path[0]).safeApprove(poolAddress, amountIn);
            require(address(IPool(poolAddress).coins(0)) == path[1], "O3Aggregator: INVALID_PATH");

            uint balanceBefore = IERC20(path[1]).balanceOf(address(this));
            IPool(poolAddress).swap(1, 0, amountIn, poolAmountOutMin, deadline);
            amountIn = IERC20(path[1]).balanceOf(address(this)) - balanceBefore;
        }

        require(path.length >= 3, 'O3Aggregator: INVALID_PATH');
        IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams(
            path[1], path[path.length-1], v3PoolFee, address(this), amountIn, aggSwapAmountOutMin, 0
        );

        (uint amountOut, uint feeAmount, ) = _swap(params);

        if (unwrapETH) {
            require(params.tokenOut == WETH, 'O3Aggregator: INVALID_TOKEN_OUT');
            IWETH(WETH).withdraw(amountOut);
            _sendETH(to, amountOut - feeAmount);
            _sendETH(feeCollector, feeAmount);
        } else {
            IERC20(params.tokenOut).safeTransfer(to, amountOut - feeAmount);
            IERC20(params.tokenOut).safeTransfer(feeCollector, feeAmount);
        }
    }

    function exactInputSingle(
        IUniswapV3SwapRouter.ExactInputSingleParams memory params,
        bool unwrapETH,
        uint deadline
    ) external payable ensure(deadline) {
        _pull(params.tokenIn, params.amountIn, 0);
        (uint amountOut, uint feeAmount, address receiver) = _swap(params);

        if (unwrapETH) {
            require(params.tokenOut == WETH, 'O3Aggregator: INVALID_TOKEN_OUT');
            IWETH(WETH).withdraw(amountOut);
            _sendETH(receiver, amountOut - feeAmount);
            _sendETH(feeCollector, feeAmount);
        } else {
            IERC20(params.tokenOut).safeTransfer(receiver, amountOut - feeAmount);
            IERC20(params.tokenOut).safeTransfer(feeCollector, feeAmount);
        }
    }

    function _pull(address token, uint amountIn, uint netFee) internal {
        if (msg.value - netFee > 0) {
            require(token == WETH, 'O3Aggregator: INVALID_TOKEN_IN');
            IWETH(WETH).deposit{value: msg.value - netFee}();
        } else {
            require(amountIn > 0, 'O3Aggregator: INSUFFICIENT_INPUT_AMOUNT');
            IERC20(token).safeTransferFrom(msg.sender, address(this), amountIn);
        }
    }

    function _swap(IUniswapV3SwapRouter.ExactInputSingleParams memory params) internal returns (uint, uint, address) {
        require(params.recipient != address(0), 'O3Aggregator: INVALID_RECIPIENT');
        address receiver = params.recipient;
        params.recipient = address(this);

        IERC20(params.tokenIn).safeApprove(router, params.amountIn);
        uint balanceBefore = IERC20(params.tokenOut).balanceOf(address(this));
        IUniswapV3SwapRouter(router).exactInputSingle(params);
        uint amountOut = IERC20(params.tokenOut).balanceOf(address(this)) - balanceBefore;
        uint feeAmount = amountOut * params.fee / 1000000;
        emit LOG_AGG_SWAP(amountOut, feeAmount);

        return (amountOut, feeAmount, receiver);
    }

    function exactInputSingleCrossChain(
        IUniswapV3SwapRouter.ExactInputSingleParams memory params,
        address poolAddress, address tokenTo, uint256 minDy, uint256 deadline, // args for swap
        uint fee, uint64 toChainId, bytes memory callData                      // args for wrapper
    ) external payable ensure(deadline) {
        _pull(params.tokenIn, params.amountIn, fee);
        uint swapperAmountIn;
        address receiver;
        {
            uint amountOut;
            uint feeAmount;
            (amountOut, feeAmount, receiver) = _swap(params);
            IERC20(params.tokenOut).safeTransfer(feeCollector, feeAmount);
            swapperAmountIn = amountOut - feeAmount;
        }

        IERC20(params.tokenOut).safeApprove(O3Wrapper, swapperAmountIn);

        IWrapper(O3Wrapper).swapAndBridgeOut{value: fee}(
            poolAddress, params.tokenOut, tokenTo, swapperAmountIn, minDy, deadline,
            toChainId, abi.encodePacked(receiver), callData
        );
    }

    function _sendETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value:amount}(new bytes(0));
        require(success, 'O3Aggregator: ETH_TRANSFER_FAILED');
    }
}