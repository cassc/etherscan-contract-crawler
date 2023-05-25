// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import './interface/ITMAsMetadata.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'tma-staking-contracts/contracts/AMTManager/AMTManager.sol';

error NameCheckError();
error NameTooShortError();
error NameAlreadyUsedError();
error NonNameError();
error RaiseLimitError();
error EnhanceCheckError();

contract TMAsMetadata is ITMAsMetadata, AccessControl {
    event UpdateMetadata(uint256 indexed id, Metadata metadata, bool updateFamily);

    IERC721 public immutable tmas;
    bytes32 public constant CONFIGURATOR_ROLE = keccak256('CONFIGURATOR_ROLE');

    mapping(string => bool) private _usedNames;
    mapping(uint256 => Metadata) private _metadatas;
    mapping(uint256 => Status) private _defaultStatus;

    IAMTManager public points;
    uint16 public maxRaise = 10;
    uint256 public nameCost = 10;
    uint256 public statusCost = 100;
    uint256 public resetFamilyCost = 5000;
    mapping(uint256 => uint256) public raiseCost;

    modifier onlyNamed(uint256 id) {
        if (bytes(_metadatas[id].name).length == 0) revert NonNameError();
        _;
    }

    modifier onlyTMAsOwner(uint256 id) {
        if (tmas.ownerOf(id) != msg.sender) revert NonNameError();
        _;
    }

    constructor(IAMTManager _points, IERC721 _tmas) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CONFIGURATOR_ROLE, msg.sender);
        raiseCost[0] = 100;
        raiseCost[1] = 400;
        raiseCost[2] = 1000;
        points = _points;
        tmas = _tmas;
    }

    //only CONFIGURATOR
    function setPoints(IAMTManager _pointse) external onlyRole(CONFIGURATOR_ROLE) {
        points = _pointse;
    }

    function setMaxRaise(uint16 _maxRaise) external onlyRole(CONFIGURATOR_ROLE) {
        maxRaise = _maxRaise;
    }

    function setStatusCost(uint256 _statusCost) external onlyRole(CONFIGURATOR_ROLE) {
        statusCost = _statusCost;
    }

    function setResetFamilyCost(uint256 _resetFamilyCost) external onlyRole(CONFIGURATOR_ROLE) {
        resetFamilyCost = _resetFamilyCost;
    }

    function setRaiseCost(uint256 index, uint256 cost) external onlyRole(CONFIGURATOR_ROLE) {
        raiseCost[index] = cost;
    }

    function setNameCost(uint256 _nameCost) external onlyRole(CONFIGURATOR_ROLE) {
        nameCost = _nameCost;
    }

    function setDefaultStatus(uint256 startIndex, Status[] memory statuses) external onlyRole(CONFIGURATOR_ROLE) {
        uint256 i = 0;

        while (i < statuses.length) {
            _defaultStatus[startIndex + i] = statuses[i];
            i++;
        }
    }

    function setMetadata(uint256 id, Metadata memory metadata) external onlyRole(CONFIGURATOR_ROLE) {
        if (metadata.raise > maxRaise) revert RaiseLimitError();
        if (!checkName(metadata.name)) revert NameCheckError();
        if (_usedNames[metadata.name]) revert NameAlreadyUsedError();
        if (!enhanceStatusCheck(id, metadata.status)) revert EnhanceCheckError();
        _usedNames[_metadatas[id].name] = false;
        _metadatas[id] = metadata;
        _usedNames[metadata.name] = true;
        emit UpdateMetadata(id, _metadatas[id], false);
    }

    //only named
    function resetFamily(uint256 id) external override onlyTMAsOwner(id) onlyNamed(id) {
        points.use(msg.sender, resetFamilyCost, 'resetFamily');
        _metadatas[id].familyResetCount++;
        emit UpdateMetadata(id, _metadatas[id], true);
    }

    function raiseUp(uint256 id) external override onlyTMAsOwner(id) onlyNamed(id) {
        if (_metadatas[id].raise + 1 > maxRaise) revert RaiseLimitError();
        points.use(msg.sender, calcRaiseCost(id), 'raiseUp');
        _metadatas[id].raise++;
        emit UpdateMetadata(id, _metadatas[id], false);
    }

    function enhanceStatus(uint256 id, Status calldata status) external override onlyTMAsOwner(id) onlyNamed(id) {
        Status memory enhanced = sumStatuses(_metadatas[id].status, status);
        if (!enhanceStatusCheck(id, enhanced)) revert EnhanceCheckError();
        points.use(msg.sender, calcEnhanceStatusCost(status), 'enhanceStatus');
        _metadatas[id].status = sumStatuses(_metadatas[id].status, status);
        emit UpdateMetadata(id, _metadatas[id], false);
    }

    //only TMAsOwner
    function setName(uint256 id, string memory name) external override onlyTMAsOwner(id) {
        if (bytes(name).length < 2) revert NameTooShortError();
        if (!checkName(name)) revert NameCheckError();
        if (_usedNames[name]) revert NameAlreadyUsedError();
        points.use(msg.sender, nameCost, 'setName');
        _usedNames[_metadatas[id].name] = false;
        _metadatas[id].name = name;
        _usedNames[name] = true;
        emit UpdateMetadata(id, _metadatas[id], false);
    }

    //view
    function usedNames(string memory name) external view override returns (bool) {
        return _usedNames[name];
    }

    function metadatas(uint256 id) external view override returns (Metadata memory metadata) {
        metadata = _metadatas[id];
    }

    function calcedMetadatas(uint256 id) external view override returns (Metadata memory metadata) {
        metadata = _metadatas[id];
        metadata.status = sumStatuses(_defaultStatus[id], _metadatas[id].status);
    }

    function power(uint256 id) external view override returns (uint256) {
        return
            _metadatas[id].status.HP +
            _metadatas[id].status.ATK +
            _metadatas[id].status.DEF +
            _metadatas[id].status.INT +
            _metadatas[id].status.AGI;
    }

    function defaultStatus(uint256 id) external view override returns (Status memory) {
        return _defaultStatus[id];
    }

    //internal
    function enhanceStatusCheck(uint256 id, Status memory enhance) internal view returns (bool) {
        Status memory check = sumStatuses(_defaultStatus[id], enhance);
        uint16 max = statusMax(_metadatas[id].raise);
        if (check.HP > max || check.ATK > max || check.DEF > max || check.INT > max || check.AGI > max) return false;
        return true;
    }

    function calcRaiseCost(uint256 id) internal view returns (uint256) {
        uint256 currentRaise = _metadatas[id].raise;
        if (currentRaise > 2) return raiseCost[2];
        return raiseCost[currentRaise];
    }

    function calcEnhanceStatusCost(Status calldata status) internal view returns (uint256 cost) {
        return statusCost * (status.HP + status.ATK + status.DEF + status.INT + status.AGI);
    }

    //pure
    function sumStatuses(Status memory source, Status memory destination) internal pure returns (Status memory) {
        destination.HP += source.HP;
        destination.ATK += source.ATK;
        destination.DEF += source.DEF;
        destination.INT += source.INT;
        destination.AGI += source.AGI;
        return destination;
    }

    function statusMax(uint256 raise) public pure returns (uint16) {
        if (raise >= 10) return 100;
        if (raise >= 3) return 20;
        if (raise >= 2) return 15;
        return 10;
    }

    function checkName(string memory str) public pure returns (bool) {
        uint256 i = 0;
        bytes memory b = bytes(str);
        if (b.length > 10) return false;

        while (i < b.length) {
            if (
                !(b[i] >= 0x30 && b[i] <= 0x39) && //9-0
                !(b[i] >= 0x41 && b[i] <= 0x5A) && //A-Z
                !(b[i] >= 0x61 && b[i] <= 0x7A) //a-z
            ) return false;

            i++;
        }

        return true;
    }
}