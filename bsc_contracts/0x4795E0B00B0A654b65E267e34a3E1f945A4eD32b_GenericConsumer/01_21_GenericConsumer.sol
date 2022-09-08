// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Chainlink } from "@chainlink/contracts/src/v0.8/Chainlink.sol";
import { ConfirmedOwner } from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
// solhint-disable-next-line max-line-length
import { ChainlinkRequestInterface, OperatorInterface } from "@chainlink/contracts/src/v0.8/interfaces/OperatorInterface.sol";
import { TypeAndVersionInterface } from "@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol";
import { KeeperBase } from "@chainlink/contracts/src/v0.8/KeeperBase.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IChainlinkExternalFulfillment } from "./interfaces/IChainlinkExternalFulfillment.sol";
import { IGenericConsumer } from "./interfaces/IGenericConsumer.sol";
import { Entry, EntryLibrary, RequestType } from "./libraries/internal/EntryLibrary.sol";
import { LotLibrary } from "./libraries/internal/LotLibrary.sol";

contract GenericConsumer is ConfirmedOwner, Pausable, KeeperBase, TypeAndVersionInterface, IGenericConsumer {
    using Address for address;
    using Chainlink for Chainlink.Request;
    using EntryLibrary for EntryLibrary.Map;
    using LotLibrary for LotLibrary.Map;

    // ChainlinkClient storage
    uint256 private constant ORACLE_ARGS_VERSION = 1; // 32 bytes
    uint256 private constant OPERATOR_ARGS_VERSION = 2; // 32 bytes
    uint256 private constant AMOUNT_OVERRIDE = 0; // 32 bytes
    address private constant SENDER_OVERRIDE = address(0); // 20 bytes
    // GenericConsumer storage
    uint8 private constant MIN_FALLBACK_MSG_DATA_LENGTH = 36; // 1 byte
    bytes4 private constant NO_CALLBACK_FUNCTION_SIGNATURE = bytes4(0); // 4 bytes
    uint96 private constant LINK_TOTAL_SUPPLY = 1e27; // 12 bytes
    address private constant NO_CALLBACK_ADDR = address(0); // 20 bytes
    bytes32 private constant NO_SPEC_ID = bytes32(0); // 32 bytes
    bytes32 private constant NO_ENTRY_KEY = bytes32(0); // 32 bytes
    LinkTokenInterface public immutable LINK; // 20 bytes
    uint96 private s_minGasLimitPerformUpkeep; // 12 bytes
    uint256 private s_requestCount = 1; // 32 bytes
    uint256 private s_latestRoundId; // 32 bytes
    string private s_description; // 64 bytes
    mapping(bytes32 => address) private s_pendingRequests; /* requestId */ /* oracle */
    mapping(address => uint96) private s_consumerToLinkBalance; /* mgs.sender */ /* LINK */
    mapping(uint256 => bool) private s_lotToIsUpkeepAllowed; /* lot */ /* bool */
    // solhint-disable-next-line max-line-length
    mapping(uint256 => mapping(bytes32 => uint256)) private s_lotToLastRequestTimestampMap; /* lot */ /* key */ /* lastRequestTimestamp */
    mapping(bytes32 => address) private s_requestIdToCallbackAddr; /* requestId */ /* callbackAddr */
    mapping(bytes32 => address) private s_requestIdToConsumer; /* requestId */ /* msg.sender or address(this) */
    LotLibrary.Map private s_lotToEntryMap; /* lot */ /* key */ /* Entry */

    error GenericConsumer__ArrayIsEmpty(string arrayName);
    error GenericConsumer__ArrayLengthsAreNotEqual(
        string array1Name,
        uint256 array1Length,
        string array2Name,
        uint256 array2Length
    );
    error GenericConsumer__CallbackAddrIsGenericConsumer(address callbackAddr);
    error GenericConsumer__CallbackAddrIsNotContract(address callbackAddr);
    error GenericConsumer__CallbackFunctionSignatureIsZero();
    error GenericConsumer__CallerIsNotRequestConsumer(address consumer, address requestConsumer);
    error GenericConsumer__ConsumerAddrIsOwner(address consumer);
    error GenericConsumer__EntryFieldCallbackFunctionSignatureIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryFieldCallbackAddrIsNotContract(uint256 lot, bytes32 key, address callbackAddr);
    error GenericConsumer__EntryFieldIntervalIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryFieldOracleIsGenericConsumer(uint256 lot, bytes32 key, address oracle);
    error GenericConsumer__EntryFieldOracleIsNotContract(uint256 lot, bytes32 key, address oracle);
    error GenericConsumer__EntryFieldPaymentIsGtLinkTotalSupply(uint256 lot, bytes32 key, uint96 payment);
    error GenericConsumer__EntryFieldSpecIdIsZero(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsInactive(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotInserted(uint256 lot, bytes32 key);
    error GenericConsumer__EntryIsNotScheduled(
        uint256 lot,
        bytes32 key,
        uint96 startAt,
        uint96 interval,
        uint256 lastRequestTimestamp,
        uint256 blockTimestamp
    );
    error GenericConsumer__FallbackMsgDataIsInvalid(bytes data);
    error GenericConsumer__LinkAllowanceIsInsufficient(address payer, uint96 allowance, uint96 amount);
    error GenericConsumer__LinkBalanceIsInsufficient(address payer, uint96 balance, uint96 amount);
    error GenericConsumer__LinkPaymentIsGtLinkTotalSupply(uint96 payment);
    error GenericConsumer__LinkTransferAndCallFailed(address to, uint96 amount, bytes encodedRequest);
    error GenericConsumer__LinkTransferFailed(address to, uint256 amount);
    error GenericConsumer__LinkTransferFromFailed(address from, address to, uint96 payment);
    error GenericConsumer__LotIsEmpty(uint256 lot);
    error GenericConsumer__LotIsNotInserted(uint256 lot);
    error GenericConsumer__LotIsNotUpkeepAllowed(uint256 lot);
    error GenericConsumer__OracleIsNotContract(address oracle);
    error GenericConsumer__CallerIsNotRequestOracle(address oracle);
    error GenericConsumer__RequestIsNotPending();
    error GenericConsumer__RequestTypeIsUnsupported(RequestType requestType);
    error GenericConsumer__SpecIdIsZero();

    event ChainlinkCancelled(bytes32 indexed requestId);
    event ChainlinkFulfilled(
        bytes32 indexed requestId,
        bool success,
        bool isForwarded,
        address indexed callbackAddr,
        bytes4 indexed callbackFunctionSignature,
        bytes data
    );
    event ChainlinkRequested(bytes32 indexed requestId);
    event DescriptionSet(string description);
    event EntryRequested(uint256 roundId, uint256 indexed lot, bytes32 indexed key, bytes32 indexed requestId);
    event EntryRemoved(uint256 indexed lot, bytes32 indexed key);
    event EntrySet(uint256 indexed lot, bytes32 indexed key, Entry entry);
    event FundsAdded(address indexed from, address indexed to, uint96 amount);
    event FundsWithdrawn(address indexed from, address indexed to, uint96 amount);
    event IsUpkeepAllowedSet(uint256 indexed lot, bool isUpkeepAllowed);
    event LastRequestTimestampSet(uint256 indexed lot, bytes32 indexed key, uint256 lastRequestTimestamp);
    event LatestRoundIdSet(uint256 latestRoundId);
    event LotRemoved(uint256 indexed lot);
    event MinGasLimitPerformUpkeepSet(uint96 minGasLimit);
    event SetExternalPendingRequestFailed(address indexed callbackAddr, bytes32 indexed requestId, bytes32 indexed key);

    /**
     * @param _link the LINK token address.
     * @param _description the contract description.
     */
    constructor(
        address _link,
        string memory _description,
        uint96 _minGasLimit
    ) ConfirmedOwner(msg.sender) {
        LINK = LinkTokenInterface(_link);
        s_description = _description;
        s_minGasLimitPerformUpkeep = _minGasLimit;
    }

    // solhint-disable-next-line no-complex-fallback, payable-fallback
    fallback() external whenNotPaused {
        bytes4 callbackFunctionSignature = msg.sig; // bytes4(msg.data);
        bytes calldata data = msg.data;
        _requireFallbackMsgData(data);
        bytes32 requestId = abi.decode(data[4:], (bytes32));
        _requireCallerIsRequestOracle(s_pendingRequests[requestId]);
        delete s_pendingRequests[requestId];
        delete s_requestIdToConsumer[requestId];
        address callbackAddr = s_requestIdToCallbackAddr[requestId];
        if (callbackAddr == NO_CALLBACK_ADDR) {
            emit ChainlinkFulfilled(requestId, true, false, address(this), callbackFunctionSignature, data);
        } else {
            delete s_requestIdToCallbackAddr[requestId];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = callbackAddr.call(data);
            emit ChainlinkFulfilled(requestId, success, true, callbackAddr, callbackFunctionSignature, data);
        }
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external {
        _requireConsumerIsNotOwner(_consumer);
        _requireLinkAllowanceIsSufficient(msg.sender, uint96(LINK.allowance(msg.sender, address(this))), _amount);
        _requireLinkBalanceIsSufficient(msg.sender, uint96(LINK.balanceOf(msg.sender)), _amount);
        s_consumerToLinkBalance[_consumer] += _amount;
        emit FundsAdded(msg.sender, _consumer, _amount);
        if (!LINK.transferFrom(msg.sender, address(this), _amount)) {
            revert GenericConsumer__LinkTransferFromFailed(msg.sender, address(this), _amount);
        }
    }

    function cancelRequest(
        bytes32 _requestId,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        uint256 _expiration
    ) external {
        address oracleAddr = s_pendingRequests[_requestId];
        _requireRequestIsPending(oracleAddr);
        address consumer = _getConsumer();
        _requireCallerIsRequestConsumer(_requestId, consumer);
        s_consumerToLinkBalance[consumer] += _payment;
        delete s_pendingRequests[_requestId];
        delete s_requestIdToConsumer[_requestId];
        emit ChainlinkCancelled(_requestId);
        OperatorInterface operator = OperatorInterface(oracleAddr);
        operator.cancelOracleRequest(_requestId, _payment, _callbackFunctionSignature, _expiration);
    }

    /**
     * @notice Pauses the contract, which prevents executing requests
     */
    function pause() external onlyOwner {
        _pause();
    }

    function performUpkeep(bytes calldata _performData) external override whenNotPaused {
        (uint256 lot, bytes32[] memory keys) = abi.decode(_performData, (uint256, bytes32[]));
        _requireLotIsInserted(lot, s_lotToEntryMap.isInserted(lot));
        if (msg.sender != owner()) {
            _requireLotIsUpkeepAllowed(lot);
        }
        uint256 keysLength = keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 blockTimestamp = block.timestamp;
        uint256 roundId = s_latestRoundId + 1;
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[lot];
        uint256 minGasLimit = uint256(s_minGasLimitPerformUpkeep);
        uint96 consumerLinkBalance = s_consumerToLinkBalance[address(this)];
        uint256 nonce = s_requestCount;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = keys[i];
            unchecked {
                ++i;
            }
            _requireEntryIsInserted(lot, key, s_keyToEntry.isInserted(key));
            Entry memory entry = s_keyToEntry.getEntry(key);
            _requireEntryIsActive(lot, key, entry.inactive);
            _requireEntryIsScheduled(
                lot,
                key,
                entry.startAt,
                entry.interval,
                s_keyToLastRequestTimestamp[key],
                blockTimestamp
            );
            _requireLinkBalanceIsSufficient(address(this), consumerLinkBalance, entry.payment);
            consumerLinkBalance -= entry.payment;
            bytes32 requestId = _buildAndSendRequest(
                nonce,
                entry.specId,
                entry.oracle,
                entry.payment,
                entry.callbackAddr,
                entry.callbackFunctionSignature,
                entry.requestType,
                entry.buffer,
                key
            );
            unchecked {
                ++nonce;
            }
            s_keyToLastRequestTimestamp[key] = blockTimestamp;
            emit EntryRequested(roundId, lot, key, requestId);
            if (gasleft() <= minGasLimit) break;
        }
        s_requestCount = nonce;
        s_consumerToLinkBalance[address(this)] = consumerLinkBalance;
        s_latestRoundId = roundId;
    }

    function removeEntries(uint256 _lot, bytes32[] calldata _keys) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = _keys[i];
            _removeEntry(s_keyToEntry, _lot, key);
            delete s_keyToLastRequestTimestamp[key];
            unchecked {
                ++i;
            }
        }
        _cleanLotData(s_keyToEntry.size(), _lot);
    }

    function removeEntry(uint256 _lot, bytes32 _key) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        _removeEntry(s_keyToEntry, _lot, _key);
        delete s_lotToLastRequestTimestampMap[_lot][_key];
        _cleanLotData(s_keyToEntry.size(), _lot);
    }

    function removeLot(uint256 _lot) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        bytes32[] memory keys = s_lotToEntryMap.getLot(_lot).keys;
        uint256 keysLength = keys.length;
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            delete s_keyToLastRequestTimestamp[keys[i]];
            unchecked {
                ++i;
            }
        }
        s_lotToEntryMap.getLot(_lot).removeAll();
        _cleanLotData(0, _lot);
        emit LotRemoved(_lot);
    }

    function requestData(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external whenNotPaused returns (bytes32) {
        return
            _requestData(
                _specId,
                _oracleAddr,
                _payment,
                address(this),
                _callbackFunctionSignature,
                _requestType,
                _buffer,
                false
            );
    }

    function requestDataAndForwardResponse(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external whenNotPaused returns (bytes32) {
        return
            _requestData(
                _specId,
                _oracleAddr,
                _payment,
                _callbackAddr,
                _callbackFunctionSignature,
                _requestType,
                _buffer,
                true
            );
    }

    function setDescription(string calldata _description) external onlyOwner {
        s_description = _description;
        emit DescriptionSet(_description);
    }

    function setEntries(
        uint256 _lot,
        bytes32[] calldata _keys,
        Entry[] calldata _entries
    ) external onlyOwner {
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "entries", _entries.length);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        for (uint256 i = 0; i < keysLength; ) {
            _setEntry(s_keyToEntry, _lot, _keys[i], _entries[i]);
            unchecked {
                ++i;
            }
        }
        s_lotToEntryMap.set(_lot);
    }

    function setEntry(
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) external onlyOwner {
        _setEntry(s_lotToEntryMap.getLot(_lot), _lot, _key, _entry);
        s_lotToEntryMap.set(_lot);
    }

    function setIsUpkeepAllowed(uint256 _lot, bool _isUpkeepAllowed) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        s_lotToIsUpkeepAllowed[_lot] = _isUpkeepAllowed;
        emit IsUpkeepAllowedSet(_lot, _isUpkeepAllowed);
    }

    function setLastRequestTimestamp(
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _setLastRequestTimestamp(
            s_lotToEntryMap.getLot(_lot),
            s_lotToLastRequestTimestampMap[_lot],
            _lot,
            _key,
            _lastRequestTimestamp
        );
    }

    function setLastRequestTimestamps(
        uint256 _lot,
        bytes32[] calldata _keys,
        uint256[] calldata _lastRequestTimestamps
    ) external onlyOwner {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        uint256 keysLength = _keys.length;
        _requireArrayIsNotEmpty("keys", keysLength);
        _requireArrayLengthsAreEqual("keys", keysLength, "lastRequestTimestamps", _lastRequestTimestamps.length);
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(_lot);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[_lot];
        for (uint256 i = 0; i < keysLength; ) {
            _setLastRequestTimestamp(
                s_keyToEntry,
                s_keyToLastRequestTimestamp,
                _lot,
                _keys[i],
                _lastRequestTimestamps[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function setLatestRoundId(uint256 _latestRoundId) external onlyOwner {
        s_latestRoundId = _latestRoundId;
        emit LatestRoundIdSet(_latestRoundId);
    }

    function setMinGasLimitPerformUpkeep(uint96 _minGasLimit) external onlyOwner {
        s_minGasLimitPerformUpkeep = _minGasLimit;
        emit MinGasLimitPerformUpkeepSet(_minGasLimit);
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawFunds(address _payee, uint96 _amount) external {
        address consumer = _getConsumer();
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _amount);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _amount;
        emit FundsWithdrawn(consumer, _payee, _amount);
        if (!LINK.transfer(_payee, _amount)) {
            revert GenericConsumer__LinkTransferFailed(_payee, _amount);
        }
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96) {
        return s_consumerToLinkBalance[_consumer];
    }

    function checkUpkeep(bytes calldata _checkData) external view override cannotExecute returns (bool, bytes memory) {
        uint256 lot = abi.decode(_checkData, (uint256));
        _requireLotIsInserted(lot, s_lotToEntryMap.isInserted(lot));
        EntryLibrary.Map storage s_keyToEntry = s_lotToEntryMap.getLot(lot);
        uint256 keysLength = s_keyToEntry.size();
        _requireLotIsNotEmpty(lot, keysLength); // NB: assertion-like
        bytes32[] memory keys = new bytes32[](keysLength);
        mapping(bytes32 => uint256) storage s_keyToLastRequestTimestamp = s_lotToLastRequestTimestampMap[lot];
        uint256 blockTimestamp = block.timestamp;
        uint256 noEntriesToRequest = 0;
        uint256 roundPayment = 0;
        for (uint256 i = 0; i < keysLength; ) {
            bytes32 key = s_keyToEntry.getKeyAtIndex(i);
            unchecked {
                ++i;
            }

            Entry memory entry = s_keyToEntry.getEntry(key);
            if (entry.inactive) continue;
            if (!_isScheduled(entry.startAt, entry.interval, s_keyToLastRequestTimestamp[key], blockTimestamp))
                continue;
            keys[noEntriesToRequest] = key;
            roundPayment += entry.payment;
            unchecked {
                ++noEntriesToRequest;
            }
        }
        bool isUpkeepNeeded;
        bytes memory performData;
        if (noEntriesToRequest > 0 && s_consumerToLinkBalance[address(this)] >= roundPayment) {
            isUpkeepNeeded = true;
            uint256 noEmptySlots = keysLength - noEntriesToRequest;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(keys, sub(mload(keys), noEmptySlots))
            }
            performData = abi.encode(lot, keys);
        }
        return (isUpkeepNeeded, performData);
    }

    function getDescription() external view returns (string memory) {
        return s_description;
    }

    function getEntry(uint256 _lot, bytes32 _key) external view returns (Entry memory) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryIsInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
        return s_lotToEntryMap.getLot(_lot).getEntry(_key);
    }

    function getEntryIsInserted(uint256 _lot, bytes32 _key) external view returns (bool) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).isInserted(_key);
    }

    function getEntryMapKeyAtIndex(uint256 _lot, uint256 _index) external view returns (bytes32) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).getKeyAtIndex(_index);
    }

    function getEntryMapKeys(uint256 _lot) external view returns (bytes32[] memory) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).keys;
    }

    function getIsUpkeepAllowed(uint256 _lot) external view returns (bool) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToIsUpkeepAllowed[_lot];
    }

    function getLastRequestTimestamp(uint256 _lot, bytes32 _key) external view returns (uint256) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        _requireEntryIsInserted(_lot, _key, s_lotToEntryMap.getLot(_lot).isInserted(_key));
        return s_lotToLastRequestTimestampMap[_lot][_key];
    }

    function getLatestRoundId() external view returns (uint256) {
        return s_latestRoundId;
    }

    function getLotIsInserted(uint256 _lot) external view returns (bool) {
        return s_lotToEntryMap.isInserted(_lot);
    }

    function getLots() external view returns (uint256[] memory) {
        return s_lotToEntryMap.lots;
    }

    function getMinGasLimitPerformUpkeep() external view returns (uint96) {
        return s_minGasLimitPerformUpkeep;
    }

    function getNumberOfEntries(uint256 _lot) external view returns (uint256) {
        _requireLotIsInserted(_lot, s_lotToEntryMap.isInserted(_lot));
        return s_lotToEntryMap.getLot(_lot).size();
    }

    function getNumberOfLots() external view returns (uint256) {
        return s_lotToEntryMap.size();
    }

    /* ========== EXTERNAL PURE FUNCTIONS ========== */

    /**
     * @notice versions:
     *
     * - GenericConsumer 1.0.0: initial release
     * - GenericConsumer 2.0.0: added support for oracle requests, consumer LINK balance, upkeep access control & more
     *
     * @inheritdoc TypeAndVersionInterface
     */
    function typeAndVersion() external pure virtual override returns (string memory) {
        return "GenericConsumer 2.0.0";
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _buildAndSendRequest(
        uint256 _nonce,
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes memory _buffer,
        bytes32 _key
    ) private returns (bytes32) {
        Chainlink.Request memory req;
        req = req.initialize(_specId, address(this), _callbackFunctionSignature);
        req.setBuffer(_buffer);
        bytes32 requestId = _sendRequestTo(_nonce, _oracleAddr, req, _payment, _requestType);
        // In case of "external request" (i.e. callbackAddr != address(this)) notify the fulfillment contract about the
        // pending request
        if (_callbackAddr != address(this)) {
            s_requestIdToCallbackAddr[requestId] = _callbackAddr;
            IChainlinkExternalFulfillment fulfillmentContract = IChainlinkExternalFulfillment(_callbackAddr);
            // solhint-disable-next-line no-empty-blocks
            try fulfillmentContract.setExternalPendingRequest(address(this), requestId) {} catch {
                emit SetExternalPendingRequestFailed(_callbackAddr, requestId, _key);
            }
        }
        return requestId;
    }

    function _cleanLotData(uint256 _noEntries, uint256 _lot) private {
        if (_noEntries == 0) {
            delete s_lotToIsUpkeepAllowed[_lot];
            s_lotToEntryMap.remove(_lot);
        }
    }

    function _removeEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key
    ) private {
        _requireEntryIsInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToEntry.remove(_key);
        emit EntryRemoved(_lot, _key);
    }

    function _requestData(
        bytes32 _specId,
        address _oracleAddr,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes memory _buffer,
        bool _isResponseForwarded
    ) private returns (bytes32) {
        _requireSpecId(_specId);
        _requireOracle(_oracleAddr);
        _requireLinkPaymentIsInRange(_payment);
        if (_isResponseForwarded) {
            _requireCallbackAddr(_callbackAddr);
        }
        _requireCallbackFunctionSignature(_callbackFunctionSignature);

        address consumer = _getConsumer();
        uint96 consumerLinkBalance = s_consumerToLinkBalance[consumer];
        _requireLinkBalanceIsSufficient(consumer, consumerLinkBalance, _payment);
        s_consumerToLinkBalance[consumer] = consumerLinkBalance - _payment;
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes32 requestId = _buildAndSendRequest(
            nonce,
            _specId,
            _oracleAddr,
            _payment,
            _callbackAddr,
            _callbackFunctionSignature,
            _requestType,
            _buffer,
            NO_ENTRY_KEY
        );
        s_requestIdToConsumer[requestId] = consumer;
        return requestId;
    }

    function _sendRequestTo(
        uint256 _nonce,
        address _oracleAddress,
        Chainlink.Request memory _req,
        uint96 _payment,
        RequestType _requestType
    ) private returns (bytes32) {
        bytes memory encodedRequest;
        if (_requestType == RequestType.ORACLE) {
            // ChainlinkClient.sendChainlinkRequestTo()
            encodedRequest = abi.encodeWithSelector(
                ChainlinkRequestInterface.oracleRequest.selector,
                SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
                AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
                _req.id,
                address(this),
                _req.callbackFunctionId,
                _nonce,
                ORACLE_ARGS_VERSION,
                _req.buf.buf
            );
        } else if (_requestType == RequestType.OPERATOR) {
            // ChainlinkClient.sendOperatorRequestTo()
            encodedRequest = abi.encodeWithSelector(
                OperatorInterface.operatorRequest.selector,
                SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
                AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
                _req.id,
                _req.callbackFunctionId,
                _nonce,
                OPERATOR_ARGS_VERSION,
                _req.buf.buf
            );
        } else {
            revert GenericConsumer__RequestTypeIsUnsupported(_requestType);
        }
        // ChainlinkClient._rawRequest()
        bytes32 requestId = keccak256(abi.encodePacked(this, _nonce));
        s_pendingRequests[requestId] = _oracleAddress;
        emit ChainlinkRequested(requestId);
        if (!LINK.transferAndCall(_oracleAddress, _payment, encodedRequest)) {
            revert GenericConsumer__LinkTransferAndCallFailed(_oracleAddress, _payment, encodedRequest);
        }
        return requestId;
    }

    function _setEntry(
        EntryLibrary.Map storage _s_keyToEntry,
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) private {
        _validateEntryFieldSpecId(_lot, _key, _entry.specId);
        _validateEntryFieldOracle(_lot, _key, _entry.oracle);
        _validateEntryFieldPayment(_lot, _key, _entry.payment);
        _validateEntryFieldCallbackAddr(_lot, _key, _entry.callbackAddr);
        _validateEntryFieldCallbackFunctionSignature(_lot, _key, _entry.callbackFunctionSignature);
        _validateEntryFieldInterval(_lot, _key, _entry.interval);
        _s_keyToEntry.set(_key, _entry);
        emit EntrySet(_lot, _key, _entry);
    }

    function _setLastRequestTimestamp(
        EntryLibrary.Map storage _s_keyToEntry,
        mapping(bytes32 => uint256) storage _s_keyToLastRequestTimestamp,
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) private {
        _requireEntryIsInserted(_lot, _key, _s_keyToEntry.isInserted(_key));
        _s_keyToLastRequestTimestamp[_key] = _lastRequestTimestamp;
        emit LastRequestTimestampSet(_lot, _key, _lastRequestTimestamp);
    }

    /* ========== PRIVATE VIEW FUNCTIONS ========== */

    function _getConsumer() private view returns (address) {
        return msg.sender == owner() ? address(this) : msg.sender;
    }

    function _requireCallbackAddr(address _callbackAddr) private view {
        if (!_callbackAddr.isContract()) {
            revert GenericConsumer__CallbackAddrIsNotContract(_callbackAddr);
        }
        if (_callbackAddr == address(this)) {
            revert GenericConsumer__CallbackAddrIsGenericConsumer(_callbackAddr);
        }
    }

    function _requireCallerIsRequestConsumer(bytes32 _requestId, address _consumer) private view {
        address requestConsumer = s_requestIdToConsumer[_requestId];
        if (_consumer != requestConsumer) {
            revert GenericConsumer__CallerIsNotRequestConsumer(_consumer, requestConsumer);
        }
    }

    function _requireCallerIsRequestOracle(address _oracleAddr) private view {
        if (_oracleAddr != msg.sender) {
            _requireRequestIsPending(_oracleAddr);
            revert GenericConsumer__CallerIsNotRequestOracle(_oracleAddr);
        }
    }

    function _requireConsumerIsNotOwner(address _consumer) private view {
        if (_consumer == owner()) {
            revert GenericConsumer__ConsumerAddrIsOwner(_consumer);
        }
    }

    function _requireLotIsUpkeepAllowed(uint256 _lot) private view {
        if (!s_lotToIsUpkeepAllowed[_lot]) {
            revert GenericConsumer__LotIsNotUpkeepAllowed(_lot);
        }
    }

    function _requireOracle(address _oracle) private view {
        if (!_oracle.isContract()) {
            revert GenericConsumer__OracleIsNotContract(_oracle);
        }
    }

    function _validateEntryFieldOracle(
        uint256 _lot,
        bytes32 _key,
        address _oracle
    ) private view {
        if (!_oracle.isContract()) {
            revert GenericConsumer__EntryFieldOracleIsNotContract(_lot, _key, _oracle);
        }
        if (_oracle == address(this)) {
            revert GenericConsumer__EntryFieldOracleIsGenericConsumer(_lot, _key, _oracle);
        }
    }

    /* ========== PRIVATE PURE FUNCTIONS ========== */

    function _isScheduled(
        uint96 _startAt,
        uint96 _interval,
        uint256 _lastRequestTimestamp,
        uint256 _blockTimestamp
    ) private pure returns (bool) {
        return (_startAt <= _blockTimestamp && (_blockTimestamp - _lastRequestTimestamp) >= _interval);
    }

    function _requireArrayIsNotEmpty(string memory _arrayName, uint256 _arrayLength) private pure {
        if (_arrayLength == 0) {
            revert GenericConsumer__ArrayIsEmpty(_arrayName);
        }
    }

    function _requireArrayLengthsAreEqual(
        string memory _array1Name,
        uint256 _array1Length,
        string memory _array2Name,
        uint256 _array2Length
    ) private pure {
        if (_array1Length != _array2Length) {
            revert GenericConsumer__ArrayLengthsAreNotEqual(_array1Name, _array1Length, _array2Name, _array2Length);
        }
    }

    function _requireCallbackFunctionSignature(bytes4 _callbackFunctionSignature) private pure {
        if (_callbackFunctionSignature == NO_CALLBACK_FUNCTION_SIGNATURE) {
            revert GenericConsumer__CallbackFunctionSignatureIsZero();
        }
    }

    function _requireEntryIsActive(
        uint256 _lot,
        bytes32 _key,
        bool _inactive
    ) private pure {
        if (_inactive) {
            revert GenericConsumer__EntryIsInactive(_lot, _key);
        }
    }

    function _requireEntryIsInserted(
        uint256 _lot,
        bytes32 _key,
        bool _isInserted
    ) private pure {
        if (!_isInserted) {
            revert GenericConsumer__EntryIsNotInserted(_lot, _key);
        }
    }

    function _requireEntryIsScheduled(
        uint256 _lot,
        bytes32 _key,
        uint96 _startAt,
        uint96 _interval,
        uint256 _lastRequestTimestamp,
        uint256 _blockTimestamp
    ) private pure {
        if (!_isScheduled(_startAt, _interval, _lastRequestTimestamp, _blockTimestamp)) {
            revert GenericConsumer__EntryIsNotScheduled(
                _lot,
                _key,
                _startAt,
                _interval,
                _lastRequestTimestamp,
                _blockTimestamp
            );
        }
    }

    function _requireFallbackMsgData(bytes calldata _data) private pure {
        if (_data.length < MIN_FALLBACK_MSG_DATA_LENGTH) {
            revert GenericConsumer__FallbackMsgDataIsInvalid(_data);
        }
    }

    function _requireLinkAllowanceIsSufficient(
        address _payer,
        uint96 _allowance,
        uint96 _amount
    ) private pure {
        if (_allowance < _amount) {
            revert GenericConsumer__LinkAllowanceIsInsufficient(_payer, _allowance, _amount);
        }
    }

    function _requireLinkBalanceIsSufficient(
        address _payer,
        uint96 _balance,
        uint96 _amount
    ) private pure {
        if (_balance < _amount) {
            revert GenericConsumer__LinkBalanceIsInsufficient(_payer, _balance, _amount);
        }
    }

    function _requireLinkPaymentIsInRange(uint96 _payment) private pure {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert GenericConsumer__LinkPaymentIsGtLinkTotalSupply(_payment);
        }
    }

    function _requireLotIsInserted(uint256 _lot, bool _isInserted) private pure {
        if (!_isInserted) {
            revert GenericConsumer__LotIsNotInserted(_lot);
        }
    }

    function _requireLotIsNotEmpty(uint256 _lot, uint256 _size) private pure {
        if (_size == 0) {
            revert GenericConsumer__LotIsEmpty(_lot);
        }
    }

    function _requireRequestIsPending(address _oracleAddr) private pure {
        if (_oracleAddr == address(0)) {
            revert GenericConsumer__RequestIsNotPending();
        }
    }

    function _requireSpecId(bytes32 _specId) private pure {
        if (_specId == NO_SPEC_ID) {
            revert GenericConsumer__SpecIdIsZero();
        }
    }

    function _validateEntryFieldCallbackAddr(
        uint256 _lot,
        bytes32 _key,
        address _callbackAddr
    ) private view {
        if (!_callbackAddr.isContract()) {
            revert GenericConsumer__EntryFieldCallbackAddrIsNotContract(_lot, _key, _callbackAddr);
        }
    }

    function _validateEntryFieldCallbackFunctionSignature(
        uint256 _lot,
        bytes32 _key,
        bytes4 _callbackFunctionSignature
    ) private pure {
        if (_callbackFunctionSignature == NO_CALLBACK_FUNCTION_SIGNATURE) {
            revert GenericConsumer__EntryFieldCallbackFunctionSignatureIsZero(_lot, _key);
        }
    }

    function _validateEntryFieldInterval(
        uint256 _lot,
        bytes32 _key,
        uint96 _interval
    ) private pure {
        if (_interval == 0) {
            revert GenericConsumer__EntryFieldIntervalIsZero(_lot, _key);
        }
    }

    function _validateEntryFieldPayment(
        uint256 _lot,
        bytes32 _key,
        uint96 _payment
    ) private pure {
        if (_payment > LINK_TOTAL_SUPPLY) {
            revert GenericConsumer__EntryFieldPaymentIsGtLinkTotalSupply(_lot, _key, _payment);
        }
    }

    function _validateEntryFieldSpecId(
        uint256 _lot,
        bytes32 _key,
        bytes32 _specId
    ) private pure {
        if (_specId == NO_SPEC_ID) {
            revert GenericConsumer__EntryFieldSpecIdIsZero(_lot, _key);
        }
    }
}