// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IPriceProvidersRepository.sol";
import "../interfaces/ISilo.sol";
import "../interfaces/IInterestRateModel.sol";
import "../interfaces/ISiloRepository.sol";
import "./EasyMathV2.sol";

library SolvencyV2 {
    using EasyMathV2 for uint256;

    /// @notice
    /// MaximumLTV - Maximum Loan-to-Value ratio represents the maximum borrowing power of all user's collateral
    /// positions in a Silo
    /// LiquidationThreshold - Liquidation Threshold represents the threshold at which all user's borrow positions
    /// in a Silo will be considered under collateralized and subject to liquidation
    enum TypeofLTV { MaximumLTV, LiquidationThreshold }

    error DifferentArrayLength();
    error UnsupportedLTVType();

    struct SolvencyParams {
        /// @param siloRepository SiloRepository address
        ISiloRepository siloRepository;
        /// @param silo Silo address
        ISilo silo;
        /// @param assets array with assets
        address[] assets;
        /// @param assetStates array of states for each asset, where index match the `assets` index
        ISilo.AssetStorage[] assetStates;
        /// @param user wallet address for which to read debt
        address user;
    }

    /// @dev is value that used for integer calculations and decimal points for utilization ratios, LTV, protocol fees
    uint256 internal constant _PRECISION_DECIMALS = 1e18;
    uint256 internal constant _INFINITY = type(uint256).max;

    /// @notice Returns current user LTV and second LTV chosen in params
    /// @dev This function is optimized for protocol use. In some cases there is no need to keep the calculation
    /// going and predefined results can be returned.
    /// @param _params `SolvencyV2.SolvencyParams` struct with needed params for calculation
    /// @param _secondLtvType type of LTV to be returned as second value
    /// @return currentUserLTV Loan-to-Value ratio represents current user's proportion of debt to collateral
    /// @return secondLTV second type of LTV which depends on _secondLtvType, zero is returned if the value of the loan
    /// or the collateral are zero
    function calculateLTVs(SolvencyParams memory _params, TypeofLTV _secondLtvType)
        internal
        view
        returns (uint256 currentUserLTV, uint256 secondLTV)
    {
        uint256[] memory totalBorrowAmounts = getBorrowAmounts(_params);

        // this return avoids eg. additional checks on withdraw, when user did not borrow any asset
        if (EasyMathV2.sum(totalBorrowAmounts) == 0) return (0, 0);

        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory borrowValues = convertAmountsToValues(
            priceProvidersRepository,
            _params.assets,
            totalBorrowAmounts
        );

        // value of user's total debt
        uint256 borrowTotalValue = EasyMathV2.sum(borrowValues);

        if (borrowTotalValue == 0) return (0, 0);

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMathV2.sum(collateralValues);

        if (collateralTotalValue == 0) return (_INFINITY, 0);

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _secondLtvType,
            collateralValues
        );

        currentUserLTV = borrowTotalValue * _PRECISION_DECIMALS / collateralTotalValue;

        // one of SolvencyV2.TypeofLTV
        secondLTV = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Calculates chosen LTV limit
    /// @dev This function should be used by external actors like SiloLens and UI/subgraph. `calculateLTVs` is
    /// optimized for protocol use and may not return second LVT calculation when they are not needed.
    /// @param _params `SolvencyV2.SolvencyParams` struct with needed params for calculation
    /// @param _ltvType acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @return limit theoretical LTV limit of `_ltvType`
    function calculateLTVLimit(SolvencyParams memory _params, TypeofLTV _ltvType)
        internal
        view
        returns (uint256 limit)
    {
        IPriceProvidersRepository priceProvidersRepository = _params.siloRepository.priceProvidersRepository();

        uint256[] memory collateralValues = getUserCollateralValues(priceProvidersRepository, _params);

        // value of user's collateral
        uint256 collateralTotalValue = EasyMathV2.sum(collateralValues);

        if (collateralTotalValue == 0) return 0;

        // value of theoretical debt user can have depending on TypeofLTV
        uint256 borrowAvailableTotalValue = _getTotalAvailableToBorrowValue(
            _params.siloRepository,
            address(_params.silo),
            _params.assets,
            _ltvType,
            collateralValues
        );

        limit = borrowAvailableTotalValue * _PRECISION_DECIMALS / collateralTotalValue;
    }

    /// @notice Returns worth (in quote token) of each collateral deposit of a user
    /// @param _priceProvidersRepository address of IPriceProvidersRepository where prices are read
    /// @param _params `SolvencyV2.SolvencyParams` struct with needed params for calculation
    /// @return collateralValues worth of each collateral deposit of a user as an array
    function getUserCollateralValues(IPriceProvidersRepository _priceProvidersRepository, SolvencyParams memory _params)
        internal
        view
        returns(uint256[] memory collateralValues)
    {
        uint256[] memory collateralAmounts = getCollateralAmounts(_params);
        collateralValues = convertAmountsToValues(_priceProvidersRepository, _params.assets, collateralAmounts);
    }

    /// @notice Convert assets amounts to values in quote token (amount * price)
    /// @param _priceProviderRepo address of IPriceProvidersRepository where prices are read
    /// @param _assets array with assets for which prices are read
    /// @param _amounts array of amounts
    /// @return values array of values for corresponding assets
    function convertAmountsToValues(
        IPriceProvidersRepository _priceProviderRepo,
        address[] memory _assets,
        uint256[] memory _amounts
    ) internal view returns (uint256[] memory values) {
        if (_assets.length != _amounts.length) revert DifferentArrayLength();

        values = new uint256[](_assets.length);

        for (uint256 i = 0; i < _assets.length; i++) {
            if (_amounts[i] == 0) continue;

            uint256 assetPrice = _priceProviderRepo.getPrice(_assets[i]);
            uint8 assetDecimals = ERC20(_assets[i]).decimals();

            values[i] = _amounts[i].toValue(assetPrice, assetDecimals);
        }
    }

    /// @notice Get amount of collateral for each asset
    /// @param _params `SolvencyV2.SolvencyParams` struct with needed params for calculation
    /// @return collateralAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not deposit given collateral token.
    function getCollateralAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory collateralAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        collateralAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 userCollateralTokenBalance = _params.assetStates[i].collateralToken.balanceOf(_params.user);
            uint256 userCollateralOnlyTokenBalance = _params.assetStates[i].collateralOnlyToken.balanceOf(_params.user);

            if (userCollateralTokenBalance + userCollateralOnlyTokenBalance == 0) continue;

            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);

            collateralAmounts[i] = getUserCollateralAmount(
                _params.assetStates[i],
                userCollateralTokenBalance,
                userCollateralOnlyTokenBalance,
                rcomp,
                _params.siloRepository
            );
        }
    }

    /// @notice Get amount of debt for each asset
    /// @param _params `SolvencyV2.SolvencyParams` struct with needed params for calculation
    /// @return totalBorrowAmounts array of amounts for each token in Silo. May contain zero values if user
    /// did not borrow given token.
    function getBorrowAmounts(SolvencyParams memory _params)
        internal
        view
        returns (uint256[] memory totalBorrowAmounts)
    {
        if (_params.assets.length != _params.assetStates.length) {
            revert DifferentArrayLength();
        }

        totalBorrowAmounts = new uint256[](_params.assets.length);

        for (uint256 i = 0; i < _params.assets.length; i++) {
            uint256 rcomp = getRcomp(_params.silo, _params.siloRepository, _params.assets[i], block.timestamp);
            totalBorrowAmounts[i] = getUserBorrowAmount(_params.assetStates[i], _params.user, rcomp);
        }
    }

    /// @notice Get amount of deposited token, including collateralOnly deposits
    /// @param _assetStates state of deposited asset in Silo
    /// @param _userCollateralTokenBalance balance of user's share collateral token
    /// @param _userCollateralOnlyTokenBalance balance of user's share collateralOnly token
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @param _siloRepository SiloRepository address
    /// @return amount of underlying token deposited, including collateralOnly deposit
    function getUserCollateralAmount(
        ISilo.AssetStorage memory _assetStates,
        uint256 _userCollateralTokenBalance,
        uint256 _userCollateralOnlyTokenBalance,
        uint256 _rcomp,
        ISiloRepository _siloRepository
    ) internal view returns (uint256) {
        uint256 assetAmount = _userCollateralTokenBalance == 0 ? 0 : _userCollateralTokenBalance.toAmount(
            totalDepositsWithInterest(
                _assetStates.totalDeposits,
                _assetStates.totalBorrowAmount,
                _siloRepository.protocolShareFee(),
                _rcomp
            ),
            _assetStates.collateralToken.totalSupply()
        );

        uint256 assetCollateralOnlyAmount = _userCollateralOnlyTokenBalance == 0
            ? 0
            : _userCollateralOnlyTokenBalance.toAmount(
                _assetStates.collateralOnlyDeposits,
                _assetStates.collateralOnlyToken.totalSupply()
            );

        return assetAmount + assetCollateralOnlyAmount;
    }

    /// @notice Get amount of borrowed token
    /// @param _assetStates state of borrowed asset in Silo
    /// @param _user user wallet address for which to read debt
    /// @param _rcomp compounded interest rate to account for during calculations, could be 0
    /// @return amount of borrowed token
    function getUserBorrowAmount(ISilo.AssetStorage memory _assetStates, address _user, uint256 _rcomp)
        internal
        view
        returns (uint256)
    {
        uint256 balance = _assetStates.debtToken.balanceOf(_user);
        if (balance == 0) return 0;

        uint256 totalBorrowAmountCached = totalBorrowAmountWithInterest(_assetStates.totalBorrowAmount, _rcomp);
        return balance.toAmountRoundUp(totalBorrowAmountCached, _assetStates.debtToken.totalSupply());
    }

    /// @notice Get compounded interest rate from the model
    /// @param _silo Silo address
    /// @param _siloRepository SiloRepository address
    /// @param _asset address of asset for which to read interest rate
    /// @param _timestamp used to determine amount of time from last rate update
    /// @return rcomp compounded interest rate for an asset
    function getRcomp(ISilo _silo, ISiloRepository _siloRepository, address _asset, uint256 _timestamp)
        internal
        view
        returns (uint256 rcomp)
    {
        IInterestRateModel model = _siloRepository.getInterestRateModel(address(_silo), _asset);
        rcomp = model.getCompoundInterestRate(address(_silo), _asset, _timestamp);
    }

    /// @notice Returns total deposits with interest dynamically calculated with the provided rComp
    /// @param _assetTotalDeposits total deposits for asset
    /// @param _assetTotalBorrows total borrows for asset
    /// @param _protocolShareFee `siloRepository.protocolShareFee()`
    /// @param _rcomp compounded interest rate
    /// @return _totalDepositsWithInterests total deposits amount with interest
    function totalDepositsWithInterest(
        uint256 _assetTotalDeposits,
        uint256 _assetTotalBorrows,
        uint256 _protocolShareFee,
        uint256 _rcomp
    )
        internal
        pure
        returns (uint256 _totalDepositsWithInterests)
    {
        uint256 depositorsShare = _PRECISION_DECIMALS - _protocolShareFee;

        return _assetTotalDeposits + _assetTotalBorrows * _rcomp / _PRECISION_DECIMALS * depositorsShare /
            _PRECISION_DECIMALS;
    }

    /// @notice Returns total borrow amount with interest dynamically calculated with the provided rComp
    /// @param _totalBorrowAmount total borrow amount
    /// @param _rcomp compounded interest rate
    /// @return totalBorrowAmountWithInterests total borrow amount with interest
    function totalBorrowAmountWithInterest(uint256 _totalBorrowAmount, uint256 _rcomp)
        internal
        pure
        returns (uint256 totalBorrowAmountWithInterests)
    {
        totalBorrowAmountWithInterests = _totalBorrowAmount + _totalBorrowAmount * _rcomp / _PRECISION_DECIMALS;
    }

    /// @notice Calculates protocol liquidation fee and new protocol total fees collected
    /// @param _protocolEarnedFees amount of total collected fees so far
    /// @param _amount amount on which we will apply fee
    /// @param _liquidationFee liquidation fee in SolvencyV2._PRECISION_DECIMALS
    /// @return liquidationFeeAmount calculated interest
    /// @return newProtocolEarnedFees the new total amount of protocol fees
    function calculateLiquidationFee(uint256 _protocolEarnedFees, uint256 _amount, uint256 _liquidationFee)
        internal
        pure
        returns (uint256 liquidationFeeAmount, uint256 newProtocolEarnedFees)
    {
        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            liquidationFeeAmount = _amount * _liquidationFee / SolvencyV2._PRECISION_DECIMALS;

            if (_protocolEarnedFees > type(uint256).max - liquidationFeeAmount) {
                newProtocolEarnedFees = type(uint256).max;
                liquidationFeeAmount = type(uint256).max - _protocolEarnedFees;
            } else {
                newProtocolEarnedFees = _protocolEarnedFees + liquidationFeeAmount;
            }
        }
    }

    /// @notice Calculates theoretical value (in quote token) that user could borrow based given collateral value
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _asset address of collateral token
    /// @param _type type of LTV limit to use for calculations
    /// @param _collateralValue value of collateral deposit (in quote token)
    /// @return availableToBorrow value (in quote token) that user can borrow against collateral value
    function _getAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address _asset,
        TypeofLTV _type,
        uint256 _collateralValue
    ) private view returns (uint256 availableToBorrow) {
        uint256 assetLTV;

        if (_type == TypeofLTV.MaximumLTV) {
            assetLTV = _siloRepository.getMaximumLTV(_silo, _asset);
        } else if (_type == TypeofLTV.LiquidationThreshold) {
            assetLTV = _siloRepository.getLiquidationThreshold(_silo, _asset);
        } else {
            revert UnsupportedLTVType();
        }

        // value that can be borrowed against the deposit
        // ie. for assetLTV = 50%, 1 ETH * 50% = 0.5 ETH of available to borrow
        availableToBorrow = _collateralValue * assetLTV / _PRECISION_DECIMALS;
    }

    /// @notice Calculates theoretical value (in quote token) that user can borrow based on deposited collateral
    /// @param _siloRepository SiloRepository address
    /// @param _silo Silo address
    /// @param _assets array with assets
    /// @param _ltvType type of LTV limit to use for calculations
    /// acceptable values are only TypeofLTV.MaximumLTV or TypeofLTV.LiquidationThreshold
    /// @param _collateralValues value (worth in quote token) of each deposit made by user
    /// @return totalAvailableToBorrowValue value (in quote token) that user can borrow against collaterals
    function _getTotalAvailableToBorrowValue(
        ISiloRepository _siloRepository,
        address _silo,
        address[] memory _assets,
        TypeofLTV _ltvType,
        uint256[] memory _collateralValues
    ) private view returns (uint256 totalAvailableToBorrowValue) {
        if (_assets.length != _collateralValues.length) revert DifferentArrayLength();

        for (uint256 i = 0; i < _assets.length; i++) {
            totalAvailableToBorrowValue += _getAvailableToBorrowValue(
                _siloRepository,
                _silo,
                _assets[i],
                _ltvType,
                _collateralValues[i]
            );
        }
    }
}