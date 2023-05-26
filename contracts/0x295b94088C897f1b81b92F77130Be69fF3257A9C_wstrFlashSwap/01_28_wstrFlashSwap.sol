// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import { WETH as IWETH } from "./interfaces/WETH.sol";
import { TreasuryProxy as ITreasuryProxy } from "./interfaces/TreasuryProxy.sol";
import { WSTR as IWSTR } from "./interfaces/WSTR.sol";
import { Ecliptic as IEcliptic } from "./interfaces/Ecliptic.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./Base.sol";

contract wstrFlashSwap is
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments,
    Base
{
    using LowGasSafeMath for uint256;

    ISwapRouter public immutable swapRouter;
    IWETH weth;
    ITreasuryProxy treasury;
    IWSTR wstr;
    IEcliptic ecliptic;

    address public constant _WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant _TREASURYPROXY = 0x3E1efDa147EC9309e1e47782EcaFeDe1d04b45E5;
    address public constant _WSTR = 0xF0dC76C22139ab22618dDFb498BE1283254612B1;
    address public constant _ECLIPTIC = 0x33EeCbf908478C10614626A9D304bfe18B78DD73;
    uint24 constant public POOL_FEE = 10000;

    //  constructor(): configure uniswap router and contract addresses
    //
    constructor(
        ISwapRouter _swapRouter,
        address _factory
    ) 
        payable 
        PeripheryImmutableState(_factory, _WETH9) 
    {
        swapRouter = _swapRouter;
        weth = IWETH(_WETH9);
        treasury = ITreasuryProxy(_TREASURYPROXY);
        wstr = IWSTR(_WSTR);
        ecliptic = IEcliptic(_ECLIPTIC);
    }

    //  uniswapV3FlashCallback(): called by uniswap pool after the flashloan is initiated
    //
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {

        // decode callback data and verify (required logic by uni)
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        // receive flashloan
        address token1 = decoded.poolKey.token1;
        TransferHelper.safeApprove(token1, address(swapRouter), decoded.amount1);

        // set length of array
        uint16[] memory stars  = new uint16[](decoded.depth);

        redeemStars(decoded.targetStar, stars);

        transferTargetStar(decoded.buyer, decoded.targetStar);

        depositStars(stars);

        payback(decoded.amount1, fee1, token1);
    }

    // redeemStars(): redeem WSTR for stars in the treasury
    //
    function redeemStars(
        uint16 targetStar, 
        uint16[] memory stars
    ) internal {

        uint16 j = 0;
        uint16 i = 0;
        while (j != targetStar) {
            j = treasury.redeem();
            stars[i] = j;
            i++;
        }
    }

    // transferTargetStar(): transfer the targeted star to the buyer
    //
    function transferTargetStar(
        address buyer, 
        uint32 targetStar
    ) internal {

        ecliptic.approve(buyer, targetStar);
        ecliptic.transferPoint(targetStar, buyer, true);
    }

    // depositStars(): deposit all remaining stars to retrieve WSTR
    //
    function depositStars(uint16[] memory stars) internal {

        for (uint16 j = 0; j < stars.length - 1; j++) {
            uint16 star = stars[j];
            ecliptic.approve(_TREASURYPROXY, uint256(star));
            treasury.deposit(star);
        }
    }

    // payback(): pay back loaned WSTR plus the pool fee
    //
    function payback(
        uint256 amount1, 
        uint256 fee1, 
        address token1
    ) internal {

        uint256 amount1Owed = LowGasSafeMath.add(amount1, fee1);
        TransferHelper.safeApprove(token1, address(this), amount1Owed);
        pay(token1, address(this), msg.sender, amount1Owed);
    }

    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
        uint24 fee2;
        uint24 fee3;
        uint16 targetStar;
        uint16 depth;
        uint256 wstrAmountOut;
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address buyer;
        PoolAddress.PoolKey poolKey;
        uint24 poolFee2;
        uint24 poolFee3;
        uint16 targetStar;
        uint16 depth;
    }

    // initFlash(): use a flashloan to recover a specific star in the WSTR treasury. The buyer provides
    // the amount of WSTR needed to redeem the target star (1.0) and pay the pool fee (0.01 per star 
    // above the target star). The remainder of the WSTR required to redeem is borrowed with a flashloan.
    //
    function initFlash(FlashParams memory params) external {

        // transfer WSTR from buyer
        TransferHelper.safeTransferFrom(_WSTR, msg.sender, address(this), params.wstrAmountOut);
        
        // set pool params
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee1
        });
        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, poolKey)
        );

        // kickoff the flashloan
        pool.flash(
            address(this),
            params.amount0,
            params.amount1,
            abi.encode(
                FlashCallbackData({
                    amount0: params.amount0,
                    amount1: params.amount1,
                    buyer: msg.sender,
                    poolKey: poolKey,
                    poolFee2: params.fee2,
                    poolFee3: params.fee3,
                    targetStar: params.targetStar,
                    depth: params.depth
                })
            )
        );
    }

    // initFlashWithSwap(): use a swap and a flashloan to recover a specific  
    // star in the WSTR treasury. The buyer just provides ETH.
    //
    function initFlashWithSwap(FlashParams memory params) external payable {

        // convert ETH to WETH
        uint256 amountInMaximum = msg.value;
        weth.deposit{ value: amountInMaximum }();

        // approve transfer and swap WETH for WSTR
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountInMaximum);
        ISwapRouter.ExactOutputSingleParams memory swapParams =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _WETH9,
                tokenOut: _WSTR,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: params.wstrAmountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });
        uint256 amountIn = swapRouter.exactOutputSingle(swapParams);

        // transfer unspent WETH back to buyer
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(_WETH9, address(swapRouter), amountInMaximum - amountIn);
            TransferHelper.safeTransfer(_WETH9, msg.sender, amountInMaximum - amountIn);
        }

        // set pool params
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee1
        });
        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, poolKey)
        );

        // kickoff the flashloan
        pool.flash(
            address(this),
            params.amount0,
            params.amount1,
            abi.encode(
                FlashCallbackData({
                    amount0: params.amount0,
                    amount1: params.amount1,
                    buyer: msg.sender,
                    poolKey: poolKey,
                    poolFee2: params.fee2,
                    poolFee3: params.fee3,
                    targetStar: params.targetStar,
                    depth: params.depth
                })
            )
        );
    }

    // initSwapStarForETH(): convert seller's star to WSTR then swap for ETH
    //
    function initSwapStarForETH(
        uint32 star,
        uint256 amountOutMinimum
    ) external {

        // caller must be owner of the star
        require(msg.sender == ecliptic.ownerOf(uint256(star)), "msg.sender does not own star");

        // transfer star from seller to contract
        ecliptic.transferPoint(star, address(this), true);

        // approve transfer and deposit star into treasury
        ecliptic.approve(_TREASURYPROXY, uint16(star));
        treasury.deposit(uint16(star));

        // approve transfer and swap WSTR for WETH
        uint256 amountIn = 1e18;
        TransferHelper.safeApprove(_WSTR, address(swapRouter), amountIn);
        ISwapRouter.ExactInputSingleParams memory swapParams =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _WSTR,
                tokenOut: _WETH9,
                fee: POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = swapRouter.exactInputSingle(swapParams);

        // convert WETH to ETH and transfer balance to seller
        weth.withdraw(amountOut);
        msg.sender.transfer(address(this).balance);
    }

}