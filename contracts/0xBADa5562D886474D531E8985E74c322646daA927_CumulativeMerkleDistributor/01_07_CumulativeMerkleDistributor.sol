// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract CumulativeMerkleDistributor is Ownable {
  using SafeERC20 for IERC20;

  address public immutable infinityToken;

  bytes32 public merkleRootINFT;
  bytes32 public merkleRootETH;
  mapping(address => uint256) public cumulativeINFTClaimed;
  mapping(address => uint256) public cumulativeETHClaimed;

  event INFTMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
  event ETHMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);
  event INFTClaimed(address user, uint256 amount);
  event ETHClaimed(address user, uint256 amount);

  constructor(address token_) {
    infinityToken = token_;
  }

  receive() external payable {}

  function setMerkleRootINFT(bytes32 merkleRoot_) external onlyOwner {
    merkleRootINFT = merkleRoot_;
    emit INFTMerkleRootUpdated(merkleRootINFT, merkleRoot_);
  }

  function setMerkleRootETH(bytes32 merkleRoot_) external onlyOwner {
    merkleRootETH = merkleRoot_;
    emit ETHMerkleRootUpdated(merkleRootETH, merkleRoot_);
  }

  function claimINFT(
    address account,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external {
    require(merkleRootINFT == expectedMerkleRoot, 'Merkle root was updated');

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), 'Invalid proof');

    // Mark it claimed
    uint256 preclaimed = cumulativeINFTClaimed[account];
    require(preclaimed < cumulativeAmount, 'Nothing to claim');
    cumulativeINFTClaimed[account] = cumulativeAmount;

    // Send the token
    unchecked {
      uint256 amount = cumulativeAmount - preclaimed;
      IERC20(infinityToken).safeTransfer(account, amount);
      emit INFTClaimed(account, amount);
    }
  }

  function claimETH(
    address account,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external {
    require(merkleRootETH == expectedMerkleRoot, 'Merkle root was updated');

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), 'Invalid proof');

    // Mark it claimed
    uint256 preclaimed = cumulativeETHClaimed[account];
    require(preclaimed < cumulativeAmount, 'Nothing to claim');
    cumulativeETHClaimed[account] = cumulativeAmount;

    // Send the token
    unchecked {
      uint256 amount = cumulativeAmount - preclaimed;
      (bool sent, ) = account.call{value: amount}('');
      require(sent, 'failed to send ether to claimer');
      emit ETHClaimed(account, amount);
    }
  }

  function _verifyAsm(
    bytes32[] calldata proof,
    bytes32 root,
    bytes32 leaf
  ) private pure returns (bool valid) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let mem1 := mload(0x40)
      let mem2 := add(mem1, 0x20)
      let ptr := proof.offset

      for {
        let end := add(ptr, mul(0x20, proof.length))
      } lt(ptr, end) {
        ptr := add(ptr, 0x20)
      } {
        let node := calldataload(ptr)

        switch lt(leaf, node)
        case 1 {
          mstore(mem1, leaf)
          mstore(mem2, node)
        }
        default {
          mstore(mem1, node)
          mstore(mem2, leaf)
        }

        leaf := keccak256(mem1, 0x40)
      }

      valid := eq(root, leaf)
    }
  }
}