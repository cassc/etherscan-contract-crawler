//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Controller.sol";

/**
 * @title dForce's lending stock controller Contract
 * @author dForce
 */
contract ControllerStock is Controller {
    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `iTokenBalance` is the number of iTokens the account owns in the collateral,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountEquityLocalVarsV2 {
        uint256 sumCollateral;
        uint256 sumBorrowed;
        uint256 iTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 underlyingPrice;
        uint256 collateralValue;
        uint256 borrowValue;
        bool isPriceValid;
    }

    /**
     * @notice Calculates current account equity plus some token and amount to effect
     * @param _account The account to query equity of
     * @param _tokenToEffect The token address to add some additional redeeem/borrow
     * @param _redeemAmount The additional amount to redeem
     * @param _borrowAmount The additional amount to borrow
     * @return account equity, shortfall, collateral value, borrowed value plus the effect.
     */
    function calcAccountEquityWithEffect(
        address _account,
        address _tokenToEffect,
        uint256 _redeemAmount,
        uint256 _borrowAmount
    )
        internal
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountEquityLocalVarsV2 memory _local;
        AccountData storage _accountData = accountsData[_account];

        // Calculate value of all collaterals
        // collateralValuePerToken = underlyingPrice * exchangeRate * collateralFactor
        // collateralValue = balance * collateralValuePerToken
        // sumCollateral += collateralValue
        uint256 _len = _accountData.collaterals.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.collaterals.at(i));

            _local.iTokenBalance = IERC20Upgradeable(address(_token)).balanceOf(
                _account
            );
            _local.exchangeRateMantissa = _token.exchangeRateStored();

            if (_tokenToEffect == address(_token) && _redeemAmount > 0) {
                _local.iTokenBalance = _local.iTokenBalance.sub(_redeemAmount);
            }

            (_local.underlyingPrice, _local.isPriceValid) = IPriceOracle(
                priceOracle
            )
                .getUnderlyingPriceAndStatus(address(_token));

            require(
                _local.underlyingPrice != 0 && _local.isPriceValid,
                "Invalid price to calculate account equity"
            );

            _local.collateralValue = _local
                .iTokenBalance
                .mul(_local.underlyingPrice)
                .rmul(_local.exchangeRateMantissa)
                .rmul(markets[address(_token)].collateralFactorMantissa);

            _local.sumCollateral = _local.sumCollateral.add(
                _local.collateralValue
            );
        }

        // Calculate all borrowed value
        // borrowValue = underlyingPrice * underlyingBorrowed / borrowFactor
        // sumBorrowed += borrowValue
        _len = _accountData.borrowed.length();
        for (uint256 i = 0; i < _len; i++) {
            IiToken _token = IiToken(_accountData.borrowed.at(i));

            _local.borrowBalance = _token.borrowBalanceStored(_account);

            if (_tokenToEffect == address(_token) && _borrowAmount > 0) {
                _local.borrowBalance = _local.borrowBalance.add(_borrowAmount);
            }

            (_local.underlyingPrice, _local.isPriceValid) = IPriceOracle(
                priceOracle
            )
                .getUnderlyingPriceAndStatus(address(_token));

            require(
                _local.underlyingPrice != 0 && _local.isPriceValid,
                "Invalid price to calculate account equity"
            );

            // borrowFactorMantissa can not be set to 0
            _local.borrowValue = _local
                .borrowBalance
                .mul(_local.underlyingPrice)
                .rdiv(markets[address(_token)].borrowFactorMantissa);

            _local.sumBorrowed = _local.sumBorrowed.add(_local.borrowValue);
        }

        // Should never underflow
        return
            _local.sumCollateral > _local.sumBorrowed
                ? (
                    _local.sumCollateral - _local.sumBorrowed,
                    uint256(0),
                    _local.sumCollateral,
                    _local.sumBorrowed
                )
                : (
                    uint256(0),
                    _local.sumBorrowed - _local.sumCollateral,
                    _local.sumCollateral,
                    _local.sumBorrowed
                );
    }

    /**
     * @notice Calculate amount of collateral iToken to seize after repaying an underlying amount
     * @dev Used in liquidation
     * @param _iTokenBorrowed The iToken was borrowed
     * @param _iTokenCollateral The collateral iToken to be seized
     * @param _actualRepayAmount The amount of underlying token liquidator has repaied
     * @return _seizedTokenCollateral amount of iTokenCollateral tokens to be seized
     */
    function liquidateCalculateSeizeTokens(
        address _iTokenBorrowed,
        address _iTokenCollateral,
        uint256 _actualRepayAmount
    ) external view override returns (uint256 _seizedTokenCollateral) {
        /* Read oracle prices for borrowed and collateral assets */
        (uint256 _priceBorrowed, bool _isPriceBorrowedValid) =
            IPriceOracle(priceOracle).getUnderlyingPriceAndStatus(
                _iTokenBorrowed
            );
        (uint256 _priceCollateral, bool _isPriceCollateralValid) =
            IPriceOracle(priceOracle).getUnderlyingPriceAndStatus(
                _iTokenCollateral
            );
        require(
            _priceBorrowed != 0 &&
                _isPriceBorrowedValid &&
                _priceCollateral != 0 &&
                _isPriceCollateralValid,
            "Borrowed or Collateral asset price is invalid"
        );

        uint256 _valueRepayPlusIncentive =
            _actualRepayAmount.mul(_priceBorrowed).rmul(
                liquidationIncentiveMantissa
            );

        // Use stored value here as it is view function
        uint256 _exchangeRateMantissa =
            IiToken(_iTokenCollateral).exchangeRateStored();

        // seizedTokenCollateral = valueRepayPlusIncentive / valuePerTokenCollateral
        // valuePerTokenCollateral = exchangeRateMantissa * priceCollateral
        _seizedTokenCollateral = _valueRepayPlusIncentive
            .rdiv(_exchangeRateMantissa)
            .div(_priceCollateral);
    }
}