// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/aave/IAaveLendingPoolV2.sol";
import "../interfaces/curve/ICurvePool.sol";
import "../interfaces/stargate/IStargateRouter.sol";
import "../interfaces/compound/ICToken.sol";
import "../interfaces/IUnwrapLp.sol";

contract UnwrapLp is Initializable, IUnwrapLp {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 3;

    // Regular assets
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Stargate aTokens
    address public constant aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

    // Stargate sTokens
    address public constant sUSDC = 0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56;
    address public constant sUSDT = 0x38EA452219524Bb87e18dE1C24D3bB59510BD783;

    // Compound cTokens
    address public constant cUSDT = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    // Curve lp tokens
    address public constant CurveTricrypto2Lp = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    address public constant Curve3PoolLp = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant CurveTUSDLp = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address public constant CurveCompoundLp = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address public constant CurveFraxUSDLp = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address public constant CurveBUSDv2Lp = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address public constant CurveAaveLp = 0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;

    // Curve pools
    address public constant CurveTricrypto2Pool = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address public constant Curve3Pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant CurveTUSDPool = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address public constant CurveCompoundPool = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public constant CurveFraxUSDPool = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address public constant CurveBUSDv2Pool = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address public constant CurveAavePool = 0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;

    // Platforms
    address public constant AaveLendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant ConvexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant StargateRouter = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;

    function initialize() public initializer {
        // silent
    }

    /**
     * @notice unwrap
     * @param assetLp assetLp
     * @param amount amount
     * @return asset
     * @return receivedAmount
     **/
    function unwrap(address assetLp, uint256 amount) external override returns (address, uint256) {
        IERC20Upgradeable(assetLp).safeTransferFrom(msg.sender, address(this), amount);

        if (assetLp == CurveTricrypto2Lp) {
            return unwrapCurveTriCrypto2(amount);
        }

        else if (assetLp == Curve3PoolLp) {
            return unwrapCurve3Pool(amount);
        }

        else if (assetLp == CurveTUSDLp) {
            return unwrapCurveTUSD(amount);
        }

        else if (assetLp == CurveCompoundLp) {
            return unwrapCurveCompound(amount);
        }

        else if (assetLp == CurveFraxUSDLp) {
            return unwrapCurveFraxUSD(amount);
        }

        else if (assetLp == CurveBUSDv2Lp) {
            return unwrapCurveBUSDv2(amount);
        }

        else if (assetLp == CurveAaveLp) {
            return unwrapCurveAave(amount);
        }

        else if (assetLp == sUSDC) {
            return unwrapSUSDC(amount);
        }

        else if (assetLp == sUSDT) {
            return unwrapSUSDT(amount);
        }

        else {
            revert("pool not supported yet");
        }
    }

    function unwrapCurveTriCrypto2(uint256 amount) internal returns (address, uint256) {
        // only want USDT from USDT+BTC+WETH LP
        uint256[3] memory min_amounts = [uint256(100), 0, 0];
        ICurvePool(CurveTricrypto2Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurve3Pool(uint256 amount) internal returns (address, uint256) {
        // only want USDT from DAI+USDC+USDT LP
        uint256[3] memory min_amounts = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveTUSD(uint256 amount) internal returns (address, uint256) {
        // only want 3CRV from tUSDT/3CRV LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveTUSDPool).remove_liquidity(amount, min_amounts);

        uint256 receivedCrv3Pool = IERC20Upgradeable(Curve3PoolLp).balanceOf(address(this));

        // only want USDT from DAI/USDC/USDT LP (3CRV)
        uint256[3] memory min_amounts_3crv = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(receivedCrv3Pool, min_amounts_3crv);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveFraxUSD(uint256 amount) internal returns (address, uint256) {
        // only want USDC from frax/USDC LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveFraxUSDPool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this));

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapCurveBUSDv2(uint256 amount) internal returns (address, uint256) {
        // only want 3Crv from BUSD/3CRV LP
        uint256[2] memory min_amounts = [uint256(100), 0];
        ICurvePool(CurveBUSDv2Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedCrv3Pool = IERC20Upgradeable(Curve3PoolLp).balanceOf(address(this));

        // only want USDT from DAI/USDC/USDT LP (3CRV)
        uint256[3] memory min_amounts_3crv = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(receivedCrv3Pool, min_amounts_3crv);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveCompound(uint256 amount) internal returns (address, uint256) {
        // only want cUSDC from cDAI/cUSDC LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveCompoundPool).remove_liquidity(amount, min_amounts);

        // unwrap USDC from cUSDC
        uint receivedCTokenBalance = uint(ICToken(cUSDC).balanceOf(address(this)));
        ICToken(cUSDC).redeem(receivedCTokenBalance);

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this));

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapCurveAave(uint256 amount) internal returns (address, uint256) {
        // only want aUSDT from aDAI/aUSDC/aUSDT LP
        uint256[3] memory min_amounts = [0, 0, uint256(100)];
        ICurvePool(CurveAavePool).remove_liquidity(amount, min_amounts);

        // unwrap USDT from aUSDT
        uint receivedATokenBalance = IERC20Upgradeable(aUSDT).balanceOf(address(this));
        IAaveLendingPoolV2(AaveLendingPool).withdraw(USDT, receivedATokenBalance, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapSUSDC(uint256 amount) internal returns (address, uint256) {
        uint256 balancePrior = IERC20Upgradeable(USDC).balanceOf(address(this));

        IStargateRouter(StargateRouter).instantRedeemLocal(1, amount, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this)) - balancePrior;

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapSUSDT(uint256 amount) internal returns (address, uint256) {
        uint256 balancePrior = IERC20Upgradeable(USDT).balanceOf(address(this));

        IStargateRouter(StargateRouter).instantRedeemLocal(2, amount, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this)) - balancePrior;

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function getAssetOut(address assetLp) external pure returns (address) {
        if (
            assetLp == CurveTricrypto2Lp ||
            assetLp == Curve3PoolLp ||
            assetLp == CurveTUSDLp ||
            assetLp == CurveBUSDv2Lp ||
            assetLp == CurveAaveLp ||
            assetLp == sUSDT
        ) {
            return USDT;
        }

        else if (
            assetLp == CurveCompoundLp ||
            assetLp == CurveFraxUSDLp ||
            assetLp == sUSDC
        ) {
            return USDC;
        }

        else {
            revert("pool not supported yet");
        }
    }
}