// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../dependant/ownable/OwnableLayout.sol";
import "../bscSPSNameServiceRef/BscSPSNameServiceRefLayout.sol";
import "../../dependant/deputyRef/DeputyRefLayout.sol";

import "./BscSPSManagerType.sol";

contract BscSPSManagerLayout is
OwnableLayout,
BscSPSNameServiceRefLayout,
DeputyRefLayout {

    //spsAddress => claimed
    /*mapping(address => bool) internal _starterMysteryBoxRecord;

    uint256 internal _starterEcgAmount;*/

    uint256 internal _mysteryBoxIdoBeginTime;
    uint256 internal _mysteryBoxIdoEndTime;
    uint256 internal _mysteryBoxIdoUsdPrice;

    uint256[12] internal _deprecated3;

    //=====================================================================================

    EnumerableSet.AddressSet internal _squadIdWhiteSet;

    mapping(uint256 => BscSPSManagerType.SquadIdoConfig)  internal _squadIdoConfig;
    //stage => who => usd invested
    mapping(uint256 => mapping(address => uint256)) internal _squadIdoUsdInvested;

    //stage => period => config
    //period starts from 1
    mapping(uint256 => mapping(uint256 => BscSPSManagerType.SquadIdoPeriodConfig))  internal _squadIdoPeriodConfig;

    //stage => who => claimed period
    //0 for not claimed any
    mapping(uint256 => mapping(address => uint256)) internal _squadIdoClaimedPeriod;

    //=====================================================================================
    uint256 internal _depositUsdBeginTime;

    uint256 internal _relayMysteryBoxIdoBeginTime;

    //=====================================================================================
    //who => reason => amount
    mapping(address => mapping(bytes32 => uint256)) internal _mysteryBoxXClaimed;

    //=====================================================================================

    EnumerableSet.AddressSet internal _haveStakedVSquadAccounts;

    uint256 internal _totalLockedSquadByVSquad;

    mapping(address => BscSPSManagerType.VSquadRecord) internal _haveStakedVSquadRecords;

    //season -> who -> got
    mapping(uint256 => mapping(address => bool)) internal _daoRewardRecord;
    mapping(uint256 => mapping(address => bool)) internal _rankRewardRecord;

}