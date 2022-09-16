// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface ICaster {

    struct EffectData {
        uint256 timestamp;
        uint256 duration;
    }

    struct SpellBookData {
        uint256 currentXp;
        uint256 createdAt;
        uint8 level;
    }

    function hasEffect(address caster, uint8 effectId) external view returns (bool);
    function setEffect(address caster, uint8 effectId, uint256 duration) external;
    function clearEffect(address caster, uint8 effectId) external;
    function getEffect(address caster, uint8 effectId) external view returns (uint256, uint256);
    function setXp(address caster, uint256 xp) external; 
    function setLevel(address caster, uint8 level) external;
    function getLevel(address caster) external view returns(uint8);
    function get(address caster) external view returns (SpellBookData memory);
    function set(SpellBookData memory data, address caster) external;   
    function create(address caster) external;   
}