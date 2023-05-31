// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IQuestDistributor {
  function questRewardToken(uint256 questID) external view returns (address);

  //Struct ClaimParams
  struct ClaimParams {
    uint256 questID;
    uint256 period;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function claim(
    uint256 questID,
    uint256 period,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;
}

interface IDelegationDistributor {
  //Struct ClaimParams
  struct ClaimParams {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
    external;
}

interface IVotiumDistributor {
  struct claimParam {
    address token;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof)
    external;
}

interface IHiddenHandDistributor {
  struct Reward {
    address token;
    bytes32 merkleRoot;
    bytes32 proof;
    uint256 updateCount;
  }

  function rewards(bytes32 indentifier) external view returns (Reward memory);

  struct Claim {
    bytes32 identifier;
    address account;
    uint256 amount;
    bytes32[] merkleProof;
  }

  function claim(Claim[] calldata _claims) external;
}