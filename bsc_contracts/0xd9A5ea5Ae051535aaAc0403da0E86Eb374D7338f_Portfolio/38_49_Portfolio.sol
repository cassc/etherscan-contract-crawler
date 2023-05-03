// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { Base } from "./Base.sol";
import { IPortfolio, Status, TrancheData, TrancheInitData } from "./interfaces/IPortfolio.sol";
import { ITranchePool } from "./interfaces/ITranchePool.sol";
import { ICurrencyConverter } from "./interfaces/ICurrencyConverter.sol";
import { IFixedInterestBulletLoans } from "./interfaces/IFixedInterestBulletLoans.sol";
import { AddLoanParams, ILoansManager } from "./interfaces/ILoansManager.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { Context } from "openzeppelin-contracts/contracts/utils/Context.sol";
import { IProtocolConfig } from "./interfaces/IProtocolConfig.sol";
import { LoansManager } from "./LoansManager.sol";
import { MathUtils } from "./libraries/MathUtils.sol";
import { UpgradeableBase } from "./UpgradeableBase.sol";

/// @title Portfolio
/// @notice This smart contract represents a portfolio of loans that are managed by tranches.
/// Each tranche can have different risk profiles and yields.
/// The main functions are starting the portfolio, closing senior and equity tranches, and handling loans.
/// It uses the LoansManager contract to manage loans and relies on TranchePool contracts for tranche management.
/// @dev Min number of tranches is 2, first tranche is always equity.
contract Portfolio is IPortfolio, UpgradeableBase, LoansManager {
    // keccak256("GOVERNANCE_ROLE")
    bytes32 public constant GOVERNANCE_ROLE = 0x71840dc4906352362b0cdaf79870196c8e42acafade72d5d5a6d59291253ceb1;

    /// @dev tranche[0] is always equity
    ITranchePool[] public tranches;
    TrancheData[] public tranchesData;
    Status public status;
    uint40 public startTimestamp;
    uint256 public stoppedTimestamp;

    using SafeERC20 for IERC20;

    /**
     * @param tranchesInitData [{equityTrancheAddress, targetApr}, {seniorTrancheAddress, targetApr}]
     */
    function initialize(
        address manager,
        address governance,
        IERC20 _asset,
        IProtocolConfig _protocolConfig,
        TrancheInitData[] memory tranchesInitData,
        IFixedInterestBulletLoans _fixedInterestBulletLoans
    )
        public
        initializer
    {
        __UpgradeableBase_init(_protocolConfig.protocolAdmin(), _protocolConfig.pauser());
        __LoanManager_init(_fixedInterestBulletLoans, _asset);
        _grantManagerRole(manager);
        _grantGovernanceRole(governance);
        uint256 tranchesCount = tranchesInitData.length;

        for (uint256 i = 0; i < tranchesCount; i++) {
            TrancheInitData memory initData = tranchesInitData[i];
            // validate
            if (i == 0 && initData.targetApr != 0) {
                revert EquityAprNotZero();
            }

            tranches.push(initData.tranche);
            initData.tranche.setPortfolio(this);

            tranchesData.push(
                TrancheData({
                    initialAssets: 0,
                    targetApr: initData.targetApr,
                    minSubordinateRatio: initData.minSubordinateRatio
                })
            );
        }

        _fixedInterestBulletLoans.setPortfolio(this);
    }

    /// @inheritdoc IPortfolio
    function start() external whenNotPaused {
        _requireManagerRole();
        _validateStart();

        startTimestamp = uint40(block.timestamp);
        uint256 tranchesCount = tranches.length;
        for (uint256 i = 0; i < tranchesCount; i++) {
            tranchesData[i].initialAssets = tranches[i].onPortfolioStart();
        }

        _changePortfolioStatus(Status.Live);
    }

    /// @inheritdoc IPortfolio
    function closeSenior() external whenNotPaused {
        _requireManagerRole();
        _validateCloseSenior();

        _distributeToTranches(1);

        _changePortfolioStatus(Status.SeniorClosed);
    }

    /// @inheritdoc IPortfolio
    function closeEquity() external whenNotPaused {
        _requireManagerRole();
        _validateCloseEquity();

        if (status == Status.Live || status == Status.Stopped) {
            _distributeToTranches(0);
        } else if (status == Status.SeniorClosed) {
            // transfer all remaining tokens to the equity tranche
            uint256 balance = _getTokenBalance();
            _transferAsset(address(tranches[0]), balance);
            tranches[0].increaseTokenBalance(balance);
        }

        _changePortfolioStatus(Status.EquityClosed);
    }

    /// @inheritdoc IPortfolio
    /// @dev no fee
    function calculateWaterfall() public view returns (uint256[] memory) {
        uint256 assetsLeft = _getTokenBalance();
        return _calculateWaterfall(assetsLeft);
    }

    /// @inheritdoc IPortfolio
    /// @dev no fee
    function calculateWaterfallForTranche(uint256 waterfallIndex) external view returns (uint256) {
        uint256 assetsLeft = _getTokenBalance();
        return _calculateWaterfall(assetsLeft)[waterfallIndex];
    }

    /// @inheritdoc IPortfolio
    /// @dev no fee
    function calculateWaterfallWithLoansForTranche(uint256 waterfallIndex) external view returns (uint256) {
        uint256 assetsLeft = _getTokenBalance() + loansValue();
        return _calculateWaterfall(assetsLeft)[waterfallIndex];
    }

    /// @inheritdoc IPortfolio
    /// @dev no fee
    function calculateWaterfallWithLoans() public view returns (uint256[] memory) {
        uint256 assetsLeft = _getTokenBalance() + loansValue();
        return _calculateWaterfall(assetsLeft);
    }

    /// @inheritdoc IPortfolio
    function loansValue() public view returns (uint256) {
        uint256[] memory _loans = activeLoanIds;

        uint256 _value = 0;
        for (uint256 i = 0; i < _loans.length; i++) {
            _value += fixedInterestBulletLoans.currentUsdValue(_loans[i]);
        }
        return _value;
    }

    /// @inheritdoc IPortfolio
    function getTokenBalance() external view returns (uint256) {
        return _getTokenBalance();
    }

    // *************** Internal *************** //

    function _validateStart() internal view {
        if (status != Status.Preparation) {
            revert AlreadyStarted();
        }

        // TODO: check ratio
    }

    /// @custom:check asset balance is enough to pay for the tranche.
    function _validateCloseSenior() internal view {
        if (status != Status.Live && status != Status.Stopped) {
            revert NotReadyToCloseSenior();
        }

        uint256 assetsLeft = _getTokenBalance();
        uint256 tranchesCount = tranches.length;
        for (uint256 i = tranchesCount - 1; i > 0; i--) {
            uint256 trancheValue = _assumedTrancheValue(i, block.timestamp);
            if (assetsLeft >= trancheValue) {
                assetsLeft -= trancheValue;
            } else {
                revert NotFullyFunded();
            }
        }
    }

    /**
     * @notice validate portfolio
     * @custom:status - Live || SeniorClosed || Stopped
     */
    function _validateCloseEquity() internal view {
        if (status != Status.Live && status != Status.SeniorClosed && status != Status.Stopped) {
            revert NotReadyToCloseEquity();
        }

        if (activeLoanIds.length > 0) {
            revert ActiveLoansExist();
        }
    }

    function _distributeToTranches(uint256 lowestIndex) internal {
        uint256[] memory waterfall = calculateWaterfall();
        uint256 tranchesCount = tranches.length;
        for (uint256 i = lowestIndex; i < tranchesCount; i++) {
            _transferAsset(address(tranches[i]), waterfall[i]);
            tranches[i].increaseTokenBalance(waterfall[i]);
        }
    }

    /**
     * @notice calculate each tranche values based only on the current assets and the status.
     * @dev    1. if the portfolio is in the preparation / equity closed stage, return the current assets of each
     * tranche.
     *         2. if the portfolio is in the live / paused stage, calculate based on the current assets in the portfolio
     * and the loans value.
     *         3. if the portfolio is in the senior closed stage, return the current assets of each tranche except for
     * the equity tranche.
     */
    function _calculateWaterfall(uint256 assetsLeft) internal view returns (uint256[] memory) {
        uint256 tranchesCount = tranches.length;
        uint256[] memory trancheValues = new uint256[](tranchesCount);
        Status _status = status;

        if (_status == Status.EquityClosed || _status == Status.Preparation) {
            for (uint256 i = 0; i < tranches.length; i++) {
                trancheValues[i] = tranches[i].totalAssets();
            }
            return trancheValues;
        } else if (_status == Status.SeniorClosed) {
            trancheValues[0] = _getTokenBalance();
            for (uint256 i = 1; i < tranches.length; i++) {
                trancheValues[i] = tranches[i].totalAssets();
            }
            return trancheValues;
        }

        // Live or Paused
        for (uint256 i = tranchesCount - 1; i > 0; i--) {
            uint256 trancheValue = _assumedTrancheValue(i, block.timestamp);
            if (assetsLeft > trancheValue) {
                assetsLeft -= trancheValue;
                trancheValues[i] = trancheValue;
            } else {
                trancheValues[i] = assetsLeft;
                return trancheValues;
            }
        }

        trancheValues[0] = assetsLeft; // equity tranche

        return trancheValues;
    }

    function _assumedTrancheValue(uint256 trancheIdx, uint256 timestamp) internal view returns (uint256) {
        TrancheData memory trancheData = tranchesData[trancheIdx];
        uint256 targetApr = trancheData.targetApr;
        uint256 initialAssets = trancheData.initialAssets;

        return initialAssets
            + MathUtils.calculateLinearInterest(initialAssets, targetApr, uint256(startTimestamp), timestamp);
    }

    function _changePortfolioStatus(Status newStatus) internal {
        status = newStatus;
        emit PortfolioStatusChanged(newStatus);
    }

    /**
     * @notice Create loan
     * @param params Loan params
     * @custom:status - Preparation, Live
     * @custom:role - manager || collateral owner
     */
    function addLoan(AddLoanParams calldata params) external whenNotPaused returns (uint256) {
        address collateral = params.collateral;
        uint256 collateralId = params.collateralId;
        if (status != Status.Preparation && status != Status.Live) {
            revert AddLoanNotAllowed();
        }
        _requireManagerOrCollateralOwner(collateral, collateralId);
        return _addLoan(params);
    }

    /**
     * @notice Fund the loan
     * @param loanId Loan id
     * @custom:status - Live
     * @custom:role - governance
     */
    function fundLoan(uint256 loanId) external whenNotPaused returns (uint256 principal) {
        _requireGovernanceRole();
        if (status != Status.Live) {
            revert FundLoanNotAllowed();
        }
        principal = _fundLoan(loanId);
    }

    /**
     * @notice Repay the loan
     * @param loanId Loan id
     * @custom:status - Live || SeniorClosed || Stopped
     * @custom:role - all
     */
    function repayLoan(uint256 loanId) external whenNotPaused returns (uint256 amount) {
        if (status != Status.Live && status != Status.SeniorClosed && status != Status.Stopped) {
            revert RepayLoanNotAllowed();
        }
        return _repayLoan(loanId);
    }

    /**
     * @notice Repay the loan
     * @param loanId Loan id
     * @param amount amount
     * @custom:status - Live || SeniorClosed || Stopped
     * @custom:role - manager
     */
    function repayDefaultedLoan(uint256 loanId, uint256 amount) external whenNotPaused {
        _requireManagerRole();
        if (status != Status.Live && status != Status.SeniorClosed && status != Status.Stopped) {
            revert RepayDefaultedLoanNotAllowed();
        }
        _repayDefaultedLoan(loanId, amount);
    }
    /**
     * @notice cancel the loan
     * @param loanId loan id
     * @custom:status - all (as long as the loan exists)
     * @custom:role - manager
     */

    function cancelLoan(uint256 loanId) external {
        _requireManagerRole();
        _cancelLoan(loanId);
    }

    function getAssumedCurrentValues()
        public
        view
        returns (uint256 equityValue, uint256 fixedRatePoolValue, uint256 overdueValue)
    {
        uint256[] memory assumedWaterfall = calculateWaterfallWithLoans();
        equityValue = assumedWaterfall[0];
        uint256 length = assumedWaterfall.length;
        for (uint256 i = 1; i < length; ++i) {
            fixedRatePoolValue += assumedWaterfall[i];
        }
        overdueValue = _calculateOverdueValue();
    }

    /**
     * @notice stop the portfolio
     * @custom:status - Live
     * @custom:role - all
     */
    function stopPortfolio() external {
        if (status != Status.Live) {
            revert StopPortfolioWithInvalidStatus();
        }

        (uint256 equityValue, uint256 fixedRatePoolValue, uint256 overdueValue) = getAssumedCurrentValues();
        bool needStop = checkPortfolioNeedStop(equityValue, fixedRatePoolValue, overdueValue);
        if (!needStop) {
            revert StopPortfolioWithInvalidValues();
        }
        stoppedTimestamp = block.timestamp;
        _changePortfolioStatus(Status.Stopped);
    }

    /**
     * @notice restart the portfolio
     * @custom:status - Stopped
     * @custom:role - within 7days: all
     *                        else: manager
     */
    function restartPortfolio() external {
        if (status != Status.Stopped) {
            revert RestartPortfolioWithInvalidStatus();
        }
        if (block.timestamp - stoppedTimestamp > 7 days) {
            if (!hasRole(MANAGER_ROLE, _msgSender())) {
                revert RestartPortfolioOverDuration();
            }
        }

        (uint256 equityValue, uint256 fixedRatePoolValue, uint256 overdueValue) = getAssumedCurrentValues();
        bool needRestart = checkPortfolioNeedRestart(equityValue, fixedRatePoolValue, overdueValue);

        if (!needRestart) {
            revert RestartPortfolioWithInvalidValues();
        }
        stoppedTimestamp = 0;
        _changePortfolioStatus(Status.Live);
    }

    function checkPortfolioNeedStop(
        uint256 equityValue,
        uint256 fixedRatePoolValue,
        uint256 overdueValue
    )
        public
        returns (bool)
    {
        if (equityValue < overdueValue) {
            return true;
        }
        //  ((equityValue - overdueValue) / fixedRatePoolValue) < 1.5 / 7
        uint256 left = (equityValue - overdueValue) * 14;
        uint256 right = 3 * fixedRatePoolValue;

        // need to stop
        if (left < right) {
            return true;
        }
        return false;
    }

    function checkPortfolioNeedRestart(
        uint256 equityValue,
        uint256 fixedRatePoolValue,
        uint256 overdueValue
    )
        public
        returns (bool)
    {
        if (equityValue < overdueValue) {
            return false;
        }
        //  ((equityValue - overdueValue) / fixedRatePoolValue) >= 2.5 / 7
        uint256 left = (equityValue - overdueValue) * 14;
        uint256 right = 5 * fixedRatePoolValue;

        // need to restart
        if (left >= right) {
            return true;
        }
        return false;
    }

    /**
     * @notice Cancel the loan
     * @param loanId Loan id
     * @custom:status - All (as long as the loan exists)
     * @custom:role - manager
     */
    function markLoanAsDefaulted(uint256 loanId) external whenNotPaused {
        _requireManagerRole();
        _markLoanAsDefaulted(loanId);
    }

    function increaseTokenBalance(uint256 amount) external {
        _requireTranchePool();
        _increaseTokenBalance(amount);
    }

    function _requireManagerOrCollateralOwner(address collateral, uint256 collateralId) internal view {
        if (ERC721(collateral).ownerOf(collateralId) == _msgSender()) {
            return;
        }
        if (hasRole(MANAGER_ROLE, _msgSender())) {
            return;
        }
        revert NotManagerOrCollateralOwner();
    }

    function _requireTranchePool() internal view {
        bool isTranche = false;
        for (uint256 i = 0; i < tranches.length; i++) {
            if (address(tranches[i]) != _msgSender()) {
                isTranche = true;
            }
        }

        if (!isTranche) {
            revert NotTranche();
        }
    }

    function _requireGovernanceRole() internal view {
        if (!hasRole(GOVERNANCE_ROLE, _msgSender())) {
            revert NotGovernance();
        }
    }

    function _grantGovernanceRole(address governance) internal {
        _grantRole(GOVERNANCE_ROLE, governance);
    }
}