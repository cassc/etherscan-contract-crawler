// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.16;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

import '../interfaces/IBakeryPair.sol';
import '../interfaces/IDODOV2.sol';
import '../interfaces/IWETH.sol';
import '../interfaces/IVyperSwap.sol';
import '../interfaces/IVyperUnderlyingSwap.sol';
import '../interfaces/ISaddleDex.sol';
import '../interfaces/IDODOV2Proxy.sol';
import '../interfaces/IBalancer.sol';
import '../interfaces/ICurveTricryptoV2.sol';
import '../interfaces/IArkenApprove.sol';
import '../interfaces/IDMMPool.sol';
import '../interfaces/IWooPP.sol';
import '../lib/DMMLibrary.sol';
import '../lib/UniswapV2Library.sol';
import '../lib/UniswapV3CallbackValidation.sol';

library ArkenDexTrader {
    using SafeERC20 for IERC20;

    // CONSTANTS
    uint256 constant _MAX_UINT_256_ = 2**256 - 1;
    // Uniswap V3
    uint160 public constant MIN_SQRT_RATIO = 4295128739 + 1;
    uint160 public constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342 - 1;
    address public constant _ETH_ = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    enum RouterInterface {
        UNISWAP_V2,
        BAKERY,
        VYPER,
        VYPER_UNDERLYING,
        SADDLE,
        DODO_V2,
        DODO_V1,
        DFYN,
        BALANCER,
        UNISWAP_V3,
        CURVE_TRICRYPTO_V2,
        LIMIT_ORDER_PROTOCOL_V2,
        KYBER_DMM,
        WOO_FI
    }
    struct TradeRoute {
        address routerAddress;
        address lpAddress;
        address fromToken;
        address toToken;
        address from;
        address to;
        uint32 part;
        uint8 direction; // DODO
        int16 fromTokenIndex; // Vyper
        int16 toTokenIndex; // Vyper
        uint16 amountAfterFee; // 9970 = fee 0.3% -- 10000 = no fee
        RouterInterface dexInterface; // uint8
    }
    struct TradeDescription {
        address srcToken;
        address dstToken;
        uint256 amountIn;
        uint256 amountOutMin;
        address payable to;
        TradeRoute[] routes;
        bool isRouterSource;
        bool isSourceFee;
    }
    struct TradeDescriptionOutside {
        address srcToken;
        address dstToken;
        uint256 amountIn;
        uint256 amountOutMin;
        address payable to;
        bool isSourceFee;
    }
    struct TradeData {
        uint256 amountIn;
        address weth;
    }
    struct UniswapV3CallbackData {
        address token0;
        address token1;
        uint24 fee;
    }

    function _tradeRoute(
        TradeRoute calldata route,
        TradeDescription calldata desc,
        TradeData memory data,
        address wethDfyn,
        address dodoApproveAddress,
        address woofiQuoteToken
    ) public {
        require(
            route.part <= 100000000,
            'Route percentage can not exceed 100000000'
        );
        require(
            route.fromToken != _ETH_ && route.toToken != _ETH_,
            'TradeRoute from/to token cannot be Ether'
        );
        if (route.from == address(1)) {
            require(
                route.fromToken == desc.srcToken,
                'Cannot transfer token from msg.sender'
            );
        }
        if (
            !desc.isSourceFee &&
            (route.toToken == desc.dstToken ||
                (_ETH_ == desc.dstToken && data.weth == route.toToken))
        ) {
            require(
                route.to == address(0),
                'Destination swap have to be ArkenDex'
            );
        }
        uint256 amountIn;
        if (route.from == address(0)) {
            amountIn =
                (IERC20(
                    route.fromToken == wethDfyn ? data.weth : route.fromToken
                ).balanceOf(address(this)) * route.part) /
                100000000;
        } else if (route.from == address(1)) {
            amountIn = (data.amountIn * route.part) / 100000000;
        }
        if (route.dexInterface == RouterInterface.UNISWAP_V2) {
            _tradeUniswapV2(route, amountIn, desc, data);
        } else if (route.dexInterface == RouterInterface.BAKERY) {
            _tradeBakery(route, amountIn, desc, data);
        } else if (route.dexInterface == RouterInterface.DODO_V2) {
            _tradeDODOV2(route, amountIn, desc, data);
        } else if (route.dexInterface == RouterInterface.DODO_V1) {
            _tradeDODOV1(route, dodoApproveAddress, amountIn);
        } else if (route.dexInterface == RouterInterface.DFYN) {
            _tradeDfyn(route, wethDfyn, amountIn, desc, data);
        } else if (route.dexInterface == RouterInterface.VYPER) {
            _tradeVyper(route, amountIn);
        } else if (route.dexInterface == RouterInterface.VYPER_UNDERLYING) {
            _tradeVyperUnderlying(route, amountIn);
        } else if (route.dexInterface == RouterInterface.SADDLE) {
            _tradeSaddle(route, amountIn);
        } else if (route.dexInterface == RouterInterface.BALANCER) {
            _tradeBalancer(route, amountIn);
        } else if (route.dexInterface == RouterInterface.UNISWAP_V3) {
            _tradeUniswapV3(route, amountIn, desc);
        } else if (route.dexInterface == RouterInterface.CURVE_TRICRYPTO_V2) {
            _tradeCurveTricryptoV2(route, amountIn);
        } else if (route.dexInterface == RouterInterface.KYBER_DMM) {
            _tradeKyberDMM(route, amountIn, desc, data);
        } else if (route.dexInterface == RouterInterface.WOO_FI) {
            _tradeWooFi(route, woofiQuoteToken, amountIn, desc);
        } else {
            revert('unknown router interface');
        }
    }

    function _tradeWooFi(
        TradeRoute calldata route,
        address woofiQuoteToken,
        uint256 amountIn,
        TradeDescription calldata desc
    ) public {
        require(route.from == address(0), 'route.from should be zero address');

        IWooPP wooPool = IWooPP(route.lpAddress);

        _increaseAllowance(route.fromToken, route.lpAddress, amountIn);

        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;

        if (route.fromToken == woofiQuoteToken) {
            // case 1: quoteToken --> baseToken
            wooPool.sellQuote(route.toToken, amountIn, 0, to, address(0));
        } else if (route.toToken == woofiQuoteToken) {
            // case 2: fromToken --> quoteToken
            wooPool.sellBase(route.fromToken, amountIn, 0, to, address(0));
        } else {
            // case 3: fromToken --> quoteToken --> toToken
            uint256 quoteAmount = wooPool.sellBase(
                route.fromToken,
                amountIn,
                0,
                address(this),
                address(0)
            );

            _increaseAllowance(woofiQuoteToken, route.lpAddress, quoteAmount);

            wooPool.sellQuote(route.toToken, quoteAmount, 0, to, address(0));
        }
    }

    function _tradeKyberDMM(
        TradeRoute calldata route,
        uint256 amountIn,
        TradeDescription calldata desc,
        TradeData memory data
    ) public {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            data.amountIn = _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken,
                data
            );
        }
        IDMMPool pair = IDMMPool(route.lpAddress);
        (
            uint112 reserve0,
            uint112 reserve1,
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint256 feeInPrecision
        ) = pair.getTradeInfo();
        if (route.fromToken != address(pair.token0())) {
            (reserve1, reserve0, _vReserve1, _vReserve0) = (
                reserve0,
                reserve1,
                _vReserve0,
                _vReserve1
            );
        }
        amountIn =
            IERC20(route.fromToken).balanceOf(route.lpAddress) -
            reserve0;
        uint256 amountOut = DMMLibrary.getAmountOut(
            amountIn,
            reserve0,
            reserve1,
            _vReserve0,
            _vReserve1,
            feeInPrecision
        );

        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (route.toToken == address(pair.token0())) {
            pair.swap(amountOut, 0, to, '');
        } else {
            pair.swap(0, amountOut, to, '');
        }
    }

    function _tradeUniswapV2(
        TradeRoute calldata route,
        uint256 amountIn,
        TradeDescription calldata desc,
        TradeData memory data
    ) public {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            data.amountIn = _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken,
                data
            );
        }
        IUniswapV2Pair pair = IUniswapV2Pair(route.lpAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveFrom, uint256 reserveTo) = route.fromToken ==
            pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        amountIn =
            IERC20(route.fromToken).balanceOf(route.lpAddress) -
            reserveFrom;
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveFrom,
            reserveTo,
            route.amountAfterFee
        );
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (route.toToken == pair.token0()) {
            pair.swap(amountOut, 0, to, '');
        } else {
            pair.swap(0, amountOut, to, '');
        }
    }

    function _tradeDfyn(
        TradeRoute calldata route,
        address wethDfyn,
        uint256 amountIn,
        TradeDescription calldata desc,
        TradeData memory data
    ) public {
        if (route.fromToken == wethDfyn) {
            _unwrapEther(data.weth, amountIn);
            _wrapEther(wethDfyn, amountIn);
        }
        _tradeUniswapV2(route, amountIn, desc, data);
        if (route.toToken == wethDfyn) {
            uint256 amountOut = IERC20(wethDfyn).balanceOf(address(this));
            _unwrapEther(wethDfyn, amountOut);
            _wrapEther(data.weth, amountOut);
        }
    }

    function _tradeBakery(
        TradeRoute calldata route,
        uint256 amountIn,
        TradeDescription calldata desc,
        TradeData memory data
    ) public {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            data.amountIn = _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken,
                data
            );
        }
        IBakeryPair pair = IBakeryPair(route.lpAddress);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveFrom, uint256 reserveTo) = route.fromToken ==
            pair.token0()
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        amountIn =
            IERC20(route.fromToken).balanceOf(route.lpAddress) -
            reserveFrom;
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveFrom,
            reserveTo,
            route.amountAfterFee
        );
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (route.toToken == pair.token0()) {
            pair.swap(amountOut, 0, to);
        } else {
            pair.swap(0, amountOut, to);
        }
    }

    function _tradeUniswapV3(
        TradeRoute calldata route,
        uint256 amountIn,
        TradeDescription calldata desc
    ) public {
        require(route.from == address(0), 'route.from should be zero address');
        IUniswapV3Pool pool = IUniswapV3Pool(route.lpAddress);
        bool zeroForOne = pool.token0() == route.fromToken;
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        pool.swap(
            to,
            zeroForOne,
            int256(amountIn),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            abi.encode(
                UniswapV3CallbackData({
                    token0: pool.token0(),
                    token1: pool.token1(),
                    fee: pool.fee()
                })
            )
        );
    }

    function _tradeDODOV2(
        TradeRoute calldata route,
        uint256 amountIn,
        TradeDescription calldata desc,
        TradeData memory data
    ) public {
        if (route.from == address(0)) {
            IERC20(route.fromToken).safeTransfer(route.lpAddress, amountIn);
        } else if (route.from == address(1)) {
            data.amountIn = _transferFromSender(
                route.fromToken,
                route.lpAddress,
                amountIn,
                desc.srcToken,
                data
            );
        }
        address to = route.to;
        if (to == address(0)) to = address(this);
        if (to == address(1)) to = desc.to;
        if (IDODOV2(route.lpAddress)._BASE_TOKEN_() == route.fromToken) {
            IDODOV2(route.lpAddress).sellBase(to);
        } else {
            IDODOV2(route.lpAddress).sellQuote(to);
        }
    }

    function _tradeDODOV1(
        TradeRoute calldata route,
        address dodoApproveAddress,
        uint256 amountIn
    ) public {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, dodoApproveAddress, amountIn);
        address[] memory dodoPairs = new address[](1);
        dodoPairs[0] = route.lpAddress;
        IDODOV2Proxy(route.routerAddress).dodoSwapV1(
            route.fromToken,
            route.toToken,
            amountIn,
            1,
            dodoPairs,
            route.direction,
            false,
            _MAX_UINT_256_
        );
    }

    function _tradeCurveTricryptoV2(TradeRoute calldata route, uint256 amountIn)
        public
    {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        ICurveTricryptoV2(route.routerAddress).exchange(
            uint16(route.fromTokenIndex),
            uint16(route.toTokenIndex),
            amountIn,
            0,
            false
        );
    }

    function _tradeVyper(TradeRoute calldata route, uint256 amountIn) public {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IVyperSwap(route.routerAddress).exchange(
            route.fromTokenIndex,
            route.toTokenIndex,
            amountIn,
            0
        );
    }

    function _tradeVyperUnderlying(TradeRoute calldata route, uint256 amountIn)
        public
    {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IVyperUnderlyingSwap(route.routerAddress).exchange_underlying(
            route.fromTokenIndex,
            route.toTokenIndex,
            amountIn,
            0
        );
    }

    function _tradeSaddle(TradeRoute calldata route, uint256 amountIn) public {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        ISaddleDex dex = ISaddleDex(route.routerAddress);
        uint8 tokenIndexFrom = dex.getTokenIndex(route.fromToken);
        uint8 tokenIndexTo = dex.getTokenIndex(route.toToken);
        dex.swap(tokenIndexFrom, tokenIndexTo, amountIn, 0, _MAX_UINT_256_);
    }

    function _tradeBalancer(TradeRoute calldata route, uint256 amountIn)
        public
    {
        require(route.from == address(0), 'route.from should be zero address');
        _increaseAllowance(route.fromToken, route.routerAddress, amountIn);
        IBalancerRouter(route.routerAddress).swap(
            Balancer.SingleSwap({
                poolId: IBalancerPool(route.lpAddress).getPoolId(),
                kind: Balancer.SwapKind.GIVEN_IN,
                assetIn: IAsset(route.fromToken),
                assetOut: IAsset(route.toToken),
                amount: amountIn,
                userData: '0x'
            }),
            Balancer.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            0,
            _MAX_UINT_256_
        );
    }

    function _increaseAllowance(
        address token,
        address spender,
        uint256 amount
    ) public {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (amount > allowance) {
            uint256 increaseAmount = _MAX_UINT_256_ - allowance;
            IERC20(token).safeIncreaseAllowance(spender, increaseAmount);
        }
    }

    function _transferFromSender(
        address token,
        address to,
        uint256 amount,
        address srcToken,
        TradeData memory data
    ) public returns (uint256 newAmountIn) {
        newAmountIn = data.amountIn - amount;
        if (srcToken != _ETH_) {
            IERC20(token).transferFrom(msg.sender, to, amount);
        } else {
            _wrapEther(data.weth, amount);
            if (to != address(this)) {
                IERC20(data.weth).safeTransfer(to, amount);
            }
        }
    }

    function _wrapEther(address weth, uint256 amount) public {
        IWETH(weth).deposit{value: amount}();
    }

    function _unwrapEther(address weth, uint256 amount) public {
        IWETH(weth).withdraw(amount);
    }

    function _getBalance(address token, address account)
        public
        view
        returns (uint256)
    {
        if (_ETH_ == token) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }
}