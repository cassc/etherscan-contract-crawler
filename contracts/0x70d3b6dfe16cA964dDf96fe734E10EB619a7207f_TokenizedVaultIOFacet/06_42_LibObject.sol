// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { EntityDoesNotExist, MissingSymbolWhenEnablingTokenization } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

import { ERC20Wrapper } from "../../../erc20/ERC20Wrapper.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    event TokenizationEnabled(bytes32 objectId, string tokenSymbol, string tokenName);
    event TokenWrapped(bytes32 indexed entityId, address tokenWrapper);
    event ObjectCreated(bytes32 objectId, bytes32 parentId, bytes32 dataHash);
    event ObjectUpdated(bytes32 objectId, bytes32 parentId, bytes32 dataHash);

    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        _createObject(_objectId);
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;

        emit ObjectCreated(_objectId, _parentId, _dataHash);
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        _createObject(_objectId);
        s.objectDataHashes[_objectId] = _dataHash;

        emit ObjectCreated(_objectId, 0, _dataHash);
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.existingObjects[_objectId], "objectId is already being used by another object");
        s.existingObjects[_objectId] = true;

        emit ObjectCreated(_objectId, 0, 0);
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.existingObjects[_objectId], "setDataHash: object doesn't exist");
        s.objectDataHashes[_objectId] = _dataHash;

        emit ObjectUpdated(_objectId, 0, _dataHash);
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.objectParent[_objectId] = _parentId;

        emit ObjectUpdated(_objectId, _parentId, 0);
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (bytes(s.objectTokenSymbol[_objectId]).length != 0);
    }

    function _enableObjectTokenization(
        bytes32 _objectId,
        string memory _symbol,
        string memory _name
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (bytes(_symbol).length == 0) {
            revert MissingSymbolWhenEnablingTokenization(_objectId);
        }

        // Ensure the entity exists before tokenizing the entity, otherwise revert.
        if (!s.existingEntities[_objectId]) {
            revert EntityDoesNotExist(_objectId);
        }

        require(!_isObjectTokenizable(_objectId), "object already tokenized");
        require(bytes(_symbol).length < 16, "symbol must be less than 16 characters");

        require(bytes(_name).length > 0, "name must not be empty");

        s.objectTokenSymbol[_objectId] = _symbol;
        s.objectTokenName[_objectId] = _name;

        emit TokenizationEnabled(_objectId, _symbol, _name);
    }

    function _isObjectTokenWrapped(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenWrapper[_objectId] != address(0));
    }

    function _wrapToken(bytes32 _entityId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_isObjectTokenizable(_entityId), "must be tokenizable");
        require(!_isObjectTokenWrapped(_entityId), "must not be wrapped already");

        ERC20Wrapper tokenWrapper = new ERC20Wrapper(_entityId);
        address wrapperAddress = address(tokenWrapper);

        s.objectTokenWrapper[_entityId] = wrapperAddress;
        s.objectTokenWrapperId[wrapperAddress] = _entityId;

        emit TokenWrapped(_entityId, wrapperAddress);
    }

    function _isObject(bytes32 _id) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingObjects[_id];
    }

    function _getObjectMeta(bytes32 _id)
        internal
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        parent = s.objectParent[_id];
        dataHash = s.objectDataHashes[_id];
        tokenSymbol = s.objectTokenSymbol[_id];
        tokenName = s.objectTokenName[_id];
        tokenWrapper = s.objectTokenWrapper[_id];
    }
}