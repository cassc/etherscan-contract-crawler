// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./DataTypes.sol";
import "./Configuration.sol";
import "./LenderToken.sol";

contract KyokoStorage {
    // using Configuration for DataTypes.NFT;

    // Seconds per year
    uint256 public constant ONE_YEAR = 365 days;

    uint256 public constant FEE_PERCENTAGE_BASE = 10000;

    // admin fee, 1 represent 1%
    uint256 public fee;

    // lToken，when the user lend ERC20,they can get this token
    LenderToken public lToken;

    //The depositId of Staking NFT
    CountersUpgradeable.Counter internal depositId;

    //The user's offerId
    CountersUpgradeable.Counter internal offerId;

    /**
     * support ERC20 white list
     */
    mapping(address => bool) internal whiteList;
    //white set
    EnumerableSetUpgradeable.AddressSet internal whiteSet;

    mapping(uint256 => DataTypes.NFT) public nftMap; //depositId => NFT

    mapping(address => EnumerableSetUpgradeable.UintSet) internal nftHolderMap; //holder address => depositId Set

    mapping(uint256 => EnumerableSetUpgradeable.UintSet)
        internal depositIdOfferMap; //depositId => offerId Set
    mapping(uint256 => DataTypes.OFFER) public offerMap; //offerId => OFFER
    // mapping(address => EnumerableSetUpgradeable.UintSet) internal userOfferMap; //user address => offerId set

    mapping(uint256 => uint256) public lendMap; //lTokenId => depositId

    // open state data, for front-end query
    EnumerableSetUpgradeable.UintSet internal open;
    // lent state data, for front-end query
    EnumerableSetUpgradeable.UintSet internal lent;
}