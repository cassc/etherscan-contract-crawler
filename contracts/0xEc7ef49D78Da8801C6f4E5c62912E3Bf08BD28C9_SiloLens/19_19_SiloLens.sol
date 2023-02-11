// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./interfaces/IBaseSilo.sol";
import "./interfaces/ISilo.sol";
import "./lib/EasyMath.sol";
import "./lib/Ping.sol";
import "./lib/SolvencyV2.sol";

/// @title SiloLens
/// @notice Utility contract that simplifies reading data from Silo protocol contracts
/// @custom:security-contact [email protected]
contract SiloLens {
    using EasyMath for uint256;

    ISiloRepository immutable public siloRepository;

    error InvalidRepository();
    error UserIsZero();

    constructor (ISiloRepository _siloRepo) {
        if (!Ping.pong(_siloRepo.siloRepositoryPing)) revert InvalidRepository();

        siloRepository = _siloRepo;
    }

    /// @dev calculates solvency using SolvencyV2 library
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address
    /// @return true if solvent, false otherwise
    function isSolvent(ISilo _silo, address _user) external view returns (bool) {
        if (_user == address(0)) revert UserIsZero();

        (address[] memory assets, IBaseSilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        (uint256 userLTV, uint256 liquidationThreshold) = SolvencyV2.calculateLTVs(
            SolvencyV2.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            SolvencyV2.TypeofLTV.LiquidationThreshold
        );

        return userLTV <= liquidationThreshold;
    }

    /// @dev Amount of token that is available for borrowing.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return Silo liquidity
    function liquidity(ISilo _silo, address _asset) external view returns (uint256) {
        return ERC20(_asset).balanceOf(address(_silo)) - _silo.assetStorage(_asset).collateralOnlyDeposits;
    }

    /// @notice Get amount of asset token that has been deposited to Silo
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of all deposits made for given asset
    function totalDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.utilizationData(_asset).totalDeposits;
    }

    /// @notice Get amount of asset token that has been deposited to Silo with option "collateralOnly"
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of all "collateralOnly" deposits made for given asset
    function collateralOnlyDeposits(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).collateralOnlyDeposits;
    }

    /// @notice Get amount of asset that has been borrowed
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of asset that has been borrowed
    function totalBorrowAmount(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).totalBorrowAmount;
    }

    /// @notice Get amount of fees earned by protocol to date
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return amount of fees earned by protocol to date
    function protocolFees(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.interestData(_asset).protocolFees;
    }

    /// @notice Returns Loan-To-Value for an account
    /// @dev Each Silo has multiple asset markets (bridge assets + unique asset). This function calculates
    /// a sum of all deposits and all borrows denominated in quote token. Returns fraction between borrow value
    /// and deposit value with 18 decimals.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which LTV is calculated
    /// @return userLTV user current LTV with 18 decimals
    function getUserLTV(ISilo _silo, address _user) external view returns (uint256 userLTV) {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        (userLTV, ) = SolvencyV2.calculateLTVs(
            SolvencyV2.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            SolvencyV2.TypeofLTV.MaximumLTV
        );
    }

    /// @notice Get totalSupply of debt token
    /// @dev Debt token represents a share in total debt of given asset
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @return totalSupply of debt token
    function totalBorrowShare(ISilo _silo, address _asset) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.totalSupply();
    }

    /// @notice Calculates current borrow amount for user with interest
    /// @dev Interest is calculated based on the provided timestamp with is expected to be current time.
    /// @param _silo Silo address from which to read data
    /// @param _asset token address for which calculation are done
    /// @param _user account for which calculation are done
    /// @param _timestamp timestamp used for interest calculations
    /// @return total amount of asset user needs to repay at provided timestamp
    function getBorrowAmount(ISilo _silo, address _asset, address _user, uint256 _timestamp)
        external
        view
        returns (uint256)
    {
        return SolvencyV2.getUserBorrowAmount(
            _silo.assetStorage(_asset),
            _user,
            SolvencyV2.getRcomp(_silo, siloRepository, _asset, _timestamp)
        );
    }

    /// @notice Get debt token balance of a user
    /// @dev Debt token represents a share in total debt of given asset. This method calls balanceOf(_user)
    /// on that token.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of debt token of given user
    function borrowShare(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        return _silo.assetStorage(_asset).debtToken.balanceOf(_user);
    }

    /// @notice Get underlying balance of all deposits of given token of given user including "collateralOnly"
    /// deposits
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of underlying tokens for the given user
    function collateralBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        // Overflow shouldn't happen if the underlying token behaves correctly, as the total supply of underlying
        // tokens can't overflow by definition
        unchecked {
            return balanceOfUnderlying(_state.totalDeposits, _state.collateralToken, _user) +
                balanceOfUnderlying(_state.collateralOnlyDeposits, _state.collateralOnlyToken, _user);
        }
    }

    /// @notice Get amount of debt of underlying token for given user
    /// @dev It reads directly from storage so interest generated between last update and now is not taken for account
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address for which to read data
    /// @param _user wallet address for which to read data
    /// @return balance of underlying token owed
    function debtBalanceOfUnderlying(ISilo _silo, address _asset, address _user) external view returns (uint256) {
        ISilo.AssetStorage memory _state = _silo.assetStorage(_asset);

        return balanceOfUnderlying(_state.totalBorrowAmount, _state.debtToken, _user);
    }

    /// @notice Calculate value of collateral asset for user
    /// @dev It dynamically adds interest earned. Takes for account collateral only deposits as well.
    /// @param _silo Silo address from which to read data
    /// @param _user account for which calculation are done
    /// @param _asset token address for which calculation are done
    /// @return value of collateral denominated in quote token with 18 decimal
    function calculateCollateralValue(ISilo _silo, address _user, address _asset)
        external
        view
        returns (uint256)
    {
        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();
        ISilo.AssetStorage memory assetStorage = _silo.assetStorage(_asset);

        uint256 assetPrice = priceProviderRepo.getPrice(_asset);
        uint8 assetDecimals = ERC20(_asset).decimals();
        uint256 userCollateralTokenBalance = assetStorage.collateralToken.balanceOf(_user);
        uint256 userCollateralOnlyTokenBalance = assetStorage.collateralOnlyToken.balanceOf(_user);

        uint256 assetAmount = SolvencyV2.getUserCollateralAmount(
            assetStorage,
            userCollateralTokenBalance,
            userCollateralOnlyTokenBalance,
            SolvencyV2.getRcomp(_silo, siloRepository, _asset, block.timestamp),
            siloRepository
        );

        return assetAmount.toValue(assetPrice, assetDecimals);
    }

    /// @notice Calculate value of borrowed asset by user
    /// @dev It dynamically adds interest earned to borrowed amount
    /// @param _silo Silo address from which to read data
    /// @param _user account for which calculation are done
    /// @param _asset token address for which calculation are done
    /// @return value of debt denominated in quote token with 18 decimal
    function calculateBorrowValue(ISilo _silo, address _user, address _asset)
        external
        view
        returns (uint256)
    {
        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();
        uint256 assetPrice = priceProviderRepo.getPrice(_asset);
        uint256 assetDecimals = ERC20(_asset).decimals();

        uint256 rcomp = SolvencyV2.getRcomp(_silo, siloRepository, _asset, block.timestamp);
        uint256 borrowAmount = SolvencyV2.getUserBorrowAmount(_silo.assetStorage(_asset), _user, rcomp);

        return borrowAmount.toValue(assetPrice, assetDecimals);
    }

    /// @notice Get combined liquidation threshold for a user
    /// @dev Methodology for calculating liquidation threshold is as follows. Each Silo is combined form multiple
    /// assets (bridge assets + unique asset). Each of these assets may have different liquidation threshold.
    /// That means effective liquidation threshold must be calculated per asset based on current deposits and
    /// borrows of given account.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return liquidationThreshold liquidation threshold of given user
    function getUserLiquidationThreshold(ISilo _silo, address _user)
        external
        view
        returns (uint256 liquidationThreshold)
    {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        liquidationThreshold = SolvencyV2.calculateLTVLimit(
            SolvencyV2.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            SolvencyV2.TypeofLTV.LiquidationThreshold
        );
    }

    /// @notice Get combined maximum Loan-To-Value for a user
    /// @dev Methodology for calculating maximum LTV is as follows. Each Silo is combined form multiple assets
    /// (bridge assets + unique asset). Each of these assets may have different maximum Loan-To-Value for
    /// opening borrow position. That means effective maximum LTV must be calculated per asset based on
    /// current deposits and borrows of given account.
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return maximumLTV Maximum Loan-To-Value of given user
    function getUserMaximumLTV(ISilo _silo, address _user) external view returns (uint256 maximumLTV) {
        (address[] memory assets, ISilo.AssetStorage[] memory assetsStates) = _silo.getAssetsWithState();

        maximumLTV = SolvencyV2.calculateLTVLimit(
            SolvencyV2.SolvencyParams(
                siloRepository,
                _silo,
                assets,
                assetsStates,
                _user
            ),
            SolvencyV2.TypeofLTV.MaximumLTV
        );
    }

    /// @notice Check if user is in debt
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return TRUE if user borrowed any amount of any asset, otherwise FALSE
    function inDebt(ISilo _silo, address _user) external view returns (bool) {
        address[] memory allAssets = _silo.getAssets();

        for (uint256 i; i < allAssets.length;) {
            if (_silo.assetStorage(allAssets[i]).debtToken.balanceOf(_user) != 0) return true;

            unchecked {
                i++;
            }
        }

        return false;
    }

    /// @notice Check if user has position (debt or borrow) in any asset
    /// @param _silo Silo address from which to read data
    /// @param _user wallet address for which to read data
    /// @return TRUE if user has position (debt or borrow) in any asset
    function hasPosition(ISilo _silo, address _user) external view returns (bool) {
        (, ISilo.AssetStorage[] memory assetsStorage) = _silo.getAssetsWithState();

        for (uint256 i; i < assetsStorage.length; i++) {
            if (assetsStorage[i].debtToken.balanceOf(_user) != 0) return true;
            if (assetsStorage[i].collateralToken.balanceOf(_user) != 0) return true;
            if (assetsStorage[i].collateralOnlyToken.balanceOf(_user) != 0) return true;
        }

        return false;
    }

    /// @notice Calculates fraction between borrowed amount and the current liquidity of tokens for given asset
    /// denominated in percentage
    /// @dev Utilization is calculated current values in storage so it does not take for account earned
    /// interest and ever-increasing total borrow amount. It assumes `Model.DP()` = 100%.
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return utilization value
    function getUtilization(ISilo _silo, address _asset) external view returns (uint256) {
        ISilo.UtilizationData memory data = ISilo(_silo).utilizationData(_asset);

        return EasyMath.calculateUtilization(
            getModel(_silo, _asset).DP(),
            data.totalDeposits,
            data.totalBorrowAmount
        );
    }

    /// @notice Yearly interest rate for depositing asset token, dynamically calculated for current block timestamp
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return APY with 18 decimals
    function depositAPY(ISilo _silo, address _asset) external view returns (uint256) {
        uint256 dp = getModel(_silo, _asset).DP();

        // amount of deposits in asset decimals
        uint256 totalDepositsAmount = totalDepositsWithInterest(_silo, _asset);

        if (totalDepositsAmount == 0) return 0;

        // amount of debt generated per year in asset decimals
        uint256 generatedDebtAmount = totalBorrowAmountWithInterest(_silo, _asset) * borrowAPY(_silo, _asset) / dp;

        return generatedDebtAmount * SolvencyV2._PRECISION_DECIMALS / totalDepositsAmount;
    }

    /// @notice Calculate amount of entry fee for given amount
    /// @param _amount amount for which to calculate fee
    /// @return Amount of token fee to be paid
    function calcFee(uint256 _amount) external view returns (uint256) {
        uint256 entryFee = siloRepository.entryFee();
        if (entryFee == 0) return 0; // no fee

        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            return _amount * entryFee / SolvencyV2._PRECISION_DECIMALS;
        }
    }

    /// @dev Method for sanity check
    /// @return always true
    function lensPing() external pure returns (bytes4) {
        return this.lensPing.selector;
    }

    /// @notice Yearly interest rate for borrowing asset token, dynamically calculated for current block timestamp
    /// @param _silo Silo address from which to read data
    /// @param _asset asset address
    /// @return APY with 18 decimals
    function borrowAPY(ISilo _silo, address _asset) public view returns (uint256) {
        return getModel(_silo, _asset).getCurrentInterestRate(address(_silo), _asset, block.timestamp);
    }

    /// @notice returns total deposits with interest dynamically calculated at current block timestamp
    /// @param _asset asset address
    /// @return _totalDeposits total deposits amount with interest
    function totalDepositsWithInterest(ISilo _silo, address _asset) public view returns (uint256 _totalDeposits) {
        uint256 rcomp = getModel(_silo, _asset).getCompoundInterestRate(address(_silo), _asset, block.timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();
        ISilo.UtilizationData memory data = _silo.utilizationData(_asset);

        return SolvencyV2.totalDepositsWithInterest(
            data.totalDeposits, data.totalBorrowAmount, protocolShareFee, rcomp
        );
    }

    /// @notice Calculates current deposit (with interest) for user
    /// Collateral only deposits are not counted here. To get collateral only deposit call:
    /// `_silo.assetStorage(_asset).collateralOnlyDeposits`
    /// @dev Interest is calculated based on the provided timestamp with is expected to be current time.
    /// @param _silo Silo address from which to read data
    /// @param _asset token address for which calculation are done
    /// @param _user account for which calculation are done
    /// @param _timestamp timestamp used for interest calculations
    /// @return totalUserDeposits amount of asset user posses
    function getDepositAmount(ISilo _silo, address _asset, address _user, uint256 _timestamp)
        public
        view
        returns (uint256 totalUserDeposits)
    {
        ISilo.AssetStorage memory data = _silo.assetStorage(_asset);

        uint256 share = data.collateralToken.balanceOf(_user);

        if (share == 0) {
            return 0;
        }

        uint256 rcomp = getModel(_silo, _asset).getCompoundInterestRate(address(_silo), _asset, _timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();

        uint256 assetTotalDeposits = SolvencyV2.totalDepositsWithInterest(
            data.totalDeposits, data.totalBorrowAmount, protocolShareFee, rcomp
        );

        return share.toAmount(assetTotalDeposits, data.collateralToken.totalSupply());
    }

    /// @notice returns total borrow amount with interest dynamically calculated at current block timestamp
    /// @param _asset asset address
    /// @return _totalBorrowAmount total deposits amount with interest
    function totalBorrowAmountWithInterest(ISilo _silo, address _asset)
        public
        view
        returns (uint256 _totalBorrowAmount)
    {
        uint256 rcomp = SolvencyV2.getRcomp(_silo, siloRepository, _asset, block.timestamp);
        ISilo.UtilizationData memory data = _silo.utilizationData(_asset);

        return SolvencyV2.totalBorrowAmountWithInterest(data.totalBorrowAmount, rcomp);
    }

    /// @notice Get underlying balance of collateral or debt token
    /// @dev You can think about debt and collateral tokens as cToken in compound. They represent ownership of
    /// debt or collateral in given Silo. This method converts that ownership to exact amount of underlying token.
    /// @param _assetTotalDeposits Total amount of assets that has been deposited or borrowed. For collateral token,
    /// use `totalDeposits` to get this value. For debt token, use `totalBorrowAmount` to get this value.
    /// @param _shareToken share token address. It's the collateral and debt share token address. You can find
    /// these addresses in:
    /// - `ISilo.AssetStorage.collateralToken`
    /// - `ISilo.AssetStorage.collateralOnlyToken`
    /// - `ISilo.AssetStorage.debtToken`
    /// @param _user wallet address for which to read data
    /// @return balance of underlying token deposited or borrowed of given user
    function balanceOfUnderlying(uint256 _assetTotalDeposits, IShareToken _shareToken, address _user)
        public
        view
        returns (uint256)
    {
        uint256 share = _shareToken.balanceOf(_user);
        return share.toAmount(_assetTotalDeposits, _shareToken.totalSupply());
    }

    /// @dev gets interest rates model object
    /// @param _silo Silo address from which to read data
    /// @param _asset asset for which to calculate interest rate
    /// @return IInterestRateModel interest rates model object
    function getModel(ISilo _silo, address _asset) public view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(_silo), _asset));
    }
}