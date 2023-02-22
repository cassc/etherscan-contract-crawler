// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {RBT} from "src/RBT.sol";
import {RewardVault} from "src/RewardVault.sol";
import {BitMapsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

contract RebornPortalStorage is IRebornDefination {
    /** you need buy a soup before reborn */
    uint256 public soupPrice = 0.01 * 1 ether;

    RBT public rebornToken;

    mapping(address => bool) public signers;

    mapping(address => uint32) public rounds;

    mapping(uint256 => LifeDetail) public details;

    mapping(uint256 => Pool) public pools;

    mapping(address => mapping(uint256 => Portfolio)) public portfolios;

    mapping(address => address) public referrals;

    RewardVault public vault;

    BitMapsUpgradeable.BitMap internal _seeds;

    uint256 public idx;

    BitMapsUpgradeable.BitMap baptism;

    /// @dev gap for potential vairable
    uint256[38] private _gap;
}