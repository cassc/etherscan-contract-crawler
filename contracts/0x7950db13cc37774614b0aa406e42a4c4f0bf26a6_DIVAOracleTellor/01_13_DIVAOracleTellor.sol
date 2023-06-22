// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {UsingTellor} from "./UsingTellor.sol";
import {IDIVAOracleTellor} from "./interfaces/IDIVAOracleTellor.sol";
import {IDIVA} from "./interfaces/IDIVA.sol";
import {IDIVAOwnershipShared} from "./interfaces/IDIVAOwnershipShared.sol";
import {SafeDecimalMath} from "./libraries/SafeDecimalMath.sol";

contract DIVAOracleTellor is UsingTellor, IDIVAOracleTellor, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using SafeDecimalMath for uint256;

    // Ordered to optimize storage
    mapping(bytes32 => mapping(address => uint256)) private _tips; // mapping poolId => tipping token address => tip amount
    mapping(bytes32 => address[]) private _poolIdToTippingTokens; // mapping poolId to tipping tokens
    mapping(bytes32 => address) private _poolIdToReporter; // mapping poolId to reporter address
    mapping(address => bytes32[]) private _reporterToPoolIds; // mapping reporter to poolIds

    uint256 private _previousMaxDIVARewardUSD; // expressed as an integer with 18 decimals, initialized to zero at contract deployment
    uint256 private _maxDIVARewardUSD; // expressed as an integer with 18 decimals
    uint256 private _startTimeMaxDIVARewardUSD;

    address private _previousExcessDIVARewardRecipient; // initialized to zero address at contract deployment
    address private _excessDIVARewardRecipient;
    uint256 private _startTimeExcessDIVARewardRecipient;

    address private immutable _ownershipContract;
    bool private constant _CHALLENGEABLE = false;
    IDIVA private immutable _DIVA;

    uint256 private constant _ACTIVATION_DELAY = 3 days;
    uint32 private constant _MIN_PERIOD_UNDISPUTED = 12 hours;

    modifier onlyOwner() {
        address _owner = _contractOwner();
        if (msg.sender != _owner) {
            revert NotContractOwner(msg.sender, _owner);
        }
        _;
    }

    constructor(
        address ownershipContract_,
        address payable tellorAddress_,
        address excessDIVARewardRecipient_,
        uint256 maxDIVARewardUSD_,
        address diva_
    ) UsingTellor(tellorAddress_) {
        if (ownershipContract_ == address(0)) {
            revert ZeroOwnershipContractAddress();
        }
        if (excessDIVARewardRecipient_ == address(0)) {
            revert ZeroExcessDIVARewardRecipient();
        }
        if (diva_ == address(0)) {
            revert ZeroDIVAAddress();
        }
        // Zero address check for `tellorAddress_` is done inside `UsingTellor.sol`

        _ownershipContract = ownershipContract_;
        _excessDIVARewardRecipient = excessDIVARewardRecipient_;
        _maxDIVARewardUSD = maxDIVARewardUSD_;
        _DIVA = IDIVA(diva_);
    }

    function addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) external override nonReentrant {
        _addTip(_poolId, _amount, _tippingToken);
    }
    
    function _addTip(
        bytes32 _poolId,
        uint256 _amount,
        address _tippingToken
    ) private {
        // Confirm that the final value hasn't been submitted to DIVA Protocol yet,
        // in which case `_poolIdToReporter` would resolve to the zero address.
        if (_poolIdToReporter[_poolId] != address(0)) {
            revert AlreadyConfirmedPool();
        }

        // Add a new entry in the `_poolIdToTippingTokens` array if the specified
        //`_tippingToken` does not yet exist for the specified pool. 
        if (_tips[_poolId][_tippingToken] == 0) {
            _poolIdToTippingTokens[_poolId].push(_tippingToken);
        }

        // Cache tipping token instance
        IERC20Metadata _tippingTokenInstance = IERC20Metadata(_tippingToken);

        // Follow the CEI pattern by updating the balance before doing a potentially
        // unsafe `safeTransferFrom` call.
        _tips[_poolId][_tippingToken] += _amount;

        // Check tipping token balance before and after the transfer to identify
        // fee-on-transfer tokens. If no fees were charged, transfer approved
        // tipping token from `msg.sender` to `this`. Otherwise, revert.
        uint256 _before = _tippingTokenInstance.balanceOf(address(this));
        _tippingTokenInstance.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 _after = _tippingTokenInstance.balanceOf(address(this));

        if (_after - _before != _amount) {
            revert FeeTokensNotSupported();
        }

        // Log event including tipped pool, amount and tipper address.
        emit TipAdded(_poolId, _tippingToken, _amount, msg.sender);
    }

    function batchAddTip(
        ArgsBatchAddTip[] calldata _argsBatchAddTip
    ) external override nonReentrant {
        uint256 _len = _argsBatchAddTip.length;
        for (uint256 i; i < _len; ) {
            _addTip(
                _argsBatchAddTip[i].poolId,
                _argsBatchAddTip[i].amount,
                _argsBatchAddTip[i].tippingToken
            );

            unchecked {
                ++i;
            }
        }
    }

    function claimReward(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external override nonReentrant {
        _claimReward(_poolId, _tippingTokens, _claimDIVAReward);
    }

    function batchClaimReward(
        ArgsBatchClaimReward[] calldata _argsBatchClaimReward
    ) external override nonReentrant {
        uint256 _len = _argsBatchClaimReward.length;
        for (uint256 i; i < _len; ) {
            _claimReward(
                _argsBatchClaimReward[i].poolId,
                _argsBatchClaimReward[i].tippingTokens,
                _argsBatchClaimReward[i].claimDIVAReward
            );

            unchecked {
                ++i;
            }
        }
    }

    function setFinalReferenceValue(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) external override nonReentrant {
        _setFinalReferenceValue(_poolId);
        _claimReward(_poolId, _tippingTokens, _claimDIVAReward);
    }

    function batchSetFinalReferenceValue(
        ArgsBatchSetFinalReferenceValue[] calldata _argsBatchSetFinalReferenceValue
    ) external override nonReentrant {
        uint256 _len = _argsBatchSetFinalReferenceValue.length;
        for (uint256 i; i < _len; ) {
            _setFinalReferenceValue(_argsBatchSetFinalReferenceValue[i].poolId);
            _claimReward(
                _argsBatchSetFinalReferenceValue[i].poolId,
                _argsBatchSetFinalReferenceValue[i].tippingTokens,
                _argsBatchSetFinalReferenceValue[i].claimDIVAReward
            );

            unchecked {
                ++i;
            }
        }
    }

    function updateExcessDIVARewardRecipient(address _newExcessDIVARewardRecipient)
        external
        override
        onlyOwner
    {
        // Confirm that provided excess DIVA reward recipient address
        // is not zero address
        if (_newExcessDIVARewardRecipient == address(0)) {
            revert ZeroExcessDIVARewardRecipient();
        }

        // Confirm that there is no pending excess DIVA reward recipient update.
        // Revoke to update pending value.
        if (_startTimeExcessDIVARewardRecipient > block.timestamp) {
            revert PendingExcessDIVARewardRecipientUpdate(
                block.timestamp,
                _startTimeExcessDIVARewardRecipient
            );
        }

        // Store current excess DIVA reward recipient in `_previousExcessDIVARewardRecipient`
        // variable
        _previousExcessDIVARewardRecipient = _excessDIVARewardRecipient;

        // Set time at which the new excess DIVA reward recipient will become applicable
        uint256 _startTimeNewExcessDIVARewardRecipient;
        unchecked {
            // Cannot realistically overflow
            _startTimeNewExcessDIVARewardRecipient = block.timestamp +
                _ACTIVATION_DELAY;
        }

        // Store start time and new excess DIVA reward recipient
        _startTimeExcessDIVARewardRecipient = _startTimeNewExcessDIVARewardRecipient;
        _excessDIVARewardRecipient = _newExcessDIVARewardRecipient;

        // Log the new excess DIVA reward recipient as well as the address that
        // initiated the change
        emit ExcessDIVARewardRecipientUpdated(
            msg.sender,
            _newExcessDIVARewardRecipient,
            _startTimeNewExcessDIVARewardRecipient
        );
    }

    function updateMaxDIVARewardUSD(uint256 _newMaxDIVARewardUSD)
        external
        override
        onlyOwner
    {
        // Confirm that there is no pending max DIVA reward USD update.
        // Revoke to update pending value.
        if (_startTimeMaxDIVARewardUSD > block.timestamp) {
            revert PendingMaxDIVARewardUSDUpdate(
                block.timestamp,
                _startTimeMaxDIVARewardUSD
            );
        }

        // Store current max DIVA reward USD in `_previousMaxDIVARewardUSD`
        // variable
        _previousMaxDIVARewardUSD = _maxDIVARewardUSD;

        // Set time at which the new max DIVA reward USD will become applicable
        uint256 _startTimeNewMaxDIVARewardUSD;
        unchecked {
            // Cannot realistically overflow
            _startTimeNewMaxDIVARewardUSD = block.timestamp +
                _ACTIVATION_DELAY;
        }        

        // Store start time and new max DIVA reward USD
        _startTimeMaxDIVARewardUSD = _startTimeNewMaxDIVARewardUSD;
        _maxDIVARewardUSD = _newMaxDIVARewardUSD;

        // Log the new max DIVA reward USD as well as the address that
        // initiated the change
        emit MaxDIVARewardUSDUpdated(
            msg.sender,
            _newMaxDIVARewardUSD,
            _startTimeNewMaxDIVARewardUSD
        );
    }

    function revokePendingExcessDIVARewardRecipientUpdate()
        external
        override
        onlyOwner
    {
        // Confirm that new excess DIVA reward recipient is not active yet
        if (_startTimeExcessDIVARewardRecipient <= block.timestamp) {
            revert ExcessDIVARewardRecipientAlreadyActive(
                block.timestamp,
                _startTimeExcessDIVARewardRecipient
            );
        }

        // Store `_excessDIVARewardRecipient` value temporarily
        address _revokedExcessDIVARewardRecipient = _excessDIVARewardRecipient;

        // Reset excess DIVA reward recipient related variables
        _startTimeExcessDIVARewardRecipient = block.timestamp;
        _excessDIVARewardRecipient = _previousExcessDIVARewardRecipient;

        // Log the excess DIVA reward recipient revoked, the previous one that now
        // applies as well as the address that initiated the change
        emit PendingExcessDIVARewardRecipientUpdateRevoked(
            msg.sender,
            _revokedExcessDIVARewardRecipient,
            _previousExcessDIVARewardRecipient
        );
    }

    function revokePendingMaxDIVARewardUSDUpdate() external override onlyOwner {
        // Confirm that new max USD DIVA reward is not active yet
        if (_startTimeMaxDIVARewardUSD <= block.timestamp) {
            revert MaxDIVARewardUSDAlreadyActive(
                block.timestamp,
                _startTimeMaxDIVARewardUSD
            );
        }

        // Store `_maxDIVARewardUSD` value temporarily
        uint256 _revokedMaxDIVARewardUSD = _maxDIVARewardUSD;

        // Reset max DIVA reward USD related variables
        _startTimeMaxDIVARewardUSD = block.timestamp;
        _maxDIVARewardUSD = _previousMaxDIVARewardUSD;

        // Log the max DIVA reward USD revoked, the previous one that now
        // applies as well as the address that initiated the change
        emit PendingMaxDIVARewardUSDUpdateRevoked(
            msg.sender,
            _revokedMaxDIVARewardUSD,
            _previousMaxDIVARewardUSD
        );
    }

    function getChallengeable() external pure override returns (bool) {
        return _CHALLENGEABLE;
    }

    function getExcessDIVARewardRecipientInfo()
        external
        view
        override
        returns (
            address previousExcessDIVARewardRecipient,
            address excessDIVARewardRecipient,
            uint256 startTimeExcessDIVARewardRecipient
        )
    {
        (
            previousExcessDIVARewardRecipient,
            excessDIVARewardRecipient,
            startTimeExcessDIVARewardRecipient
        ) = (
            _previousExcessDIVARewardRecipient,
            _excessDIVARewardRecipient,
            _startTimeExcessDIVARewardRecipient
        );
    }

    function getMaxDIVARewardUSDInfo()
        external
        view
        override
        returns (
            uint256 previousMaxDIVARewardUSD,
            uint256 maxDIVARewardUSD,
            uint256 startTimeMaxDIVARewardUSD
        )
    {
        (previousMaxDIVARewardUSD, maxDIVARewardUSD, startTimeMaxDIVARewardUSD) = (
            _previousMaxDIVARewardUSD,
            _maxDIVARewardUSD,
            _startTimeMaxDIVARewardUSD
        );
    }

    function getMinPeriodUndisputed() external pure override returns (uint32) {
        return _MIN_PERIOD_UNDISPUTED;
    }

    function getTippingTokens(
        ArgsGetTippingTokens[] calldata _argsGetTippingTokens
    ) external view override returns (address[][] memory) {
        uint256 _len = _argsGetTippingTokens.length;
        address[][] memory _tippingTokens = new address[][](_len);
        for (uint256 i; i < _len; ) {
            address[] memory _tippingTokensForPoolId = new address[](
                _argsGetTippingTokens[i].endIndex -
                    _argsGetTippingTokens[i].startIndex
            );
            for (
                uint256 j = _argsGetTippingTokens[i].startIndex;
                j < _argsGetTippingTokens[i].endIndex;

            ) {
                if (
                    j >=
                    _poolIdToTippingTokens[_argsGetTippingTokens[i].poolId]
                        .length
                ) {
                    _tippingTokensForPoolId[
                        j - _argsGetTippingTokens[i].startIndex
                    ] = address(0);
                } else {
                    _tippingTokensForPoolId[
                        j - _argsGetTippingTokens[i].startIndex
                    ] = _poolIdToTippingTokens[_argsGetTippingTokens[i].poolId][
                        j
                    ];
                }

                unchecked {
                    ++j;
                }
            }
            _tippingTokens[i] = _tippingTokensForPoolId;

            unchecked {
                ++i;
            }
        }
        return _tippingTokens;
    }

    function getTippingTokensLengthForPoolIds(bytes32[] calldata _poolIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 _len = _poolIds.length;
        uint256[] memory _tippingTokensLength = new uint256[](_len);
        for (uint256 i; i < _len; ) {
            _tippingTokensLength[i] = _poolIdToTippingTokens[_poolIds[i]]
                .length;

            unchecked {
                ++i;
            }
        }
        return _tippingTokensLength;
    }

    function getTipAmounts(ArgsGetTipAmounts[] calldata _argsGetTipAmounts)
        external
        view
        override
        returns (uint256[][] memory)
    {
        uint256 _len = _argsGetTipAmounts.length;
        uint256[][] memory _tipAmounts = new uint256[][](_len);
        for (uint256 i; i < _len; ) {
            uint256 _tippingTokensLen = _argsGetTipAmounts[i]
                .tippingTokens
                .length;
            uint256[] memory _tipAmountsForPoolId = new uint256[](
                _tippingTokensLen
            );
            for (uint256 j = 0; j < _tippingTokensLen; ) {
                _tipAmountsForPoolId[j] = _tips[_argsGetTipAmounts[i].poolId][
                    _argsGetTipAmounts[i].tippingTokens[j]
                ];

                unchecked {
                    ++j;
                }
            }

            _tipAmounts[i] = _tipAmountsForPoolId;

            unchecked {
                ++i;
            }
        }
        return _tipAmounts;
    }

    function getDIVAAddress() external view override returns (address) {
        return address(_DIVA);
    }

    function getReporters(bytes32[] calldata _poolIds)
        external
        view
        override
        returns (address[] memory)
    {
        uint256 _len = _poolIds.length;
        address[] memory _reporters = new address[](_len);
        for (uint256 i; i < _len; ) {
            _reporters[i] = _poolIdToReporter[_poolIds[i]];

            unchecked {
                ++i;
            }
        }
        return _reporters;
    }

    function getPoolIdsForReporters(
        ArgsGetPoolIdsForReporters[] calldata _argsGetPoolIdsForReporters
    ) external view override returns (bytes32[][] memory) {
        uint256 _len = _argsGetPoolIdsForReporters.length;
        bytes32[][] memory _poolIds = new bytes32[][](_len);
        for (uint256 i; i < _len; ) {
            bytes32[] memory _poolIdsForReporter = new bytes32[](
                _argsGetPoolIdsForReporters[i].endIndex -
                    _argsGetPoolIdsForReporters[i].startIndex
            );
            for (
                uint256 j = _argsGetPoolIdsForReporters[i].startIndex;
                j < _argsGetPoolIdsForReporters[i].endIndex;

            ) {
                if (
                    j >=
                    _reporterToPoolIds[_argsGetPoolIdsForReporters[i].reporter]
                        .length
                ) {
                    _poolIdsForReporter[
                        j - _argsGetPoolIdsForReporters[i].startIndex
                    ] = 0;
                } else {
                    _poolIdsForReporter[
                        j - _argsGetPoolIdsForReporters[i].startIndex
                    ] = _reporterToPoolIds[
                        _argsGetPoolIdsForReporters[i].reporter
                    ][j];
                }

                unchecked {
                    ++j;
                }
            }
            _poolIds[i] = _poolIdsForReporter;

            unchecked {
                ++i;
            }
        }
        return _poolIds;
    }

    function getPoolIdsLengthForReporters(address[] calldata _reporters)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 _len = _reporters.length;
        uint256[] memory _poolIdsLength = new uint256[](_len);
        for (uint256 i; i < _len; ) {
            _poolIdsLength[i] = _reporterToPoolIds[_reporters[i]].length;

            unchecked {
                ++i;
            }
        }
        return _poolIdsLength;
    }

    function getOwnershipContract() external view override returns (address) {
        return _ownershipContract;
    }

    function getActivationDelay() external pure override returns (uint256) {
        return _ACTIVATION_DELAY;
    }

    function getQueryDataAndId(bytes32 _poolId)
        public
        view
        override
        returns (bytes memory queryData, bytes32 queryId)
    {
        // Construct Tellor query data
        queryData = 
                abi.encode(
                    "DIVAProtocol",
                    abi.encode(_poolId, address(_DIVA), block.chainid)
                );

        // Construct Tellor queryId
        queryId = keccak256(queryData);
    }

    function _getCurrentExcessDIVARewardRecipient() internal view returns (address) {
        // Return the new excess DIVA reward recipient if `block.timestamp` is at or
        // past the activation time, else return the current excess DIVA reward
        // recipient
        return
            block.timestamp < _startTimeExcessDIVARewardRecipient
                ? _previousExcessDIVARewardRecipient
                : _excessDIVARewardRecipient;
    }

    function _getCurrentMaxDIVARewardUSD() internal view returns (uint256) {
        // Return the new max DIVA reward USD if `block.timestamp` is at or past
        // the activation time, else return the current max DIVA reward USD
        return
            block.timestamp < _startTimeMaxDIVARewardUSD
                ? _previousMaxDIVARewardUSD
                : _maxDIVARewardUSD;
    }

    function _contractOwner() internal view returns (address) {
        return IDIVAOwnershipShared(_ownershipContract).getCurrentOwner();
    }

    function _claimReward(
        bytes32 _poolId,
        address[] calldata _tippingTokens,
        bool _claimDIVAReward
    ) private {
        // Check that the pool has already been confirmed. The `_poolIdToReporter`
        // value is set during `setFinalReferenceValue`
        if (_poolIdToReporter[_poolId] == address(0)) {
            revert NotConfirmedPool();
        }

        // Iterate over the provided `_tippingTokens` array. Will skip the for
        // loop if no tipping tokens have been provided.
        uint256 _len = _tippingTokens.length;
        for (uint256 i; i < _len; ) {
            address _tippingToken = _tippingTokens[i];

            // Get tip amount for pool and tipping token.
            uint256 _tipAmount = _tips[_poolId][_tippingToken];

            // Set tip amount to zero to prevent multiple payouts in the event that 
            // the same tipping token is provided multiple times.
            _tips[_poolId][_tippingToken] = 0;

            // Transfer tip from `this` to eligible reporter.
            IERC20Metadata(_tippingToken).safeTransfer(
                _poolIdToReporter[_poolId],
                _tipAmount
            );

            // Log event for each tipping token claimed
            emit TipClaimed(
                _poolId,
                _poolIdToReporter[_poolId],
                _tippingToken,
                _tipAmount
            );

            unchecked {
                ++i;
            }
        }

        // Claim DIVA reward if indicated in the function call. Alternatively,
        // DIVA rewards can be claimed from the DIVA smart contract directly.
        if (_claimDIVAReward) {
            IDIVA.Pool memory _params = _DIVA.getPoolParameters(_poolId);
            _DIVA.claimFee(_params.collateralToken, _poolIdToReporter[_poolId]);
        }
    }

    function _setFinalReferenceValue(bytes32 _poolId) private {
        // Load pool information from the DIVA smart contract.
        IDIVA.Pool memory _params = _DIVA.getPoolParameters(_poolId);

        // Get queryId from poolId for the value look-up inside the Tellor contract.
        (, bytes32 _queryId) = getQueryDataAndId(_poolId);

        // Find first oracle submission after or at expiryTime, if it exists.
        (
            bytes memory _valueRetrieved,
            uint256 _timestampRetrieved
        ) = getDataAfter(_queryId, _params.expiryTime);

        // Check that data exists (_timestampRetrieved = 0 if it doesn't).
        if (_timestampRetrieved == 0) {
            revert NoOracleSubmissionAfterExpiryTime();
        }

        // Check that `_MIN_PERIOD_UNDISPUTED` has passed after `_timestampRetrieved`.
        if (block.timestamp - _timestampRetrieved < _MIN_PERIOD_UNDISPUTED) {
            revert MinPeriodUndisputedNotPassed();
        }

        // Format values (18 decimals)
        (
            uint256 _formattedFinalReferenceValue,
            uint256 _formattedCollateralToUSDRate
        ) = abi.decode(_valueRetrieved, (uint256, uint256));

        // Get address of reporter who will receive
        address _reporter = getReporterByTimestamp(
            _queryId,
            _timestampRetrieved
        );

        // Set reporter with poolId
        _poolIdToReporter[_poolId] = _reporter;
        _reporterToPoolIds[_reporter].push(_poolId);

        // Forward final value to DIVA contract. Credits the DIVA reward to `this`
        // contract as part of that process. DIVA reward claim is transferred to
        // the corresponding reporter via the `batchTransferFeeClaim` function
        // further down below.
        _DIVA.setFinalReferenceValue(
            _poolId,
            _formattedFinalReferenceValue,
            _CHALLENGEABLE
        );

        uint256 _SCALING;
        unchecked {
            // Cannot over-/underflow as collateralToken decimals are restricted to
            // a minimum of 6 and a maximum of 18 inside DIVA Protocol.
            _SCALING = uint256(
                10**(18 - IERC20Metadata(_params.collateralToken).decimals())
            );
        }        

        // Get the current DIVA reward claim allocated to this contract address (msg.sender)
        uint256 divaRewardClaim = _DIVA.getClaim(
            _params.collateralToken,
            address(this)
        ); // denominated in collateral token; integer with collateral token decimals

        uint256 divaRewardClaimUSD = (divaRewardClaim * _SCALING).multiplyDecimal(
            _formattedCollateralToUSDRate
        ); // denominated in USD; integer with 18 decimals
        uint256 divaRewardToReporter;

        uint256 _currentMaxDIVARewardUSD = _getCurrentMaxDIVARewardUSD();
        if (divaRewardClaimUSD > _currentMaxDIVARewardUSD) {
            // if _formattedCollateralToUSDRate = 0, then divaRewardClaimUSD = 0 in
            // which case it will go into the else part, hence division by zero
            // is not a problem
            divaRewardToReporter =
                _currentMaxDIVARewardUSD.divideDecimal(
                    _formattedCollateralToUSDRate
                ) /
                _SCALING; // integer with collateral token decimals
        } else {
            divaRewardToReporter = divaRewardClaim;
        }

        // Transfer DIVA reward claim to reporter and excess DIVA reward recipient.
        // Note that the transfer takes place internally inside the DIVA smart contract
        // and the reward has to be claimed separately either by setting the `_claimDIVAReward`
        // parameter to `true` when calling `setFinalReferenceValue` inside this contract
        // or later by calling the `claimReward` function. 
        IDIVA.ArgsBatchTransferFeeClaim[]
            memory _divaRewardClaimTransfers = new IDIVA.ArgsBatchTransferFeeClaim[](
                2
            );
        _divaRewardClaimTransfers[0] = IDIVA.ArgsBatchTransferFeeClaim(
            _reporter,
            _params.collateralToken,
            divaRewardToReporter
        );
        _divaRewardClaimTransfers[1] = IDIVA.ArgsBatchTransferFeeClaim(
            _getCurrentExcessDIVARewardRecipient(),
            _params.collateralToken,
            divaRewardClaim - divaRewardToReporter // integer with collateral token decimals
        );
        _DIVA.batchTransferFeeClaim(_divaRewardClaimTransfers);

        // Log event including reported information
        emit FinalReferenceValueSet(
            _poolId,
            _formattedFinalReferenceValue,
            _params.expiryTime,
            _timestampRetrieved
        );
    }
}