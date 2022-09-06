// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== FraxlendPair ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian
// Travis Moore: https://github.com/FortisFortuna
// Jack Corddry: https://github.com/corddry
// Rich Gee: https://github.com/zer0blockchain

// ====================================================================

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./FraxlendPairConstants.sol";
import "./FraxlendPairCore.sol";
import "./libraries/VaultAccount.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IFraxlendWhitelist.sol";
import "./interfaces/IRateCalculator.sol";
import "./interfaces/ISwapper.sol";

contract FraxlendPair is IERC20Metadata, FraxlendPairCore {
    using VaultAccountingLibrary for VaultAccount;
    using SafeERC20 for IERC20;

    constructor(
        bytes memory _configData,
        bytes memory _immutables,
        uint256 _maxLTV,
        uint256 _liquidationFee,
        uint256 _maturityDate,
        uint256 _penaltyRate,
        bool _isBorrowerWhitelistActive,
        bool _isLenderWhitelistActive
    )
        FraxlendPairCore(
            _configData,
            _immutables,
            _maxLTV,
            _liquidationFee,
            _maturityDate,
            _penaltyRate,
            _isBorrowerWhitelistActive,
            _isLenderWhitelistActive
        )
        ERC20("", "")
        Ownable()
        Pausable()
    {}

    // ============================================================================================
    // ERC20 Metadata
    // ============================================================================================

    function name() public view override(ERC20, IERC20Metadata) returns (string memory) {
        return nameOfContract;
    }

    function symbol() public view override(ERC20, IERC20Metadata) returns (string memory) {
        // prettier-ignore
        // solhint-disable-next-line max-line-length
        return string(abi.encodePacked("FraxlendV1 - ", collateralContract.safeSymbol(), "/", assetContract.safeSymbol()));
    }

    function decimals() public pure override(ERC20, IERC20Metadata) returns (uint8) {
        return 18;
    }

    // totalSupply for fToken ERC20 compatibility
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return totalAsset.shares;
    }

    // ============================================================================================
    // Functions: Helpers
    // ============================================================================================

    function asset() external view returns (address) {
        return address(assetContract);
    }

    function getConstants()
        external
        pure
        returns (
            uint256 _LTV_PRECISION,
            uint256 _LIQ_PRECISION,
            uint256 _UTIL_PREC,
            uint256 _FEE_PRECISION,
            uint256 _EXCHANGE_PRECISION,
            uint64 _DEFAULT_INT,
            uint16 _DEFAULT_PROTOCOL_FEE,
            uint256 _MAX_PROTOCOL_FEE
        )
    {
        _LTV_PRECISION = LTV_PRECISION;
        _LIQ_PRECISION = LIQ_PRECISION;
        _UTIL_PREC = UTIL_PREC;
        _FEE_PRECISION = FEE_PRECISION;
        _EXCHANGE_PRECISION = EXCHANGE_PRECISION;
        _DEFAULT_INT = DEFAULT_INT;
        _DEFAULT_PROTOCOL_FEE = DEFAULT_PROTOCOL_FEE;
        _MAX_PROTOCOL_FEE = MAX_PROTOCOL_FEE;
    }

    /// @notice The ```getImmutableAddressBool``` function gets all the address and bool configs
    /// @return _assetContract Address of asset
    /// @return _collateralContract Address of collateral
    /// @return _oracleMultiply Address of oracle numerator
    /// @return _oracleDivide Address of oracle denominator
    /// @return _rateContract Address of rate contract
    /// @return _DEPLOYER_CONTRACT Address of deployer contract
    /// @return _COMPTROLLER_ADDRESS Address of comptroller
    /// @return _FRAXLEND_WHITELIST Address of whitelist
    /// @return _borrowerWhitelistActive Boolean is borrower whitelist active
    /// @return _lenderWhitelistActive Boolean is lender whitelist active
    function getImmutableAddressBool()
        external
        view
        returns (
            address _assetContract,
            address _collateralContract,
            address _oracleMultiply,
            address _oracleDivide,
            address _rateContract,
            address _DEPLOYER_CONTRACT,
            address _COMPTROLLER_ADDRESS,
            address _FRAXLEND_WHITELIST,
            bool _borrowerWhitelistActive,
            bool _lenderWhitelistActive
        )
    {
        _assetContract = address(assetContract);
        _collateralContract = address(collateralContract);
        _oracleMultiply = oracleMultiply;
        _oracleDivide = oracleDivide;
        _rateContract = address(rateContract);
        _DEPLOYER_CONTRACT = DEPLOYER_ADDRESS;
        _COMPTROLLER_ADDRESS = COMPTROLLER_ADDRESS;
        _FRAXLEND_WHITELIST = FRAXLEND_WHITELIST_ADDRESS;
        _borrowerWhitelistActive = borrowerWhitelistActive;
        _lenderWhitelistActive = lenderWhitelistActive;
    }

    /// @notice The ```getImmutableUint256``` function gets all uint256 config values
    /// @return _oracleNormalization Oracle normalization factor
    /// @return _maxLTV Maximum LTV
    /// @return _cleanLiquidationFee Clean Liquidation Fee
    /// @return _maturityDate Maturity Date
    /// @return _penaltyRate Penalty Rate
    function getImmutableUint256()
        external
        view
        returns (
            uint256 _oracleNormalization,
            uint256 _maxLTV,
            uint256 _cleanLiquidationFee,
            uint256 _maturityDate,
            uint256 _penaltyRate
        )
    {
        _oracleNormalization = oracleNormalization;
        _maxLTV = maxLTV;
        _cleanLiquidationFee = cleanLiquidationFee;
        _maturityDate = maturityDate;
        _penaltyRate = penaltyRate;
    }

    /// @notice The ```getUserSnapshot``` function gets user level accounting data
    /// @param _address The user address
    /// @return _userAssetShares The user fToken balance
    /// @return _userBorrowShares The user borrow shares
    /// @return _userCollateralBalance The user collateral balance
    function getUserSnapshot(address _address)
        external
        view
        returns (
            uint256 _userAssetShares,
            uint256 _userBorrowShares,
            uint256 _userCollateralBalance
        )
    {
        _userAssetShares = balanceOf(_address);
        _userBorrowShares = userBorrowShares[_address];
        _userCollateralBalance = userCollateralBalance[_address];
    }

    /// @notice The ```getPairAccounting``` function gets all pair level accounting numbers
    /// @return _totalAssetAmount Total assets deposited and interest accrued, total claims
    /// @return _totalAssetShares Total fTokens
    /// @return _totalBorrowAmount Total borrows
    /// @return _totalBorrowShares Total borrow shares
    /// @return _totalCollateral Total collateral
    function getPairAccounting()
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        )
    {
        VaultAccount memory _totalAsset = totalAsset;
        _totalAssetAmount = _totalAsset.amount;
        _totalAssetShares = _totalAsset.shares;

        VaultAccount memory _totalBorrow = totalBorrow;
        _totalBorrowAmount = _totalBorrow.amount;
        _totalBorrowShares = _totalBorrow.shares;
        _totalCollateral = totalCollateral;
    }

    /// @notice The ```toBorrowShares``` function converts a given amount of borrow debt into the number of shares
    /// @param _amount Amount of borrow
    /// @param _roundUp Whether to roundup during division
    function toBorrowShares(uint256 _amount, bool _roundUp) external view returns (uint256) {
        return totalBorrow.toShares(_amount, _roundUp);
    }

    /// @notice The ```toBorrowAmount``` function converts a given amount of borrow debt into the number of shares
    /// @param _shares Shares of borrow
    /// @param _roundUp Whether to roundup during division
    /// @return The amount of asset
    function toBorrowAmount(uint256 _shares, bool _roundUp) external view returns (uint256) {
        return totalBorrow.toAmount(_shares, _roundUp);
    }

    /// @notice The ```toAssetAmount``` function converts a given number of shares to an asset amount
    /// @param _shares Shares of asset (fToken)
    /// @param _roundUp Whether to round up after division
    /// @return The amount of asset
    function toAssetAmount(uint256 _shares, bool _roundUp) external view returns (uint256) {
        return totalAsset.toAmount(_shares, _roundUp);
    }

    /// @notice The ```toAssetShares``` function converts a given asset amount to a number of asset shares (fTokens)
    /// @param _amount The amount of asset
    /// @param _roundUp Whether to round up after division
    /// @return The number of shares (fTokens)
    function toAssetShares(uint256 _amount, bool _roundUp) external view returns (uint256) {
        return totalAsset.toShares(_amount, _roundUp);
    }

    // ============================================================================================
    // Functions: Configuration
    // ============================================================================================
    /// @notice The ```SetTimeLock``` event fires when the TIME_LOCK_ADDRESS is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetTimeLock(address _oldAddress, address _newAddress);

    /// @notice The ```setTimeLock``` function sets the TIME_LOCK address
    /// @param _newAddress the new time lock address
    function setTimeLock(address _newAddress) external {
        if (msg.sender != TIME_LOCK_ADDRESS) revert OnlyTimeLock();
        emit SetTimeLock(TIME_LOCK_ADDRESS, _newAddress);
        TIME_LOCK_ADDRESS = _newAddress;
    }

    /// @notice The ```ChangeFee``` event first when the fee is changed
    /// @param _newFee The new fee
    event ChangeFee(uint32 _newFee);

    /// @notice The ```changeFee``` function changes the protocol fee, max 50%
    /// @param _newFee The new fee
    function changeFee(uint32 _newFee) external whenNotPaused {
        if (msg.sender != TIME_LOCK_ADDRESS) revert OnlyTimeLock();
        if (_newFee > MAX_PROTOCOL_FEE) {
            revert BadProtocolFee();
        }
        _addInterest();
        currentRateInfo.feeToProtocolRate = _newFee;
        emit ChangeFee(_newFee);
    }

    /// @notice The ```WithdrawFees``` event fires when the fees are withdrawn
    /// @param _shares Number of _shares (fTokens) redeemed
    /// @param _recipient To whom the assets were sent
    /// @param _amountToTransfer The amount of fees redeemed
    event WithdrawFees(uint128 _shares, address _recipient, uint256 _amountToTransfer);

    /// @notice The ```withdrawFees``` function withdraws fees accumulated
    /// @param _shares Number of fTokens to redeem
    /// @param _recipient Address to send the assets
    /// @return _amountToTransfer Amount of assets sent to recipient
    function withdrawFees(uint128 _shares, address _recipient) external onlyOwner returns (uint256 _amountToTransfer) {
        // Grab some data from state to save gas
        VaultAccount memory _totalAsset = totalAsset;
        VaultAccount memory _totalBorrow = totalBorrow;

        // Take all available if 0 value passed
        if (_shares == 0) _shares = uint128(balanceOf(address(this)));

        // We must calculate this before we subtract from _totalAsset or invoke _burn
        _amountToTransfer = _totalAsset.toAmount(_shares, true);

        // Check for sufficient withdraw liquidity
        uint256 _assetsAvailable = _totalAssetAvailable(_totalAsset, _totalBorrow);
        if (_assetsAvailable < _amountToTransfer) {
            revert InsufficientAssetsInContract(_assetsAvailable, _amountToTransfer);
        }

        // Effects: bookkeeping
        _totalAsset.amount -= uint128(_amountToTransfer);
        _totalAsset.shares -= _shares;

        // Effects: write to states
        // NOTE: will revert if _shares > balanceOf(address(this))
        _burn(address(this), _shares);
        totalAsset = _totalAsset;

        // Interactions
        assetContract.safeTransfer(_recipient, _amountToTransfer);
        emit WithdrawFees(_shares, _recipient, _amountToTransfer);
    }

    /// @notice The ```SetSwapper``` event fires whenever a swapper is black or whitelisted
    /// @param _swapper The swapper address
    /// @param _approval The approval
    event SetSwapper(address _swapper, bool _approval);

    /// @notice The ```setSwapper``` function is called to black or whitelist a given swapper address
    /// @dev
    /// @param _swapper The swapper address
    /// @param _approval The approval
    function setSwapper(address _swapper, bool _approval) external onlyOwner {
        swappers[_swapper] = _approval;
        emit SetSwapper(_swapper, _approval);
    }

    /// @notice The ```SetApprovedLender``` event fires when a lender is black or whitelisted
    /// @param _address The address
    /// @param _approval The approval
    event SetApprovedLender(address indexed _address, bool _approval);

    /// @notice The ```setApprovedLenders``` function sets a given set of addresses to the whitelist
    /// @dev Cannot black list self
    /// @param _lenders The addresses who's status will be set
    /// @param _approval The approval status
    function setApprovedLenders(address[] calldata _lenders, bool _approval) external approvedLender(msg.sender) {
        for (uint256 i = 0; i < _lenders.length; i++) {
            // Do not set when _approval == false and _lender == msg.sender
            if (_approval || _lenders[i] != msg.sender) {
                approvedLenders[_lenders[i]] = _approval;
                emit SetApprovedLender(_lenders[i], _approval);
            }
        }
    }

    /// @notice The ```SetApprovedBorrower``` event fires when a borrower is black or whitelisted
    /// @param _address The address
    /// @param _approval The approval
    event SetApprovedBorrower(address indexed _address, bool _approval);

    /// @notice The ```setApprovedBorrowers``` function sets a given array of addresses to the whitelist
    /// @dev Cannot black list self
    /// @param _borrowers The addresses who's status will be set
    /// @param _approval The approval status
    function setApprovedBorrowers(address[] calldata _borrowers, bool _approval) external approvedBorrower {
        for (uint256 i = 0; i < _borrowers.length; i++) {
            // Do not set when _approval == false and _borrower == msg.sender
            if (_approval || _borrowers[i] != msg.sender) {
                approvedBorrowers[_borrowers[i]] = _approval;
                emit SetApprovedBorrower(_borrowers[i], _approval);
            }
        }
    }

    function pause() external {
        if (
            msg.sender != CIRCUIT_BREAKER_ADDRESS &&
            msg.sender != COMPTROLLER_ADDRESS &&
            msg.sender != owner() &&
            msg.sender != DEPLOYER_ADDRESS
        ) {
            revert ProtocolOrOwnerOnly();
        }
        _addInterest(); // accrue any interest prior to pausing as it won't accrue during pause
        _pause();
    }

    function unpause() external {
        if (msg.sender != COMPTROLLER_ADDRESS && msg.sender != owner()) {
            revert ProtocolOrOwnerOnly();
        }
        // Resets the lastTimestamp which has the effect of no interest accruing over the pause period
        _addInterest();
        _unpause();
    }
}