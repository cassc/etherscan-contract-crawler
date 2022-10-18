// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {TokenVesting} from "./TokenVesting.sol";
import {MerkleDistributor} from "./MerkleDistributor.sol";

contract MerkleTokenVestingV2 is TokenVesting, MerkleDistributor {
  event Claimed(uint256 index, address account, uint256 amount, bool revocable);

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to beneficiaries gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param start start block to begin vesting
   * @param cliff cliff to start vesting on, set to zero if immediately after start
   * @param duration duration in blocks to vest over
   */
  function initialize(
    uint256 start,
    uint256 cliff,
    uint256 duration,
    address token,
    bytes32 _merkleRoot
  ) public initializer {
    __TokenVesting_init(start, cliff, duration, token);
    __MerkleDistributor_init(_merkleRoot);
  }

  function claimAward(
    uint256 index,
    address account,
    uint256 amount,
    bool revocable,
    bytes32[] calldata merkleProof
  ) external {
    require(!isClaimed(index), "Award already claimed");

    // Verify the merkle proof.
    bytes32 node =
      keccak256(abi.encodePacked(index, account, amount, revocable));
    _verifyClaim(merkleProof, node);

    _setClaimed(index);

    _awardTokens(account, amount, revocable);

    emit Claimed(index, account, amount, revocable);
  }

  // Function to award tokens to an account if it was missed in the merkle tree
  function awardTokens(
    address account,
    uint256 amount,
    bool revocable
  ) external onlyOwner {
    _awardTokens(account, amount, revocable);
  }

  function empty() external onlyOwner {
    targetToken.transfer(owner(), targetToken.balanceOf(address(this)));
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    require(_merkleRoot != merkleRoot, "Same root");
    merkleRoot = _merkleRoot;
  }
}