// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AccessControlEnumerable} from '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/utils/Context.sol';

contract IsekaiBattleBag is Context, AccessControlEnumerable {
    bytes32 public constant BAG_ADDON_SETTER_ROLE = keccak256('BAG_ADDON_SETTER_ROLE');

    //events
    event ArmBagAddonChange(address indexed user, uint256 oldAmount, uint256 newAmount);
    event WpnBagAddonChange(address indexed user, uint256 oldAmount, uint256 newAmount);
    event DefaultBagChange(uint256 oldAmount, uint256 newAmount);

    mapping(address => uint256) public armBagAddon;
    mapping(address => uint256) public wpnBagAddon;

    uint256 defaultBag = 120;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BAG_ADDON_SETTER_ROLE, _msgSender());
    }

    function getWpnBagCount(address user) public view virtual returns (uint256) {
        return defaultBag + wpnBagAddon[user];
    }

    function getArmBagCount(address user) public view virtual returns (uint256) {
        return defaultBag + armBagAddon[user];
    }

    function setDefaultBag(uint256 value) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 old = defaultBag;
        defaultBag = value;
        emit DefaultBagChange(old, value);
    }

    function setArmBagAddon(address account, uint256 amount) public virtual onlyRole(BAG_ADDON_SETTER_ROLE) {
        uint256 old = armBagAddon[account];
        armBagAddon[account] += amount;
        emit ArmBagAddonChange(account, old, amount);
    }

    function setWpnBagAddon(address account, uint256 amount) public virtual onlyRole(BAG_ADDON_SETTER_ROLE) {
        uint256 old = armBagAddon[account];
        wpnBagAddon[account] += amount;
        emit WpnBagAddonChange(account, old, amount);
    }
}