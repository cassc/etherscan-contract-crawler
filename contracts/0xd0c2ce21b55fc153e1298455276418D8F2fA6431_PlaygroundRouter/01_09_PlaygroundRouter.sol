//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "./utils/interfaces/IPlaygroundRouter.sol";
import "./utils/interfaces/IPlaygroundPair.sol";
import "./utils/interfaces/IPlaygroundFactory.sol";
import "./utils/libs/TransferHelper.sol";
import "./utils/libs/PlaygroundLibrary.sol";
import "./utils/interfaces/IWETH.sol";
import "./utils/interfaces/IERC20.sol";
import "./utils/FeeUtil.sol";

contract PlaygroundRouter is IPlaygroundRouter, FeeUtil {
    address public immutable override WETH;
    address public immutable override factory;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "PlaygroundRouter: EXPIRED");
        _;
    }

    address private USDC;

    constructor(
        address _factory,
        address _WETH,
        uint256 _fee,
        address _feeTo,
        address _USDC
    ) {
        factory = _factory;
        WETH = _WETH;
        USDC = _USDC;
        // Init fee util
        initialize(_factory, _fee, _feeTo);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IPlaygroundFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            if (tokenA == WETH) {
                IPlaygroundFactory(factory).createPair(
                    tokenB,
                    tokenA,
                    address(this)
                );
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else {
                IPlaygroundFactory(factory).createPair(
                    tokenA,
                    tokenB,
                    address(this)
                );
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenB;
            }
        }
        (uint256 reserveA, uint256 reserveB) = PlaygroundLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            if (tokenA == WETH) {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else if (tokenA == USDC) {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenA;
            } else {
                pairFeeAddress[
                    IPlaygroundFactory(factory).getPair(tokenA, tokenB)
                ] = tokenB;
            }
        } else {
            uint256 amountBOptimal = PlaygroundLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "PlaygroundRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = PlaygroundLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "PlaygroundRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
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
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPlaygroundPair(pair).mint(to);
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
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountETH,
            uint256 amountToken,
            uint256 liquidity
        )
    {
        (amountETH, amountToken) = _addLiquidity(
            WETH,
            token,
            msg.value,
            amountTokenDesired,
            amountETHMin,
            amountTokenMin
        );
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPlaygroundPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
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
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        IPlaygroundPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IPlaygroundPair(pair).burn(to);
        (address token0, ) = PlaygroundLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "PlaygroundRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "PlaygroundRouter: INSUFFICIENT_B_AMOUNT");
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
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = PlaygroundLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
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
        returns (uint256 amountToken, uint256 amountETH)
    {
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
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
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );
        IWETH(WETH).withdraw(amountETH);
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
    ) external virtual override returns (uint256 amountETH) {
        address pair = PlaygroundLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPlaygroundPair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PlaygroundLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            (uint256 amount0Fee, uint256 amount1Fee) = _calculateFees(
                input,
                output,
                amounts[i],
                amount0Out,
                amount1Out
            );
            address to = i < path.length - 2
                ? PlaygroundLibrary.pairFor(factory, output, path[i + 2])
                : _to;
            IPlaygroundPair(PlaygroundLibrary.pairFor(factory, input, output)).swap(
                    amount0Out,
                    amount1Out,
                    amount0Fee,
                    amount1Fee,
                    to,
                    new bytes(0)
                );
        }
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
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
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
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );

            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        }

        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
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
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 eth = msg.value;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (eth, appliedFee) = PlaygroundLibrary.applyFee(eth, fee);
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, eth, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(pair, amounts[0]));
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
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 appliedFee;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= amountInMax,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        }
        _swap(amounts, path, address(this));

        uint256 amountETHOut = amounts[amounts.length - 1];
        if (path[1] == pairFeeAddress[pair]) {
            (amountETHOut, appliedFee) = PlaygroundLibrary.applyFee(
                amountETHOut,
                fee
            );
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
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
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");

        uint256 appliedFee;
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        amounts = PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amounts[0]);
        _swap(amounts, path, address(this));

        uint256 amountETHOut = amounts[amounts.length - 1];
        if (path[1] == pairFeeAddress[pair]) {
            (amountETHOut, appliedFee) = PlaygroundLibrary.applyFee(
                amountETHOut,
                fee
            );
        }
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(to, amountETHOut);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
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
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= msg.value,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );

            (amounts[0], appliedFee) = PlaygroundLibrary.applyFee(
                amounts[0],
                fee
            );
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
            amounts = PlaygroundLibrary.getAmountsOut(factory, amounts[0], path);
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(IWETH(WETH).transfer(pair, amounts[0]));
        } else {
            amounts = PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
            require(
                amounts[0] <= msg.value,
                "PlaygroundRouter: EXCESSIVE_INPUT_AMOUNT"
            );
            IWETH(WETH).deposit{value: amounts[0]}();
            assert(
                IWETH(WETH).transfer(
                    PlaygroundLibrary.pairFor(factory, path[0], path[1]),
                    amounts[0]
                )
            );
        }

        _swap(amounts, path, to);
        // refund dust eth, if any
        uint256 bal = amounts[0] + appliedFee;
        if (msg.value > bal)
            TransferHelper.safeTransferETH(msg.sender, msg.value - bal);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PlaygroundLibrary.sortTokens(input, output);

            (uint256 amountInput, uint256 amountOutput) = _calculateAmounts(
                input,
                output,
                token0
            );
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));

            (uint256 amount0Fee, uint256 amount1Fee) = _calculateFees(
                input,
                output,
                amountInput,
                amount0Out,
                amount1Out
            );

            address to = i < path.length - 2
                ? PlaygroundLibrary.pairFor(factory, output, path[i + 2])
                : _to;

            IPlaygroundPair pair = IPlaygroundPair(
                PlaygroundLibrary.pairFor(factory, input, output)
            );

            pair.swap(
                amount0Out,
                amount1Out,
                amount0Fee,
                amount1Fee,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (path[1] == pairFeeAddress[pair]) {
            (amountOutMin, appliedFee) = PlaygroundLibrary.applyFee(
                amountOutMin,
                fee
            );
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[0] == WETH, "PlaygroundRouter: INVALID_PATH");
        uint256 amountIn = msg.value;

        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);
        uint256 appliedFee;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, appliedFee) = PlaygroundLibrary.applyFee(amountIn, fee);
            if (address(this) != getFeeTo()) {
                payable(getFeeTo()).transfer(appliedFee);
            }
        }

        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (path[1] == pairFeeAddress[pair]) {
            (amountOutMin, appliedFee) = PlaygroundLibrary.applyFee(
                amountOutMin,
                fee
            );
        }
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >=
                amountOutMin,
            "PlaygroundRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path.length == 2, "PlaygroundRouter: ONLY_TWO_TOKENS_ALLOWED");
        require(path[path.length - 1] == WETH, "PlaygroundRouter: INVALID_PATH");
        address pair = PlaygroundLibrary.pairFor(factory, path[0], path[1]);

        if (path[0] == pairFeeAddress[pair]) {
            uint256 appliedFee = (amountIn * fee) / (10**3);
            amountIn = amountIn - appliedFee;
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                getFeeTo(),
                appliedFee
            );
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        amountOutMin;
        if (path[1] == pairFeeAddress[pair]) {
            uint256 appliedFee = (amountOut * fee) / (10**3);
            amountOut = amountOut - appliedFee;
        }
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return PlaygroundLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return
            PlaygroundLibrary.getAmountOut(
                amountIn,
                reserveIn,
                reserveOut,
                0,
                false
            );
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return
            PlaygroundLibrary.getAmountIn(
                amountOut,
                reserveIn,
                reserveOut,
                0,
                false
            );
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PlaygroundLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return PlaygroundLibrary.getAmountsIn(factory, amountOut, path);
    }

    function _calculateFees(
        address input,
        address output,
        uint256 amountIn,
        uint256 amount0Out,
        uint256 amount1Out
    ) internal view virtual returns (uint256 amount0Fee, uint256 amount1Fee) {
        IPlaygroundPair pair = IPlaygroundPair(
            PlaygroundLibrary.pairFor(factory, input, output)
        );
        (address token0, ) = PlaygroundLibrary.sortTokens(input, output);
        address feeToken = pair.feeToken();
        uint256 totalFee = pair.totalFee();
        amount0Fee = feeToken != token0 ? uint256(0) : input == token0
            ? (amountIn * totalFee) / 10**3
            : (amount0Out * totalFee) / 10**3;
        amount1Fee = feeToken == token0 ? uint256(0) : input != token0
            ? (amountIn * totalFee) / 10**3
            : (amount1Out * totalFee) / 10**3;
    }

    function _calculateAmounts(
        address input,
        address output,
        address token0
    ) internal view returns (uint256 amountInput, uint256 amountOutput) {
        IPlaygroundPair pair = IPlaygroundPair(
            PlaygroundLibrary.pairFor(factory, input, output)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        bool hasFee = pair.feeToken() != address(0);
        uint256 totalFee = pair.totalFee();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = PlaygroundLibrary.getAmountOut(
            amountInput,
            reserveInput,
            reserveOutput,
            totalFee,
            hasFee
        );
    }
}