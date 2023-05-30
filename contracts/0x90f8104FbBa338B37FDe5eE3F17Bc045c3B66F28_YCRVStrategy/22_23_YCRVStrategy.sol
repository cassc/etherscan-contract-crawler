// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../integrations/balancer/IBalancerPriceOracle.sol";
import "../integrations/curve/ICurve.sol";

contract YCRVStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    address internal constant yCRVVault =
        0x27B5739e22ad9033bcBf192059122d163b60349D;
    address internal constant yCRV = 0xFCc5c47bE19d06BF83eB04298b026F81069ff65b;
    address internal constant USDC_WETH_BALANCER_POOL =
        0x96646936b91d6B9D7D0c47C496AfBF3D6ec7B6f8;
    address internal constant YCRV_CRV_CURVE_POOL =
        0x453D92C7d4263201C69aACfaf589Ed14202d83a4;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CRV_USDC_UNI_V3_POOL =
        0x9445bd19767F73DCaE6f2De90e6cd31192F62589;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage = 9500; // 5%

    constructor(address _vault) BaseStrategy(_vault) {
        want.approve(CURVE_SWAP_ROUTER, type(uint256).max);
        ERC20(yCRV).approve(CURVE_SWAP_ROUTER, type(uint256).max);
        ERC20(yCRV).approve(yCRVVault, type(uint256).max);
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    function name() external pure override returns (string memory) {
        return "StrategyYearn";
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfStakedYCrv() public view returns (uint256) {
        return IERC20(yCRVVault).balanceOf(address(this));
    }

    function balanceOfYCrv() public view returns (uint256) {
        return IERC20(yCRV).balanceOf(address(this));
    }

    function crvToWant(uint256 crvTokens) public view returns (uint256) {
        (int24 meanTick, ) = OracleLibrary.consult(
            CRV_USDC_UNI_V3_POOL,
            TWAP_RANGE_SECS
        );
        return
            OracleLibrary.getQuoteAtTick(
                meanTick,
                uint128(crvTokens),
                CRV,
                address(want)
            );
    }

    function yCrvToWant(uint256 yCRVTokens) public view returns (uint256) {
        uint256 crvRatio = ICurve(YCRV_CRV_CURVE_POOL).get_virtual_price();
        uint256 crvTokens = (yCRVTokens * 1e18) / crvRatio;
        return crvToWant(crvTokens);
    }

    function stYCRVToWant(uint256 stTokens) public view returns (uint256) {
        uint256 yCRVTokens = (stTokens * VaultAPI(yCRVVault).pricePerShare()) /
            1e18;
        return yCrvToWant(yCRVTokens);
    }

    function wantToStYCrv(
        uint256 wantTokens
    ) public view virtual returns (uint256) {
        uint256 stYCrvRate = 1e36 / stYCRVToWant(1e18);
        return (wantTokens * stYCrvRate) / 1e18;
    }

    function wantToYCrv(uint256 wantTokens) public view returns (uint256) {
        uint256 yCrvRate = 1e36 / yCrvToWant(1e18);
        return (wantTokens * yCrvRate) / 1e18;
    }

    function _scaleDecimals(
        uint _amount,
        ERC20 _fromToken,
        ERC20 _toToken
    ) internal view returns (uint _scaled) {
        uint decFrom = _fromToken.decimals();
        uint decTo = _toToken.decimals();

        if (decTo > decFrom) {
            return _amount * (10 ** (decTo - decFrom));
        } else {
            return _amount / (10 ** (decFrom - decTo));
        }
    }

    function _withdrawSome(uint256 _amountNeeded) internal {
        uint256 yCrvToUnstake = Math.min(
            balanceOfStakedYCrv(),
            wantToStYCrv(_amountNeeded)
        );

        if (yCrvToUnstake > 0) {
            _exitPosition(yCrvToUnstake);
        }
    }

    function _exitPosition(uint256 stYCrvAmount) internal {
        VaultAPI(yCRVVault).withdraw(stYCrvAmount);
        uint256 yCrvBalance = balanceOfYCrv();

        address[9] memory _route = [
            yCRV,
            0x453D92C7d4263201C69aACfaf589Ed14202d83a4, // yCRV pool
            0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
            0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511, // crveth pool
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
            0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
            0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
            0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
            address(want) // USDC
        ];
        uint256[3][4] memory _swap_params = [
            [uint256(1), uint256(0), uint256(1)], // yCRV -> CRV, stable swap exchange
            [uint256(1), uint256(0), uint256(3)], // CRV -> ETH, cryptoswap exchange
            [uint256(2), uint256(0), uint256(3)], // ETH -> USDT, cryptoswap exchange
            [uint256(2), uint256(1), uint256(1)] // USDT -> USDC, stable swap exchange
        ];
        uint256 _expected = (yCrvToWant(yCrvBalance) * slippage) / 10000;
        address[4] memory _pools = [
            address(0),
            address(0),
            address(0),
            address(0)
        ];

        ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
            _route,
            _swap_params,
            yCrvBalance,
            _expected,
            _pools
        );
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view override returns (uint256) {
        IBalancerPriceOracle.OracleAverageQuery[] memory queries;
        queries = new IBalancerPriceOracle.OracleAverageQuery[](1);
        queries[0] = IBalancerPriceOracle.OracleAverageQuery({
            variable: IBalancerPriceOracle.Variable.PAIR_PRICE,
            secs: TWAP_RANGE_SECS,
            ago: 0
        });

        uint256[] memory results;
        results = IBalancerPriceOracle(USDC_WETH_BALANCER_POOL)
            .getTimeWeightedAverage(queries);

        return
            _scaleDecimals(
                (_amtInWei * results[0]) / 1e18,
                ERC20(WETH),
                ERC20(address(want))
            );
    }

    function estimatedTotalAssets()
        public
        view
        virtual
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += yCrvToWant(balanceOfYCrv());
        _wants += stYCRVToWant(balanceOfStakedYCrv());
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

        _withdrawSome(_debtOutstanding + _profit);

        uint256 _liquidWant = want.balanceOf(address(this));

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
        uint256 _wantBal = balanceOfWant();

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            address[9] memory _route = [
                address(want),
                0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7, // 3pool
                0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT
                0xD51a44d3FaE010294C616388b506AcdA1bfAAE46, // tricrypto2 pool
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
                0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511, // crveth pool
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x453D92C7d4263201C69aACfaf589Ed14202d83a4, // yCRV pool
                yCRV // yCRV
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(1), uint256(2), uint256(1)], // USDC -> USDT, stable swap exchange
                [uint256(0), uint256(2), uint256(3)], // USDT -> ETH, cryptoswap exchange
                [uint256(0), uint256(1), uint256(3)], // ETH -> CRV, cryptoswap exchange
                [uint256(0), uint256(1), uint256(1)] // CRV -> yCRV, stable swap exchange
            ];
            uint256 _expected = (wantToYCrv(_excessWant) * slippage) / 10000;
            address[4] memory _pools = [
                address(0),
                address(0),
                address(0),
                address(0)
            ];

            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                _expected,
                _pools
            );
        }

        uint256 _yCrvBal = IERC20(yCRV).balanceOf(address(this));
        if (_yCrvBal > 0) {
            VaultAPI(yCRVVault).deposit(_yCrvBal, address(this));
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(balanceOfStakedYCrv());
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
        IERC20(yCRV).safeTransfer(
            _newStrategy,
            IERC20(yCRV).balanceOf(address(this))
        );
        IERC20(yCRVVault).safeTransfer(
            _newStrategy,
            IERC20(yCRVVault).balanceOf(address(this))
        );
    }

    function protectedTokens()
        internal
        pure
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = yCRV;
        protected[1] = yCRVVault;
        return protected;
    }
}