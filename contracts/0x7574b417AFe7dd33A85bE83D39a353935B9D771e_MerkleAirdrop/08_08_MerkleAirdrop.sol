// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MerkleAirdrop is Ownable {
  using SafeERC20 for IERC20;

  IERC20 private immutable token;
  bytes32 public immutable merkleRoot;

  //user address -> bool
  mapping(address => bool) public claimed;

  event Claimed(address user, uint256 balance);

  constructor(IERC20 _token, bytes32 _merkleRoot) {
    token = _token;
    merkleRoot = _merkleRoot;
  }

  function claim(address _to, uint256 _balance, bytes32[] memory _merkleProof) external {
    _claim(_to, _balance, _merkleProof);
    _pay(_to, _balance);
  }

  function verifyClaim(
    address _to,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) external view returns (bool) {
    return _verifyClaim(_to, _balance, _merkleProof);
  }

  function withdraw(address _to, uint256 _balance) external onlyOwner {
    uint256 tokenAmount = _balance;

    if (_balance == 0) {
      tokenAmount = token.balanceOf(address(this));
    }

    token.safeTransfer(_to, tokenAmount);
  }

  function _claim(address _to, uint256 _balance, bytes32[] memory _merkleProof) private {
    require(!claimed[_to], 'It has already claimed');
    require(_verifyClaim(_to, _balance, _merkleProof), 'Incorrect merkle proof');

    claimed[_to] = true;

    emit Claimed(_to, _balance);
  }

  function _verifyClaim(
    address _to,
    uint256 _balance,
    bytes32[] memory _merkleProof
  ) private view returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_to, _balance))));

    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function _pay(address _to, uint256 _balance) private {
    require(_balance > 0, 'No balance would be transferred');

    token.safeTransfer(_to, _balance);
  }
}