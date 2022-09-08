// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { Entry, EntryLibrary, RequestType } from "../libraries/internal/EntryLibrary.sol";
import { LotLibrary } from "../libraries/internal/LotLibrary.sol";

interface IGenericConsumer is KeeperCompatibleInterface {
    /* ========== EXTERNAL FUNCTIONS ========== */

    function addFunds(address _consumer, uint96 _amount) external;

    function cancelRequest(
        bytes32 _requestId,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        uint256 _expiration
    ) external;

    function pause() external;

    function removeEntries(uint256 _lot, bytes32[] calldata _keys) external;

    function removeEntry(uint256 _lot, bytes32 _key) external;

    function removeLot(uint256 _lot) external;

    function requestData(
        bytes32 _specId,
        address _oracle,
        uint96 _payment,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external returns (bytes32);

    function requestDataAndForwardResponse(
        bytes32 _specId,
        address _oracle,
        uint96 _payment,
        address _callbackAddr,
        bytes4 _callbackFunctionSignature,
        RequestType _requestType,
        bytes calldata _buffer
    ) external returns (bytes32);

    function setDescription(string calldata _description) external;

    function setEntries(
        uint256 _lot,
        bytes32[] calldata _keys,
        Entry[] calldata _entries
    ) external;

    function setEntry(
        uint256 _lot,
        bytes32 _key,
        Entry calldata _entry
    ) external;

    function setIsUpkeepAllowed(uint256 _lot, bool _isUpkeepAllowed) external;

    function setLastRequestTimestamp(
        uint256 _lot,
        bytes32 _key,
        uint256 _lastRequestTimestamp
    ) external;

    function setLastRequestTimestamps(
        uint256 _lot,
        bytes32[] calldata _keys,
        uint256[] calldata _lastRequestTimestamps
    ) external;

    function setLatestRoundId(uint256 _latestRoundId) external;

    function setMinGasLimitPerformUpkeep(uint96 _minGasLimit) external;

    function unpause() external;

    function withdrawFunds(address _payee, uint96 _amount) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    function availableFunds(address _consumer) external view returns (uint96);

    function getDescription() external view returns (string memory);

    function getEntry(uint256 _lot, bytes32 _key) external view returns (Entry memory);

    function getEntryIsInserted(uint256 _lot, bytes32 _key) external view returns (bool);

    function getEntryMapKeyAtIndex(uint256 _lot, uint256 _index) external view returns (bytes32);

    function getEntryMapKeys(uint256 _lot) external view returns (bytes32[] memory);

    function getIsUpkeepAllowed(uint256 _lot) external view returns (bool);

    function getLastRequestTimestamp(uint256 _lot, bytes32 _key) external view returns (uint256);

    function getLatestRoundId() external view returns (uint256);

    function getLotIsInserted(uint256 _lot) external view returns (bool);

    function getLots() external view returns (uint256[] memory);

    function getNumberOfEntries(uint256 _lot) external view returns (uint256);

    function getNumberOfLots() external view returns (uint256);
}