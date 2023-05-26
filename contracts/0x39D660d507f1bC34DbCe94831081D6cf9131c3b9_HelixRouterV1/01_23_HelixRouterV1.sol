// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HelixPair.sol";
import "../libraries/HelixLibrary.sol";
import "../interfaces/IHelixV2Router02.sol";
import "../interfaces/ISwapRewards.sol";

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract HelixRouterV1 is IHelixV2Router02, Pausable, Ownable {
    address public immutable _factory;
    address public immutable _WETH;
    address public swapRewards;

    // Emitted when liquidity is added
    event AddLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountAReturned,
        uint256 amountBReturned,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    );

    // Emitted when liquidity is removed
    event RemoveLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        address indexed pair,
        address to,
        uint256 amountARemoved,
        uint256 amountBRemoved
    );

    // Emitted when tokens are swapped
    event Swap(
        uint256[] indexed amounts,
        address[] indexed path,
        address indexed to
    );

    // Emitted when tokens supporting fees are swapped
    event SwapSupportingFeeOnTransferTokens(address[] indexed path, address indexed to);

    modifier onlyValidDeadline(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: invalid deadline");
        _;
    }

    constructor(address factory_, address WETH_) Ownable() {
        _factory = factory_;
        _WETH = WETH_;
    }

    receive() external payable {
        require(msg.sender == _WETH, "Router: caller not weth");
    }

    function factory() external view override returns (address) {
        return _factory;
    }

    function WETH() external view returns (address) {
        return _WETH;
    }

    function setSwapRewards(address _swapRewards) external onlyOwner {
        swapRewards = _swapRewards;
    }

    // **** ADD LIQUIDITY ****

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) 
        internal 
        virtual 
        whenNotPaused
        returns (uint256 amountA, uint256 amountB) 
    {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(_factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(_factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = HelixLibrary.getReserves(_factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = HelixLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                _requireGEQ(amountBOptimal, amountBMin);
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = HelixLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                _requireGEQ(amountAOptimal, amountAMin);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        emit AddLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
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
        onlyValidDeadline(deadline) 
        returns (uint256 amountA, uint256 amountB, uint256 liquidity) 
    {
        (amountA, amountB) = _addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin
        );
        address pair = HelixLibrary.pairFor(_factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = HelixPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) 
        external 
        virtual 
        override 
        payable 
        onlyValidDeadline(deadline) 
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) 
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            _WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = HelixLibrary.pairFor(_factory, token, _WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(_WETH).deposit{value: amountETH}();
        assert(IWETH(_WETH).transfer(pair, amountETH));
        liquidity = HelixPair(pair).mint(to);

        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    // **** REMOVE LIQUIDITY ****

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) 
        public 
        virtual 
        override 
        whenNotPaused
        onlyValidDeadline(deadline) 
        returns (uint256 amountA, uint256 amountB) 
    {
        address pair = HelixLibrary.pairFor(_factory, tokenA, tokenB);
        HelixPair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint256 amount0, uint256 amount1) = HelixPair(pair).burn(to);
        (address token0,) = HelixLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        _requireGEQ(amountA, amountAMin);
        _requireGEQ(amountB, amountBMin);

        emit RemoveLiquidity(
            tokenA,
            tokenB,
            pair,
            to,
            amountA,
            amountB
        );
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) 
        public 
        virtual 
        override 
        onlyValidDeadline(deadline) 
        returns (uint256 amountToken, uint256 amountETH) 
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            _WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(_WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) 
        external 
        virtual 
        override 
        returns (uint256 amountA, uint256 amountB) 
    {
        address pair = HelixLibrary.pairFor(_factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint).max : liquidity;
        HelixPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(
            tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) 
        external 
        virtual 
        override 
        returns (uint256 amountToken, uint256 amountETH) 
    {
        address pair = HelixLibrary.pairFor(_factory, token, _WETH);
        uint256 value = approveMax ? type(uint).max : liquidity;
        HelixPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) 
        public 
        virtual 
        override 
        onlyValidDeadline(deadline) 
        returns (uint256 amountETH) 
    {
        (, amountETH) = removeLiquidity(
            token,
            _WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(_WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        external 
        virtual 
        override 
        returns (uint256 amountETH) 
    {
        address pair = HelixLibrary.pairFor(_factory, token, _WETH);
        uint256 value = approveMax ? type(uint).max : liquidity;
        HelixPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****

    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) 
        internal 
        virtual 
        whenNotPaused
    {
        uint256 length = path.length - 1;
        for (uint256 i; i < length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = HelixLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? 
                (uint(0), amountOut) : 
                (amountOut, uint(0));
    
            address to = i < path.length - 2 ? 
                HelixLibrary.pairFor(_factory, output, path[i + 2]) : 
                _to;

            HelixPair(HelixLibrary.pairFor(_factory, input, output)).swap(
                amount0Out, amount1Out, to
            );

            if (swapRewards != address(0)) {
                ISwapRewards(swapRewards).swap(msg.sender, output, amountOut);
            }
        }

        emit Swap(amounts, path, _to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) 
        external 
        virtual 
        override 
        onlyValidDeadline(deadline) 
        returns (uint256[] memory amounts) 
    {
        amounts = HelixLibrary.getAmountsOut(_factory, amountIn, path);
        _requireGEQ(amounts[amounts.length - 1], amountOutMin);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) 
        external 
        virtual 
        override 
        onlyValidDeadline(deadline) 
        returns (uint256[] memory amounts) 
    {
        amounts = HelixLibrary.getAmountsIn(_factory, amountOut, path);
        _requireLEQ(amounts[0], amountInMax);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    )
        external
        virtual
        override
        payable
        onlyValidDeadline(deadline)
        returns (uint256[] memory amounts)
    {
        _requireValidPath(path[0]);
        amounts = HelixLibrary.getAmountsOut(_factory, msg.value, path);
        _requireGEQ(amounts[amounts.length - 1], amountOutMin);
        IWETH(_WETH).deposit{value: amounts[0]}();
        assert(IWETH(_WETH).transfer(HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut, 
        uint256 amountInMax, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    )
        external
        virtual
        override
        onlyValidDeadline(deadline)
        returns (uint256[] memory amounts)
    {
        _requireValidPath(path[path.length - 1]);
        amounts = HelixLibrary.getAmountsIn(_factory, amountOut, path);
        _requireLEQ(amounts[0], amountInMax);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(_WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    )
        external
        virtual
        override
        onlyValidDeadline(deadline)
        returns (uint256[] memory amounts)
    {
        _requireValidPath(path[path.length - 1]); 
        amounts = HelixLibrary.getAmountsOut(_factory, amountIn, path);
        _requireGEQ(amounts[amounts.length - 1], amountOutMin);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(_WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut, 
        address[] calldata path, 
        address to, 
        uint256 deadline
    )
        external
        virtual
        override
        payable
        onlyValidDeadline(deadline)
        returns (uint256[] memory amounts)
    {
        _requireValidPath(path[0]);
        amounts = HelixLibrary.getAmountsIn(_factory, amountOut, path);
        _requireLEQ(amounts[0], msg.value);
        IWETH(_WETH).deposit{value: amounts[0]}();

        assert(
            IWETH(_WETH).transfer(HelixLibrary.pairFor(_factory, path[0], path[1]), amounts[0])
        );
        _swap(amounts, path, to);

        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****

    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path, 
        address _to
    ) internal virtual whenNotPaused {
        uint256 length = path.length - 1;
        for (uint256 i; i < length; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = HelixLibrary.sortTokens(input, output);
            HelixPair pair = HelixPair(HelixLibrary.pairFor(_factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;

            { // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? 
                    (reserve0, reserve1) : 
                    (reserve1, reserve0);

                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = HelixLibrary.getAmountOut(
                    amountInput, reserveInput, reserveOutput, pair.swapFee()
                );
            }
            
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? 
                (uint(0), amountOutput) : 
                (amountOutput, uint(0));
            address to = i < path.length - 2 ? 
                HelixLibrary.pairFor(_factory, output, path[i + 2]) : 
                _to;
            pair.swap(amount0Out, amount1Out, to);

            if (swapRewards != address(0)) {
                ISwapRewards(swapRewards).swap(msg.sender, output, amountOutput);
            }
        }

        emit SwapSupportingFeeOnTransferTokens(path, _to);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override onlyValidDeadline(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        _requireGEQ(IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore, amountOutMin);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        payable
        onlyValidDeadline(deadline)
    {
        _requireValidPath(path[0]);
        uint256 amountIn = msg.value;
        IWETH(_WETH).deposit{value: amountIn}();
        assert(
            IWETH(_WETH).transfer(HelixLibrary.pairFor(_factory, path[0], path[1]), amountIn)
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        _requireGEQ(IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore, amountOutMin);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        onlyValidDeadline(deadline)
    {
        _requireValidPath(path[path.length - 1]);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, HelixLibrary.pairFor(_factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(_WETH).balanceOf(address(this));
        _requireGEQ(amountOut, amountOutMin);
        IWETH(_WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****

    function quote(
        uint256 amountA, 
        uint256 reserveA, 
        uint256 reserveB
    ) 
        public 
        pure 
        virtual 
        override 
        returns (uint256 amountB) 
    {
        return HelixLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn, 
        uint256 reserveIn, 
        uint256 reserveOut, 
        uint256 swapFee
    )
        public
        pure
        virtual
        returns (uint256 amountOut)
    {
        return HelixLibrary.getAmountOut(amountIn, reserveIn, reserveOut, swapFee);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return HelixLibrary.getAmountOut(amountIn, reserveIn, reserveOut, 0);
    }

    function getAmountIn(
        uint256 amountOut, 
        uint256 reserveIn, 
        uint256 reserveOut, 
        uint256 swapFee
    )
        public
        pure
        virtual
        returns (uint256 amountIn)
    {
        return HelixLibrary.getAmountIn(amountOut, reserveIn, reserveOut, swapFee);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
    public
    pure
    virtual
    override
    returns (uint256 amountIn)
    {
        return HelixLibrary.getAmountIn(amountOut, reserveIn, reserveOut, /*swapFee=*/0);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return HelixLibrary.getAmountsOut(_factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return HelixLibrary.getAmountsIn(_factory, amountOut, path);
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // require amount to be greater than or equal to min
    function _requireGEQ(uint256 amount, uint256 min) private pure {
        require(amount >= min, "Router: insufficient amount");
    }

    function _requireLEQ(uint256 amount, uint256 max) private pure {
        require(amount <= max, "Router: excessive amount");
    }

    function _requireValidPath(address path) private view {
        require(path == _WETH, "Router: invalid path");
    }
}