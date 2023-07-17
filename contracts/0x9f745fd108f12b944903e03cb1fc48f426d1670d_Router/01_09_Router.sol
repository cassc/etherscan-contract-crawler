// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IWETH.sol";
import "./libraries/DEXLibrary.sol";

import "./../core/interfaces/IERC20Pair.sol";
import "./../core/interfaces/IPoolFactory.sol";

contract Router is IRouter {
    address public immutable override factory;

    address public immutable override WNative;

    constructor(address _factory, address _WNative) {
        factory = _factory;
        WNative = _WNative;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    receive() external payable {
        assert(msg.sender == WNative);
        // only accept Native via fallback from the WNative contract
    }

    // SWAP

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        uint32[] calldata feePath,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = DEXLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
            ? (uint256(0), amountOut)
            : (amountOut, uint256(0));
            address to = i < path.length - 2
            ? DEXLibrary.pairFor(factory, output, path[i + 2], feePath[i])
            : _to;
            IERC20Pair(DEXLibrary.pairFor(factory, input, output, feePath[i]))
            .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        amounts = DEXLibrary.getAmountsOut(factory, amountIn, path, feePath);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, to);
    }

    function swapExactNativeForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        require(path[0] == WNative, "Router: INVALID_PATH");
        amounts = DEXLibrary.getAmountsOut(factory, msg.value, path, feePath);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WNative).deposit{value : amounts[0]}();
        assert(
            IWETH(WNative).transfer(
                DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
                amounts[0]
            )
        );
        _swap(amounts, path, feePath, to);
    }

    function swapTokensForExactNative(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WNative, "Router: INVALID_PATH");
        amounts = DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        safeTransferFrom(
            path[0],
            msg.sender,
            DEXLibrary.pairFor(factory, path[0], path[1], feePath[0]),
            amounts[0]
        );
        _swap(amounts, path, feePath, address(this));
        IWETH(WNative).withdraw(amounts[amounts.length - 1]);
        safeTransferNative(to, amounts[amounts.length - 1]);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IPoolFactory(factory).getPair(tokenA, tokenB, fee) == address(0)) {
            IPoolFactory(factory).createPair(tokenA, tokenB, fee);
        }
        (uint256 reserveA, uint256 reserveB) = DEXLibrary.getReserves(
            factory,
            tokenA,
            tokenB,
            fee
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = this.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "Router: INSUFFICIENT B AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = this.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "Router: INSUFFICIENT A AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    virtual
    override
    ensure(deadline)
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            fee,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        {
            address _tokenA = tokenA;
            address _tokenB = tokenB;
            uint32 _fee = fee;
            address pair = DEXLibrary.pairFor(factory, _tokenA, _tokenB, _fee);
            safeTransferFrom(_tokenA, msg.sender, pair, amountA);
            safeTransferFrom(_tokenB, msg.sender, pair, amountB);
            liquidity = IERC20Pair(pair).mint(to);
        }
    }

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    )
    external
    payable
    virtual
    override
    ensure(deadline)
    returns (
        uint256 amountToken,
        uint256 amountNative,
        uint256 liquidity
    )
    {
        (amountToken, amountNative) = _addLiquidity(
            token,
            WNative,
            fee,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountNativeMin
        );
        address pair = DEXLibrary.pairFor(factory, token, WNative, fee);
        safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WNative).deposit{value : amountNative}();
        assert(IWETH(WNative).transfer(pair, amountNative));
        liquidity = IERC20Pair(pair).mint(to);
        // refund dust Native, if any
        if (msg.value > amountNative)
            safeTransferNative(msg.sender, msg.value - amountNative);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (uint256 amountA, uint256 amountB)
    {
        address pair = DEXLibrary.pairFor(factory, tokenA, tokenB, fee);
        IERC20Pair(pair).transferFrom(msg.sender, pair, liquidity);
        // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IERC20Pair(pair).burn(to);
        (address token0,) = DEXLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
        ? (amount0, amount1)
        : (amount1, amount0);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountNativeMin,
        address to,
        uint256 deadline
    )
    public
    virtual
    override
    ensure(deadline)
    returns (uint256 amountToken, uint256 amountNative)
    {
        (amountToken, amountNative) = removeLiquidity(
            token,
            WNative,
            fee,
            liquidity,
            amountTokenMin,
            amountNativeMin,
            address(this),
            deadline
        );
        safeTransfer(token, to, amountToken);
        IWETH(WNative).withdraw(amountNative);
        safeTransferNative(to, amountNative);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure virtual override returns (uint256 amountB) {
        return DEXLibrary.quote(amountA, reserveA, reserveB);
    }

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view virtual override returns (uint256 amountB) {
        amountB = 0;
        address poolAddress = IPoolFactory(factory).getPair(
            tokenA,
            tokenB,
            fee
        );
        if (poolAddress != address(0)) {
            (uint256 reserveA, uint256 reserveB) = DEXLibrary.getReserves(
                factory,
                tokenA,
                tokenB,
                fee
            );
            amountB = DEXLibrary.quote(amountA, reserveA, reserveB);
        }
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure virtual override returns (uint256 amountOut) {
        return DEXLibrary.getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure virtual override returns (uint256 amountIn) {
        return DEXLibrary.getAmountIn(amountOut, reserveIn, reserveOut, fee);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        uint32[] calldata feePath
    ) external view virtual override returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsOut(factory, amountIn, path, feePath);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path,
        uint32[] calldata feePath
    ) external view virtual override returns (uint256[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        for (uint256 i; i < path.length - 1; i++) {
            address poolAddress = IPoolFactory(factory).getPair(
                path[i],
                path[i + 1],
                feePath[i]
            );
            if (poolAddress == address(0)) {
                amounts = new uint256[](2);
                amounts[0] = 0;
                amounts[1] = 0;
                return amounts;
            }
        }
        return DEXLibrary.getAmountsIn(factory, amountOut, path, feePath);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Router::transferFrom: transferFrom failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Router::safeTransfer: transfer failed"
        );
    }

    function safeTransferNative(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "Router::safeTransferNative: Native transfer failed");
    }

    function pairAddress(
        address tokenA,
        address tokenB,
        uint32 poolFee
    ) external view returns (address) {
        return IPoolFactory(factory).getPair(tokenA, tokenB, poolFee);
    }
}