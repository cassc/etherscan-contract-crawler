// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.18;

import {BaseStrategy, StrategyParams} from "@yearn-protocol/contracts/BaseStrategy.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../integrations/weth/IWETH.sol";
import "../integrations/frax/IFraxMinter.sol";
import "../integrations/frax/ISfrxEth.sol";
import "../integrations/curve/ICurve.sol";

contract FraxStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    address internal constant fraxMinter =
        0xbAFA44EFE7901E04E39Dad13167D089C559c1138;
    address internal constant sfrxEth =
        0xac3E018457B222d93114458476f3E3416Abbe38F;
    address internal constant frxEth =
        0x5E8422345238F34275888049021821E8E08CAa1f;
    address internal constant frxEthCurvePool =
        0xa1F8A6807c402E4A15ef4EBa36528A3FED24E577;
    address internal constant curveSwapRouter =
        0x99a58482BD75cbab83b27EC03CA68fF489b5788f;

    uint256 public slippage = 9990; // 0.1%

    constructor(address _vault) BaseStrategy(_vault) {
        IERC20(frxEth).approve(curveSwapRouter, type(uint256).max);
    }

    function name() external view override returns (string memory) {
        return "StrategyFrax";
    }

    /// @notice Balance of want sitting in our strategy.
    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function estimatedTotalAssets()
        public
        view
        override
        returns (uint256 _wants)
    {
        _wants = balanceOfWant();
        _wants += address(this).balance;
        _wants += sfrxToWant(IERC20(sfrxEth).balanceOf(address(this)));
        _wants += frxToWant(IERC20(frxEth).balanceOf(address(this)));
        return _wants;
    }

    function sfrxToWant(uint256 _amount) public view returns (uint256) {
        return frxToWant(ISfrxEth(sfrxEth).previewRedeem(_amount));
    }

    function wantToSfrx(uint256 _amount) public view returns (uint256) {
        return ISfrxEth(sfrxEth).previewWithdraw(wantToFrx(_amount));
    }

    function frxToWant(uint256 _amount) public view returns (uint256) {
        return (ICurve(frxEthCurvePool).price_oracle() * _amount) / 1e18;
    }

    function wantToFrx(uint256 _amount) public view returns (uint256) {
        return (_amount * 1e18) / ICurve(frxEthCurvePool).price_oracle();
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

        withdrawSome(_debtOutstanding + _profit);

        uint256 _liquidWant = want.balanceOf(address(this));

        if (_liquidWant <= _profit) {
            // enough to pay profit (partial or full) only
            _profit = _liquidWant;
            _debtPayment = 0;
        } else {
            // enough to pay for all profit and _debtOutstanding (partial or full)
            _debtPayment = Math.min(_liquidWant - _profit, _debtOutstanding);
        }
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        if (IERC20(frxEth).balanceOf(address(this)) > 0) {
            _sellAllFrx();
        }
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal > _debtOutstanding) {
            uint256 _excessWeth = _wethBal - _debtOutstanding;
            IWETH(address(want)).withdraw(_excessWeth);
        }
        if (address(this).balance > 0) {
            IFraxMinter(fraxMinter).submitAndDeposit{
                value: address(this).balance
            }(address(this));
        }
    }

    function withdrawSome(uint256 _amountNeeded) internal {
        uint256 sfrxToUnstake = Math.min(
            wantToSfrx(_amountNeeded),
            IERC20(sfrxEth).balanceOf(address(this))
        );
        if (sfrxToUnstake > 0) {
            _exitPosition(sfrxToUnstake);
        }
    }

    function liquidatePosition(
        uint256 _amountNeeded
    ) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        uint256 _wethBal = want.balanceOf(address(this));
        if (_wethBal >= _amountNeeded) {
            return (_amountNeeded, 0);
        }

        withdrawSome(_amountNeeded);

        _wethBal = want.balanceOf(address(this));
        if (_amountNeeded > _wethBal) {
            _liquidatedAmount = _wethBal;
            _loss = _amountNeeded - _wethBal;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        _exitPosition(IERC20(sfrxEth).balanceOf(address(this)));
        return want.balanceOf(address(this));
    }

    function _exitPosition(uint256 _sfrxToUnstake) internal {
        ISfrxEth(sfrxEth).redeem(_sfrxToUnstake, address(this), address(this));
        _sellAllFrx();
    }

    function _sellAllFrx() internal {
        uint256 _frxAmount = IERC20(frxEth).balanceOf(address(this));
        uint256 _minAmountOut = (frxToWant(_frxAmount) * slippage) / 10000;
        address[9] memory _route = [
            frxEth, // FRX
            frxEthCurvePool, // frxeth pool
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // ETH
            address(want), // no pool for ETH->WETH
            address(want), // wETH
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        uint256[3][4] memory _swap_params = [
            [uint256(1), uint256(0), uint256(1)], // FRX -> ETH, stableswap exchange
            [uint256(0), uint256(0), uint256(15)], // ETH -> WETH, special 15 op
            [uint256(0), uint256(0), uint256(0)],
            [uint256(0), uint256(0), uint256(0)]
        ];
        address[4] memory _pools = [
            address(0),
            address(0),
            address(0),
            address(0)
        ];
        ICurveSwapRouter(curveSwapRouter).exchange_multiple(
            _route,
            _swap_params,
            _frxAmount,
            _minAmountOut,
            _pools
        );
    }

    function prepareMigration(address _newStrategy) internal override {
        uint256 sfrxBal = IERC20(sfrxEth).balanceOf(address(this));
        if (sfrxBal > 0) {
            IERC20(sfrxEth).safeTransfer(_newStrategy, sfrxBal);
        }
        uint256 frxBal = IERC20(frxEth).balanceOf(address(this));
        if (frxBal > 0) {
            IERC20(frxEth).safeTransfer(_newStrategy, frxBal);
        }
        uint256 ethBal = address(this).balance;
        if (ethBal > 0) {
            payable(_newStrategy).transfer(ethBal);
        }
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {
        address[] memory protected = new address[](2);
        protected[0] = sfrxEth;
        protected[1] = frxEth;
        return protected;
    }

    function ethToWant(
        uint256 _amtInWei
    ) public view virtual override returns (uint256) {
        return _amtInWei;
    }

    function setSlippage(uint256 _slippage) external onlyStrategist {
        require(_slippage < 10_000, "!_slippage");
        slippage = _slippage;
    }

    receive() external payable {}
}