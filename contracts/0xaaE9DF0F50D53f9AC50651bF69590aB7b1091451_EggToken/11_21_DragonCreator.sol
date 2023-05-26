// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "./structs/DragonInfo.sol";
import "./access/BaseAccessControl.sol";
import "./DragonToken.sol";

contract DragonCreator is BaseAccessControl {
    
    using Address for address;

    address private _tokenContractAddress;

    mapping(DragonInfo.Types => uint) private _zeroDragonsIssueLimits;
    mapping(address => bool) private _giveBirthCallers;

    bool private _isChangeOfIssueLimitsAllowed;

    event DragonCreated(
        uint dragonId, 
        uint eggId,
        uint parent1Id,
        uint parent2Id,
        uint generation,
        DragonInfo.Types t,
        uint genes,
        address indexed creator,
        address indexed to);

    constructor(address accessControl, address tknContract) BaseAccessControl(accessControl) {
        _tokenContractAddress = tknContract;
        _isChangeOfIssueLimitsAllowed = true;
    }

    function tokenContract() public view returns (address) {
        return _tokenContractAddress;
    }

    function setTokenContract(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _tokenContractAddress;
        _tokenContractAddress = newAddress;
        emit AddressChanged("tokenContract", previousAddress, newAddress);
    }

    function isChangeOfIssueLimitsAllowed() public view returns (bool) {
        return _isChangeOfIssueLimitsAllowed;
    }

    function currentIssueLimitFor(DragonInfo.Types _dragonType) external view returns (uint) {
        return _zeroDragonsIssueLimits[_dragonType];
    }

    function updateIssueLimitFor(DragonInfo.Types _dragonType, uint newValue) external onlyRole(CEO_ROLE) {
        require(isChangeOfIssueLimitsAllowed(), 
            "DragonCreator: updating the issue limits is not allowed anymore");
        _zeroDragonsIssueLimits[_dragonType] = newValue;
    }

    function blockUpdatingIssueLimitsForever() external onlyRole(CEO_ROLE) {
        _isChangeOfIssueLimitsAllowed = false;
    }
    
    function setGiveBirthCallers(address[] calldata callers, bool value) external onlyRole(CEO_ROLE) {
        for (uint i = 0; i < callers.length; i++) {
            bool previousValue = _giveBirthCallers[callers[i]];
            _giveBirthCallers[callers[i]] = value;
            emit BoolValueChanged(string(abi.encodePacked("giveBirthCallers.", callers[i])), previousValue, value);
        }
    }

    function issue(uint genes, address to) external onlyRole(CEO_ROLE) returns (uint) {
        DragonInfo.Types dragonType = DragonInfo.calcType(genes);
        uint currentLimit = _zeroDragonsIssueLimits[dragonType];
        require(dragonType != DragonInfo.Types.Unknown, "DragonCreator: unable to identify a type of the given dragon");
        require(currentLimit > 0, "DragonCreator: the issue limit has exceeded");
        _zeroDragonsIssueLimits[dragonType] = currentLimit - 1;

        return _createDragon(0, 0, 0, genes, dragonType, to);
    }

    function giveBirth(uint eggId, uint genes, address to) external returns (uint) {
        require(_giveBirthCallers[_msgSender()], "DragonCreator: not enough privileges to call the method");    
        return _createDragon(eggId, 0, 0, genes, DragonInfo.Types.Unknown, to);
    }

    function giveBirth(uint parent1Id, uint parent2Id, uint genes, address to) external returns (uint) {
        require(_giveBirthCallers[_msgSender()], "DragonCreator: not enough privileges to call the method");
        return _createDragon(0, parent1Id, parent2Id, genes, DragonInfo.Types.Unknown, to);
    }

    function _createDragon(uint _eggId, uint _parent1Id, uint _parent2Id, uint _genes, DragonInfo.Types _dragonType, address to)
    internal returns (uint) {
        DragonToken dragonToken = DragonToken(tokenContract());
        DragonInfo.Details memory parent1Details = dragonToken.dragonInfo(_parent1Id);
        DragonInfo.Details memory parent2Details = dragonToken.dragonInfo(_parent2Id);

        if (_parent1Id > 0 && _parent2Id > 0) { //if not 1st-generation dragons
            require(_parent1Id != _parent2Id, "DragonCreator: parent dragons must be different");
            require(
                parent1Details.dragonType != DragonInfo.Types.Legendary 
                && parent2Details.dragonType != DragonInfo.Types.Legendary, 
                "DragonCreator: neither of the parent dragons can be of Legendary-type"
            );
            require(!dragonToken.isSiblings(_parent1Id, _parent2Id), "DragonCreator: the parent dragons must not be siblings");
            require(
                !dragonToken.isParent(_parent1Id, _parent2Id) && !dragonToken.isParent(_parent2Id, _parent1Id), 
                "DragonCreator: neither of the parent dragons must be a parent or child of another"
            );
        }

        DragonInfo.Details memory info = DragonInfo.Details({ 
            eggId: _eggId,
            parent1Id: _parent1Id,
            parent2Id: _parent2Id,
            generation: DragonInfo.calcGeneration(parent1Details.generation, parent2Details.generation),
            dragonType: (_dragonType == DragonInfo.Types.Unknown) ? DragonInfo.calcType(_genes) : _dragonType,
            strength: 0, //DragonInfo.calcStrength(_genes),
            genes: _genes
        });

        uint newDragonId = dragonToken.mint(to, info);
        
        emit DragonCreated(
            newDragonId, info.eggId,
            info.parent1Id, info.parent2Id, 
            info.generation, info.dragonType, 
            info.genes, _msgSender(), to);

        return newDragonId; 
    }
}