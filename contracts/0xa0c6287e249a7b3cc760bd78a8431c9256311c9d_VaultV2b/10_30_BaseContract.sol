pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import { ITrustVaultLib as VaultLib } from "./../libraries/ItrustVaultLib.sol"; 

abstract contract BaseContract is Initializable, ContextUpgradeable
{
    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;

    uint8 internal _locked;
    address internal _iTrustFactoryAddress;

    mapping (address => uint32) internal _CurrentRoundNumbers;
    mapping (address => uint) internal _TotalUnstakedWnxm;
    mapping (address => uint[]) internal _TotalSupplyKeys;
    mapping (address => uint[]) internal _TotalUnstakingKeys;
    mapping (address => uint[]) internal _TotalSupplyForDayKeys;
   
    mapping (address => address[]) public totalRewardTokenAddresses;
    mapping (address => address[]) internal _UnstakingAddresses;
    mapping (address => address[]) internal _AccountStakesAddresses;

    mapping (address => VaultLib.UnStaking[]) internal _UnstakingRequests;
    mapping (address => mapping (address => uint32)) internal _RewardStartingRounds;
    mapping (address => mapping (address => VaultLib.AccountStaking)) internal _AccountStakes;
    mapping (address => mapping (address => VaultLib.UnStaking[])) internal _AccountUnstakings;

    mapping (address => mapping (address => uint8)) internal _RewardTokens;
    mapping (address => mapping (address => uint)) internal _AccountUnstakingTotals;
    mapping (address => mapping (address => uint)) internal _AccountUnstakedTotals;
    mapping (address => mapping (uint => uint)) internal _TotalSupplyHistory;
    mapping (address => mapping (address => mapping (address => VaultLib.ClaimedReward))) internal _AccountRewards;
    mapping (address => mapping (uint => VaultLib.RewardTokenRound)) internal _Rounds;

    mapping (address => mapping (uint => uint)) internal _TotalSupplyForDayHistory;
    


    mapping (address => mapping (uint => VaultLib.UnStaking)) internal _TotalUnstakingHistory;
    
    function _nonReentrant() internal view {
        require(_locked == FALSE);  
    }

}