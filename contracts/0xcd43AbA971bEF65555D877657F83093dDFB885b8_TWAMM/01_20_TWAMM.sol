// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "./interfaces/ITWAMM.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IWETH.sol";
import "./libraries/Library.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TWAMM is ITWAMM {
    using Library for address;
    using SafeERC20 for IERC20;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "TWAMM: Expired");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
        IFactory(factory).initialize(address(this));
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function obtainReserves(
        address token0,
        address token1
    ) external view override returns (uint256 reserve0, uint256 reserve1) {
        (reserve0, reserve1) = Library.getReserves(factory, token0, token1);
    }

    function obtainTotalSupply(
        address token0,
        address token1
    ) external view override returns (uint256) {
        if (IFactory(factory).getPair(token0, token1) == address(0)) {
            return 0;
        } else {
            address pair = IFactory(factory).getPair(token0, token1);
            return IPair(pair).getTotalSupply();
        }
    }

    function obtainPairAddress(
        address token0,
        address token1
    ) external view override returns (address) {
        return Library.pairFor(factory, token0, token1);
    }

    function createPairWrapper(
        address token0,
        address token1,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (address pair) {
        require(
            IFactory(factory).getPair(token0, token1) == address(0),
            "Pair Existing Already!"
        );
        pair = IFactory(factory).createPair(token0, token1);
    }

    function addInitialLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 lpTokenAmount)
    {
        // create the pair if it doesn't exist yet
        if (IFactory(factory).getPair(token0, token1) == address(0)) {
            IFactory(factory).createPair(token0, token1);
        }

        address pair = Library.pairFor(factory, token0, token1);
        IERC20(token0).safeTransferFrom(msg.sender, pair, amount0);
        IERC20(token1).safeTransferFrom(msg.sender, pair, amount1);

        (uint256 amountA, uint256 amountB) = Library.sortAmounts(
            token0,
            token1,
            amount0,
            amount1
        );
        lpTokenAmount = IPair(pair).provideInitialLiquidity(
            msg.sender,
            amountA,
            amountB
        );
    }

    function addInitialLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 lpTokenAmount)
    {
        // create the pair if it doesn't exist yet
        if (IFactory(factory).getPair(token, WETH) == address(0)) {
            IFactory(factory).createPair(token, WETH);
        }

        address pair = Library.pairFor(factory, token, WETH);
        IERC20(token).safeTransferFrom(msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        IERC20(WETH).safeTransfer(pair, amountETH);

        (uint256 amountA, uint256 amountB) = Library.sortAmounts(
            token,
            WETH,
            amountToken,
            amountETH
        );
        lpTokenAmount = IPair(pair).provideInitialLiquidity(
            msg.sender,
            amountA,
            amountB
        );

        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    function addLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 amountIn0Max,
        uint256 amountIn1Max,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountIn0, uint256 amountIn1)
    {
        address pair = Library.pairFor(factory, token0, token1);
        IPair(pair).executeVirtualOrders(block.number);
        {
            // scope to avoid stack too deep errors
            (uint256 reserve0, uint256 reserve1) = Library.getReserves(
                factory,
                token0,
                token1
            );
            uint256 totalSupplyLP = IPair(pair).getTotalSupply();
            amountIn0 = (lpTokenAmount * reserve0) / totalSupplyLP;
            amountIn1 = (lpTokenAmount * reserve1) / totalSupplyLP;
        }

        require(
            amountIn0 <= amountIn0Max && amountIn1 <= amountIn1Max,
            "Excessive Input Amount"
        );
        IERC20(token0).safeTransferFrom(msg.sender, pair, amountIn0);
        IERC20(token1).safeTransferFrom(msg.sender, pair, amountIn1);
        IPair(pair).provideLiquidity(msg.sender, lpTokenAmount);
    }

    function addLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 amountTokenInMax,
        uint256 amountETHInMax,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountTokenIn, uint256 amountETHIn)
    {
        address pair = Library.pairFor(factory, token, WETH);
        IPair(pair).executeVirtualOrders(block.number);
        {
            // scope to avoid stack too deep errors
            (uint256 reserveToken, uint256 reserveETH) = Library.getReserves(
                factory,
                token,
                WETH
            );
            uint256 totalSupplyLP = IPair(pair).getTotalSupply();
            amountTokenIn = (lpTokenAmount * reserveToken) / totalSupplyLP;
            amountETHIn = (lpTokenAmount * reserveETH) / totalSupplyLP;
        }

        require(
            amountTokenIn <= amountTokenInMax && amountETHIn <= amountETHInMax,
            "Excessive Input Amount"
        );
        IERC20(token).safeTransferFrom(msg.sender, pair, amountTokenIn);
        IWETH(WETH).deposit{value: amountETHIn}();
        IERC20(WETH).safeTransfer(pair, amountETHIn);
        IPair(pair).provideLiquidity(msg.sender, lpTokenAmount);

        // refund dust eth, if any
        if (msg.value > amountETHIn)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHIn);
    }

    function withdrawLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 amountOut0Min,
        uint256 amountOut1Min,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountOut0, uint256 amountOut1)
    {
        address pair = Library.pairFor(factory, token0, token1);
        {
            // scope to avoid stack too deep errors
            (uint256 amountOutA, uint256 amountOutB) = IPair(pair)
                .removeLiquidity(msg.sender, lpTokenAmount);
            (amountOut0, amountOut1) = Library.sortAmounts(
                token0,
                token1,
                amountOutA,
                amountOutB
            );
        }

        require(
            amountOut0 >= amountOut0Min && amountOut1 >= amountOut1Min,
            "Insufficient Output Amount"
        );
        require(
            IERC20(token0).balanceOf(address(this)) >= amountOut0 &&
                IERC20(token1).balanceOf(address(this)) >= amountOut1,
            "Inaccurate Amount for Tokens."
        );
        IERC20(token0).safeTransfer(msg.sender, amountOut0);
        IERC20(token1).safeTransfer(msg.sender, amountOut1);
    }

    function withdrawLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 amountTokenOutMin,
        uint256 amountETHOutMin,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountTokenOut, uint256 amountETHOut)
    {
        address pair = Library.pairFor(factory, token, WETH);
        {
            // scope to avoid stack too deep errors
            (uint256 amountOutA, uint256 amountOutB) = IPair(pair)
                .removeLiquidity(msg.sender, lpTokenAmount);
            (amountTokenOut, amountETHOut) = Library.sortAmounts(
                token,
                WETH,
                amountOutA,
                amountOutB
            );
        }

        require(
            amountTokenOut >= amountTokenOutMin &&
                amountETHOut >= amountETHOutMin,
            "Insufficient Output Amount"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= amountTokenOut &&
                IWETH(WETH).balanceOf(address(this)) >= amountETHOut,
            "Inaccurate Amount for Tokens."
        );
        IERC20(token).safeTransfer(msg.sender, amountTokenOut);
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(msg.sender, amountETHOut);
    }

    function instantSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountOut) {
        address pair = Library.pairFor(factory, token0, token1);
        IERC20(token0).safeTransferFrom(msg.sender, pair, amountIn);
        (address tokenA, ) = Library.sortTokens(token0, token1);

        if (tokenA == token0) {
            amountOut = IPair(pair).instantSwapFromAToB(msg.sender, amountIn);
        } else {
            amountOut = IPair(pair).instantSwapFromBToA(msg.sender, amountIn);
        }

        require(amountOut >= amountOutMin, "Insufficient Output Amount");
        require(
            IERC20(token1).balanceOf(address(this)) >= amountOut,
            "Inaccurate Amount for Token."
        );
        IERC20(token1).safeTransfer(msg.sender, amountOut);
    }

    function instantSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 amountETHOutMin,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountETHOut)
    {
        address pair = Library.pairFor(factory, token, WETH);
        IERC20(token).safeTransferFrom(msg.sender, pair, amountTokenIn);
        (address tokenA, ) = Library.sortTokens(token, WETH);

        if (tokenA == token) {
            amountETHOut = IPair(pair).instantSwapFromAToB(
                msg.sender,
                amountTokenIn
            );
        } else {
            amountETHOut = IPair(pair).instantSwapFromBToA(
                msg.sender,
                amountTokenIn
            );
        }

        require(amountETHOut >= amountETHOutMin, "Insufficient Output Amount");
        require(
            IWETH(WETH).balanceOf(address(this)) >= amountETHOut,
            "Inaccurate Amount for WETH."
        );
        IWETH(WETH).withdraw(amountETHOut);
        TransferHelper.safeTransferETH(msg.sender, amountETHOut);
    }

    function instantSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 amountTokenOutMin,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountTokenOut)
    {
        address pair = Library.pairFor(factory, WETH, token);
        IWETH(WETH).deposit{value: amountETHIn}();
        IERC20(WETH).safeTransfer(pair, amountETHIn);
        (address tokenA, ) = Library.sortTokens(WETH, token);

        if (tokenA == WETH) {
            amountTokenOut = IPair(pair).instantSwapFromAToB(
                msg.sender,
                amountETHIn
            );
        } else {
            amountTokenOut = IPair(pair).instantSwapFromBToA(
                msg.sender,
                amountETHIn
            );
        }

        require(
            amountTokenOut >= amountTokenOutMin,
            "Insufficient Output Amount"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= amountTokenOut,
            "Inaccurate Amount for Token."
        );
        IERC20(token).safeTransfer(msg.sender, amountTokenOut);

        // refund dust eth, if any
        if (msg.value > amountETHIn)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHIn);
    }

    function longTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 orderId) {
        address pair = Library.pairFor(factory, token0, token1);
        IERC20(token0).safeTransferFrom(msg.sender, pair, amountIn);
        (address tokenA, ) = Library.sortTokens(token0, token1);

        if (tokenA == token0) {
            orderId = IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountIn,
                numberOfBlockIntervals
            );
        } else {
            orderId = IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountIn,
                numberOfBlockIntervals
            );
        }
    }

    function longTermSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 orderId) {
        address pair = Library.pairFor(factory, token, WETH);
        IERC20(token).safeTransferFrom(msg.sender, pair, amountTokenIn);
        (address tokenA, ) = Library.sortTokens(token, WETH);

        if (tokenA == token) {
            orderId = IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountTokenIn,
                numberOfBlockIntervals
            );
        } else {
            orderId = IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountTokenIn,
                numberOfBlockIntervals
            );
        }
    }

    function longTermSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 orderId)
    {
        address pair = Library.pairFor(factory, WETH, token);
        IWETH(WETH).deposit{value: amountETHIn}();
        IERC20(WETH).safeTransfer(pair, amountETHIn);
        (address tokenA, ) = Library.sortTokens(WETH, token);

        if (tokenA == WETH) {
            orderId = IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountETHIn,
                numberOfBlockIntervals
            );
        } else {
            orderId = IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountETHIn,
                numberOfBlockIntervals
            );
        }

        // refund dust eth, if any
        if (msg.value > amountETHIn)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHIn);
    }

    function cancelTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 unsoldAmount, uint256 purchasedAmount)
    {
        address pair = Library.pairFor(factory, token0, token1);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == token0 && tokenBuy == token1,
            "Wrong Sell Or Buy Token"
        );

        (unsoldAmount, purchasedAmount) = IPair(pair).cancelLongTermSwap(
            msg.sender,
            orderId
        );

        require(
            IERC20(token0).balanceOf(address(this)) >= unsoldAmount &&
                IERC20(token1).balanceOf(address(this)) >= purchasedAmount,
            "Inaccurate Amount for Tokens."
        );
        IERC20(token0).safeTransfer(msg.sender, unsoldAmount);
        IERC20(token1).safeTransfer(msg.sender, purchasedAmount);
    }

    function cancelTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 unsoldTokenAmount, uint256 purchasedETHAmount)
    {
        address pair = Library.pairFor(factory, token, WETH);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == token && tokenBuy == WETH,
            "Wrong Sell Or Buy Token"
        );

        (unsoldTokenAmount, purchasedETHAmount) = IPair(pair)
            .cancelLongTermSwap(msg.sender, orderId);

        require(
            IERC20(token).balanceOf(address(this)) >= unsoldTokenAmount &&
                IWETH(WETH).balanceOf(address(this)) >= purchasedETHAmount,
            "Inaccurate Amount for Tokens."
        );
        IERC20(token).safeTransfer(msg.sender, unsoldTokenAmount);
        IWETH(WETH).withdraw(purchasedETHAmount);
        TransferHelper.safeTransferETH(msg.sender, purchasedETHAmount);
    }

    function cancelTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 unsoldETHAmount, uint256 purchasedTokenAmount)
    {
        address pair = Library.pairFor(factory, WETH, token);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == WETH && tokenBuy == token,
            "Wrong Sell Or Buy Token"
        );

        (unsoldETHAmount, purchasedTokenAmount) = IPair(pair)
            .cancelLongTermSwap(msg.sender, orderId);

        require(
            IERC20(token).balanceOf(address(this)) >= purchasedTokenAmount &&
                IWETH(WETH).balanceOf(address(this)) >= unsoldETHAmount,
            "Inaccurate Amount for Tokens."
        );
        IERC20(token).safeTransfer(msg.sender, purchasedTokenAmount);
        IWETH(WETH).withdraw(unsoldETHAmount);
        TransferHelper.safeTransferETH(msg.sender, unsoldETHAmount);
    }

    function withdrawProceedsFromTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 proceeds) {
        address pair = Library.pairFor(factory, token0, token1);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == token0 && tokenBuy == token1,
            "Wrong Sell Or Buy Token"
        );

        proceeds = IPair(pair).withdrawProceedsFromLongTermSwap(
            msg.sender,
            orderId
        );

        require(
            IERC20(token1).balanceOf(address(this)) >= proceeds,
            "Inaccurate Amount for Token."
        );
        IERC20(token1).safeTransfer(msg.sender, proceeds);
    }

    function withdrawProceedsFromTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 proceedsETH) {
        address pair = Library.pairFor(factory, token, WETH);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == token && tokenBuy == WETH,
            "Wrong Sell Or Buy Token"
        );

        proceedsETH = IPair(pair).withdrawProceedsFromLongTermSwap(
            msg.sender,
            orderId
        );

        require(
            IWETH(WETH).balanceOf(address(this)) >= proceedsETH,
            "Inaccurate Amount for WETH."
        );
        IWETH(WETH).withdraw(proceedsETH);
        TransferHelper.safeTransferETH(msg.sender, proceedsETH);
    }

    function withdrawProceedsFromTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 proceedsToken)
    {
        address pair = Library.pairFor(factory, WETH, token);
        address tokenSell = IPair(pair).getOrderDetails(orderId).sellTokenId;
        address tokenBuy = IPair(pair).getOrderDetails(orderId).buyTokenId;
        require(
            tokenSell == WETH && tokenBuy == token,
            "Wrong Sell Or Buy Token"
        );

        proceedsToken = IPair(pair).withdrawProceedsFromLongTermSwap(
            msg.sender,
            orderId
        );

        require(
            IERC20(token).balanceOf(address(this)) >= proceedsToken,
            "Inaccurate Amount for Token."
        );
        IERC20(token).safeTransfer(msg.sender, proceedsToken);
    }

    function executeVirtualOrdersWrapper(
        address pair,
        uint256 blockNumber
    ) external virtual override {
        IPair(pair).executeVirtualOrders(blockNumber);
    }
}