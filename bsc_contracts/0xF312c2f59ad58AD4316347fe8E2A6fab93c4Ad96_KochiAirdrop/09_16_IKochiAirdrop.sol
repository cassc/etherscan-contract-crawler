// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKochiAirdrop {
  enum ESchedule {
    instant,
    vested,
    locked
  }

  struct SAirdropMetadata {
    uint256 uid;
    address creator;
    uint256 created_at;
    address token;
    address[] recipients;
    uint256[] amounts;
    ESchedule schedule;
    uint256 startline;
    uint256 deadline;
    uint256 schedule_duration;
    bool owner_claimed;
  }

  function airdrop(
    address _token,
    address[] memory _recipients,
    uint256[] memory _amounts,
    ESchedule _schedule,
    uint256 _startline,
    uint256 _deadline,
    uint256 _schedule_duration
  ) external;

  function airdropETH(
    address[] memory _recipients,
    uint256[] memory _amounts,
    ESchedule _schedule,
    uint256 _startline,
    uint256 _deadline,
    uint256 _schedule_duration
  ) external payable;

  function claim(uint256 uid) external;

  function ownerClaimStale(uint256 uid) external;

  function getMyAirdrops() external view returns (uint256[] memory uids);

  function getClaimable(address beneficiary, uint256 uid) external view returns (uint256 amount);

  function getAirdropMetadata(uint256 uid) external view returns (SAirdropMetadata memory metadata);

  event Airdropped(SAirdropMetadata metadata);

  event Claimed(
    uint256 indexed uid,
    address indexed token,
    address indexed recipient,
    uint256 amount,
    ESchedule schedule,
    uint256 startline,
    uint256 deadline,
    uint256 schedule_duration,
    address schedule_contract
  );

  event OwnerClaimed(uint256 indexed uid, address indexed token, address owner, uint256 amount);
}