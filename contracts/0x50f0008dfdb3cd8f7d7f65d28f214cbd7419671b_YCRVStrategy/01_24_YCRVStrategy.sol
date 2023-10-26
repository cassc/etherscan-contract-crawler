// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams, VaultAPI} from "@yearn-protocol/contracts/BaseStrategy.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../utils/Utils.sol";
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
        0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant CRV_USDC_UNI_V3_POOL =
        0x9445bd19767F73DCaE6f2De90e6cd31192F62589;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant CURVE_SWAP_ROUTER =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    uint32 internal constant TWAP_RANGE_SECS = 1800;
    uint256 public slippage;

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(address _vault, address _strategist) external {
        _initialize(_vault, _strategist, _strategist, _strategist);

        want.safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(yCRV).safeApprove(CURVE_SWAP_ROUTER, type(uint256).max);
        IERC20(yCRV).safeApprove(yCRVVault, type(uint256).max);
        slippage = 9800; // 2%
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
        uint256 scaledPrice = (ICurve(
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14
        ).price_oracle(1) * crvTokens) / 1e18;
        return
            Utils.scaleDecimals(scaledPrice, ERC20(CRV), ERC20(address(want)));
    }

    function yCrvToWant(uint256 yCRVTokens) public view returns (uint256) {
        uint256 crvRatio = ICurve(YCRV_CRV_CURVE_POOL).price_oracle();
        uint256 crvTokens = (crvRatio * yCRVTokens) / 1e18;
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
            yCRV, // yCRV
            0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5, // yCRV pool
            0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
            0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
            0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
            0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
            address(want), // USDC
            address(0),
            address(0)
        ];
        uint256[3][4] memory _swap_params = [
            [uint256(1), uint256(0), uint256(1)], // yCRV -> CRV, stable swap exchange
            [uint256(2), uint256(0), uint256(3)], // CRV -> crvUSD, cryptoswap exchange
            [uint256(1), uint256(0), uint256(1)], // crvUSD -> USDC, stable swap exchange
            [uint256(0), uint256(0), uint256(0)]
        ];
        uint256 _expected = (yCrvToWant(yCrvBalance) * slippage) / 10000;

        ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
            _route,
            _swap_params,
            yCrvBalance,
            _expected
        );
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

        uint256 _wantBal = balanceOfWant();

        if (_wantBal > _debtOutstanding) {
            uint256 _excessWant = _wantBal - _debtOutstanding;

            address[9] memory _route = [
                address(want),
                0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E, // crvUSD/USDC pool
                0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E, // crvUSD
                0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TriCRV pool
                0xD533a949740bb3306d119CC777fa900bA034cd52, // CRV
                0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5, // yCRV pool
                yCRV, // yCRV
                address(0),
                address(0)
            ];
            uint256[3][4] memory _swap_params = [
                [uint256(0), uint256(1), uint256(1)], // USDC -> crvUSD, stable swap exchange
                [uint256(0), uint256(2), uint256(3)], // crvUSD -> CRV, cryptoswap exchange
                [uint256(0), uint256(1), uint256(1)], // CRV -> yCRV, stable swap exchange
                [uint256(0), uint256(0), uint256(0)]
            ];

            uint256 _expected = (wantToYCrv(_excessWant) * slippage) / 10000;
            ICurveSwapRouter(CURVE_SWAP_ROUTER).exchange_multiple(
                _route,
                _swap_params,
                _excessWant,
                _expected
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