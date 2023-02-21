//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBiswapFarm {
  function BONUS_MULTIPLIER (  ) external view returns ( uint256 );
  function BSW (  ) external view returns ( address );
  function BSWPerBlock (  ) external view returns ( uint256 );
  function add ( uint256 _allocPoint, address _lpToken, bool _withUpdate ) external;
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function depositedBsw (  ) external view returns ( uint256 );
  function devPercent (  ) external view returns ( uint256 );
  function devaddr (  ) external view returns ( address );
  function emergencyWithdraw ( uint256 _pid ) external;
  function enterStaking ( uint256 _amount ) external;
  function getMultiplier ( uint256 _from, uint256 _to ) external view returns ( uint256 );
  function lastBlockDevWithdraw (  ) external view returns ( uint256 );
  function leaveStaking ( uint256 _amount ) external;
  function massUpdatePools (  ) external;
  function migrate ( uint256 _pid ) external;
  function migrator (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function pendingBSW ( uint256 _pid, address _user ) external view returns ( uint256 );
  function percentDec (  ) external view returns ( uint256 );
  function poolInfo ( uint256 ) external view returns ( address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accBSWPerShare );
  function poolLength (  ) external view returns ( uint256 );
  function refAddr (  ) external view returns ( address );
  function refPercent (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function safuPercent (  ) external view returns ( uint256 );
  function safuaddr (  ) external view returns ( address );
  function set ( uint256 _pid, uint256 _allocPoint, bool _withUpdate ) external;
  function setDevAddress ( address _devaddr ) external;
  function setMigrator ( address _migrator ) external;
  function setRefAddress ( address _refaddr ) external;
  function setSafuAddress ( address _safuaddr ) external;
  function stakingPercent (  ) external view returns ( uint256 );
  function startBlock (  ) external view returns ( uint256 );
  function totalAllocPoint (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function updateBswPerBlock ( uint256 newAmount ) external;
  function updateMultiplier ( uint256 multiplierNumber ) external;
  function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardDebt );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
  function withdrawDevAndRefFee (  ) external;
}