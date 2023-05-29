// contracts/HighTableVault.sol
// SPDX-License-Identifier: BUSL
// Teahouse Finance

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./IHighTableVault.sol";


/// @title An investment vault for working with TeaVaultV2
/// @author Teahouse Finance
contract HighTableVault is IHighTableVault, AccessControl, ERC20 {

    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_IN_A_YEAR = 365 * 86400;             // for calculating management fee
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    IERC20 internal immutable assetToken;

    FeeConfig public feeConfig;
    FundConfig public fundConfig;
    address[] public nftEnabled;

    GlobalState public globalState;
    mapping(uint32 => CycleState) public cycleState;
    mapping(address => UserState) public userState;

    Price public initialPrice;          // initial price
    Price public closePrice;            // price after fund is closed

    /// @param _name name of the vault token
    /// @param _symbol symbol of the vault token
    /// @param _asset address of the asset token
    /// @param _priceNumerator initial price for each vault token in asset token
    /// @param _priceDenominator price denominator (actual price = _initialPrice / _priceDenominator)
    /// @param _startTimestamp starting timestamp of the first cycle
    /// @param _initialAdmin address of the initial admin
    /// @notice To setup a HighTableVault, the procedure should be
    /// @notice 1. Deploy HighTableVault
    /// @notice 2. Set FeeConfig
    /// @notice 3. (optionally) Deploy TeaVaultV2
    /// @notice 4. Set TeaVaultV2's investor to HighTableVault
    /// @notice 5. Set TeaVaultV2 address (setTeaVaultV2)
    /// @notice 6. Grant auditor role to an address (grantRole)
    /// @notice 7. Set fund locking timestamp for initial cycle (setFundLockingTimestamp)
    /// @notice 8. Set deposit limit for initial cycle (setDepositLimit)
    /// @notice 9. Set enabled NFT list, or disable NFT check (setEnabledNFTs or setDisableNFTChecks)
    /// @notice 10. Users will be able to request deposits
    /// @notice On initial price: the vault token has 18 decimals, so if the asset token is not 18 decimals,
    /// @notice should take extra care in setting the initial price.
    /// @notice For example, if using USDC (has 6 decimals), and want to have 1:1 inital price,
    /// @notice the initial price should be numerator = 1_000_000 and denominator = 1_000_000_000_000_000_000.
    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint128 _priceNumerator,
        uint128 _priceDenominator,
        uint64 _startTimestamp,
        address _initialAdmin,
        address _mintAddress,
        uint256 _mintAmount)
        ERC20(_name, _symbol) {
        if (_priceNumerator == 0 || _priceDenominator == 0) revert InvalidInitialPrice();
        
        _grantRole(DEFAULT_ADMIN_ROLE, _initialAdmin);

        assetToken = IERC20(_asset);
        initialPrice = Price(_priceNumerator, _priceDenominator);

        globalState.cycleStartTimestamp = _startTimestamp;
        _mint(_mintAddress, _mintAmount);

        emit FundInitialized(msg.sender, _priceNumerator, _priceDenominator, _startTimestamp, _initialAdmin);
    }

    /// @inheritdoc IHighTableVault
    function setEnabledNFTs(address[] calldata _nfts) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        nftEnabled = _nfts;

        emit NFTEnabled(msg.sender, globalState.cycleIndex, _nfts);
    }

    /// @inheritdoc IHighTableVault
    function setDisableNFTChecks(bool _checks) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        fundConfig.disableNFTChecks = _checks;

        emit DisableNFTChecks(msg.sender, globalState.cycleIndex, _checks);
    }

    /// @inheritdoc IHighTableVault
    function setFeeConfig(FeeConfig calldata _feeConfig) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();

        if (_feeConfig.managerEntryFee + _feeConfig.platformEntryFee +
            _feeConfig.managerExitFee + _feeConfig.platformExitFee > 1000000) revert InvalidFeePercentage();
        if (_feeConfig.managerPerformanceFee + _feeConfig.platformPerformanceFee > 1000000) revert InvalidFeePercentage();
        if (_feeConfig.managerManagementFee + _feeConfig.platformManagementFee > 1000000) revert InvalidFeePercentage();

        feeConfig = _feeConfig;

        emit FeeConfigChanged(msg.sender, globalState.cycleIndex, _feeConfig);
    }

    /// @inheritdoc IHighTableVault
    function setTeaVaultV2(address _teaVaultV2) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAvailableToAdmins();
        
        fundConfig.teaVaultV2 = ITeaVaultV2(_teaVaultV2);

        emit UpdateTeaVaultV2(msg.sender, globalState.cycleIndex, _teaVaultV2);
    }

    /// @inheritdoc IHighTableVault
    /// @dev Does not use nonReentrant because it can only be called from auditors
    function enterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint128 _withdrawAmount,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) external override returns (uint256 platformFee, uint256 managerFee) {

        // withdraw from vault
        if (_withdrawAmount > 0) {
            fundConfig.teaVaultV2.withdraw(address(this), address(assetToken), _withdrawAmount);
        }

        // permission checks are done in the internal function
        (platformFee, managerFee) = _internalEnterNextCycle(_cycleIndex, _fundValue, _depositLimit, _cycleStartTimestamp, _fundingLockTimestamp, _closeFund);

        // distribute fees
        if (platformFee > 0) {
            assetToken.safeTransfer(feeConfig.platformVault, platformFee);
        }

        if (managerFee > 0) {
            assetToken.safeTransfer(feeConfig.managerVault, managerFee);
        }

        // check if the remaining balance is enough for locked assets
        // and deposit extra balance back to the vault
        uint256 deposits = _internalCheckDeposits();
        if (deposits > 0) {
            assetToken.safeApprove(address(fundConfig.teaVaultV2), deposits);
            fundConfig.teaVaultV2.deposit(address(assetToken), deposits);
        }
    }

    /// @inheritdoc IHighTableVault
    function previewNextCycle(uint128 _fundValue, uint64 _timestamp) external override view returns (uint256 withdrawAmount) {
        if (globalState.cycleIndex > 0) {
            // calculate performance and management fees
            (uint256 pFee, uint256 mFee) = _calculatePMFees(_fundValue, _timestamp);
            withdrawAmount += pFee + mFee;
        }

        uint32 cycleIndex = globalState.cycleIndex;

        // convert total withdrawals to assets
        if (cycleState[cycleIndex].requestedWithdrawals > 0) {
            // if requestedWithdrawals > 0, there must be some remaining shares so totalSupply() won't be zero
            uint256 fundValueAfterPMFee = _fundValue - withdrawAmount;
            withdrawAmount += uint256(cycleState[cycleIndex].requestedWithdrawals) * fundValueAfterPMFee / totalSupply();
        }

        if (cycleState[cycleIndex].requestedDeposits > 0) {
            uint256 requestedDeposits = cycleState[cycleIndex].requestedDeposits;
            uint256 platformFee = requestedDeposits * feeConfig.platformEntryFee / 1000000;
            uint256 managerFee = requestedDeposits * feeConfig.managerEntryFee / 1000000;
            withdrawAmount += platformFee + managerFee;

            if (withdrawAmount > requestedDeposits) {
                withdrawAmount -= requestedDeposits;
            }
            else {
                withdrawAmount = 0;
            }
        }
    }

    /// @inheritdoc IHighTableVault
    function setFundLockingTimestamp(uint64 _fundLockingTimestamp) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        globalState.fundingLockTimestamp = _fundLockingTimestamp;

        emit FundLockingTimestampUpdated(msg.sender, globalState.cycleIndex, _fundLockingTimestamp);
    }

    /// @inheritdoc IHighTableVault
    function setDepositLimit(uint128 _depositLimit) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        globalState.depositLimit = _depositLimit;

        emit DepositLimitUpdated(msg.sender, globalState.cycleIndex, _depositLimit);
    }

    /// @inheritdoc IHighTableVault
    function setDisableFunding(bool _disableDepositing, bool _disableWithdrawing, bool _disableCancelDepositing, bool _disableCancelWithdrawing) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        fundConfig.disableDepositing = _disableDepositing;
        fundConfig.disableWithdrawing = _disableWithdrawing;
        fundConfig.disableCancelDepositing = _disableCancelDepositing;
        fundConfig.disableCancelWithdrawing = _disableCancelWithdrawing; 

        emit FundingChanged(msg.sender, globalState.cycleIndex, _disableDepositing, _disableWithdrawing, _disableCancelDepositing, _disableCancelWithdrawing);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets    
    function depositToVault(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        uint256 balance = assetToken.balanceOf(address(this));
        if (balance - globalState.lockedAssets < _value) revert NotEnoughAssets();

        assetToken.safeApprove(address(fundConfig.teaVaultV2), _value);
        fundConfig.teaVaultV2.deposit(address(assetToken), _value);

        emit DepositToVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since there is no checking nor recording of amount of assets
    function withdrawFromVault(uint256 _value) external override {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();

        fundConfig.teaVaultV2.withdraw(address(this), address(assetToken), _value);

        emit WithdrawFromVault(msg.sender, globalState.cycleIndex, address(fundConfig.teaVaultV2), _value);
    }

    /// @inheritdoc IHighTableVault
    function asset() external override view returns (address assetTokenAddress) {
        return address(assetToken);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function requestDeposit(uint256 _assets, address _receiver) public override {
        assetToken.safeTransferFrom(msg.sender, address(this), _assets);
        _internalRequestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since recording of deposited assets happens after receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function claimAndRequestDeposit(uint256 _assets, address _receiver) external override returns (uint256 assets) {
        assets = claimOwedAssets(msg.sender);
        requestDeposit(_assets, _receiver);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since removing of deposited assets happens before receiving assets
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function cancelDeposit(uint256 _assets, address _receiver) external override {
        _internalCancelDeposit(_assets, _receiver);
        assetToken.safeTransfer(_receiver, _assets);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts    
    function requestWithdraw(uint256 _shares, address _owner) public override {
        if (fundConfig.disableWithdrawing) revert WithdrawDisabled();
        if (globalState.fundClosed) revert FundIsClosed();
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();

        if (_owner != msg.sender) {
            _spendAllowance(_owner, msg.sender, _shares);
        }

        _transfer(_owner, address(this), _shares);

        uint32 cycleIndex = globalState.cycleIndex;
        uint128 shares = SafeCast.toUint128(_shares);
        cycleState[cycleIndex].requestedWithdrawals += shares;

        // if user has previously requested deposits or withdrawals, convert them
        _convertPreviousRequests(_owner);

        userState[_owner].requestedWithdrawals += shares;
        userState[_owner].requestCycleIndex = cycleIndex;

        emit WithdrawalRequested(msg.sender, cycleIndex, _owner, _shares);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function claimAndRequestWithdraw(uint256 _shares, address _owner) external override returns (uint256 shares) {
        shares = claimOwedShares(msg.sender);
        requestWithdraw(_shares, _owner);
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function cancelWithdraw(uint256 _shares, address _receiver) external override {
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (fundConfig.disableCancelWithdrawing) revert CancelWithdrawDisabled();

        uint32 cycleIndex = globalState.cycleIndex;

        if (userState[msg.sender].requestCycleIndex != cycleIndex) revert NotEnoughWithdrawals();
        if (userState[msg.sender].requestedWithdrawals < _shares) revert NotEnoughWithdrawals();

        uint128 shares = SafeCast.toUint128(_shares);
        cycleState[cycleIndex].requestedWithdrawals -= shares;
        userState[msg.sender].requestedWithdrawals -= shares;

        _transfer(address(this), _receiver, _shares);

        emit WithdrawalCanceled(msg.sender, cycleIndex, _receiver, _shares);
    }

    /// @inheritdoc IHighTableVault
    function requestedFunds(address _owner) external override view returns (uint256 assets, uint256 shares) {
        if (userState[_owner].requestCycleIndex != globalState.cycleIndex) {
            return (0, 0);
        }

        assets = userState[_owner].requestedDeposits;
        shares = userState[_owner].requestedWithdrawals;
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because there is no danger of reentrance attack
    /// @dev since owed assets are cleared before sending out
    /// @dev and assetToken has to be attacked in some way to perform reentrance
    function claimOwedAssets(address _receiver) public override returns (uint256 assets) {
        assets = _internalClaimOwedAssets(_receiver);
        if (assets > 0) {
            assetToken.safeTransfer(_receiver, assets);
        }
    }

    /// @inheritdoc IHighTableVault
    /// @dev No need for nonReentrant because this function does not call other contracts
    function claimOwedShares(address _receiver) public override returns (uint256 shares) {
        _convertPreviousRequests(msg.sender);

        if (userState[msg.sender].owedShares > 0) {
            shares = userState[msg.sender].owedShares;
            userState[msg.sender].owedShares = 0;
            _transfer(address(this), _receiver, shares);

            emit ClaimOwedShares(msg.sender, _receiver, shares);
        }
    }

    /// @inheritdoc IHighTableVault
    function claimOwedFunds(address _receiver) external override returns (uint256 assets, uint256 shares) {
        assets = claimOwedAssets(_receiver);
        shares = claimOwedShares(_receiver);
    }

    /// @inheritdoc IHighTableVault
    function closePosition(uint256 _shares, address _owner) public override returns (uint256 assets) {
        if (!globalState.fundClosed) revert FundIsNotClosed();

        if (_owner != msg.sender) {
            _spendAllowance(_owner, msg.sender, _shares);
        }

        _burn(_owner, _shares);

        // closePrice.denominator is the remaining amount of shares when the fund is closed
        // so if it's zero, no one would have any remaining shares to call closePosition
        assets = _shares * closePrice.numerator / closePrice.denominator;
        userState[_owner].owedAssets += SafeCast.toUint128(assets);
    }

    /// @inheritdoc IHighTableVault
    function closePositionAndClaim(address _receiver) external override returns (uint256 assets) {
        claimOwedShares(msg.sender);
        uint256 shares = balanceOf(msg.sender);
        closePosition(shares, msg.sender);
        assets = claimOwedAssets(_receiver);
    }

    /// @notice Internal function for entering next cycle
    function _internalEnterNextCycle(
        uint32 _cycleIndex,
        uint128 _fundValue,
        uint128 _depositLimit,
        uint64 _cycleStartTimestamp,
        uint64 _fundingLockTimestamp,
        bool _closeFund) internal returns (uint256 platformFee, uint256 managerFee) {
        if (!hasRole(AUDITOR_ROLE, msg.sender)) revert OnlyAvailableToAuditors();
        if (address(fundConfig.teaVaultV2) == address(0)) revert IncorrectVaultAddress();
        if (feeConfig.platformVault == address(0)) revert IncorrectVaultAddress();
        if (feeConfig.managerVault == address(0)) revert IncorrectVaultAddress();
        if (globalState.fundClosed) revert FundIsClosed();
        if (_cycleIndex != globalState.cycleIndex) revert IncorrectCycleIndex();
        if (_cycleStartTimestamp <= globalState.cycleStartTimestamp || _cycleStartTimestamp > block.timestamp) revert IncorrectCycleStartTimestamp();

        // record current cycle state
        cycleState[_cycleIndex].totalFundValue = _fundValue;

        uint256 pFee;
        uint256 mFee;
        if (_cycleIndex > 0) {
            // distribute performance and management fees
            (pFee, mFee) = _calculatePMFees(_fundValue, _cycleStartTimestamp);
            platformFee += pFee;
            managerFee += mFee;
        }

        uint256 fundValueAfterPMFees = _fundValue - platformFee - managerFee;
        uint256 currentTotalSupply = totalSupply();

        if (currentTotalSupply > 0 && fundValueAfterPMFees == 0) revert InvalidFundValue();
        if (currentTotalSupply == 0 && cycleState[_cycleIndex].requestedDeposits == 0) revert NoDeposits();

        (pFee, mFee) = _processRequests(fundValueAfterPMFees);
        platformFee += pFee;
        managerFee += mFee;

        if (_closeFund) {
            // calculate exit fees for all remaining funds
            (pFee, mFee) = _calculateCloseFundFees();
            platformFee += pFee;
            managerFee += mFee;

            // set price for closing position
            uint128 finalFundValue = SafeCast.toUint128(cycleState[globalState.cycleIndex].fundValueAfterRequests - pFee - mFee);
            closePrice = Price(finalFundValue, SafeCast.toUint128(totalSupply()));
            globalState.lockedAssets += finalFundValue;
            globalState.fundClosed = true;
        }

        if (currentTotalSupply == 0) {
            emit EnterNextCycle(
                msg.sender,
                _cycleIndex,
                _fundValue,
                initialPrice.numerator,
                initialPrice.denominator,
                _depositLimit,
                _cycleStartTimestamp,
                _fundingLockTimestamp,
                _closeFund,
                platformFee,
                managerFee);
        }
        else {
            emit EnterNextCycle(
                msg.sender,
                _cycleIndex,
                _fundValue,
                fundValueAfterPMFees,
                currentTotalSupply,
                _depositLimit,
                _cycleStartTimestamp,
                _fundingLockTimestamp,
                _closeFund,
                platformFee,
                managerFee);
        }

        // enter next cycle
        globalState.cycleIndex ++;
        globalState.cycleStartTimestamp = _cycleStartTimestamp;
        globalState.depositLimit = _depositLimit;
        globalState.fundingLockTimestamp = _fundingLockTimestamp;
    }

    /// @notice Interal function for checking if the remaining balance is enough for locked assets
    function _internalCheckDeposits() internal view returns (uint256 deposits) {
        deposits = assetToken.balanceOf(address(this));
        if (deposits < globalState.lockedAssets) revert NotEnoughAssets();
        unchecked {
            deposits = deposits - globalState.lockedAssets;
        }
    }

    /// @notice Calculate performance and management fees
    function _calculatePMFees(uint128 _fundValue, uint64 _timestamp) internal view returns (uint256 platformFee, uint256 managerFee) {
        // calculate management fees
        uint256 fundValue = _fundValue;
        uint64 timeDiff = _timestamp - globalState.cycleStartTimestamp;
        unchecked {
            platformFee = fundValue * feeConfig.platformManagementFee * timeDiff / (SECONDS_IN_A_YEAR * 1000000);
            managerFee = fundValue * feeConfig.managerManagementFee * timeDiff / (SECONDS_IN_A_YEAR * 1000000);
        }

        // calculate and distribute performance fees
        if (fundValue > cycleState[globalState.cycleIndex - 1].fundValueAfterRequests) {
            unchecked {
                uint256 profits = fundValue - cycleState[globalState.cycleIndex - 1].fundValueAfterRequests;
                platformFee += profits * feeConfig.platformPerformanceFee / 1000000;
                managerFee += profits * feeConfig.managerPerformanceFee / 1000000;
            }
        }
    }

    /// @notice Calculate exit fees when closing fund
    function _calculateCloseFundFees() internal view returns (uint256 platformFee, uint256 managerFee) {
        // calculate exit fees for remaining funds
        uint256 fundValue = cycleState[globalState.cycleIndex].fundValueAfterRequests;

        unchecked {
            platformFee = fundValue * feeConfig.platformExitFee / 1000000;
            managerFee = fundValue * feeConfig.managerExitFee / 1000000;
        }
    }

    /// @notice Process requested withdrawals and deposits
    function _processRequests(uint256 _fundValueAfterPMFees) internal returns (uint256 platformFee, uint256 managerFee) {
        uint32 cycleIndex = globalState.cycleIndex;
        uint256 currentTotalSupply = totalSupply();
        uint256 fundValueAfterRequests = _fundValueAfterPMFees;

        // convert total withdrawals to assets and calculate exit fees
        if (cycleState[cycleIndex].requestedWithdrawals > 0) {
            // if requestedWithdrawals > 0, there must be some remaining shares so totalSupply() won't be zero
            uint256 withdrawnAssets = _fundValueAfterPMFees * cycleState[cycleIndex].requestedWithdrawals / currentTotalSupply;
            uint256 pFee;
            uint256 mFee;

            unchecked {
                pFee = withdrawnAssets * feeConfig.platformExitFee / 1000000;
                mFee = withdrawnAssets * feeConfig.managerExitFee / 1000000;
            }

            // record remaining assets available for withdrawals
            cycleState[cycleIndex].convertedWithdrawals = SafeCast.toUint128(withdrawnAssets - pFee - mFee);
            globalState.lockedAssets += cycleState[cycleIndex].convertedWithdrawals;
            fundValueAfterRequests -= SafeCast.toUint128(withdrawnAssets);

            platformFee += pFee;
            managerFee += mFee;

            // burn converted share tokens
            _burn(address(this), cycleState[cycleIndex].requestedWithdrawals);
        }

        // convert total deposits to shares and calculate entry fees
        if (cycleState[cycleIndex].requestedDeposits > 0) {
            uint256 requestedDeposits = cycleState[cycleIndex].requestedDeposits;
            uint256 pFee;
            uint256 mFee;
            
            unchecked {
                pFee = requestedDeposits * feeConfig.platformEntryFee / 1000000;
                mFee = requestedDeposits * feeConfig.managerEntryFee / 1000000;
            }

            globalState.lockedAssets -= cycleState[cycleIndex].requestedDeposits;
            requestedDeposits = requestedDeposits - pFee - mFee;
            fundValueAfterRequests += SafeCast.toUint128(requestedDeposits);

            if (currentTotalSupply == 0) {
                // use initial price if there's no share tokens
                cycleState[cycleIndex].convertedDeposits = SafeCast.toUint128(requestedDeposits * initialPrice.denominator / initialPrice.numerator);
            }
            else {
                // _fundValueAfterPMFees is checked to be non-zero when total supply is non-zero
                cycleState[cycleIndex].convertedDeposits = SafeCast.toUint128(requestedDeposits * currentTotalSupply / _fundValueAfterPMFees);
            }

            platformFee += pFee;
            managerFee += mFee;

            // mint new share tokens
            _mint(address(this), cycleState[cycleIndex].convertedDeposits);
        }

        cycleState[cycleIndex].fundValueAfterRequests = SafeCast.toUint128(fundValueAfterRequests);
    }

    /// @notice Convert previous requested deposits and withdrawls
    function _convertPreviousRequests(address _receiver) internal {
        uint32 cycleIndex = userState[_receiver].requestCycleIndex;

        if (cycleIndex >= globalState.cycleIndex) {
            return;
        }

        if (userState[_receiver].requestedDeposits > 0) {
            // if requestedDeposits of a user > 0 then requestedDeposits of the cycle must be > 0
            uint256 owedShares = uint256(userState[_receiver].requestedDeposits) * cycleState[cycleIndex].convertedDeposits / cycleState[cycleIndex].requestedDeposits;
            userState[_receiver].owedShares += SafeCast.toUint128(owedShares);
            emit ConvertToShares(_receiver, cycleIndex, userState[_receiver].requestedDeposits, owedShares);
            userState[_receiver].requestedDeposits = 0;
        }

        if (userState[_receiver].requestedWithdrawals > 0) {
            // if requestedWithdrawals of a user > 0 then requestedWithdrawals of the cycle must be > 0
            uint256 owedAssets = uint256(userState[_receiver].requestedWithdrawals) * cycleState[cycleIndex].convertedWithdrawals / cycleState[cycleIndex].requestedWithdrawals;
            userState[_receiver].owedAssets += SafeCast.toUint128(owedAssets);
            emit ConvertToAssets(_receiver, cycleIndex, userState[_receiver].requestedWithdrawals, owedAssets);
            userState[_receiver].requestedWithdrawals = 0;
        }
    }

    /// @notice Internal function for processing deposit requests
    function _internalRequestDeposit(uint256 _assets, address _receiver) internal {
        if (fundConfig.disableDepositing) revert DepositDisabled();
        if (globalState.fundClosed) revert FundIsClosed();
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (_assets + cycleState[globalState.cycleIndex].requestedDeposits > globalState.depositLimit) revert ExceedDepositLimit();
        if (!_hasNFT(_receiver)) revert ReceiverDoNotHasNFT();

        uint32 cycleIndex = globalState.cycleIndex;
        uint128 assets = SafeCast.toUint128(_assets);
        cycleState[cycleIndex].requestedDeposits += assets;
        globalState.lockedAssets += assets;

        // if user has previously requested deposits or withdrawals, convert them
        _convertPreviousRequests(_receiver);

        userState[_receiver].requestedDeposits += assets;
        userState[_receiver].requestCycleIndex = cycleIndex;

        emit DepositRequested(msg.sender, cycleIndex, _receiver, _assets);
    }

    /// @notice Internal function for canceling deposit requests
    function _internalCancelDeposit(uint256 _assets, address _receiver) internal {
        if (block.timestamp > globalState.fundingLockTimestamp) revert FundingLocked();
        if (fundConfig.disableCancelDepositing) revert CancelDepositDisabled();

        uint32 cycleIndex = globalState.cycleIndex;

        if (userState[msg.sender].requestCycleIndex != cycleIndex) revert NotEnoughDeposits();
        if (userState[msg.sender].requestedDeposits < _assets) revert NotEnoughDeposits();

        uint128 assets = SafeCast.toUint128(_assets);
        cycleState[cycleIndex].requestedDeposits -= assets;
        globalState.lockedAssets -= assets;
        userState[msg.sender].requestedDeposits -= assets;

        emit DepositCanceled(msg.sender, cycleIndex, _receiver, _assets);
    }

    /// @notice Internal function for claiming owed assets
    function _internalClaimOwedAssets(address _receiver) internal returns (uint256 assets) {
        _convertPreviousRequests(msg.sender);

        if (userState[msg.sender].owedAssets > 0) {
            assets = userState[msg.sender].owedAssets;
            globalState.lockedAssets -= userState[msg.sender].owedAssets;
            userState[msg.sender].owedAssets = 0;

            emit ClaimOwedAssets(msg.sender, _receiver, assets);
        }
    }

    /// @notice Internal NFT checker
    /// @param _receiver address of the receiver
    /// @return hasNFT true if the receiver has at least one of the NFT, false if not
    /// @dev always returns true if disableNFTChecks is enabled
    function _hasNFT(address _receiver) internal view returns (bool hasNFT) {
        if (fundConfig.disableNFTChecks) {
            return true;
        }

        uint256 i;
        uint256 length = nftEnabled.length;
        for (i = 0; i < length; ) {
            if (IERC721(nftEnabled[i]).balanceOf(_receiver) > 0) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }
}