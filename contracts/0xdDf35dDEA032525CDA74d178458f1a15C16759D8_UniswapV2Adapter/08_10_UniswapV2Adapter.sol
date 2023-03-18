// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UniswapV2Library, IUniswapV2Pair} from "../libraries/UniswapV2Library.sol";
import {IExchangeWithExactOutput} from "../interfaces/IExchangeWithExactOutput.sol";

contract UniswapV2Adapter is IExchangeWithExactOutput {
    using SafeERC20 for IERC20;

    address public immutable wethLike;
    address public immutable factory;
    bytes32 internal immutable initCodeHash;

    constructor(address factory_, bytes32 initCodeHash_, address wethLike_) {
        factory = factory_;
        initCodeHash = initCodeHash_;
        wethLike = wethLike_;
    }

    /// @inheritdoc IExchangeWithExactOutput
    function getAmountIn(uint256 amountOut_, bytes memory path_) external view override returns (uint256 _amountIn) {
        _amountIn = UniswapV2Library.getAmountsIn(factory, initCodeHash, amountOut_, abi.decode(path_, (address[])))[0];
    }

    function swapExactInput(address[] calldata path_) external {
        IERC20 _tokenIn = IERC20(path_[0]);
        _tokenIn.safeTransfer(
            UniswapV2Library.pairFor(factory, initCodeHash, path_[0], path_[1]), _tokenIn.balanceOf(address(this))
        );
        _swap(path_, address(this));
    }

    /// @inheritdoc IExchangeWithExactOutput
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address remainingReceiver_,
        address outRecipient_
    ) external override returns (uint256 _amountIn) {
        address[] memory _path = abi.decode(path_, (address[]));
        IERC20 _tokenIn = IERC20(_path[0]);

        _amountIn = UniswapV2Library.getAmountsIn(factory, initCodeHash, amountOut_, _path)[0];
        require(_amountIn <= amountInMax_, "Too much requested");

        _tokenIn.safeTransfer(UniswapV2Library.pairFor(factory, initCodeHash, _path[0], _path[1]), _amountIn);
        _swap(_path, outRecipient_);

        // If swap end up costly less than _amountInMax then return remaining
        uint256 _remainingAmountIn = amountInMax_ - _amountIn;
        if (_remainingAmountIn > 0) {
            _tokenIn.safeTransfer(remainingReceiver_, _remainingAmountIn);
        }
    }

    /**
     * NOTICE:: This function is being used as is from Uniswap's V2SwapRouter.sol deployed
     * at 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 and licensed under GPL-2.0-or-later.
     * - It does supports fee-on-transfer tokens
     * - It does requires the initial amount to have already been sent to the first pair
     */
    function _swap(address[] memory path, address _to) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, initCodeHash, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            // scope to avoid stack too deep errors
            {
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to =
                i < path.length - 2 ? UniswapV2Library.pairFor(factory, initCodeHash, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}