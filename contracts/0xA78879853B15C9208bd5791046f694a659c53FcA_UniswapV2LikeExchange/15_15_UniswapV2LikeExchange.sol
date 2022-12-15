// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/uniswap/libraries/UniswapV2Library.sol";
import "../access/Governable.sol";
import "../interfaces/swapper/IExchange.sol";

/**
 * @notice UniswapV2 Like Exchange
 */
contract UniswapV2LikeExchange is IExchange, Governable {
    using SafeERC20 for IERC20;

    /**
     * @notice The WETH-Like token (a.k.a. Native Token)
     * @dev I.e. should be the most liquid token that offer best routers among trade pairs
     * @dev It's usually the wrapper token of the chain's native coin but it isn't always true
     * For instance: On Polygon, the `WETH` is more liquid than `WMATIC` on UniV3 protocol.
     */
    address public wethLike;

    /**
     * @notice The UniswapV2-Like factory contract
     */
    address public immutable factory;

    bytes32 internal immutable initCodeHash;
    /// @notice Emitted when wethLike token is updated
    event WethLikeTokenUpdated(address oldWethLike, address newWethLike);

    /**
     * @dev Doesn't consider router.WETH() as `wethLike` because isn't guaranteed that it's the most liquid token.
     */
    constructor(
        address factory_,
        bytes32 initCodeHash_,
        address wethLike_
    ) {
        factory = factory_;
        initCodeHash = initCodeHash_;
        wethLike = wethLike_;
    }

    /// @inheritdoc IExchange
    function getAmountsIn(uint256 amountOut_, bytes memory path_) external view override returns (uint256 _amountIn) {
        _amountIn = getAmountsIn(amountOut_, _decodePath(path_));
    }

    /// @inheritdoc IExchange
    function getAmountsOut(uint256 amountIn_, bytes memory path_) external view override returns (uint256 _amountOut) {
        _amountOut = getAmountsOut(amountIn_, _decodePath(path_));
    }

    /**
     * @dev getBestAmountIn require a try/catch version of getAmountsIn and try/catch do not work with internal
     * library functions, hence wrapped library call in this function so that it can be used in try/catch
     */
    function getAmountsIn(uint256 amountOut_, address[] memory path_) public view returns (uint256 _amountIn) {
        _amountIn = UniswapV2Library.getAmountsIn(factory, initCodeHash, amountOut_, path_)[0];
    }

    /**
     * @dev getBestAmountOut require a try/catch version of getAmountsOut and try/catch do not work with internal
     * library functions, hence wrapped library call in this function so that it can be used in try/catch
     */
    function getAmountsOut(uint256 amountIn_, address[] memory path_) public view returns (uint256 _amountOut) {
        _amountOut = UniswapV2Library.getAmountsOut(factory, initCodeHash, amountIn_, path_)[path_.length - 1];
    }

    /// @inheritdoc IExchange
    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external returns (uint256 _amountIn, bytes memory _path) {
        // 1. Check IN-OUT pair
        address[] memory _pathA = new address[](2);
        _pathA[0] = tokenIn_;
        _pathA[1] = tokenOut_;
        uint256 _amountInA = _getAmountsIn(amountOut_, _pathA);

        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            // Returns if one of the token is WETH-Like
            require(_amountInA > 0, "no-path-found");
            return (_amountInA, _encodePath(_pathA));
        }

        // 2. Check IN-WETH-OUT path
        address[] memory _pathB = new address[](3);
        _pathB[0] = tokenIn_;
        _pathB[1] = wethLike;
        _pathB[2] = tokenOut_;
        uint256 _amountInB = _getAmountsIn(amountOut_, _pathB);

        // 3. Get best route between paths A and B
        require(_amountInA > 0 || _amountInB > 0, "no-path-found");

        // Returns A if it's valid and better than B or if B isn't valid
        if ((_amountInA > 0 && _amountInA < _amountInB) || _amountInB == 0) {
            return (_amountInA, _encodePath(_pathA));
        }
        return (_amountInB, _encodePath(_pathB));
    }

    /// @inheritdoc IExchange
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, bytes memory _path) {
        // 1. Check IN-OUT pair
        address[] memory _pathA = new address[](2);
        _pathA[0] = tokenIn_;
        _pathA[1] = tokenOut_;
        uint256 _amountOutA = _getAmountsOut(amountIn_, _pathA);

        if (tokenIn_ == wethLike || tokenOut_ == wethLike) {
            // Returns if one of the token is WETH-Like
            require(_amountOutA > 0, "no-path-found");
            return (_amountOutA, _encodePath(_pathA));
        }

        // 2. Check IN-WETH-OUT path
        address[] memory _pathB = new address[](3);
        _pathB[0] = tokenIn_;
        _pathB[1] = wethLike;
        _pathB[2] = tokenOut_;
        uint256 _amountOutB = _getAmountsOut(amountIn_, _pathB);

        // 3. Get best route between paths A and B
        require(_amountOutA > 0 || _amountOutB > 0, "no-path-found");
        if (_amountOutA > _amountOutB) return (_amountOutA, _encodePath(_pathA));
        return (_amountOutB, _encodePath(_pathB));
    }

    /// @inheritdoc IExchange
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external returns (uint256 _amountOut) {
        address[] memory _path = _decodePath(path_);
        IERC20 _tokenIn = IERC20(_path[0]);
        IERC20 _tokenOut = IERC20(_path[_path.length - 1]);

        _tokenIn.safeTransfer(UniswapV2Library.pairFor(factory, initCodeHash, _path[0], _path[1]), amountIn_);
        uint256 balanceBefore = _tokenOut.balanceOf(outReceiver_);
        _swap(_path, outReceiver_);
        _amountOut = _tokenOut.balanceOf(outReceiver_) - balanceBefore;
        require(_amountOut >= amountOutMin_, "Too little received");
    }

    /// @inheritdoc IExchange
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address inSender_,
        address outRecipient_
    ) external returns (uint256 _amountIn) {
        address[] memory _path = _decodePath(path_);
        IERC20 _tokenIn = IERC20(_path[0]);

        _amountIn = UniswapV2Library.getAmountsIn(factory, initCodeHash, amountOut_, _path)[0];
        require(_amountIn <= amountInMax_, "Too much requested");

        _tokenIn.safeTransfer(UniswapV2Library.pairFor(factory, initCodeHash, _path[0], _path[1]), _amountIn);
        _swap(_path, outRecipient_);

        // If swap end up costly less than _amountInMax then return remaining
        uint256 _remainingAmountIn = amountInMax_ - _amountIn;
        if (_remainingAmountIn > 0) {
            _tokenIn.safeTransfer(inSender_, _remainingAmountIn);
        }
    }

    /// @dev Returns `0` if reverts
    function _getAmountsIn(uint256 _amountOut, address[] memory _path) internal view returns (uint256 _amountIn) {
        try this.getAmountsIn(_amountOut, _path) returns (uint256 amountIn) {
            _amountIn = amountIn;
        } catch {}
    }

    /// @dev Returns `0` if reverts
    function _getAmountsOut(uint256 amountIn_, address[] memory path_) internal view returns (uint256 _amountOut) {
        try this.getAmountsOut(amountIn_, path_) returns (uint256 amountOut) {
            _amountOut = amountOut;
        } catch {}
    }

    /**
     * @notice Encode path from `address[]` to `bytes`
     */
    function _encodePath(address[] memory path_) private pure returns (bytes memory _path) {
        return abi.encode(path_);
    }

    /**
     * @notice Encode path from `bytes` to `address[]`
     */
    function _decodePath(bytes memory path_) private pure returns (address[] memory _path) {
        return abi.decode(path_, (address[]));
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
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, initCodeHash, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            // scope to avoid stack too deep errors
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, initCodeHash, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @notice Update WETH-Like token
     */
    function updateWethLikeToken(address wethLike_) external onlyGovernor {
        emit WethLikeTokenUpdated(wethLike, wethLike_);
        wethLike = wethLike_;
    }
}