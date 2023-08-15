// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MangaDAO token
 */
contract MAD is ERC20Votes, Pausable, Ownable {
  using SafeERC20 for IERC20;

  // Total supply is $MAD 100 million
  uint256 public constant MAX_SUPPLY = 100_000_000 ether;

  // Merkle root node. Can be set by the owner (unless contract is frozen)
  bytes32 public merkleRoot;

  // Merkle root will not be updateable once contract is frozen
  bool public frozen = false;

  // Updates list when a wallet claims tokens
  mapping(address => bool) public claimedTokens;

  event Claimed(address indexed account, uint256 amount);

  constructor(bytes32 _merkleRoot)
    ERC20("MangaDAO", "MAD")
    ERC20Permit("MangaDAO")
  {
    _mint(address(this), MAX_SUPPLY);
    merkleRoot = _merkleRoot;
  }

  /**
   * @notice Retroactive claiming of $MAD
   * @param totalAmount Amount of $MAD to be claimed. This action can be performed
   * once per wallet
   * @param merkleProof Proof of inclusion in the merkle tree. This is a concatenation of
   * [address, amount].
   */
  function claim(uint256 totalAmount, bytes32[] calldata merkleProof) external {
    require(
      totalAmount > 0 && totalAmount < type(uint120).max,
      "MAD: totalAmount must be greater than 0 and less than max uint120 value"
    );

    bytes32 node = keccak256(abi.encodePacked(_msgSender(), totalAmount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, node),
      "MAD: could not verify merkleProof"
    );

    require(
      claimedTokens[_msgSender()] == false,
      "MAD: Already claimed tokens"
    );

    claimedTokens[_msgSender()] = true;

    IERC20(address(this)).safeTransfer(_msgSender(), totalAmount);

    emit Claimed(_msgSender(), totalAmount);
  }

  /**
   * @notice Updates merkle tree unless contract is frozen
   * @param _merkleRoot Root node of the new tree
   */
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    require(!frozen, "MAD: Contract is frozen.");
    merkleRoot = _merkleRoot;
  }

  function freeze() external onlyOwner {
    frozen = true;
  }

  /**
   * @notice Rescue any ether sent to contract
   */
  function withdrawAll() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(owner(), balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "MAD: Transfer failed.");
  }
}