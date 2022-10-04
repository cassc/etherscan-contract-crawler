import "solmate/auth/Owned.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface BoringSecurity {
  function safeTransferFrom(address, address, uint256, uint256, bytes memory) external;

  function balanceOf(address, uint256) external view returns (uint256);
}

error InvalidProof();
error InvalidToken();
error AlreadyClaimed();
error Not101Holder();

contract BoringClaimer is Owned {
  address private constant BORING_SECURITY_VAULT = 0x52C45Bab6d0827F44a973899666D9Cd18Fd90bCF;
  BoringSecurity private immutable boringSecurity;

  mapping(uint256 => bytes32) roots;
  mapping(address => mapping(uint256 => bool)) public claimed;

  constructor() Owned(msg.sender) {
    boringSecurity = BoringSecurity(0x0164fB48891b891e748244B8Ae931F2318b0c25B);
  }

  function claim(bytes32[] calldata _proof, uint256 tokenId) external {
    bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));
    if (tokenId != 101 && tokenId != 102) revert InvalidToken();
    if (claimed[msg.sender][tokenId]) revert AlreadyClaimed();
    if (tokenId == 102 && boringSecurity.balanceOf(msg.sender, 101) == 0) revert Not101Holder();

    if (!MerkleProof.verify(_proof, roots[tokenId], leaf)) {
        revert InvalidProof();
    }

    claimed[msg.sender][tokenId] = true;

    boringSecurity.safeTransferFrom(BORING_SECURITY_VAULT, msg.sender, tokenId, 1, "");
  }

  function setRoot(bytes32 _root, uint256 tokenId) external onlyOwner {
    if (tokenId != 101 && tokenId != 102) revert InvalidToken();

    roots[tokenId] = _root;
  }
}