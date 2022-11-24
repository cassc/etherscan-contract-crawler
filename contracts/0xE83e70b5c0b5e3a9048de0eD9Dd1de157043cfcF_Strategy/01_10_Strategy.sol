// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC20, BaseStrategy} from "BaseStrategy.sol";
import "./libraries/DataTypes.sol";

import "./interfaces/ILendingPool.sol";
import "./interfaces/ILendingPoolAddressesProvider.sol";
import "./interfaces/IProtocolDataProvider.sol";
import "./interfaces/IReserveInterestRateStrategy.sol";

contract Strategy is BaseStrategy {
    IProtocolDataProvider public constant PROTOCOL_DATA_PROVIDER =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    address public immutable aToken;

    constructor(
        address _vault,
        string memory _name
    ) BaseStrategy(_vault, _name) {
        (address _aToken, , ) = PROTOCOL_DATA_PROVIDER
            .getReserveTokensAddresses(asset);
        aToken = _aToken;
    }

    function _maxWithdraw(
        address owner
    ) internal view override returns (uint256) {
        return Math.min(IERC20(asset).balanceOf(aToken), _totalAssets());
    }

    function _freeFunds(
        uint256 _amount
    ) internal returns (uint256 _amountFreed) {
        uint256 _idleAmount = balanceOfAsset();
        if (_amount <= _idleAmount) {
            // we have enough idle assets for the vault to take
            _amountFreed = _amount;
        } else {
            // We need to take from Aave enough to reach _amount
            // Balance of
            // We run with 'unchecked' as we are safe from underflow
            unchecked {
                _withdrawFromAave(
                    Math.min(_amount - _idleAmount, balanceOfAToken())
                );
            }
            _amountFreed = balanceOfAsset();
        }
    }

    function _withdraw(uint256 amount) internal override returns (uint256) {
        return _freeFunds(amount);
    }

    function _totalAssets() internal view override returns (uint256) {
        return balanceOfAsset() + balanceOfAToken();
    }

    function _invest() internal override {
        uint256 _availableToInvest = balanceOfAsset();
        require(_availableToInvest > 0, "no funds to invest");
        _depositToAave(_availableToInvest);
    }

    function _depositToAave(uint256 amount) internal {
        ILendingPool lp = _lendingPool();
        _checkAllowance(address(lp), asset, amount);
        lp.deposit(asset, amount, address(this), 0);
    }

    function _withdrawFromAave(uint256 amount) internal {
        ILendingPool lp = _lendingPool();
        _checkAllowance(address(lp), aToken, amount);
        lp.withdraw(asset, amount, address(this));
    }

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).approve(_contract, 0);
            IERC20(_token).approve(_contract, _amount);
        }
    }

    function _lendingPool() internal view returns (ILendingPool) {
        return
            ILendingPool(
                PROTOCOL_DATA_PROVIDER.ADDRESSES_PROVIDER().getLendingPool()
            );
    }

    function balanceOfAToken() internal view returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    function balanceOfAsset() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function aprAfterDebtChange(int256 delta) external view returns (uint256) {
        // i need to calculate new supplyRate after Deposit (when deposit has not been done yet)
        DataTypes.ReserveData memory reserveData = _lendingPool()
            .getReserveData(address(asset));

        (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            ,
            ,
            ,
            uint256 averageStableBorrowRate,
            ,
            ,

        ) = PROTOCOL_DATA_PROVIDER.getReserveData(address(asset));

        int256 newLiquidity = int256(availableLiquidity) + delta;

        (, , , , uint256 reserveFactor, , , , , ) = PROTOCOL_DATA_PROVIDER
            .getReserveConfigurationData(address(asset));

        (uint256 newLiquidityRate, , ) = IReserveInterestRateStrategy(
            reserveData.interestRateStrategyAddress
        ).calculateInterestRates(
                address(asset),
                uint256(newLiquidity),
                totalStableDebt,
                totalVariableDebt,
                averageStableBorrowRate,
                reserveFactor
            );

        return newLiquidityRate / 1e9; // ray to wad
    }
}