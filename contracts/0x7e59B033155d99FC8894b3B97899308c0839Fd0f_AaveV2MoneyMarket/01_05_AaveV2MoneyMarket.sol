// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';

import '../dependencies/aave/ILendingPool.sol';

import '../libraries/helpers/Errors.sol';

contract AaveV2MoneyMarket is IOpenSkyMoneyMarket {
    address private immutable original;

    ILendingPool public immutable aave;

    constructor(ILendingPool aave_) {
        aave = aave_;
        original = address(this);
    }

    function _requireDelegateCall() private view {
        require(address(this) != original, Errors.MONEY_MARKET_REQUIRE_DELEGATE_CALL);
    }

    modifier requireDelegateCall() {
        _requireDelegateCall();
        _;
    }

    function depositCall(address asset, uint256 amount) external override requireDelegateCall {
        require(amount > 0, Errors.MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED);
        _approveToken(asset, amount);
        aave.deposit(asset, amount, address(this), uint16(0));
    }

    function _approveToken(address asset, uint256 amount) internal virtual {
        require(IERC20(asset).approve(address(aave), amount), Errors.MONEY_MARKET_APPROVAL_FAILED);
    }

    function withdrawCall(address asset, uint256 amount, address to) external override requireDelegateCall {
        require(amount > 0, Errors.MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED);

        _approveAToken(asset, amount);
        uint256 withdrawn = aave.withdraw(asset, amount, to);
        require(withdrawn == amount, Errors.MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH);
    }

    function _approveAToken(address asset, uint256 amount) internal virtual {
        address aToken = getMoneyMarketToken(asset);
        require(IERC20(aToken).approve(address(aave), amount), Errors.MONEY_MARKET_APPROVAL_FAILED);
    }

    function getMoneyMarketToken(address asset) public view override virtual returns (address) {
        address aToken = aave.getReserveData(asset).aTokenAddress;

        return aToken;
    }

    function getBalance(address asset, address account) external view override returns (uint256) {
        address aToken = getMoneyMarketToken(asset);
        return IERC20(aToken).balanceOf(account);
    }

    function getSupplyRate(address asset) external view override returns (uint256) {
        return aave.getReserveData(asset).currentLiquidityRate;
    }

    receive() external payable {
        revert('RECEIVE_NOT_ALLOWED');
    }

    fallback() external payable {
        revert('FALLBACK_NOT_ALLOWED');
    }
}