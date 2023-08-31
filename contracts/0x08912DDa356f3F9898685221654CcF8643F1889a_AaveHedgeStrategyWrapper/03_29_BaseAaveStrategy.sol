// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseLendingStrategy, IERC20Metadata} from "./BaseLendingStrategy.sol";
import {IAavePool} from "contracts/interfaces/ext/aave/IAavePool.sol";
import {IAavePriceOracle} from "contracts/interfaces/ext/aave/IAavePriceOracle.sol";
import {IAavePoolAddressesProvider} from "contracts/interfaces/ext/aave/IAavePoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseAaveStrategy is BaseLendingStrategy {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    IAavePool private immutable aavePool;
    IAavePriceOracle private immutable aavePriceOracle;

    IERC20 private immutable debtToken;
    IERC20 private immutable aToken;

    constructor(IAavePool _aavePool) {
        aavePool = _aavePool;
        aavePriceOracle = IAavePriceOracle(IAavePoolAddressesProvider(aavePool.ADDRESSES_PROVIDER()).getPriceOracle());

        debtToken = IERC20(aavePool.getReserveData(address(tokenToBorrow)).variableDebtTokenAddress);
        aToken = IERC20(aavePool.getReserveData(address(collateral)).aTokenAddress);

        tokenToBorrow.safeIncreaseAllowance(address(aavePool), type(uint256).max);
        collateral.safeIncreaseAllowance(address(aavePool), type(uint256).max);
        aToken.safeIncreaseAllowance(address(aavePool), type(uint256).max);
    }

    function _getCurrentDebt() internal view override returns (uint256) {
        return debtToken.balanceOf(address(this));
    }

    function _getCurrentCollateral() internal view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    modifier doNothingIfZero(uint256 amount) {
        if (amount != 0) {
            _;
        }
    }

    function _supply(uint256 amount) internal override doNothingIfZero(amount) {
        aavePool.supply(address(collateral), amount, address(this), 0);
    }

    function _borrow(uint256 amount) internal override doNothingIfZero(amount) {
        aavePool.borrow(address(tokenToBorrow), amount, 2, 0, address(this));
    }

    function _repay(uint256 amount) internal override doNothingIfZero(amount) {
        aavePool.repay(address(tokenToBorrow), amount, 2, address(this));
    }

    function _withdraw(uint256 amount) internal override doNothingIfZero(amount) {
        aavePool.withdraw(address(collateral), amount, address(this));
    }

    function _getTokenToBorrowPrice() internal view override returns (uint256) {
        return aavePriceOracle.getAssetPrice(address(tokenToBorrow));
    }

    function _getCollateralPrice() internal view override returns (uint256) {
        return aavePriceOracle.getAssetPrice(address(collateral));
    }

    function getLendingPositionState()
        public
        view
        override
        returns (BaseLendingStrategy.LendingPositionState memory state)
    {
        // TODO we should consider not duplicating this code
        // We can't call _getCurrentDebt() and _getCurrentCollateral() because they are non-view
        state.debt = debtToken.balanceOf(address(this));
        state.collateral = aToken.balanceOf(address(this));
    }
}