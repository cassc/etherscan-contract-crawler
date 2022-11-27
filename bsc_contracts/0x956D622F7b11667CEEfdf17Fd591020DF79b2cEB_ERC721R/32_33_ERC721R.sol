// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IERC721R.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";

/// @custom:security-contact [email protected]
contract ERC721R is IERC721R, UUPSUpgradeable, EIP712Upgradeable, ERC721PresetMinterPauserAutoIdUpgradeable {
  using StringsUpgradeable for *;
  using ECDSAUpgradeable for *;
  using MerkleProofUpgradeable for *;

  /// @dev value is equal to keccak256("ERC721R_v1")
  bytes32 public constant VERSION = 0x5e0552f6dd362c5662d2fa5933e126337ae8694639a8f14cda60fa3df2995615;

  /// @dev value is equal to keccak256("UPGRADER_ROLE")
  bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
  /// @dev value is equal to keccak256("OPERATOR_ROLE")
  bytes32 public constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

  uint256 private constant __RANDOM_BIT = 0xffffffffffffffff;
  uint256 private constant __CUP_MASK = 0xccccccccccccccc; // 5%
  uint256 private constant __MASCOT_MASK = 0x1999999999999999; // 5%
  uint256 private constant __QATAR_MASK = 0x4ccccccccccccccc; // 20%
  uint256 private constant __SHOE_MASK = 0x7fffffffffffffff; // 20%

  /// @dev value is equal to keccak256("Permit(address user,uint256 userSeed,bytes32 houseSeed,uint256 deadline,uint256 nonce)")
  bytes32 private constant __PERMIT_TYPE_HASH = 0xc02a18540b1f8010e03e4c5817e47f97371234f484e9bfa5b8d7423d54fad488;

  bytes32 public root;
  address public signer;
  uint256 public globalNonces;
  uint256 public tokenIdTracker;
  string public baseExtension;

  mapping(address => uint256) public signingNonces;
  mapping(address => CommitInfo) public commitments;
  mapping(uint8 => uint64[]) public attributePercentageMask;

  string public baseTokenURI;
  uint256 public cost;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() payable {
    _disableInitializers();
  }

  function init(
    string calldata name_,
    string calldata symbol_,
    string calldata baseTokenURI_, //
    string calldata baseExtension_ // json
  ) external initializer {
    __UUPSUpgradeable_init_unchained();
    __EIP712_init_unchained(type(ERC721R).name, "1");
    baseExtension = baseExtension_;
    address sender = _msgSender();
    __ERC721PresetMinterPauserAutoId_init(name_, symbol_, baseTokenURI_);

    _grantRole(UPGRADER_ROLE, sender);
    _grantRole(OPERATOR_ROLE, sender);
    _grantRole(DEFAULT_ADMIN_ROLE, sender);
  }

  function setSigner(address signer_) external onlyRole(OPERATOR_ROLE) {
    signer = signer_;
  }

  function commit(bytes32 commitment_) external {
    address user = _msgSender();
    CommitInfo memory commitInfo;
    unchecked {
      commitInfo = CommitInfo({
        commit: commitment_,
        blockNumberStart: block.number + 1,
        blockNumberEnd: block.number + 40
      });
    }
    emit Commited(user, commitInfo.blockNumberStart, commitInfo.blockNumberEnd, commitment_);

    commitments[user] = commitInfo;
  }

  function mintRandom(uint256 userSeed_, bytes32 houseSeed_, uint256 deadline_, bytes calldata signature_) external {
    address user = _msgSender();
    require(block.timestamp < deadline_, "NFT: EXPIRED");

    CommitInfo memory commitInfo = commitments[user];
    require(
      _hashTypedDataV4(
        keccak256(abi.encode(__PERMIT_TYPE_HASH, user, userSeed_, houseSeed_, deadline_, ++signingNonces[user]))
      ).recover(signature_) == signer,
      "NFT: INVALID_SIGNATURE"
    );

    __mintRandom(commitInfo, user, userSeed_, houseSeed_);
  }

  function mintRandom(uint256 userSeed_, bytes32 houseSeed_, bytes32[] calldata proofs_) external {
    require(proofs_.verify(root, houseSeed_), "NFT: INVALID_HOUSE_SEED");

    address user = _msgSender();
    CommitInfo memory commitInfo = commitments[user];
    __mintRandom(commitInfo, user, userSeed_, houseSeed_);
  }

  function metadataOf(uint256 tokenId_) public view returns (uint256 rarity_, uint256 attributeId_) {
    require(ownerOf(tokenId_) != address(0), "NFT: NOT_EXISTED");
    unchecked {
      rarity_ = tokenId_ & ((1 << 3) - 1);
      attributeId_ = (tokenId_ >> 3) & ((1 << 3) - 1);
    }
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = baseTokenURI;
    (uint256 rarity, uint256 attributeId) = metadataOf(tokenId);
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, "/", rarity.toString(), "/", attributeId.toString(), baseExtension))
        : "";
  }

  function attributePercentMask(uint8 rarity_) external view returns (uint64[] memory) {
    return attributePercentageMask[rarity_];
  }

  function updateAttributePercentMask(
    uint256 rarity_,
    uint64[] memory percentageMask_
  ) external onlyRole(OPERATOR_ROLE) {
    attributePercentageMask[uint8(rarity_)] = percentageMask_;
  }

  function setRoot(bytes32 root_) external onlyRole(OPERATOR_ROLE) {
    root = root_;
  }

  function setCost(uint256 _newCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) external onlyRole(OPERATOR_ROLE) {
    baseTokenURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyRole(OPERATOR_ROLE) {
    baseExtension = _newBaseExtension;
  }

  // function safeMint(address to_, uint256 tokenId_) external onlyRole(MINTER_ROLE) {
  //   _safeMint(to_, tokenId_);
  // }

  function __mintRandom(CommitInfo memory commitInfo, address user, uint256 userSeed_, bytes32 houseSeed_) private {
    uint256 revealBlock;
    unchecked {
      revealBlock = commitInfo.blockNumberStart + ((commitInfo.blockNumberEnd - commitInfo.blockNumberStart) >> 2);
      // revealBlock = commitInfo.blockNumberStart + 3;
    }
    assert(blockhash(revealBlock) != 0);

    require(block.number > revealBlock, "NFT: REVEAL_NOT_YET_STARTED");
    require(block.number < commitInfo.blockNumberEnd, "NFT: REVEAL_EXPIRED");

    require(keccak256(abi.encode(houseSeed_, userSeed_, user)) == commitInfo.commit, "NFT: INVALID_REVEAL");
    delete commitments[user];

    uint256 seed;
    unchecked {
      seed = uint256(
        keccak256(
          abi.encode(
            user,
            ++globalNonces,
            userSeed_,
            houseSeed_,
            address(this),
            blockhash(revealBlock),
            blockhash(block.number - 1),
            blockhash(block.number - 2)
          )
        )
      );
    }

    seed >>= 96;
    seed &= __RANDOM_BIT;

    uint256 rarity;
    if (seed < __CUP_MASK) rarity = uint256(Rarity.CUP);
    if (seed < __MASCOT_MASK) rarity = uint256(Rarity.MASCOT);
    if (seed < __QATAR_MASK) rarity = uint256(Rarity.QATAR);
    if (seed < __SHOE_MASK) rarity = uint256(Rarity.SHOE);
    else rarity = uint256(Rarity.BALL);

    seed = uint256(keccak256(abi.encode(seed ^ block.timestamp, user)));
    seed >>= 96;
    seed &= __RANDOM_BIT;

    uint256 attributeId;
    uint64[] memory percentageMask = attributePercentageMask[uint8(rarity)];
    uint256 length = percentageMask.length;
    for (uint256 i; i < length; ) {
      if (seed < percentageMask[i]) {
        attributeId = i;
        break;
      }
      unchecked {
        ++i;
      }
    }
    uint256 tokenId;
    unchecked {
      tokenId = (++tokenIdTracker << 6) | (attributeId << 3) | rarity;
    }

    _mint(user, tokenId);

    emit Unboxed(user, tokenId, rarity, attributeId);
  }

  function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
    (bool ok, ) = signer.call{ value: address(this).balance }("");
    require(ok, "NFT: TRANSFER_FAILED");
  }

  function _authorizeUpgrade(address newImplementation_) internal override onlyRole(UPGRADER_ROLE) {}

  // The following functions are overrides required by Solidity.
  uint256[40] private __gap;
}