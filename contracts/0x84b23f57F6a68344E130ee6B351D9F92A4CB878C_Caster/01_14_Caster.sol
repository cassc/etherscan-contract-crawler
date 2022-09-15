// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Interfaces/ICaster.sol";

contract Caster is AccessControl, ICaster {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SPELLBOOK_ROLE = keccak256("SPELLBOOK_ROLE");

    address[] public casterList;

    mapping(address => SpellBookData) public casters;
    mapping(address => mapping(uint8 => EffectData)) public effects;

    constructor() {
        address _owner = _msgSender();
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function setSpellBook(address addr) public onlyRole(ADMIN_ROLE) {
        _grantRole(SPELLBOOK_ROLE, addr);
    }

    function promoteAdmin(address newAdmin) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, newAdmin);
    }

    function hasEffect(address caster, uint8 effectId) public view override returns (bool) {
        (uint256 timestamp, uint256 duration) = getEffect(caster, effectId);
        return (timestamp + duration) > block.timestamp;
    }

    function setEffect(address caster, uint8 effectId, uint256 duration) public override onlyRole(SPELLBOOK_ROLE) {
        effects[caster][effectId].timestamp = block.timestamp;
        effects[caster][effectId].duration = duration;
    }

    function clearEffect(address caster, uint8 effectId) public override onlyRole(SPELLBOOK_ROLE) { 
        delete effects[caster][effectId];
    }

    function getEffect(address caster, uint8 effectId) public view override returns (uint256, uint256) {
        EffectData memory _data = effects[caster][effectId];
        return (_data.timestamp, _data.duration);
    }

    function setXp(address caster, uint256 xp) public override onlyRole(SPELLBOOK_ROLE) {
        casters[caster].currentXp = xp;
    }

    function getLevel(address caster) public view override returns (uint8) {
        return casters[caster].level;
    }

    function setLevel(address caster, uint8 level) public override onlyRole(SPELLBOOK_ROLE) {
        casters[caster].level = level;
    }

    function get(address caster) public view override returns (SpellBookData memory) {
        SpellBookData memory _data = casters[caster];
        return _data;
    }

    function set(SpellBookData memory data, address caster) public override onlyRole(SPELLBOOK_ROLE) {
        casters[caster].currentXp = data.currentXp;
        casters[caster].level = data.level;
        casters[caster].createdAt = data.createdAt;
    }

    function create(address caster) public override onlyRole(SPELLBOOK_ROLE) {
        casters[caster].currentXp = 0;
        casters[caster].level = 0;
        casters[caster].createdAt = block.timestamp;
        
        casterList.push(caster);
    }

}