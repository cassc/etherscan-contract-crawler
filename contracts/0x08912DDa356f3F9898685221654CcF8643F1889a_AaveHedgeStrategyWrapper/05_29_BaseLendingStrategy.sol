// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract BaseLendingStrategy {
    struct LendingPositionState {
        uint256 collateral;
        uint256 debt;
    }

    IERC20Metadata public immutable collateral;
    IERC20Metadata public immutable tokenToBorrow;

    constructor(IERC20Metadata _collateral, IERC20Metadata _tokenToBorrow) {
        collateral = _collateral;
        tokenToBorrow = _tokenToBorrow;
    }

    function _getCurrentDebt() internal virtual returns (uint256);
    function _getCurrentCollateral() internal virtual returns (uint256);

    // @dev must fetch price from lending protocol's oracle
    function _getCollateralPrice() internal view virtual returns (uint256);
    // @dev must fetch price from lending protocol's oracle
    function _getTokenToBorrowPrice() internal view virtual returns (uint256);

    function _getCurrentLTV() internal returns (uint256) {
        uint256 debtValue = _getTokenToBorrowPrice() * _getCurrentDebt() / (10 ** tokenToBorrow.decimals());
        uint256 collateralValue = _getCollateralPrice() * _getCurrentCollateral() / (10 ** collateral.decimals());

        if ((debtValue == 0) || (collateralValue == 0)) {
            return 0;
        }
        return debtValue * (10 ** 6) / collateralValue;
    }

    function _getNeededDebt(uint256 collateralAmount, uint256 ltv) internal view returns (uint256 neededDebt) {
        uint256 collateralValue = collateralAmount * _getCollateralPrice() / (10 ** collateral.decimals());
        uint256 neededDebtValue = collateralValue * ltv / (10 ** 6);
        neededDebt = neededDebtValue * (10 ** tokenToBorrow.decimals()) / _getTokenToBorrowPrice();
    }

    function _supply(uint256) internal virtual;
    function _borrow(uint256) internal virtual;

    function _repay(uint256) internal virtual;
    function _withdraw(uint256) internal virtual;

    function _repayAndWithdrawProportionally(uint256 amountToRepay) internal returns (uint256 amountToWithdraw) {
        amountToWithdraw = amountToRepay * _getCurrentCollateral() / _getCurrentDebt();
        _repay(amountToRepay);
        _withdraw(amountToWithdraw);
    }

    function getLendingPositionState() public view virtual returns (LendingPositionState memory);
}