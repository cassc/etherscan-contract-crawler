// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "../dependencies/@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IQuoter} from "../dependencies/@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {Path} from "../dependencies/@uniswap/v3-periphery/contracts/libraries/Path.sol";
import {IExchangeWithExactOutput} from "../interfaces/IExchangeWithExactOutput.sol";
import {Adapter} from "./Adapter.sol";

contract UniswapV3Adapter is IExchangeWithExactOutput, Adapter {
    using SafeERC20 for IERC20;
    using Path for bytes;

    IQuoter internal constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    ISwapRouter public immutable router;

    address public immutable wethLike;

    constructor(address router_, address wethLike_) {
        router = ISwapRouter(router_);
        wethLike = wethLike_;
    }

    /// @inheritdoc IExchangeWithExactOutput
    function getAmountIn(uint256 amountOut_, bytes memory path_) external override returns (uint256 _amountIn) {
        try QUOTER.quoteExactOutput(path_, amountOut_) returns (uint256 __amountIn) {
            _amountIn = __amountIn;
        } catch {}
    }

    function swapExactInput(bytes calldata path_) external {
        (address _tokenInAddress,,) = path_.decodeFirstPool();
        IERC20 _tokenIn = IERC20(_tokenInAddress);
        uint256 _amountIn = _tokenIn.balanceOf(address(this));
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path_,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 0
        });

        _approveIfNeeded(IERC20(_tokenIn), address(router), _amountIn);
        router.exactInput(params);
    }

    /**
     * @inheritdoc IExchangeWithExactOutput
     * @dev UniswapV3 uses reversed path for `exactOutput`
     * For example: The correct path for exactOutput(USDC, DAI) is [DAI, fee, USDC]
     * See more: https://docs.uniswap.org/contracts/v3/guides/swaps/multihop-swaps#exact-output-multihop-swap
     */
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address remainingReceiver_,
        address outReceiver_
    ) external override returns (uint256 _amountIn) {
        address _tokenInAddress;
        if (path_.numPools() == 1) {
            (, _tokenInAddress,) = path_.decodeFirstPool();
        } else if (path_.numPools() == 2) {
            (, _tokenInAddress,) = path_.skipToken().decodeFirstPool();
        } else {
            revert("invalid-path-length");
        }

        IERC20 _tokenIn = IERC20(_tokenInAddress);

        _approveIfNeeded(IERC20(_tokenIn), address(router), amountInMax_);

        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: path_,
            recipient: outReceiver_,
            deadline: block.timestamp,
            amountOut: amountOut_,
            amountInMaximum: amountInMax_
        });

        _amountIn = router.exactOutput(params);

        // If swap end up costly less than _amountInMax then return remaining to caller
        uint256 _remainingAmountIn = amountInMax_ - _amountIn;
        if (_remainingAmountIn > 0) {
            _tokenIn.safeTransfer(remainingReceiver_, _remainingAmountIn);
        }
    }
}