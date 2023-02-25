// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
pragma abicoder v1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract CumulativeMerkleDistributor is Ownable {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _tokens;

  mapping(address => bytes32) public erc20MerkleRoots;
  bytes32 public ethMerkleRoot;

  // user address => token address => cumulative amount claimed
  mapping(address => mapping(address => uint256)) public cumulativeErc20Claimed;
  // user address => cumulative amount claimed
  mapping(address => uint256) public cumulativeEthClaimed;

  ///@notice user events
  event Erc20MerkleRootUpdated(address token, bytes32 oldRoot, bytes32 newRoot);
  event EthMerkleRootUpdated(bytes32 oldRoot, bytes32 newRoot);

  event Erc20Claimed(address token, address user, uint256 amount);
  event EthClaimed(address user, uint256 amount);

  ///@notice admin events
  event EthWithdrawn(address destination, uint256 amount);
  event Erc20Withdrawn(address destination, address currency, uint256 amount);
  event Erc20Added(address token);
  event Erc20Removed(address token);

  constructor() {}

  receive() external payable {}

  // ================================================== USER FUNCTIONS ==================================================

  function claimErc20(
    address token,
    address account,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external {
    require(erc20MerkleRoots[token] == expectedMerkleRoot, 'Invalid proof');

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), 'Invalid proof');

    // Mark it claimed
    uint256 preclaimed = cumulativeErc20Claimed[token][account];
    require(preclaimed < cumulativeAmount, 'Nothing to claim');
    cumulativeErc20Claimed[token][account] = cumulativeAmount;

    // Send the token
    unchecked {
      uint256 amount = cumulativeAmount - preclaimed;
      IERC20(token).safeTransfer(account, amount);
      emit Erc20Claimed(token, account, amount);
    }
  }

  function claimEth(
    address account,
    uint256 cumulativeAmount,
    bytes32 expectedMerkleRoot,
    bytes32[] calldata merkleProof
  ) external {
    require(ethMerkleRoot == expectedMerkleRoot, 'Invalid proof');

    // Verify the merkle proof
    bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
    require(_verifyAsm(merkleProof, expectedMerkleRoot, leaf), 'Invalid proof');

    // Mark it claimed
    uint256 preclaimed = cumulativeEthClaimed[account];
    require(preclaimed < cumulativeAmount, 'Nothing to claim');
    cumulativeEthClaimed[account] = cumulativeAmount;

    // Send ETH
    unchecked {
      uint256 amount = cumulativeAmount - preclaimed;
      (bool sent, ) = account.call{value: amount}('');
      require(sent, 'failed to send ether to claimer');
      emit EthClaimed(account, amount);
    }
  }

  // ==================================================== HELPERS =====================================================

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

  // ======================================================= VIEW FUNCTIONS ============================================================

  function numTokens() external view returns (uint256) {
    return _tokens.length();
  }

  function getTokenAt(uint256 index) external view returns (address) {
    return _tokens.at(index);
  }

  function isValidToken(address token) external view returns (bool) {
    return _tokens.contains(token);
  }

  // =========================================== ADMIN FUNCTIONS ===========================================

  /// @dev Used for withdrawing any ETH wrongly sent to the contract
  function withdrawEth(address destination) external onlyOwner {
    uint256 amount = address(this).balance;
    (bool sent, ) = destination.call{value: amount}('');
    require(sent, 'failed');
    emit EthWithdrawn(destination, amount);
  }

  /// @dev Used for withdrawing any ERC20 tokens wrongly sent to the contract
  function withdrawErc20(
    address destination,
    address currency,
    uint256 amount
  ) external onlyOwner {
    IERC20(currency).transfer(destination, amount);
    emit Erc20Withdrawn(destination, currency, amount);
  }

  function addToken(address token) external onlyOwner {
    _tokens.add(token);
    emit Erc20Added(token);
  }

  function removeCurrency(address token) external onlyOwner {
    _tokens.remove(token);
    emit Erc20Removed(token);
  }

  function setErc20MerkleRoot(address token, bytes32 merkleRoot) external onlyOwner {
    bytes32 oldMerkleRoot = erc20MerkleRoots[token];
    erc20MerkleRoots[token] = merkleRoot;
    emit Erc20MerkleRootUpdated(token, oldMerkleRoot, merkleRoot);
  }

  function setEthMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    bytes32 oldEthMerkleRoot = ethMerkleRoot;
    ethMerkleRoot = merkleRoot;
    emit EthMerkleRootUpdated(oldEthMerkleRoot, merkleRoot);
  }
}