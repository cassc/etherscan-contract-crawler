// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721R {
  enum Rarity {
    CUP,
    MASCOT,
    QATAR,
    SHOE,
    BALL
  }
  struct CommitInfo {
    bytes32 commit;
    uint256 blockNumberStart;
    uint256 blockNumberEnd;
  }
  event Commited(address indexed user, uint256 indexed revealStart, uint256 indexed revealEnd, bytes32 commit);
  event Unboxed(address indexed user, uint256 indexed tokenId, uint256 indexed rarity, uint256 attributeId);

  // function pause() external;

  // function unpause() external;

  function setRoot(bytes32 root_) external;

  function setSigner(address signer_) external;

  function setBaseURI(string memory _newBaseURI) external;

  function setBaseExtension(string memory _newBaseExtension) external;

  function commit(bytes32 commitment_) external;

  // function safeMint(address to_, uint256 tokenId_) external;

  function updateAttributePercentMask(uint256 rarity_, uint64[] memory percentageMask_) external;

  function mintRandom(uint256 userSeed_, bytes32 houseSeed_, bytes32[] calldata proofs_) external;

  function metadataOf(uint256 tokenId_) external view returns (uint256 rarity_, uint256 attributeId_);

  function mintRandom(uint256 userSeed_, bytes32 houseSeed_, uint256 deadline_, bytes calldata signature_) external;
}