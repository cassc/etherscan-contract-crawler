// SPDX-License-Identifier: GPL-3.0

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
    IUniswapV3Factory
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {GasStationRecipient} from "./abstract/GasStationRecipient.sol";
import {Ownable} from "./abstract/Ownable.sol";
import {SwapGuard} from "./abstract/SwapGuard.sol";
import {TYPES, IHyperLPFactory, IHyperLPool} from "./interfaces/IHyper.sol";
import {
    IHyperLPoolFactoryStorage,
    IHyperLPoolStorage
} from "./interfaces/IHyperStorage.sol";
import {SafeERC20v2} from "./utils/SafeERC20v2.sol";
import {LiquidityAmounts} from "./vendor/uniswap/LiquidityAmounts.sol";
import {SafeCast} from "./vendor/uniswap/SafeCast.sol";
import {TickMath} from "./vendor/uniswap/TickMath.sol";

interface IERC20Meta {
    function decimals() external view returns (uint8);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract HyperLPRouter is
    SwapGuard,
    GasStationRecipient,
    Ownable,
    ReentrancyGuard
{
    using SafeERC20v2 for IERC20;
    using TickMath for int24;
    using SafeCast for uint256;

    address private constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IHyperLPFactory public immutable lpfactory;
    IUniswapV3Factory public immutable factory;
    IWETH public immutable wETH;

    constructor(address hyperlpfactory, address weth) {
        lpfactory = IHyperLPFactory(hyperlpfactory);
        factory = IUniswapV3Factory(
            IHyperLPoolFactoryStorage(hyperlpfactory).factory()
        );
        wETH = IWETH(weth);
    }

    event Minted(
        address receiver,
        uint256 mintAmount,
        uint256 amount0In,
        uint256 amount1In,
        uint128 liquidityMinted
    );

    /**
     * @notice mint fungible `hyperpool` tokens with `token` or ETH transformation
     * to `hyperpool` tokens
     * when current tick is outside of [lowerTick, upperTick]
     * @dev see HyperLPool.mint method
     * @param hyperpool HyperLPool address
     * @param paymentToken token to pay
     * @param paymentAmount amount of token to pay
     * @param sqrtPriceLimitX960 sqrtRatioX96 from uniswap pool store
     * @param sqrtPriceLimitX961 sqrtRatioX96 from uniswap pool store
     * @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
     * @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
     * @return mintAmount The number of HyperLP tokens to mint
     * @return liquidityMinted amount of liquidity added to the underlying Uniswap V3 position
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function mint(
        address hyperpool,
        address paymentToken,
        uint256 paymentAmount,
        uint160 sqrtPriceLimitX960,
        uint160 sqrtPriceLimitX961
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint128 liquidityMinted
        )
    {
        require(paymentAmount > 0, "!amount");
        require(lpfactory.isTrustedPool(hyperpool), "!pool");

        address transferFrom = _msgSender();

        if (paymentToken == _ETH) {
            require(paymentAmount == msg.value, "!eth");
            wETH.deposit{value: paymentAmount}();
            wETH.transfer(address(this), paymentAmount); // change for gasStation usage
            paymentToken = address(wETH);
            transferFrom = address(this);
        }

        address token0;
        address token1;

        (amount0, amount1, token0, token1) = calculateShares(
            IHyperLPoolStorage(hyperpool),
            paymentToken,
            paymentAmount
        );

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        if (paymentToken != token0) {
            amount0 = _swap(
                paymentToken,
                token0,
                fee,
                amount0,
                sqrtPriceLimitX960,
                transferFrom
            );
        }

        if (paymentToken != token1) {
            amount1 = _swap(
                paymentToken,
                token1,
                fee,
                amount1,
                sqrtPriceLimitX961,
                transferFrom
            );
        }

        IERC20(token0).approve(hyperpool, amount0);
        IERC20(token1).approve(hyperpool, amount1);

        (amount0, amount1, mintAmount, liquidityMinted) = IHyperLPool(hyperpool)
            .mint(amount0, amount1, _msgSender());

        emit Minted(
            _msgSender(),
            mintAmount,
            amount0,
            amount1,
            liquidityMinted
        );

        amount0 = IERC20(token0).balanceOf(address(this));
        amount1 = IERC20(token1).balanceOf(address(this));

        if (amount0 > 0) {
            IERC20(token0).safeTransfer(_msgSender(), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).safeTransfer(_msgSender(), amount1);
        }
    }

    // solhint-disable-next-line function-max-lines, code-complexity
    function calculateShares(
        IHyperLPoolStorage hyperpool,
        address paymentToken,
        uint256 paymentAmount
    )
        public
        view
        returns (
            uint256 share0,
            uint256 share1,
            address token0,
            address token1
        )
    {
        token0 = address(hyperpool.token0());
        token1 = address(hyperpool.token1());

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();

        uint256 price0 = 0;
        if (paymentToken != token0) {
            price0 = _calculatePrice(token0, paymentToken, fee);
        }

        uint256 price1 = 0;
        if (paymentToken != token1) {
            price1 = _calculatePrice(token1, paymentToken, fee);
        }

        (uint160 sqrtRatioX96, , , , , , ) =
            IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).slot0();

        (share0, share1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            IHyperLPoolStorage(hyperpool).lowerTick().getSqrtRatioAtTick(),
            IHyperLPoolStorage(hyperpool).upperTick().getSqrtRatioAtTick(),
            1e18
        );

        share0 =
            (paymentAmount * price0 * share0) /
            (price0 * share0 + price1 * share1);
        share1 = paymentAmount - share0;
    }

    function calculatePrice(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (uint256 price) {
        price =
            _calculatePrice(token0, token1, fee) /
            10**(18 - IERC20Meta(token0).decimals());
    }

    function _calculatePrice(
        address token0,
        address token1,
        uint24 fee
    ) internal view returns (uint256 price) {
        address pool = factory.getPool(token0, token1, fee);
        require(pool != address(0), "!swap pool");

        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        price = token0 > token1
            ? ((1e9 * 2**96) / sqrtRatioX96)**2
            : ((1e9 * sqrtRatioX96) / 2**96)**2;
    }

    /// @notice Uniswap v3 callback fn, called back on pool.swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override swapCallBack nonReentrant {
        (address pool, address payer) = abi.decode(data, (address, address));
        require(_msgSender() == pool, "callback caller");
        if (amount0Delta > 0) {
            IERC20(IUniswapV3Pool(pool).token0()).safeTransferFrom(
                payer,
                pool,
                uint256(amount0Delta)
            );
        } else {
            IERC20(IUniswapV3Pool(pool).token1()).safeTransferFrom(
                payer,
                pool,
                uint256(amount1Delta)
            );
        }
    }

    function _swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        address transferFrom
    ) internal swapCall returns (uint256 amount) {
        if (amountIn == 0) {
            return 0;
        }

        address pool = factory.getPool(tokenIn, tokenOut, fee);
        require(pool != address(0), "!swap pool");

        bool zeroForOne = tokenIn < tokenOut;
        bytes memory callData = abi.encode(pool, transferFrom);

        IUniswapV3Pool(pool).swap(
            address(this),
            zeroForOne,
            amountIn.toInt256(),
            sqrtPriceLimitX96 == 0
                ? (
                    zeroForOne
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : sqrtPriceLimitX96,
            callData
        );
        amount = IERC20(tokenOut).balanceOf(address(this));
        require(amount > 0, "!swap out");
    }

    /**
     * @dev Set a new trusted gas station address
     * @param _gasStation New gas station address
     */
    function setGasStation(address _gasStation) external onlyOwner {
        _setGasStation(_gasStation);
    }

    /**
     * @dev Forwards calls to the this contract and extracts a fee based on provided arguments
     * @param msgData The byte data representing a mint using the original contract.
     * This is either recieved from the Multiswap API directly or we construct it
     * in order to perform a single swap trade
     */
    function route(bytes calldata msgData) external returns (bytes memory) {
        (bool success, bytes memory resultData) = address(this).call(msgData);

        if (!success) {
            _revertWithData(resultData);
        }

        _returnWithData(resultData);
    }

    /**
     * @dev Revert with arbitrary bytes.
     * @param data Revert data.
     */
    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    /**
     * @dev Return with arbitrary bytes.
     */
    function _returnWithData(bytes memory data) private pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}