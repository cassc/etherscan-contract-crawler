// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/LiquidationReentrancyGuard.sol";

import "./interfaces/IBaseSilo.sol";
import "./interfaces/IGuardedLaunch.sol";
import "./interfaces/ISiloRepository.sol";
import "./interfaces/IPriceProvidersRepository.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/IShareToken.sol";

import "./lib/Ping.sol";
import "./lib/EasyMath.sol";
import "./lib/TokenHelper.sol";
import "./lib/Solvency.sol";

/// @title BaseSilo
/// @dev Base contract for Silo core logic.
/// @custom:security-contact [email protected]
abstract contract BaseSilo is IBaseSilo, ReentrancyGuard, LiquidationReentrancyGuard {
    using SafeERC20 for ERC20;
    using EasyMath for uint256;

    ISiloRepository immutable public override siloRepository;

    // asset address for which Silo was created
    address public immutable siloAsset;

    /// @dev version of silo
    /// @notice It tells us which `SiloRepository.siloFactory(version)` created this Silo
    uint128 public immutable VERSION; // solhint-disable-line var-name-mixedcase

    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable _ASSET_DECIMAL_POINTS;

    /// @dev stores all *synced* assets (bridge assets + removed bridge assets + siloAsset)
    address[] private _allSiloAssets;

    /// @dev asset => AssetStorage
    mapping(address => AssetStorage) private _assetStorage;

    /// @dev asset => AssetInterestData
    mapping(address => AssetInterestData) private _interestData;

    error AssetDoesNotExist();
    error BorrowNotPossible();
    error DepositNotPossible();
    error DepositsExceedLimit();
    error InvalidRepository();
    error InvalidSiloVersion();
    error MaximumLTVReached();
    error NotEnoughLiquidity();
    error NotEnoughDeposits();
    error NotSolvent();
    error OnlyRouter();
    error Paused();
    error UnexpectedEmptyReturn();
    error UserIsZero();

    modifier onlyExistingAsset(address _asset) {
        if (_interestData[_asset].status == AssetStatus.Undefined) {
            revert AssetDoesNotExist();
        }

        _;
    }

    modifier onlyRouter() {
        if (msg.sender != siloRepository.router()) revert OnlyRouter();

        _;
    }

    modifier validateMaxDepositsAfter(address _asset) {
        _;

        IPriceProvidersRepository priceProviderRepo = siloRepository.priceProvidersRepository();

        AssetStorage storage _assetState = _assetStorage[_asset];
        uint256 allDeposits = _assetState.totalDeposits + _assetState.collateralOnlyDeposits;

        if (
            priceProviderRepo.getPrice(_asset) * allDeposits / (10 ** IERC20Metadata(_asset).decimals()) >
            IGuardedLaunch(address(siloRepository)).getMaxSiloDepositsValue(address(this), _asset)
        ) {
            revert DepositsExceedLimit();
        }
    }

    constructor (ISiloRepository _repository, address _siloAsset, uint128 _version) {
        if (!Ping.pong(_repository.siloRepositoryPing)) revert InvalidRepository();
        if (_version == 0) revert InvalidSiloVersion();

        uint256 decimals = TokenHelper.assertAndGetDecimals(_siloAsset);

        VERSION = _version;
        siloRepository = _repository;
        siloAsset = _siloAsset;
        _ASSET_DECIMAL_POINTS = 10**decimals;
    }

    /// @dev this is exposed only for test purposes, but it is safe to leave it like that
    function initAssetsTokens() external nonReentrant {
        _initAssetsTokens();
    }

    /// @inheritdoc IBaseSilo
    function syncBridgeAssets() external override nonReentrant {
        // sync removed assets
        address[] memory removedBridgeAssets = siloRepository.getRemovedBridgeAssets();

        for (uint256 i = 0; i < removedBridgeAssets.length; i++) {
            // If removed bridge asset is the silo asset for this silo, do not remove it
            address removedBridgeAsset = removedBridgeAssets[i];
            if (removedBridgeAsset != siloAsset) {
                _interestData[removedBridgeAsset].status = AssetStatus.Removed;
                emit AssetStatusUpdate(removedBridgeAsset, AssetStatus.Removed);
            }
        }

        // must be called at the end, because we overriding `_assetStorage[removedBridgeAssets[i]].removed`
        _initAssetsTokens();
    }

    /// @inheritdoc IBaseSilo
    function assetStorage(address _asset) external view override returns (AssetStorage memory) {
        return _assetStorage[_asset];
    }

    /// @inheritdoc IBaseSilo
    function interestData(address _asset) external view override returns (AssetInterestData memory) {
        return _interestData[_asset];
    }

    /// @inheritdoc IBaseSilo
    function utilizationData(address _asset) external view override returns (UtilizationData memory data) {
        AssetStorage storage _assetState = _assetStorage[_asset];

        return UtilizationData(
            _assetState.totalDeposits,
            _assetState.totalBorrowAmount,
            _interestData[_asset].interestRateTimestamp
        );
    }

    /// @inheritdoc IBaseSilo
    function getAssets() public view override returns (address[] memory assets) {
        return _allSiloAssets;
    }

    /// @inheritdoc IBaseSilo
    function getAssetsWithState() public view override returns (
        address[] memory assets,
        AssetStorage[] memory assetsStorage
    ) {
        assets = _allSiloAssets;
        assetsStorage = new AssetStorage[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            assetsStorage[i] = _assetStorage[assets[i]];
        }
    }

    /// @inheritdoc IBaseSilo
    function isSolvent(address _user) public view override returns (bool) {
        if (_user == address(0)) revert UserIsZero();

        (address[] memory assets, AssetStorage[] memory assetsStates) = getAssetsWithState();

        (uint256 userLTV, uint256 liquidationThreshold) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.LiquidationThreshold
        );

        return userLTV <= liquidationThreshold;
    }

    /// @inheritdoc IBaseSilo
    function depositPossible(address _asset, address _depositor) public view override returns (bool) {
        return _assetStorage[_asset].debtToken.balanceOf(_depositor) == 0
            && _interestData[_asset].status == AssetStatus.Active;
    }

    /// @inheritdoc IBaseSilo
    function borrowPossible(address _asset, address _borrower) public view override returns (bool) {
        AssetStorage storage _assetState = _assetStorage[_asset];

        return _assetState.collateralToken.balanceOf(_borrower) == 0
            && _assetState.collateralOnlyToken.balanceOf(_borrower) == 0
            && _interestData[_asset].status == AssetStatus.Active;
    }

    /// @inheritdoc IBaseSilo
    function liquidity(address _asset) public view returns (uint256) {
        return ERC20(_asset).balanceOf(address(this)) - _assetStorage[_asset].collateralOnlyDeposits;
    }

    /// @dev Initiate asset by deploying accounting EC20 tokens for collateral and debt
    /// @param _tokensFactory factory contract that deploys collateral and debt tokens
    /// @param _asset which asset to initialize
    /// @param _isBridgeAsset true if initialized asset is a bridge asset
    function _initAsset(ITokensFactory _tokensFactory, address _asset, bool _isBridgeAsset) internal {
        AssetSharesMetadata memory metadata = _generateSharesNames(_asset, _isBridgeAsset);

        AssetStorage storage _assetState = _assetStorage[_asset];

        _assetState.collateralToken = _tokensFactory.createShareCollateralToken(
            metadata.collateralName, metadata.collateralSymbol, _asset
        );

        _assetState.collateralOnlyToken = _tokensFactory.createShareCollateralToken(
            metadata.protectedName, metadata.protectedSymbol, _asset
        );

        _assetState.debtToken = _tokensFactory.createShareDebtToken(
            metadata.debtName, metadata.debtSymbol, _asset
        );

        // keep synced asset in storage array
        _allSiloAssets.push(_asset);
        _interestData[_asset].status = AssetStatus.Active;
        emit AssetStatusUpdate(_asset, AssetStatus.Active);
    }

    /// @dev Initializes all assets (bridge assets + unique asset) for Silo but only if asset has not been
    /// initialized already. It's safe to call it multiple times. It's safe for anyone to call it at any time.
    function _initAssetsTokens() internal {
        ITokensFactory tokensFactory = siloRepository.tokensFactory();

        // init silo asset if needed
        if (address(_assetStorage[siloAsset].collateralToken) == address(0)) {
            _initAsset(tokensFactory, siloAsset, false);
        }

        // sync active assets
        address[] memory bridgeAssets = siloRepository.getBridgeAssets();

        for (uint256 i = 0; i < bridgeAssets.length; i++) {
            address bridgeAsset = bridgeAssets[i];
            // In case a bridge asset is added that already has a Silo,
            // do not initiate that asset in its Silo
            if (address(_assetStorage[bridgeAsset].collateralToken) == address(0)) {
                _initAsset(tokensFactory, bridgeAsset, true);
            } else {
                _interestData[bridgeAsset].status = AssetStatus.Active;
                emit AssetStatusUpdate(bridgeAsset, AssetStatus.Active);
            }
        }
    }

    /// @dev Generate asset shares tokens names and symbols
    /// @param _asset asset for which shares tokens will be initializaed
    /// @param _isBridgeAsset true if initialized asset is a bridge asset
    function _generateSharesNames(address _asset, bool _isBridgeAsset)
        internal
        view
        returns (AssetSharesMetadata memory metadata)
    {
        // Naming convention in UNI example:
        // - for siloAsset: sUNI, dUNI, spUNI
        // - for bridgeAsset: sWETH-UNI, dWETH-UNI, spWETH-UNI
        string memory assetSymbol = TokenHelper.symbol(_asset);

        metadata = AssetSharesMetadata({
            collateralName: string.concat("Silo Finance Borrowable ", assetSymbol, " Deposit"),
            collateralSymbol: string.concat("s", assetSymbol),
            protectedName: string.concat("Silo Finance Protected ", assetSymbol, " Deposit"),
            protectedSymbol: string.concat("sp", assetSymbol),
            debtName: string.concat("Silo Finance ", assetSymbol, " Debt"),
            debtSymbol: string.concat("d", assetSymbol)
        });

        if (_isBridgeAsset) {
            string memory baseSymbol = TokenHelper.symbol(siloAsset);

            metadata.collateralName = string.concat(metadata.collateralName, " in ", baseSymbol, " Silo");
            metadata.collateralSymbol = string.concat(metadata.collateralSymbol, "-", baseSymbol);

            metadata.protectedName = string.concat(metadata.protectedName, " in ", baseSymbol, " Silo");
            metadata.protectedSymbol = string.concat(metadata.protectedSymbol, "-", baseSymbol);

            metadata.debtName = string.concat(metadata.debtName, " in ", baseSymbol, " Silo");
            metadata.debtSymbol = string.concat(metadata.debtSymbol, "-", baseSymbol);
        }
    }

    /// @dev Main deposit function that handles all deposit logic and validation
    /// @param _asset asset address that is being deposited
    /// @param _from wallet address form which to pull asset tokens
    /// @param _depositor wallet address that will be granted ownership of deposited tokens. Keep in mind
    /// that deposit can be made by Router contract but the owner of the deposit should be user.
    /// @param _amount deposit amount
    /// @param _collateralOnly true if deposit should be used for collateral only. Otherwise false.
    /// Collateral only deposit cannot be borrowed by anyone and does not earn any interest. However,
    /// it can be used as collateral and can be subject to liquidation.
    /// @return collateralAmount deposited amount
    /// @return collateralShare `_depositor` collateral shares based on deposited amount
    function _deposit(
        address _asset,
        address _from,
        address _depositor,
        uint256 _amount,
        bool _collateralOnly
    )
        internal
        nonReentrant
        validateMaxDepositsAfter(_asset)
        returns (uint256 collateralAmount, uint256 collateralShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        if (!depositPossible(_asset, _depositor)) revert DepositNotPossible();

        AssetStorage storage _state = _assetStorage[_asset];

        collateralAmount = _amount;

        uint256 totalDepositsCached = _collateralOnly ? _state.collateralOnlyDeposits : _state.totalDeposits;

        if (_collateralOnly) {
            collateralShare = _amount.toShare(totalDepositsCached, _state.collateralOnlyToken.totalSupply());
            _state.collateralOnlyDeposits = totalDepositsCached + _amount;
            _state.collateralOnlyToken.mint(_depositor, collateralShare);
        } else {
            collateralShare = _amount.toShare(totalDepositsCached, _state.collateralToken.totalSupply());
            _state.totalDeposits = totalDepositsCached + _amount;
            _state.collateralToken.mint(_depositor, collateralShare);
        }

        ERC20(_asset).safeTransferFrom(_from, address(this), _amount);

        emit Deposit(_asset, _depositor, _amount, _collateralOnly);
    }

    /// @dev Main withdraw function that handles all withdraw logic and validation
    /// @param _asset asset address that is being withdrawn
    /// @param _depositor wallet address that is an owner of the deposited tokens
    /// @param _receiver wallet address that will receive withdrawn tokens. It's possible that Router
    /// contract is the owner of deposited tokens but we want user to get these tokens directly.
    /// @param _amount amount to withdraw. If amount is equal to maximum value stored by uint256 type
    /// (type(uint256).max), it will be assumed that user wants to withdraw all tokens and final account
    /// will be dynamically calculated including interest.
    /// @param _collateralOnly true if collateral only tokens are to be withdrawn. Otherwise false.
    /// User can deposit the same asset as collateral only and as regular deposit. During withdraw,
    /// it must be specified which tokens are to be withdrawn.
    /// @return withdrawnAmount withdrawn amount that was transferred to user
    /// @return withdrawnShare burned share based on `withdrawnAmount`
    function _withdraw(address _asset, address _depositor, address _receiver, uint256 _amount, bool _collateralOnly)
        internal
        nonReentrant // because we transferring tokens
        onlyExistingAsset(_asset)
        returns (uint256 withdrawnAmount, uint256 withdrawnShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        (withdrawnAmount, withdrawnShare) = _withdrawAsset(
            _asset,
            _amount,
            _depositor,
            _receiver,
            _collateralOnly,
            0 // do not apply any fees on regular withdraw
        );

        if (withdrawnAmount == 0) revert UnexpectedEmptyReturn();

        if (!isSolvent(_depositor)) revert NotSolvent();

        emit Withdraw(_asset, _depositor, _receiver, withdrawnAmount, _collateralOnly);
    }

    /// @dev Main borrow function that handles all borrow logic and validation
    /// @param _asset asset address that is being borrowed
    /// @param _borrower wallet address that will own debt
    /// @param _receiver wallet address that will receive borrowed tokens. It's possible that Router
    /// contract is executing borrowing for user and should be the one receiving tokens, however,
    /// the owner of the debt should be user himself.
    /// @param _amount amount of asset to borrow
    /// @return debtAmount borrowed amount
    /// @return debtShare user debt share based on borrowed amount
    function _borrow(address _asset, address _borrower, address _receiver, uint256 _amount)
        internal
        nonReentrant
        returns (uint256 debtAmount, uint256 debtShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        if (!borrowPossible(_asset, _borrower)) revert BorrowNotPossible();

        if (liquidity(_asset) < _amount) revert NotEnoughLiquidity();

        AssetStorage storage _state = _assetStorage[_asset];

        uint256 totalBorrowAmount = _state.totalBorrowAmount;
        uint256 entryFee = siloRepository.entryFee();
        uint256 fee = entryFee == 0 ? 0 : _amount * entryFee / Solvency._PRECISION_DECIMALS;
        debtShare = (_amount + fee).toShareRoundUp(totalBorrowAmount, _state.debtToken.totalSupply());
        debtAmount = _amount;

        _state.totalBorrowAmount = totalBorrowAmount + _amount + fee;
        _interestData[_asset].protocolFees += fee;

        _state.debtToken.mint(_borrower, debtShare);

        emit Borrow(_asset, _borrower, _amount);
        ERC20(_asset).safeTransfer(_receiver, _amount);

        // IMPORTANT - keep `validateBorrowAfter` at the end
        _validateBorrowAfter(_borrower);
    }

    /// @dev Main repay function that handles all repay logic and validation
    /// @param _asset asset address that is being repaid
    /// @param _borrower wallet address for which debt is being repaid
    /// @param _repayer wallet address that will pay the debt. It's possible that Router
    /// contract is executing repay for user and should be the one paying the debt.
    /// @param _amount amount of asset to repay
    /// @return repaidAmount amount repaid
    /// @return repaidShare burned debt share
    function _repay(address _asset, address _borrower, address _repayer, uint256 _amount)
        internal
        onlyExistingAsset(_asset)
        nonReentrant
        returns (uint256 repaidAmount, uint256 repaidShare)
    {
        // MUST BE CALLED AS FIRST METHOD!
        _accrueInterest(_asset);

        AssetStorage storage _state = _assetStorage[_asset];
        (repaidAmount, repaidShare) = _calculateDebtAmountAndShare(_state, _borrower, _amount);

        if (repaidShare == 0) revert UnexpectedEmptyReturn();

        emit Repay(_asset, _borrower, repaidAmount);

        ERC20(_asset).safeTransferFrom(_repayer, address(this), repaidAmount);

        // change debt state before, because share token state is changes the same way (notification is after burn)
        _state.totalBorrowAmount -= repaidAmount;
        _state.debtToken.burn(_borrower, repaidShare);
    }

    /// @param _assets all current assets, this is an optimization, so we don't have to read it from storage few times
    /// @param _user user to liquidate
    /// @param _flashReceiver address which will get all collaterals and will be notified once collaterals will be send
    /// @param _flashReceiverData custom data to forward to receiver
    /// @return receivedCollaterals amounts of collaterals transferred to `_flashReceiver`
    /// @return shareAmountsToRepay expected amounts to repay
    function _userLiquidation(
        address[] memory _assets,
        address _user,
        IFlashLiquidationReceiver _flashReceiver,
        bytes memory _flashReceiverData
    )
        internal
        // we can not use `nonReentrant` because we are using it in `_repay`,
        // and `_repay` needs to be reentered as part of a liquidation
        liquidationNonReentrant
        returns (uint256[] memory receivedCollaterals, uint256[] memory shareAmountsToRepay)
    {
        // gracefully fail if _user is solvent
        if (isSolvent(_user)) {
            uint256[] memory empty = new uint256[](_assets.length);
            return (empty, empty);
        }

        (receivedCollaterals, shareAmountsToRepay) = _flashUserLiquidation(_assets, _user, address(_flashReceiver));

        // _flashReceiver needs to repayFor user
        _flashReceiver.siloLiquidationCallback(
            _user,
            _assets,
            receivedCollaterals,
            shareAmountsToRepay,
            _flashReceiverData
        );

        for (uint256 i = 0; i < _assets.length; i++) {
            if (receivedCollaterals[i] != 0 || shareAmountsToRepay[i] != 0) {
                emit Liquidate(_assets[i], _user, shareAmountsToRepay[i], receivedCollaterals[i]);
            }
        }

        if (!isSolvent(_user)) revert NotSolvent();
    }

    function _flashUserLiquidation(address[] memory _assets, address _borrower, address _liquidator)
        internal
        returns (uint256[] memory receivedCollaterals, uint256[] memory amountsToRepay)
    {
        uint256 assetsLength = _assets.length;
        receivedCollaterals = new uint256[](assetsLength);
        amountsToRepay = new uint256[](assetsLength);

        uint256 protocolLiquidationFee = siloRepository.protocolLiquidationFee();

        for (uint256 i = 0; i < assetsLength; i++) {
            _accrueInterest(_assets[i]);

            AssetStorage storage _state = _assetStorage[_assets[i]];

            // we do not allow for partial repayment on liquidation, that's why max
            (amountsToRepay[i],) = _calculateDebtAmountAndShare(_state, _borrower, type(uint256).max);

            (uint256 withdrawnOnlyAmount,) = _withdrawAsset(
                _assets[i],
                type(uint256).max,
                _borrower,
                _liquidator,
                true, // collateral only
                protocolLiquidationFee
            );

            (uint256 withdrawnAmount,) = _withdrawAsset(
                _assets[i],
                type(uint256).max,
                _borrower,
                _liquidator,
                false, // collateral only
                protocolLiquidationFee
            );

            receivedCollaterals[i] = withdrawnOnlyAmount + withdrawnAmount;
        }
    }

    /// @dev Utility function for withdrawing an asset
    /// @param _asset asset to withdraw
    /// @param _assetAmount amount of asset to withdraw
    /// @param _depositor wallet address that is an owner of the deposit
    /// @param _receiver wallet address that is receiving the token
    /// @param _collateralOnly true if withdraw collateral only.
    /// @param _protocolLiquidationFee if provided (!=0) liquidation fees will be applied and returned
    /// `withdrawnAmount` will be decreased
    /// @return withdrawnAmount amount of asset that has been sent to receiver
    /// @return burnedShare burned share based on `withdrawnAmount`
    function _withdrawAsset(
        address _asset,
        uint256 _assetAmount,
        address _depositor,
        address _receiver,
        bool _collateralOnly,
        uint256 _protocolLiquidationFee
    )
        internal
        returns (uint256 withdrawnAmount, uint256 burnedShare)
    {
        (uint256 assetTotalDeposits, IShareToken shareToken, uint256 availableLiquidity) =
            _getWithdrawAssetData(_asset, _collateralOnly);

        if (_assetAmount == type(uint256).max) {
            burnedShare = shareToken.balanceOf(_depositor);
            withdrawnAmount = burnedShare.toAmount(assetTotalDeposits, shareToken.totalSupply());
        } else {
            burnedShare = _assetAmount.toShareRoundUp(assetTotalDeposits, shareToken.totalSupply());
            withdrawnAmount = _assetAmount;
        }

        if (withdrawnAmount == 0) {
            // we can not revert here, because liquidation will fail when one of collaterals will be empty
            return (0, 0);
        }

        if (assetTotalDeposits < withdrawnAmount) revert NotEnoughDeposits();

        unchecked {
            // can be unchecked because of the `if` above
            assetTotalDeposits -=  withdrawnAmount;
        }

        uint256 amountToTransfer = _applyLiquidationFee(_asset, withdrawnAmount, _protocolLiquidationFee);

        if (availableLiquidity < amountToTransfer) revert NotEnoughLiquidity();

        AssetStorage storage _state = _assetStorage[_asset];

        if (_collateralOnly) {
            _state.collateralOnlyDeposits = assetTotalDeposits;
        } else {
            _state.totalDeposits = assetTotalDeposits;
        }

        shareToken.burn(_depositor, burnedShare);
        // in case token sent in fee-on-transfer type of token we do not care when withdrawing
        ERC20(_asset).safeTransfer(_receiver, amountToTransfer);
    }

    /// @notice Calculates liquidations fee and returns amount of asset transferred to liquidator
    /// @param _asset asset address
    /// @param _amount amount on which we will apply fee
    /// @param _protocolLiquidationFee liquidation fee in Solvency._PRECISION_DECIMALS
    /// @return change amount left after subtracting liquidation fee
    function _applyLiquidationFee(address _asset, uint256 _amount, uint256 _protocolLiquidationFee)
        internal
        returns (uint256 change)
    {
        if (_protocolLiquidationFee == 0) {
            return _amount;
        }

        uint256 liquidationFeeAmount;

        (
            liquidationFeeAmount,
            _interestData[_asset].protocolFees
        ) = Solvency.calculateLiquidationFee(_interestData[_asset].protocolFees, _amount, _protocolLiquidationFee);

        unchecked {
            // if fees will not be higher than 100% this will not underflow, this is responsibility of siloRepository
            // in case we do underflow, we can expect liquidator reject tx because of too little change
            change = _amount - liquidationFeeAmount;
        }
    }

    /// @dev harvest protocol fees from particular asset
    /// @param _asset asset we want to harvest fees from
    /// @param _receiver address of fees receiver
    /// @return harvestedFees harvested fee
    function _harvestProtocolFees(address _asset, address _receiver)
        internal
        nonReentrant
        returns (uint256 harvestedFees)
    {
        AssetInterestData storage data = _interestData[_asset];

        harvestedFees = data.protocolFees - data.harvestedProtocolFees;

        uint256 currentLiquidity = liquidity(_asset);

        if (harvestedFees > currentLiquidity) {
            harvestedFees = currentLiquidity;
        }

        if (harvestedFees == 0) {
            return 0;
        }

        unchecked {
            // This can't overflow because this addition is less than or equal to data.protocolFees
            data.harvestedProtocolFees += harvestedFees;
        }

        ERC20(_asset).safeTransfer(_receiver, harvestedFees);
    }

    /// @notice Accrue interest for asset
    /// @dev Silo Interest Rate Model implements dynamic interest rate that changes every second. Returned
    /// interest rate by the model is compounded rate so it can be used in math calculations as if it was
    /// static. Rate is calculated for the time range between last update and current timestamp.
    /// @param _asset address of the asset for which interest should be accrued
    /// @return accruedInterest total accrued interest
    function _accrueInterest(address _asset) internal returns (uint256 accruedInterest) {
        /// @dev `_accrueInterest` is called on every user action, including liquidation. It's enough to check
        /// if Silo is paused in this function.
        if (IGuardedLaunch(address(siloRepository)).isSiloPaused(address(this), _asset)) {
            revert Paused();
        }

        AssetStorage storage _state = _assetStorage[_asset];
        AssetInterestData storage _assetInterestData = _interestData[_asset];
        uint256 lastTimestamp = _assetInterestData.interestRateTimestamp;

        // This is the first time, so we can return early and save some gas
        if (lastTimestamp == 0) {
            _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
            return 0;
        }

        // Interest has already been accrued this block
        if (lastTimestamp == block.timestamp) {
            return 0;
        }

        uint256 rcomp = _getModel(_asset).getCompoundInterestRateAndUpdate(_asset, block.timestamp);
        uint256 protocolShareFee = siloRepository.protocolShareFee();

        uint256 totalBorrowAmountCached = _state.totalBorrowAmount;
        uint256 protocolFeesCached = _assetInterestData.protocolFees;
        uint256 newProtocolFees;
        uint256 protocolShare;
        uint256 depositorsShare;

        accruedInterest = totalBorrowAmountCached * rcomp / Solvency._PRECISION_DECIMALS;

        unchecked {
            // If we overflow on multiplication it should not revert tx, we will get lower fees
            protocolShare = accruedInterest * protocolShareFee / Solvency._PRECISION_DECIMALS;
            newProtocolFees = protocolFeesCached + protocolShare;

            if (newProtocolFees < protocolFeesCached) {
                protocolShare = type(uint256).max - protocolFeesCached;
                newProtocolFees = type(uint256).max;
            }
    
            depositorsShare = accruedInterest - protocolShare;
        }

        // update contract state
        _state.totalBorrowAmount = totalBorrowAmountCached + accruedInterest;
        _state.totalDeposits = _state.totalDeposits + depositorsShare;
        _assetInterestData.protocolFees = newProtocolFees;
        _assetInterestData.interestRateTimestamp = uint64(block.timestamp);
    }

    /// @dev gets interest rates model object
    /// @param _asset asset for which to calculate interest rate
    /// @return IInterestRateModel interest rates model object
    function _getModel(address _asset) internal view returns (IInterestRateModel) {
        return IInterestRateModel(siloRepository.getInterestRateModel(address(this), _asset));
    }

    /// @dev calculates amount to repay based on user shares, we do not apply virtual balances here,
    /// if needed, they need to be apply beforehand
    /// @param _state asset storage struct
    /// @param _borrower borrower address
    /// @param _amount proposed amount of asset to repay. Based on that,`repayShare` is calculated.
    /// @return amount amount of asset to repay
    /// @return repayShare amount of debt token representing debt ownership
    function _calculateDebtAmountAndShare(AssetStorage storage _state, address _borrower, uint256 _amount)
        internal
        view
        returns (uint256 amount, uint256 repayShare)
    {
        uint256 borrowerDebtShare = _state.debtToken.balanceOf(_borrower);
        uint256 debtTokenTotalSupply = _state.debtToken.totalSupply();
        uint256 totalBorrowed = _state.totalBorrowAmount;
        uint256 maxAmount = borrowerDebtShare.toAmountRoundUp(totalBorrowed, debtTokenTotalSupply);

        if (_amount >= maxAmount) {
            amount = maxAmount;
            repayShare = borrowerDebtShare;
        } else {
            amount = _amount;
            repayShare = _amount.toShare(totalBorrowed, debtTokenTotalSupply);
        }
    }

    /// @dev verifies if user did not borrow more than allowed maximum
    function _validateBorrowAfter(address _user) private view {
        (address[] memory assets, AssetStorage[] memory assetsStates) = getAssetsWithState();

        (uint256 userLTV, uint256 maximumAllowedLTV) = Solvency.calculateLTVs(
            Solvency.SolvencyParams(
                siloRepository,
                ISilo(address(this)),
                assets,
                assetsStates,
                _user
            ),
            Solvency.TypeofLTV.MaximumLTV
        );

        if (userLTV > maximumAllowedLTV) revert MaximumLTVReached();
    }

    function _getWithdrawAssetData(address _asset, bool _collateralOnly)
        private
        view
        returns(uint256 assetTotalDeposits, IShareToken shareToken, uint256 availableLiquidity)
    {
        AssetStorage storage _state = _assetStorage[_asset];

        if (_collateralOnly) {
            assetTotalDeposits = _state.collateralOnlyDeposits;
            shareToken = _state.collateralOnlyToken;
            availableLiquidity = assetTotalDeposits;
        } else {
            assetTotalDeposits = _state.totalDeposits;
            shareToken = _state.collateralToken;
            availableLiquidity = liquidity(_asset);
        }
    }
}