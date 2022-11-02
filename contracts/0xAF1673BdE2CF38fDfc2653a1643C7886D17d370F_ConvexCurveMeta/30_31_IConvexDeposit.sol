// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IConvexDeposit {
  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  function poolInfo(uint256)
    external
    view
    returns (
      address,
      address,
      address,
      address,
      address,
      bool
    );

  // deposit lp tokens and stake
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  // deposit all lp tokens and stake
  function depositAll(uint256 _pid, bool _stake) external returns (bool);

  function poolLength() external view returns (uint256);

  // withdraw lp tokens
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

  // withdraw all lp tokens
  function withdrawAll(uint256 _pid) external returns (bool);

  // claim crv + extra rewards
  function earmarkRewards(uint256 _pid) external returns (bool);

  // claim  rewards on stash (msg.sender == stash)
  function claimRewards(uint256 _pid, address _gauge) external returns (bool);

  // delegate address votes on dao (needs to be voteDelegate)
  function vote(
    uint256 _voteId,
    address _votingAddress,
    bool _support
  ) external returns (bool);

  function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight) external returns (bool);
}