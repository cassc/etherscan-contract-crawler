// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {BaseERC20} from "../token/BaseERC20.sol";
import {IERC20Metadata} from "../token/IERC20Metadata.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {Math} from "../lib/Math.sol";
import {Adminable} from "../lib/Adminable.sol";
import {Address} from "../lib/Address.sol";
import {Bytes32} from "../lib/Bytes32.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";

import {SapphireTypes} from "./SapphireTypes.sol";
import {SapphireCoreStorage} from "./SapphireCoreStorage.sol";
import {SapphireAssessor} from "./SapphireAssessor.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";
import {ISapphirePool} from "./SapphirePool/ISapphirePool.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";

contract SapphireCoreV1 is Adminable, ReentrancyGuard, SapphireCoreStorage {

    /* ========== Structs ========== */

    struct LiquidationVars {
        uint256 liquidationPrice;
        uint256 debtToRepay;
        uint256 collateralPrecisionScalar;
        uint256 collateralToSell;
        uint256 valueCollateralSold;
        uint256 profit;
        uint256 arcShare;
        uint256 liquidatorCollateralShare;
    }

    /* ========== Libraries ========== */

    using Address for address;
    using Bytes32 for bytes32;

    /* ========== Events ========== */

    event Deposited(
        address indexed _user,
        uint256 _deposit,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Withdrawn(
        address indexed _user,
        uint256 _withdrawn,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Borrowed(
        address indexed _user,
        uint256 _borrowed,
        address indexed _borrowAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Repaid(
        address indexed _user,
        address indexed _repayer,
        uint256 _repaid,
        address indexed _repayAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event Liquidated(
        address indexed _userLiquidator,
        address indexed _liquidator,
        uint256 _collateralPrice,
        uint256 _assessedCRatio,
        uint256 _liquidatedCollateral,
        uint256 _repayAmount,
        address indexed _repayAsset,
        uint256 _collateralAmount,
        uint256 _accumulatedDebt,
        uint256 _principalAmount
    );

    event FeesUpdated(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    );

    event LimitsUpdated(
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum,
        uint256 _defaultBorrowLimit
    );

    event IndexUpdated(
        uint256 _newIndex,
        uint256 _lastUpdateTime
    );

    event InterestRateUpdated(uint256 _value);

    event OracleUpdated(address _oracle);

    event PauseStatusUpdated(bool _pauseStatus);

    event InterestSetterUpdated(address _newInterestSetter);

    event PauseOperatorUpdated(address _newPauseOperator);

    event AssessorUpdated(address _newAssessor);

    event CollateralRatiosUpdated(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    );

    event FeeCollectorUpdated(
        address _feeCollector
    );

    event ProofProtocolSet(
        string _creditProtocol,
        string _borrowLimitProtocol
    );

    event BorrowPoolUpdated(address _borrowPool);

    /* ========== Modifiers ========== */

    /**
     * @dev Saves the precision scalar of the token, if not done already
     */
    modifier cacheAssetDecimals(address _asset) {
        _savePrecisionScalar(_asset);
        _;
    }

    /* ========== Admin Setters ========== */

    /**
     * @dev Initialize the protocol with the appropriate parameters. Can only be called once.
     *      IMPORTANT: the contract assumes the collateral contract is to be trusted.
     *      Make sure this is true before calling this function.
     *
     * @param _collateralAddress    The address of the collateral to be used
     * @param _oracleAddress        The address of the IOracle conforming contract
     * @param _interestSetter       The address which can update interest rates
     * @param _pauseOperator        The address which can pause the contract
     * @param _assessorAddress,     The address of assessor contract conforming ISapphireAssessor,
     *                              which provides credit score functionality
     * @param _feeCollector         The address of the ARC fee collector when a liquidation occurs
     * @param _highCollateralRatio  High limit of how much collateral is needed to borrow
     * @param _lowCollateralRatio   Low limit of how much collateral is needed to borrow
     */
    function init(
        address _collateralAddress,
        address _oracleAddress,
        address _interestSetter,
        address _pauseOperator,
        address _assessorAddress,
        address _feeCollector,
        uint256 _highCollateralRatio,
        uint256 _lowCollateralRatio
    )
        external
        onlyAdmin
        cacheAssetDecimals(_collateralAddress)
    {
        require(
            collateralAsset == address(0),
            "SapphireCoreV1: cannot re-initialize contract"
        );

        require(
            _collateralAddress.isContract(),
            "SapphireCoreV1: collateral is not a contract"
        );

        paused          = true;
        borrowIndex     = BASE;
        indexLastUpdate = currentTimestamp();
        collateralAsset = _collateralAddress;
        interestSetter  = _interestSetter;
        pauseOperator   = _pauseOperator;
        feeCollector    = _feeCollector;
        _scoreProtocols = [
            bytes32("arcx.credit"),
            bytes32("arcx.creditLimit")
        ];

        setAssessor(_assessorAddress);
        setOracle(_oracleAddress);
        setCollateralRatios(_lowCollateralRatio, _highCollateralRatio);
    }

    /**
     * @dev Set the instance of the oracle to report prices from. Must conform to IOracle.sol
     *
     * @notice Can only be called by the admin
     *
     * @param _oracleAddress The address of the IOracle instance
     */
    function setOracle(
        address _oracleAddress
    )
        public
        onlyAdmin
    {
        require(
            _oracleAddress.isContract(),
            "SapphireCoreV1: oracle is not a contract"
        );

        require(
            _oracleAddress != address(oracle),
            "SapphireCoreV1: the same oracle is already set"
        );

        oracle = ISapphireOracle(_oracleAddress);
        emit OracleUpdated(_oracleAddress);
    }

    /**
     * @dev Set low and high collateral ratios of collateral value to debt.
     *
     * @notice Can only be called by the admin.
     *
     * @param _lowCollateralRatio The minimal allowed ratio expressed up to 18 decimal places
     * @param _highCollateralRatio The maximum allowed ratio expressed up to 18 decimal places
     */
    function setCollateralRatios(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    )
        public
        onlyAdmin
    {
        require(
            _lowCollateralRatio <= _highCollateralRatio,
            "SapphireCoreV1: high c-ratio is lower than the low c-ratio"
        );

        require(
            _lowCollateralRatio >= BASE,
            "SapphireCoreV1: collateral ratio has to be at least 1"
        );

        require(
            (_lowCollateralRatio != lowCollateralRatio) ||
            (_highCollateralRatio != highCollateralRatio),
            "SapphireCoreV1: the same ratios are already set"
        );

        lowCollateralRatio = _lowCollateralRatio;
        highCollateralRatio = _highCollateralRatio;

        emit CollateralRatiosUpdated(lowCollateralRatio, highCollateralRatio);
    }

    /**
     * @dev Set the fees in the system.
     *
     * @notice Can only be called by the admin.
     *
     * @param _liquidatorDiscount Determines the penalty a user must pay by discounting their
     * collateral price to provide a profit incentive for liquidators.
     * @param _liquidationArcFee The percentage of the profit earned from the liquidation,
     * which the feeCollector earns.
     * @param _borrowFee The percentage of the the loan that is added as immediate interest.
     * @param _poolInterestFee The percentage of the interest paid that goes to the borrow pool.
     */
    function setFees(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    )
        public
        onlyAdmin
    {
        require(
            (_liquidatorDiscount != liquidatorDiscount) ||
            (_liquidationArcFee != liquidationArcFee) ||
            (_borrowFee != borrowFee) ||
            (_poolInterestFee != poolInterestFee),
            "SapphireCoreV1: the same fees are already set"
        );

        _setFees(
            _liquidatorDiscount,
            _liquidationArcFee,
            _borrowFee,
            _poolInterestFee
        );
    }

    /**
     * @dev Set the limits of the system to ensure value can be capped.
     *
     * @notice Can only be called by the admin
     *
     * @param _vaultBorrowMinimum The minimum allowed borrow amount for vault
     * @param _vaultBorrowMaximum The maximum allowed borrow amount for vault
     */
    function setLimits(
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum,
        uint256 _defaultBorrowLimit
    )
        public
        onlyAdmin
    {
        require(
            _vaultBorrowMinimum <= _vaultBorrowMaximum,
            "SapphireCoreV1: required condition is vaultMin <= vaultMax"
        );

        require(
            (_vaultBorrowMinimum != vaultBorrowMinimum) ||
            (_vaultBorrowMaximum != vaultBorrowMaximum) ||
            (_defaultBorrowLimit != defaultBorrowLimit),
            "SapphireCoreV1: the same limits are already set"
        );

        vaultBorrowMinimum = _vaultBorrowMinimum;
        vaultBorrowMaximum = _vaultBorrowMaximum;
        defaultBorrowLimit = _defaultBorrowLimit;

        emit LimitsUpdated(vaultBorrowMinimum, vaultBorrowMaximum, _defaultBorrowLimit);
    }

    /**
     * @dev Set the address which can set interest rate
     *
     * @notice Can only be called by the admin
     *
     * @param _interestSetter The address of the new interest rate setter
     */
    function setInterestSetter(
        address _interestSetter
    )
        external
        onlyAdmin
    {
        require(
            _interestSetter != interestSetter,
            "SapphireCoreV1: cannot set the same interest setter"
        );

        interestSetter = _interestSetter;
        emit InterestSetterUpdated(interestSetter);
    }

    function setPauseOperator(
        address _pauseOperator
    )
        external
        onlyAdmin
    {
        require(
            _pauseOperator != pauseOperator,
            "SapphireCoreV1: the same pause operator is already set"
        );

        pauseOperator = _pauseOperator;
        emit PauseOperatorUpdated(pauseOperator);
    }

    function setAssessor(
        address _assessor
    )
        public
        onlyAdmin
    {
        require(
            _assessor.isContract(),
            "SapphireCoreV1: the address is not a contract"
        );

        require(
            _assessor != address(assessor),
            "SapphireCoreV1: the same assessor is already set"
        );

        assessor = ISapphireAssessor(_assessor);
        emit AssessorUpdated(_assessor);
    }

    function setBorrowPool(
        address _borrowPool
    )
        external
        onlyAdmin
    {
        require(
            _borrowPool != address(borrowPool),
            "SapphireCoreV1: the same borrow pool is already set"
        );

        require(
            _borrowPool.isContract(),
            "SapphireCoreV1: the address is not a contract"
        );

        borrowPool = _borrowPool;
        emit BorrowPoolUpdated(_borrowPool);
    }

    function setFeeCollector(
        address _newFeeCollector
    )
        external
        onlyAdmin
    {
        require(
            _newFeeCollector != address(feeCollector),
            "SapphireCoreV1: the same fee collector is already set"
        );

        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(feeCollector);
    }

    function setPause(
        bool _value
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "SapphireCoreV1: caller is not the pause operator"
        );

        require(
            _value != paused,
            "SapphireCoreV1: cannot set the same pause value"
        );

        paused = _value;
        emit PauseStatusUpdated(paused);
    }

    /**
     * @dev Update the interest rate of the protocol. Since this rate is compounded
     *      every second rather than being purely linear, the calculate for r is expressed
     *      as the following (assuming you want 5% APY):
     *
     *      r^N = 1.05
     *      since N = 365 * 24 * 60 * 60 (number of seconds in a year)
     *      r = 1.000000001547125957863212...
     *      rate = 1547125957 (r - 1e18 decimal places solidity value)
     *
     * @notice Can only be called by the interest setter of the protocol and the maximum
     *         rate settable is 99% (21820606489)
     *
     * @param _interestRate The interest rate expressed per second
     */
    function setInterestRate(
        uint256 _interestRate
    )
        external
    {

        require(
            msg.sender == interestSetter,
            "SapphireCoreV1: caller is not interest setter"
        );

        require(
            _interestRate < 21820606489,
            "SapphireCoreV1: interest rate cannot be more than 99% - 21820606489"
        );

        interestRate = _interestRate;
        emit InterestRateUpdated(interestRate);
    }

    function setProofProtocols(
        bytes32[] memory _protocols
    )
        external
        onlyAdmin
    {

        require(
            _protocols.length == 2,
            "SapphireCoreV1: array should contain two protocols"
        );

        _scoreProtocols = _protocols;

        emit ProofProtocolSet(
            _protocols[0].toString(),
            _protocols[1].toString()
        );
    }

    /* ========== Public Functions ========== */

    /**
     * @dev Deposits the given `_amount` of collateral to the `msg.sender`'s vault.
     *
     * @param _amount           The amount of collateral to deposit
     * @param _passportProofs   The passport score proofs - optional
     *                          Index 0 - score proof
     */
    function deposit(
        uint256 _amount,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            address(0),
            SapphireTypes.Operation.Deposit,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    function withdraw(
        uint256 _amount,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            address(0),
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Borrow against an existing position
     *
     * @param _amount The amount of stablecoins to borrow
     * @param _borrowAssetAddress The address of token to borrow
     * @param _passportProofs The passport score proofs - mandatory
     *                        Index 0 - score proof
     *                        Index 1 - borrow limit proof
     */
    function borrow(
        uint256 _amount,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            _borrowAssetAddress,
            SapphireTypes.Operation.Borrow,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    function repay(
        uint256 _amount,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            _borrowAssetAddress,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Repays the entire debt and withdraws the all the collateral
     *
     * @param _borrowAssetAddress The address of token to repay
     * @param _passportProofs     The passport score proofs - optional
     *                            Index 0 - score proof
     */
    function exit(
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
        cacheAssetDecimals(_borrowAssetAddress)
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](2);
        SapphireTypes.Vault memory vault = vaults[msg.sender];

        uint256 repayAmount = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        // Repay outstanding debt
        actions[0] = SapphireTypes.Action(
            repayAmount / precisionScalars[_borrowAssetAddress],
            _borrowAssetAddress,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        // Withdraw all collateral
        actions[1] = SapphireTypes.Action(
            vault.collateralAmount,
            address(0),
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev Liquidate a user's vault. When this process occurs you're essentially
     *      purchasing the user's debt at a discount in exchange for the collateral
     *      they have deposited inside their vault.
     *
     * @param _owner the owner of the vault to liquidate
     * @param _borrowAssetAddress The address of token to repay
     * @param _passportProofs     The passport score proof - optional
     *                            Index 0 - score proof
     */
    function liquidate(
        address _owner,
        address _borrowAssetAddress,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            0,
            _borrowAssetAddress,
            SapphireTypes.Operation.Liquidate,
            _owner
        );

        executeActions(actions, _passportProofs);
    }

    /**
     * @dev All other user-called functions use this function to execute the
     *      passed actions. This function first updates the indexes before
     *      actually executing the actions.
     *
     * @param _actions          An array of actions to execute
     * @param _passportProofs   The passport score proof - optional
     *                          Index 0 - score proof
     *                          Index 1 - borrow limit proof
     */
    function executeActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof[] memory _passportProofs
    )
        public
        nonReentrant
    {
        require(
            !paused,
            "SapphireCoreV1: the contract is paused"
        );

        require(
            _actions.length > 0,
            "SapphireCoreV1: there must be at least one action"
        );

        require (
            _passportProofs[0].protocol == _scoreProtocols[0],
            "SapphireCoreV1: incorrect credit score protocol"
        );

        // Update the index to calculate how much interest has accrued
        updateIndex();

        // Get the c-ratio and current price if necessary. The current price only be >0 if
        // it's required by an action
        (
            uint256 assessedCRatio,
            uint256 currentPrice
        ) = _getVariablesForActions(_actions, _passportProofs[0]);

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            if (action.operation == SapphireTypes.Operation.Deposit) {
                _deposit(action.amount);

            } else if (action.operation == SapphireTypes.Operation.Withdraw){
                _withdraw(action.amount, assessedCRatio, currentPrice);

            } else if (action.operation == SapphireTypes.Operation.Borrow) {
                _borrow(action.amount, action.borrowAssetAddress, assessedCRatio, currentPrice, _passportProofs[1]);

            }  else if (action.operation == SapphireTypes.Operation.Repay) {
                _repay(
                    msg.sender,
                    msg.sender,
                    action.amount,
                    action.borrowAssetAddress,
                    false
                );

            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
                _liquidate(action.userToLiquidate, currentPrice, assessedCRatio, action.borrowAssetAddress);
            }
        }
    }

    function updateIndex()
        public
        returns (uint256)
    {
        if (indexLastUpdate == currentTimestamp()) {
            return borrowIndex;
        }

        borrowIndex = currentBorrowIndex();
        indexLastUpdate = currentTimestamp();

        emit IndexUpdated(borrowIndex, indexLastUpdate);

        return borrowIndex;
    }

    /* ========== Public Getters ========== */

    function accumulatedInterest()
        public
        view
        returns (uint256)
    {
        return interestRate * (currentTimestamp() - indexLastUpdate);
    }

    function currentBorrowIndex()
        public
        view
        returns (uint256)
    {
        return borrowIndex * accumulatedInterest() / BASE + borrowIndex;
    }

    function getProofProtocol(uint8 index)
        external
        view
        returns (string memory)
    {
        return _scoreProtocols[index].toString();
    }

    function getSupportedBorrowAssets()
        external
        view
        returns (address[] memory)
    {
        return ISapphirePool(borrowPool).getDepositAssets();
    }

    /**
     * @dev Check if the vault is collateralized or not
     *
     * @param _owner The owner of the vault
     * @param _currentPrice The current price of the collateral
     * @param _assessedCRatio The assessed collateral ratio of the owner
     */
    function isCollateralized(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio
    )
        public
        view
        returns (bool)
    {
        SapphireTypes.Vault memory vault = vaults[_owner];

        if (
            vault.normalizedBorrowedAmount == 0 ||
            vault.collateralAmount == 0
        ) {
            return true;
        }

        uint256 currentCRatio = calculateCollateralRatio(
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.collateralAmount,
            _currentPrice
        );

        return currentCRatio >= _assessedCRatio;
    }

    /* ========== Developer Functions ========== */

    /**
     * @dev Returns current block's timestamp
     *
     * @notice This function is introduced in order to properly test time delays in this contract
     */
    function currentTimestamp()
        public
        virtual
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Calculate how much collateralRatio you would have
     *      with a certain borrow and collateral amount
     *
     * @param _denormalizedBorrowAmount The denormalized borrow amount (NOT principal)
     * @param _collateralAmount The amount of collateral, in its original decimals
     * @param _collateralPrice What price do you want to calculate the inverse at
     * @return                  The calculated c-ratio
     */
    function calculateCollateralRatio(
        uint256 _denormalizedBorrowAmount,
        uint256 _collateralAmount,
        uint256 _collateralPrice
    )
        public
        view
        returns (uint256)
    {
        return _collateralAmount *
             precisionScalars[collateralAsset] *
            _collateralPrice /
            _denormalizedBorrowAmount;
    }

    /* ========== Private Functions ========== */

    /**
     * @dev Normalize the given borrow amount by dividing it with the borrow index.
     *      It is used when manipulating with other borrow values
     *      in order to take in account current borrowIndex.
     */
    function _normalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        uint256 currentBIndex = currentBorrowIndex();

        if (_roundUp) {
            return Math.roundUpDiv(_amount, currentBIndex);
        }

        return _amount * BASE / currentBIndex;
    }

    /**
     * @dev Multiply the given amount by the borrow index. Used to convert
     *      borrow amounts back to their real value.
     */
    function _denormalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        if (_roundUp) {
            return Math.roundUpMul(_amount, currentBorrowIndex());
        }

        return _amount * currentBorrowIndex() / BASE;
    }

    /**
     * @dev Deposits the collateral amount in the user's vault
     */
    function _deposit(
        uint256 _amount
    )
        private
    {
        // Record deposit
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        if (_amount == 0) {
            return;
        }

        vault.collateralAmount = vault.collateralAmount + _amount;

        // Execute transfer
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransferFrom(
            collateralAsset,
            msg.sender,
            address(this),
            _amount
        );

        emit Deposited(
            msg.sender,
            _amount,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Withdraw the collateral amount in the user's vault, then ensures
     *      the withdraw amount is not greater than the deposited collateral.
     *      Afterwards ensure that collateral limit is not smaller than returned
     *      from assessor one.
     */
    function _withdraw(
        uint256 _amount,
        uint256 _assessedCRatio,
        uint256 _collateralPrice
    )
        private
    {
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        require(
            vault.collateralAmount >= _amount,
            "SapphireCoreV1: cannot withdraw more collateral than the vault balance"
        );

        vault.collateralAmount = vault.collateralAmount - _amount;

        // if we don't have debt we can withdraw as much as we want.
        if (vault.normalizedBorrowedAmount > 0) {
            uint256 collateralRatio = calculateCollateralRatio(
                _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
                vault.collateralAmount,
                _collateralPrice
            );

            require(
                collateralRatio >= _assessedCRatio,
                "SapphireCoreV1: the vault will become undercollateralized"
            );
        }

        // Execute transfer
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransfer(collateralAsset, msg.sender, _amount);

        emit Withdrawn(
            msg.sender,
            _amount,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Borrows the given borrow assets against the user's vault. It ensures the vault
     *      still maintains the required collateral ratio
     *
     * @param _amount               The amount of stablecoins to borrow
     * @param _borrowAssetAddress   The address of the stablecoin token to borrow
     * @param _assessedCRatio       The assessed c-ratio for user's credit score
     * @param _collateralPrice      The current collateral price
     */
    function _borrow(
        uint256 _amount,
        address _borrowAssetAddress,
        uint256 _assessedCRatio,
        uint256 _collateralPrice,
        SapphireTypes.ScoreProof memory _borrowLimitProof
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        require(
            _borrowLimitProof.account == msg.sender ||
            _borrowLimitProof.account == address(0),
            "SapphireCoreV1: proof.account must match msg.sender"
        );

        require(
            _borrowLimitProof.protocol == _scoreProtocols[1],
            "SapphireCoreV1: incorrect borrow limit proof protocol"
        );

        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        uint256 actualVaultBorrowAmount = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        uint256 scaledAmount = _amount * precisionScalars[_borrowAssetAddress];

        // Calculate new actual vault borrow amount with the added borrow fee
        uint256 _newActualVaultBorrowAmount = actualVaultBorrowAmount + scaledAmount;

        // Ensure the vault is collateralized if the borrow action succeeds
        uint256 collateralRatio = calculateCollateralRatio(
            _newActualVaultBorrowAmount,
            vault.collateralAmount,
            _collateralPrice
        );

        require(
            collateralRatio >= _assessedCRatio,
            "SapphireCoreV1: the vault will become undercollateralized"
        );

        if (_newActualVaultBorrowAmount > defaultBorrowLimit) {
            require(
                assessor.assessBorrowLimit(_newActualVaultBorrowAmount, _borrowLimitProof),
                "SapphireCoreV1: total borrow amount should not exceed borrow limit"
            );
        }

        // Calculate new normalized vault borrow amount, including the borrow fee, if any
        uint256 _newNormalizedVaultBorrowAmount;
        if (borrowFee > 0) {
            _newNormalizedVaultBorrowAmount = _normalizeBorrowAmount(
                _newActualVaultBorrowAmount + Math.roundUpMul(scaledAmount, borrowFee),
                true
            );
        } else {
            _newNormalizedVaultBorrowAmount = _normalizeBorrowAmount(
                _newActualVaultBorrowAmount,
                true
            );
        }

        // Record borrow amount (update vault and total amount)
        normalizedTotalBorrowed = normalizedTotalBorrowed -
            vault.normalizedBorrowedAmount +
            _newNormalizedVaultBorrowAmount;

        vault.normalizedBorrowedAmount = _newNormalizedVaultBorrowAmount;
        vault.principal = vault.principal + scaledAmount;

        // Do not borrow more than the maximum vault borrow amount
        require(
            _newActualVaultBorrowAmount <= vaultBorrowMaximum,
            "SapphireCoreV1: borrowed amount cannot be greater than vault limit"
        );

        // Do not borrow if amount is smaller than limit
        require(
            _newActualVaultBorrowAmount >= vaultBorrowMinimum,
            "SapphireCoreV1: borrowed amount cannot be less than limit"
        );

        // Borrow stablecoins from pool
        ISapphirePool(borrowPool).borrow(
            _borrowAssetAddress,
            scaledAmount,
            msg.sender
        );

        emit Borrowed(
            msg.sender,
            _amount,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Repays the given `_amount` of the stablecoin
     *
     * @param _owner The owner of the vault
     * @param _repayer The person who repays the debt
     * @param _amountScaled The amount to repay, denominated in the decimals of the borrow asset
     * @param _borrowAssetAddress The address of token to repay
     * @param _isLiquidation Indicates if it should clean the remaining debt after repayment
     */
    function _repay(
        address _owner,
        address _repayer,
        uint256 _amountScaled,
        address _borrowAssetAddress,
        bool _isLiquidation
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[_owner];

        // Calculate actual vault borrow amount
        uint256 actualVaultBorrowAmountScaled = _denormalizeBorrowAmount(
            vault.normalizedBorrowedAmount,
            true
        ) / precisionScalars[_borrowAssetAddress];

        require(
            _amountScaled <= actualVaultBorrowAmountScaled,
            "SapphireCoreV1: there is not enough debt to repay"
        );

        uint256 _interestScaled = (
            actualVaultBorrowAmountScaled -
            vault.principal / precisionScalars[_borrowAssetAddress]
        );

        uint256 _feeCollectorFeesScaled;
        uint256 _poolFeesScaled;
        uint256 _principalPaidScaled;
        uint256 _stablesLentDecreaseAmt;

        // Calculate new vault's borrowed amount
        uint256 _newNormalizedBorrowAmount = _normalizeBorrowAmount(
            (actualVaultBorrowAmountScaled - _amountScaled) * precisionScalars[_borrowAssetAddress],
            true
        );

        // Update principal
        if(_amountScaled > _interestScaled) {
            _poolFeesScaled = Math.roundUpMul(_interestScaled, poolInterestFee);
            _feeCollectorFeesScaled = _interestScaled - _poolFeesScaled;

            // User repays the entire interest and some (or all) principal
            _principalPaidScaled = _amountScaled - _interestScaled;
            vault.principal = vault.principal -
                _principalPaidScaled * precisionScalars[_borrowAssetAddress];
        } else {
            // Only interest is paid
            _poolFeesScaled = Math.roundUpMul(_amountScaled, poolInterestFee);
            _feeCollectorFeesScaled = _amountScaled - _poolFeesScaled;
        }

        // Update vault's borrowed amounts and clean debt if requested
        if (_isLiquidation) {
            normalizedTotalBorrowed -= vault.normalizedBorrowedAmount;
            _stablesLentDecreaseAmt = (actualVaultBorrowAmountScaled - _amountScaled) *
                precisionScalars[_borrowAssetAddress];

            // Can only decrease by the amount borrowed
            if (_stablesLentDecreaseAmt > vault.principal) {
                _stablesLentDecreaseAmt = vault.principal;
            }

            vault.principal = 0;
            vault.normalizedBorrowedAmount = 0;
        } else {
            normalizedTotalBorrowed = normalizedTotalBorrowed -
                vault.normalizedBorrowedAmount +
                _newNormalizedBorrowAmount;
            vault.normalizedBorrowedAmount = _newNormalizedBorrowAmount;
        }

        // Transfer fees to pool and fee collector (if any)
        if (_interestScaled > 0) {
            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                borrowPool,
                _poolFeesScaled
            );

            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                feeCollector,
                _feeCollectorFeesScaled
            );
        }

        // Swap the principal paid back into the borrow pool
        if (_principalPaidScaled > 0) {
            // Transfer tokens to the core
            SafeERC20.safeTransferFrom(
                IERC20Metadata(_borrowAssetAddress),
                _repayer,
                address(this),
                _principalPaidScaled
            );

            SafeERC20.safeApprove(
                IERC20Metadata(_borrowAssetAddress),
                borrowPool,
                _principalPaidScaled
            );

            // Repay stables to pool
            ISapphirePool(borrowPool).repay(
                _borrowAssetAddress,
                _principalPaidScaled
            );
        }

        // Clean the remaining debt if requested
        if (_stablesLentDecreaseAmt > 0) {
            ISapphirePool(borrowPool).decreaseStablesLent(_stablesLentDecreaseAmt);
        }

        emit Repaid(
            _owner,
            _repayer,
            _amountScaled,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    function _liquidate(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio,
        address _borrowAssetAddress
    )
        private
        cacheAssetDecimals(_borrowAssetAddress)
    {
        // CHECKS:
        // 1. Ensure that the position is valid (check if there is a non-0x0 owner)
        // 2. Ensure that the position is indeed undercollateralized

        // EFFECTS:
        // 1. Calculate the liquidation price based on the liquidation penalty
        // 2. Calculate the amount of collateral to be sold based on the entire debt
        //    in the vault
        // 3. If the discounted collateral is more than the amount in the vault, limit
        //    the sale to that amount
        // 4. Decrease the owner's debt
        // 5. Decrease the owner's collateral

        // INTEGRATIONS
        // 1. Transfer the debt to pay from the liquidator to the pool
        // 2. Transfer the user portion of the collateral sold to the msg.sender
        // 3. Transfer Arc's portion of the profit to the fee collector
        // 4. If there is bad debt, make LPs pay for it by reducing the stablesLent on the pool
        //    by the amount of the bad debt.

        // --- CHECKS ---

        require(
            _owner != address(0),
            "SapphireCoreV1: position owner cannot be address 0"
        );

        SapphireTypes.Vault storage vault = vaults[_owner];
        // Use struct to go around the stack too deep error
        LiquidationVars memory vars;

        // Ensure that the vault is not collateralized
        require(
            !isCollateralized(
                _owner,
                _currentPrice,
                _assessedCRatio
            ),
            "SapphireCoreV1: vault is collateralized"
        );

        // --- EFFECTS ---

        // Get the liquidation price of the asset (discount for liquidator)
        vars.liquidationPrice = Math.roundUpMul(_currentPrice, BASE - liquidatorDiscount);

        // Calculate the amount of collateral to be sold based on the entire debt
        // in the vault
        vars.debtToRepay = _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true);

        vars.collateralPrecisionScalar = precisionScalars[collateralAsset];
        // Do a rounded up operation of
        // debtToRepay / LiquidationFee / collateralPrecisionScalar
        vars.collateralToSell = (
            Math.roundUpDiv(vars.debtToRepay, vars.liquidationPrice) + vars.collateralPrecisionScalar - 1
        ) / vars.collateralPrecisionScalar;

        // If the discounted collateral is more than the amount in the vault, limit
        // the sale to that amount
        if (vars.collateralToSell > vault.collateralAmount) {
            vars.collateralToSell = vault.collateralAmount;
            // Calculate the new debt to repay
            vars.debtToRepay = vars.collateralToSell * vars.collateralPrecisionScalar * vars.liquidationPrice / BASE;
        }

        // Calculate the profit made in USD
        vars.valueCollateralSold = vars.collateralToSell *
            vars.collateralPrecisionScalar *
            _currentPrice /
            BASE;

        // Total profit in dollar amount
        vars.profit = vars.valueCollateralSold - vars.debtToRepay;

        // Calculate the ARC share
        vars.arcShare = vars.profit *
            liquidationArcFee /
            vars.liquidationPrice /
            vars.collateralPrecisionScalar;

        // Calculate liquidator's share
        vars.liquidatorCollateralShare = vars.collateralToSell - vars.arcShare;

        // Update owner's vault
        vault.collateralAmount = vault.collateralAmount - vars.collateralToSell;

        // --- INTEGRATIONS ---

        // Repay the debt
        _repay(
            _owner,
            msg.sender,
            vars.debtToRepay / precisionScalars[_borrowAssetAddress],
            _borrowAssetAddress,
            true
        );

        // Transfer user collateral
        IERC20Metadata collateralAsset = IERC20Metadata(collateralAsset);
        SafeERC20.safeTransfer(
            collateralAsset,
            msg.sender,
            vars.liquidatorCollateralShare
        );

        // Transfer Arc's share of collateral
        SafeERC20.safeTransfer(
            collateralAsset,
            feeCollector,
            vars.arcShare
        );

        emit Liquidated(
            _owner,
            msg.sender,
            _currentPrice,
            _assessedCRatio,
            vars.collateralToSell,
            vars.debtToRepay,
            _borrowAssetAddress,
            vault.collateralAmount,
            _denormalizeBorrowAmount(vault.normalizedBorrowedAmount, true),
            vault.principal
        );
    }

    /**
     * @dev Gets the required variables for the actions passed, if needed. The credit score
     *      will be assessed if there is at least one action. The oracle price will only be
     *      fetched if there is at least one borrow or liquidate actions.
     *
     * @param _actions      the actions that are about to be ran
     * @param _scoreProof   the credit score proof
     * @return              the assessed c-ratio and the current collateral price
     */
    function _getVariablesForActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        private
        returns (uint256, uint256)
    {
        uint256 assessedCRatio;
        uint256 collateralPrice;
        uint256 collateralPriceTimestamp;

        bool mandatoryProof = false;
        bool needsCollateralPrice = false;

        // Check if the score proof has an address. If it's address zero,
        // replace it with msg.sender. This is to prevent users from borrowing
        // after having already registered a score on chain

        if (_scoreProof.account == address(0)) {
            _scoreProof.account = msg.sender;
        }

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            /**
            * Ensure the credit score proof refers to the correct account given
            * the action.
            */
            if (
                action.operation == SapphireTypes.Operation.Deposit ||
                action.operation == SapphireTypes.Operation.Withdraw ||
                action.operation == SapphireTypes.Operation.Borrow
            ) {
                require(
                    _scoreProof.account == msg.sender,
                    "SapphireCoreV1: proof.account must match msg.sender"
                );

                if (
                    action.operation == SapphireTypes.Operation.Borrow ||
                    action.operation == SapphireTypes.Operation.Withdraw
                ) {
                    needsCollateralPrice = true;
                }

            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
               require(
                    _scoreProof.account == action.userToLiquidate,
                    "SapphireCoreV1: proof.account does not match the user to liquidate"
                );

                needsCollateralPrice = true;

                // If the effective passport epoch of the user to liquidate is gte to the
                // current epoch, then the proof is mandatory. Otherwise, will assume the
                // high c-ratio
                (, uint256 currentEpoch) = _getPassportAndEpoch();
                if (currentEpoch >= expectedEpochWithProof[action.userToLiquidate]) {
                    mandatoryProof = true;
                }

            }
        }

        if (needsCollateralPrice) {
            require(
                address(oracle) != address(0),
                "SapphireCoreV1: the oracle is not set"
            );

            // Collateral price denominated in 18 decimals
            (collateralPrice, collateralPriceTimestamp) = oracle.fetchCurrentPrice();

            require(
                _isOracleNotOutdated(collateralPriceTimestamp),
                "SapphireCoreV1: the oracle has stale prices"
            );

            require(
                collateralPrice > 0,
                "SapphireCoreV1: the oracle returned a price of 0"
            );
        }

        // Set the effective epoch of the caller if it's not set yet
        _setEffectiveEpoch(_scoreProof);

        if (address(assessor) == address(0) || _actions.length == 0) {
            assessedCRatio = highCollateralRatio;
        } else {
            assessedCRatio = assessor.assess(
                lowCollateralRatio,
                highCollateralRatio,
                _scoreProof,
                mandatoryProof
            );
        }

        return (assessedCRatio, collateralPrice);
    }

    function _setFees(
        uint256 _liquidatorDiscount,
        uint256 _liquidationArcFee,
        uint256 _borrowFee,
        uint256 _poolInterestFee
    )
        private
    {
        require(
            _liquidatorDiscount <= BASE &&
            _liquidationArcFee <= BASE,
            "SapphireCoreV1: fees cannot be more than 100%"
        );

        require(
            _liquidatorDiscount <= BASE &&
            _poolInterestFee <= BASE &&
            _liquidationArcFee <= BASE,
            "SapphireCoreV1: invalid fees"
        );

        liquidatorDiscount = _liquidatorDiscount;
        liquidationArcFee = _liquidationArcFee;
        borrowFee = _borrowFee;
        poolInterestFee = _poolInterestFee;

        emit FeesUpdated(
            liquidatorDiscount,
            liquidationArcFee,
            _borrowFee,
            _poolInterestFee
        );
    }

    /**
     * @dev Returns true if oracle is not outdated
     */
    function _isOracleNotOutdated(
        uint256 _oracleTimestamp
    )
        internal
        virtual
        view
        returns (bool)
    {
        return _oracleTimestamp >= currentTimestamp() - 60 * 60 * 12;
    }

    /**
     * @dev Saves the token's precision scalar, if it doesn't exist in the mapping.
     */
    function _savePrecisionScalar(
        address _tokenAddress
    )
        internal
    {
        if (_tokenAddress != address(0) && precisionScalars[_tokenAddress] == 0) {
            uint8 tokenDecimals = IERC20Metadata(_tokenAddress).decimals();
            require(
                tokenDecimals <= 18,
                "SapphireCoreV1: token has more than 18 decimals"
            );

            precisionScalars[_tokenAddress] = 10 ** (18 - uint256(tokenDecimals));
        }
    }

    /**
     * @dev Set the effective epoch of the caller if it's not set yet
     */
    function _setEffectiveEpoch(
        SapphireTypes.ScoreProof memory _scoreProof
    )
        private
    {
        (
            ISapphirePassportScores passportScores,
            uint256 currentEpoch
        ) = _getPassportAndEpoch();

        if (_scoreProof.merkleProof.length == 0) {
            // Proof is not passed. If the proof's owner has no expected epoch, set it to the next 2
            if (expectedEpochWithProof[_scoreProof.account] == 0) {
                expectedEpochWithProof[_scoreProof.account] = currentEpoch + 2;
            }
        } else {
            // Proof is passed, expected epoch for proof's account is not set yet
            require(
                passportScores.verify(_scoreProof),
                "SapphireCoreV1: invalid proof"
            );

            if (
                expectedEpochWithProof[_scoreProof.account] == 0 ||
                expectedEpochWithProof[_scoreProof.account] > currentEpoch
            ) {
                // Owner has a valid proof, so will enforce liquidations to pass a proof for this
                // user from now on
                expectedEpochWithProof[_scoreProof.account] = currentEpoch;
            }
        }
    }

    function _getPassportAndEpoch()
        private
        view
        returns (ISapphirePassportScores, uint256)
    {
        ISapphirePassportScores passportScores = ISapphirePassportScores(
            assessor.getPassportScoresContract()
        );

        return (passportScores, passportScores.currentEpoch());
    }
}