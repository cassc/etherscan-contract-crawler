// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/curve/ICurve.sol";
import "../integrations/convex/IConvexRewards.sol";
import "../integrations/convex/IConvexDeposit.sol";
import "../integrations/uniswap/v3/IV3SwapRouter.sol";
import "../integrations/frax/IFraxRouter.sol";

import "../utils/Utils.sol";
import "../utils/CVXRewards.sol";

contract FXSStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address internal constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address internal constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;
    address internal constant CONVEX_CVX_REWARD_POOL =
        0xf16Fc1571E9e26Abff127D7790931E99f75A276e;

    address internal constant FXS_FRAX_UNI_V3_POOL =
        0xb64508B9f7b81407549e13DB970DD5BB5C19107F;

    address internal constant CURVE_FXS_POOL =
        0x6a9014FB802dCC5efE3b97Fd40aAa632585636D0;

    address internal constant FXS_CONVEX_DEPOSIT =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address internal constant FXS_CONVEX_CRV_REWARDS =
        0x19F3C877eA278e61fE1304770dbE5D78521792D2;

    address internal constant FRAX_ROUTER_V2 =
        0xC14d550632db8592D1243Edc8B95b0Ad06703867;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    uint256 private WANT_DECIMALS;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        IERC20(CRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CVX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(CURVE_FXS_POOL).safeApprove(
            FXS_CONVEX_DEPOSIT,
            type(uint256).max
        );
        IERC20(FXS).safeApprove(CURVE_FXS_POOL, type(uint256).max);
        IERC20(FRAX).safeApprove(FRAX_ROUTER_V2, type(uint256).max);
        IERC20(FRAX).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(FXS).safeApprove(FRAX_ROUTER_V2, type(uint256).max);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        WANT_DECIMALS = ERC20(address(want)).decimals();
        slippage = 9800; // 2%
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyFXS";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfFrax() public view returns (uint256) {
        return IERC20(FRAX).balanceOf(address(this));
    }

    function balanceOfFxs() public view returns (uint256) {
        return IERC20(FXS).balanceOf(address(this));
    }

    function balanceOfCurveLPUnstaked() public view returns (uint256) {
        return ERC20(CURVE_FXS_POOL).balanceOf(address(this));
    }

    function balanceOfCurveLPStaked() public view returns (uint256) {
        return IConvexRewards(FXS_CONVEX_CRV_REWARDS).balanceOf(address(this));
    }

    function balanceOfCrvRewards() public view virtual returns (uint256) {
        return IConvexRewards(FXS_CONVEX_CRV_REWARDS).earned(address(this));
    }

    function balanceOfFxsRewards() public view returns (uint256) {
        return 0;
    }

    function balanceOfCvxRewards(
        uint256 crvRewards
    ) public view virtual returns (uint256) {
        return
            IConvexRewards(CONVEX_CVX_REWARD_POOL).earned(address(this)) +
            CVXRewardsMath.convertCrvToCvx(crvRewards);
    }

    function lpPriceOracle() public view returns (uint256) {
        uint256 virtualPrice = ICurve(CURVE_FXS_POOL).get_virtual_price();
        uint256 priceOracle = ICurve(CURVE_FXS_POOL).price_oracle();
        return (virtualPrice * _sqrtInt(priceOracle)) / 1e18;
    }

    function lpPrice() public view returns (uint256) {
        return ICurve2(CURVE_FXS_POOL).calc_withdraw_one_coin(1e18, int128(0));
    }

    function curveLPToWant(uint256 _lpTokens) public view returns (uint256) {
        uint256 fxsAmount = (
            _lpTokens > 0 ? (lpPrice() * _lpTokens) / 1e18 : 0
        );
        return fxsToWant(fxsAmount);
    }

    function wantToCurveLP(
        uint256 _want
    ) public view virtual returns (uint256) {
        uint256 oneCurveLPPrice = curveLPToWant(1e18);
        return (_want * 1e18) / oneCurveLPPrice;
    }

    function _sqrtInt(uint256 x) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = (x + 1e18) / 2;
        uint256 y = x;

        for (uint256 i = 0; i < 256; i++) {
            if (z == y) return y;
            y = z;
            z = ((x * 1e18) / z + z) / 2;
        }

        return y;
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        if (_amountNeeded == 0) {
            return;
        }

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 earnedFxs = balanceOfFxsRewards();
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 totalFxs = earnedFxs + ERC20(FXS).balanceOf(address(this));
        uint256 rewardsTotal = crvToWant(totalCrv) +
            cvxToWant(totalCvx) +
            fxsToWant(totalFxs);

        if (rewardsTotal >= _amountNeeded) {
            IConvexRewards(FXS_CONVEX_CRV_REWARDS).getReward(
                address(this),
                true
            );
            _sellCrvAndCvx(
                ERC20(CRV).balanceOf(address(this)),
                ERC20(CVX).balanceOf(address(this))
            );
            _sellFxs(ERC20(FXS).balanceOf(address(this)));
        } else {
            uint256 lpTokensToWithdraw = Math.min(
                wantToCurveLP(_amountNeeded - rewardsTotal),
                balanceOfCurveLPStaked()
            );
            _exitPosition(lpTokensToWithdraw);
        }
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B
        ).price_oracle(1) * _amtInWei) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(WETH), ERC20(address(want)));
    }

    function fraxToWant(uint256 fraxTokens) public view returns (uint256) {
        return
            Utils.scaleDecimals(fraxTokens, ERC20(FRAX), ERC20(address(want)));
    }

    function wantToFrax(uint256 wantTokens) public view returns (uint256) {
        return
            Utils.scaleDecimals(wantTokens, ERC20(address(want)), ERC20(FRAX));
    }

    function fraxToFxs(uint256 fraxTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(fraxTokens),
                FRAX,
                FXS
            );
    }

    function fxsToFrax(uint256 fxsTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(fxsTokens),
                FXS,
                FRAX
            );
    }

    function fxsToWant(uint256 fxsTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            FXS_FRAX_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            fraxToWant(
                OracleLibrary.getQuoteAtTick(
                    meanTick,
                    uint128(fxsTokens),
                    FXS,
                    FRAX
                )
            );
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function cvxToWant(uint256 cvxTokens) public view returns (uint256) {
        uint256 scaledPrice = (ICurve(
            0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4
        ).price_oracle() * cvxTokens) / 1e18;
        return ethToWant(scaledPrice);
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += curveLPToWant(
            balanceOfCurveLPStaked() + balanceOfCurveLPUnstaked()
        );

        uint256 earnedCrv = balanceOfCrvRewards();
        uint256 earnedCvx = balanceOfCvxRewards(earnedCrv);
        uint256 earnedFxs = balanceOfFxsRewards();
        uint256 totalCrv = earnedCrv + ERC20(CRV).balanceOf(address(this));
        uint256 totalCvx = earnedCvx + ERC20(CVX).balanceOf(address(this));
        uint256 totalFxs = earnedFxs + ERC20(FXS).balanceOf(address(this));

        _wants += crvToWant(totalCrv);
        _wants += cvxToWant(totalCvx);
        _wants += fxsToWant(totalFxs);
    }

    function prepareReturn(
        uint256 _debtOutstanding
    )
        internal
        override
        returns (uint256 _profit, uint256 _loss, uint256 _debtPayment)
    {
        uint256 _totalAssets = estimatedTotalAssets();
        uint256 _totalDebt = vault.strategies(address(this)).totalDebt;

        if (_totalAssets >= _totalDebt) {
            _profit = _totalAssets - _totalDebt;
            _loss = 0;
        } else {
            _profit = 0;
            _loss = _totalDebt - _totalAssets;
        }

        uint256 _liquidWant = balanceOfWant();
        uint256 _amountNeeded = _debtOutstanding + _profit;
        if (_liquidWant <= _amountNeeded) {
            _withdrawSome(_amountNeeded - _liquidWant);
            _liquidWant = balanceOfWant();
        }

        // enough to pay profit (partial or full) only
        if (_liquidWant <= _profit) {
            _profit = _liquidWant;
            _debtPayment = 0;
            // enough to pay for all profit and _debtOutstanding (partial or full)
        } else {
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (emergencyExit) {
            return;
        }

        IConvexRewards(FXS_CONVEX_CRV_REWARDS).getReward(address(this), true);
        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 _wantBal = balanceOfWant();

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;
            uint256 fraxExpected = (wantToFrax(_excessWant) * slippage) /
                10_000;

            address[9] memory _route = [
                address(want),
                0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2, // fraxusdc pool
                FRAX, // FRAX
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(1)], // USDC -> FRAX, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                fraxExpected
            );
        }

        if (balanceOfFrax() > 0) {
            uint256 fraxBalance = balanceOfFrax();
            uint256 fxsExpected = (fraxToFxs(fraxBalance) * slippage) / 10_000;
            address[] memory path = new address[](2);
            path[0] = FRAX;
            path[1] = FXS;

            IUniswapV2Router01V5(FRAX_ROUTER_V2).swapExactTokensForTokens(
                fraxBalance,
                fxsExpected,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 fxsBalance = ERC20(FXS).balanceOf(address(this));
        if (fxsBalance > 0) {
            uint256 lpExpected = (fxsBalance * 1e18) / lpPrice();
            uint256[2] memory amounts = [fxsBalance, uint256(0)];
            ICurve(CURVE_FXS_POOL).add_liquidity(
                amounts,
                (lpExpected * slippage) / 10000,
                address(this)
            );
        }

        if (balanceOfCurveLPUnstaked() > 0) {
            require(
                IConvexDeposit(FXS_CONVEX_DEPOSIT).depositAll(
                    uint256(203),
                    true
                ),
                "Convex staking failed"
            );
        }
    }

    function _cvxToCrv(uint256 cvxTokens) internal view returns (uint256) {
        uint256 wantAmount = cvxToWant(cvxTokens);
        uint256 oneCrv = crvToWant(1 ether);
        return (wantAmount * (10 ** WANT_DECIMALS)) / oneCrv;
    }

    function _sellCrvAndCvx(uint256 _crvAmount, uint256 _cvxAmount) internal {
        if (_cvxAmount > 0) {
            address[9] memory _route = [
                CVX, // CVX
                0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4, // cvxeth pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                CRV, // CRV
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(0), uint256(3)], // CVX -> WETH, cryptoswap exchange
                [uint256(1), uint256(2), uint256(3)], // WETH -> CRV, cryptoswap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (_cvxToCrv(_cvxAmount) * slippage) / 10000;

            _crvAmount += ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _cvxAmount,
                _expected
            );
        }

        if (_crvAmount > 0) {
            address[9] memory _route = [
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                address(want),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
                [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            uint256 _expected = (crvToWant(_crvAmount) * slippage) / 10000;

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _crvAmount,
                _expected
            );
        }
    }

    function _exitPosition(uint256 _stakedLpTokens) internal {
        IConvexRewards(FXS_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            _stakedLpTokens,
            true
        );

        _sellCrvAndCvx(
            ERC20(CRV).balanceOf(address(this)),
            ERC20(CVX).balanceOf(address(this))
        );

        uint256 lpTokens = balanceOfCurveLPUnstaked();
        uint256 withdrawAmount = ICurve2(CURVE_FXS_POOL).calc_withdraw_one_coin(
            lpTokens,
            int128(0)
        );
        ICurve(CURVE_FXS_POOL).remove_liquidity_one_coin(
            lpTokens,
            int128(0),
            (withdrawAmount * slippage) / 10000,
            address(this)
        );

        _sellFxs(ERC20(FXS).balanceOf(address(this)));
    }

    function _sellFxs(uint256 fxsAmount) internal {
        if (fxsAmount > 0) {
            uint256 fraxExpected = (fxsToFrax(fxsAmount) * slippage) / 10_000;
            address[] memory path = new address[](2);
            path[0] = FXS;
            path[1] = FRAX;

            IUniswapV2Router01V5(FRAX_ROUTER_V2).swapExactTokensForTokens(
                fxsAmount,
                fraxExpected,
                path,
                address(this),
                block.timestamp
            );
        }

        uint256 fraxBalance = balanceOfFrax();
        if (fraxBalance > 0) {
            uint256 wantExpected = (fraxToWant(fraxBalance) * slippage) /
                10_000;

            address[9] memory _route = [
                FRAX, // FRAX
                0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2, // fraxusdc pool
                address(want), // USDC
                address(0),
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(1), uint256(1)], // USDC -> FRAX, stable swap exchange
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)],
                [uint256(0), uint256(0), uint256(0)]
            ];
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                fraxBalance,
                wantExpected
            );
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfCurveLPStaked());
        return want.balanceOf(address(this));
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wantBal = want.balanceOf(address(this));
        if (_wantBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        _withdrawSome(_amountNeeded - _wantBal);
        _wantBal = want.balanceOf(address(this));

        if (_amountNeeded > _wantBal) {
            _liquidatedAmount = _wantBal;
            _loss = _amountNeeded - _wantBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function prepareMigration(address _newStrategy) internal override {
        IConvexRewards(FXS_CONVEX_CRV_REWARDS).withdrawAndUnwrap(
            balanceOfCurveLPStaked(),
            true
        );
        IERC20(CRV).safeTransfer(
            _newStrategy,
            IERC20(CRV).balanceOf(address(this))
        );
        IERC20(FXS).safeTransfer(
            _newStrategy,
            IERC20(FXS).balanceOf(address(this))
        );
        IERC20(CVX).safeTransfer(
            _newStrategy,
            IERC20(CVX).balanceOf(address(this))
        );
        IERC20(CURVE_FXS_POOL).safeTransfer(
            _newStrategy,
            IERC20(CURVE_FXS_POOL).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](4);
        protected[0] = CVX;
        protected[1] = CRV;
        protected[2] = FXS;
        protected[3] = CURVE_FXS_POOL;
        return protected;
    }
}