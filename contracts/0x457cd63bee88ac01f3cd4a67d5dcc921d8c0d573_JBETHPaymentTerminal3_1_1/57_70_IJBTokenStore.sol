// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IJBFundingCycleStore} from './IJBFundingCycleStore.sol';
import {IJBProjects} from './IJBProjects.sol';
import {IJBToken} from './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address holder, uint256 projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 projectId) external view returns (uint256);

  function totalSupplyOf(uint256 projectId) external view returns (uint256);

  function balanceOf(address holder, uint256 projectId) external view returns (uint256 result);

  function issueFor(
    uint256 projectId,
    string calldata name,
    string calldata symbol
  ) external returns (IJBToken token);

  function setFor(uint256 projectId, IJBToken token) external;

  function burnFrom(
    address holder,
    uint256 projectId,
    uint256 amount,
    bool preferClaimedTokens
  ) external;

  function mintFor(
    address holder,
    uint256 projectId,
    uint256 amount,
    bool preferClaimedTokens
  ) external;

  function claimFor(address holder, uint256 projectId, uint256 amount) external;

  function transferFrom(
    address holder,
    uint256 projectId,
    address recipient,
    uint256 amount
  ) external;
}