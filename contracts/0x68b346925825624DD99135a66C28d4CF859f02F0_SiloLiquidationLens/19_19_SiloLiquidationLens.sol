// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/ISilo.sol";
import "../lib/SolvencyV2.sol";
import "../lib/EasyMath.sol";
import "../lib/Ping.sol";

/// @title SiloLiquidationLens
/// @custom:security-contact [email protected]
contract SiloLiquidationLens {
    using EasyMath for uint256;

    ISiloRepository immutable public siloRepository;

    error InvalidSiloRepository();

    constructor (ISiloRepository _siloRepo) {
        if (!Ping.pong(_siloRepo.siloRepositoryPing)) revert InvalidSiloRepository();

        siloRepository = _siloRepo;
    }

    /// @dev view method of ISilo.flashLiquidate
    /// @param _silo Silo address from which to read data
    /// @param _users array of users for witch we want to get liquidation data
    /// @return assets array of all processed assets (collateral + debt, including removed)
    /// @return receivedCollaterals receivedCollaterals[userId][assetId] => amount
    /// amounts of collaterals send to `_flashReceiver`
    /// @return shareAmountsToRepay shareAmountsToRepaid[userId][assetId] => amount
    /// required amounts of debt to be repaid
    function flashLiquidateView(ISilo _silo, address[] memory _users)
        external
        view
        returns (
            address[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepay
        )
    {
        assets = _silo.getAssets();
        uint256 usersLength = _users.length;
        receivedCollaterals = new uint256[][](usersLength);
        shareAmountsToRepay = new uint256[][](usersLength);

        for (uint256 i = 0; i < usersLength; i++) {
            (receivedCollaterals[i], shareAmountsToRepay[i]) = _userLiquidationView(_silo, assets, _users[i]);
        }
    }

    /// @dev gets interest rates model object
    /// @param _silo Silo address from which to read data
    /// @param _asset asset for which to calculate interest rate
    /// @return IInterestRateModel interest rates model object
    function getModel(ISilo _silo, address _asset) public view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(_silo), _asset));
    }

    function _userLiquidationView(ISilo _silo, address[] memory _assets, address _user)
        internal
        view
        returns (uint256[] memory receivedCollaterals, uint256[] memory shareAmountsToRepay)
    {
        // gracefully fail if _user is solvent
        if (_silo.isSolvent(_user)) {
            uint256[] memory empty = new uint256[](_assets.length);
            return (empty, empty);
        }

        (receivedCollaterals, shareAmountsToRepay) = _flashUserLiquidationView(_silo, _assets, _user);
    }

    function _flashUserLiquidationView(ISilo _silo, address[] memory _allSiloAssets, address _borrower)
        internal
        view
        returns (uint256[] memory receivedCollaterals, uint256[] memory amountsToRepay)
    {
        uint256 assetsLength = _allSiloAssets.length;
        receivedCollaterals = new uint256[](assetsLength);
        amountsToRepay = new uint256[](assetsLength);

        uint256 protocolLiquidationFee = siloRepository.protocolLiquidationFee();

        for (uint256 i = 0; i < assetsLength; i++) {
            ISilo.AssetStorage memory _state = _silo.assetStorage(_allSiloAssets[i]);
            ISilo.AssetInterestData memory _assetInterestData = _silo.interestData(_allSiloAssets[i]);

            _accrueInterestView(_silo, _state, _assetInterestData, _allSiloAssets[i]);
            // we do not allow for partial repayment on liquidation, that's why max
            (amountsToRepay[i],) = _calculateDebtAmountAndShare(_state, _borrower);

            uint256 withdrawnOnlyAmount = _calculateWithdrawAssetAmount(
                _state.collateralOnlyDeposits,
                _state.collateralOnlyToken,
                _borrower,
                protocolLiquidationFee,
                _assetInterestData.protocolFees
            );

            uint256 withdrawnAmount = _calculateWithdrawAssetAmount(
                _state.totalDeposits,
                _state.collateralToken,
                _borrower,
                protocolLiquidationFee,
                _assetInterestData.protocolFees
            );

            receivedCollaterals[i] = withdrawnOnlyAmount + withdrawnAmount;
        }
    }

    function _accrueInterestView(
        ISilo _silo,
        ISilo.AssetStorage memory _state,
        ISilo.AssetInterestData memory _assetInterestData,
        address _asset
    )
        internal
        view
    {
        uint256 lastTimestamp = _assetInterestData.interestRateTimestamp;

        // This is the first time, so we can return early and save some gas
        if (lastTimestamp == 0) {
            _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
            return;
        }

        // Interest has already been accrued this block
        if (lastTimestamp == block.timestamp) {
            return;
        }

        uint256 rcomp = getModel(_silo, _asset).getCompoundInterestRate(address(_silo), _asset, block.timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();

        uint256 totalBorrowAmountCached = _state.totalBorrowAmount;

        uint256 totalInterest = totalBorrowAmountCached * rcomp / SolvencyV2._PRECISION_DECIMALS;
        uint256 protocolShare = totalInterest * protocolShareFee / SolvencyV2._PRECISION_DECIMALS;
        uint256 depositorsShare = totalInterest - protocolShare;

        // update contract state
        _state.totalBorrowAmount = totalBorrowAmountCached + totalInterest;
        _state.totalDeposits = _state.totalDeposits + depositorsShare;
        _assetInterestData.protocolFees = _assetInterestData.protocolFees + protocolShare;
        _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
    }

    function _calculateDebtAmountAndShare(ISilo.AssetStorage memory _assetStorage, address _borrower)
        internal
        view
        returns (uint256 amount, uint256 repayShare)
    {
        repayShare = _assetStorage.debtToken.balanceOf(_borrower);
        uint256 debtTokenTotalSupply = _assetStorage.debtToken.totalSupply();
        uint256 totalBorrowed = _assetStorage.totalBorrowAmount;
        amount = repayShare.toAmountRoundUp(totalBorrowed, debtTokenTotalSupply);
    }

    function _calculateWithdrawAssetAmount(
        uint256 _assetTotalDeposits,
        IShareToken _shareToken,
        address _depositor,
        uint256 _protocolLiquidationFee,
        uint256 _protocolFees
    )
        internal
        view
        returns (uint256 withdrawnAmount)
    {
        uint256 burnedShare = _shareToken.balanceOf(_depositor);
        withdrawnAmount = burnedShare.toAmount(_assetTotalDeposits, _shareToken.totalSupply());

        if (withdrawnAmount == 0) return 0;

        if (_protocolLiquidationFee != 0) {
            withdrawnAmount = _applyLiquidationFee(withdrawnAmount, _protocolLiquidationFee, _protocolFees);
        }
    }

    function _applyLiquidationFee(
        uint256 _amount,
        uint256 _protocolLiquidationFee,
        uint256 _protocolFees
    )
        internal
        pure
        returns (uint256 change)
    {
        uint256 liquidationFeeAmount;

        (liquidationFeeAmount,) = SolvencyV2.calculateLiquidationFee(_protocolFees, _amount, _protocolLiquidationFee);

        unchecked {
            // if fees will not be higher than 100% this will not underflow, this is responsibility of siloRepository
            // in case we do underflow, we can expect liquidator reject tx because of too little change
            change = _amount - liquidationFeeAmount;
        }
    }
}