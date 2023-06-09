// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { Ownable } from "solady/src/auth/Ownable.sol";
import { MerkleProofLib } from "solady/src/utils/MerkleProofLib.sol";

enum Proof {
  CLAIM,
  MINT
}

enum Tier {
  PUBLIC,
  ACCESS_LIST,
  OG
}

enum Phase {
  PRIVATE_SALE,
  PUBLIC_SALE,
  CLOSED
}

/**
 * @title TheAssetsClub NFT Collection
 * @author Mathieu "Windyy" Bour
 * @notice The Assets Club NFT collection implementation based Azuki's ERC721A contract.
 * Less gas, more assets, thanks Azuki <3!
 * We also are optimizing the gas spent using the Vectorized/solady library.
 *
 * In order to enforce the creator fees on secondary sales, we chose to adhere to the Operator Filter Registry
 * standard that was initially developed by OpenSea.
 * For more information, see https://github.com/ProjectOpenSea/operator-filter-registry
 *
 * Four two phase are planned for the mint process (see {Tier} above)
 * Our Merkle Tree type is [address, Proof, uint8].
 * - If proof is Proof.CLAIM, the last param corresponds to the claimable quantity.
 * - If proof is Proof.MINT, the last param corresponds to the tier (ACCESS_LIST=1,OG=2).
 *
 * Governance:
 * - TheAssetsClub uses Ownable to manage the contract.
 * - Owner is a safe.global multi-signature contract.
 * - The owner can change the token URIs, especially because we plan to fully move to IPFS in the future.
 *
 * milady
 */
contract TheAssetsClub is ERC721A, ERC2981, Ownable, VRFConsumerBaseV2, DefaultOperatorFilterer {
  /// The maximum Assets mints, which effectively caps the total supply.
  uint256 constant MAXIMUM_MINTS = 5777;

  /// Royalties 7.7% on secondary sales.
  uint96 constant ROYALTIES = 770;

  /// The maximum token mints per account.
  uint256 constant MAXIMUM_MINTS_PER_ACCOUNT = 7;
  /// The price per token for paid mints.
  uint256 constant SALE_PRICE = 0.02 ether;

  /// The private sale duration in seconds.
  uint256 constant PRIVATE_SALE_DURATION = 24 * 3600; // 1 day in seconds
  /// The public sale duration in seconds.
  uint256 constant PUBLIC_SALE_DURATION = 2 * 24 * 3600; // 2 days in seconds

  /// Thu Apr 27 2023 09:00:00 GMT
  uint256 constant START_DATE = 1682586000;
  /// Thu Apr 28 2023 09:00:00 GMT
  uint256 constant PRIVATE_SALE_END_DATE = START_DATE + PRIVATE_SALE_DURATION;
  /// Thu Apr 30 2023 09:00:00 GMT
  uint256 constant PUBLIC_SALE_END_DATE = PRIVATE_SALE_END_DATE + PUBLIC_SALE_DURATION;

  // Token URIs; they might be migrated to IPFS
  string private _contractURI = "https://static.theassets.club/contract.json";
  string private baseURI = "https://static.theassets.club/tokens/";

  // ----- NFT Paris Collection -----
  /// TheAssetsClub at NFT ERC721 contract.
  IERC721A immutable paris;
  /// The addresses which used a certain TheAssetsClub at NFT Paris token.
  mapping(uint256 => address) public parisUsed;
  /// Thrown when the minter does not hold a TheAssetsClub at NFT Paris token.
  error NotParisHolder(uint256 tokenId);
  /// Thrown when the minter tries to use TheAssetsClub at NFT Paris token for the second time.
  error ParisAlreadyUsed(uint256 tokenId);

  // ----- Mint -----
  /// The number of reserved, claimable tokens.
  uint256 public reserved;
  /// The  Merkle Tree root that controls the OG, access list and the reservations (claims).
  bytes32 public merkelRoot;

  /// The number of minted tokens per address.
  mapping(address => uint256) public minted;
  /// If an address has claimed its reserved tokens.
  mapping(address => bool) public claimed;

  // ----- Reveal -----
  /// If the collectioon has been reveal.
  /// This state has to seperated from seed since VRF request and fullfilment are written in seperate transactions.
  bool revealed = false;

  /// The collection reveal seed.
  uint256 public seed;

  // Chainlink VRF parameters
  VRFCoordinatorV2Interface public coordinator;
  bytes32 keyHash;
  uint64 subId;
  uint16 constant minimumRequestConfirmations = 10;
  uint32 constant callbackGasLimit = 2500000;
  uint256 requestId;

  /// Thrown when the reveal has already been triggered by an admin.
  error OnlyUnrevealed();
  /// Thrown when the reveal request id is invalid.
  error InvalidVRFRequestId(uint256 expected, uint256 actual);
  /// Thrown when the mint is not open (before the START_DATE or after the PUBLIC_SALE_END_DATE).
  error Closed();
  /// Thrown when the mint quantity is invalid (only allowed values are 1, 2 or 3).
  error InvalidPricing(Tier tier, uint256 quantity, uint256 skip);
  /// Thrown when the Merkle Tree provided proof is invalid.
  error InvalidMerkleProof(address acccount);
  /// Thrown when the sender tier is insufficient.
  error InsufficientTier(address acccount, Tier tier);
  /// Thrown when the transaction value is insufficient.
  error InsufficientValue(uint256 quantity, uint256 expected, uint256 actual);
  /// Thrown when the supply is insufficient to execute the transaction.
  error InsufficientSupply(uint256 remaining, uint256 actual);
  /// Thrown when the wallet has already claimed his tokens.
  error AlreadyClaimed(address account, uint256 quantity);
  /// Thrown when the withdraw to the treasury reverts.
  error WithdrawFailed();

  constructor(
    address admin,
    address treasury,
    IERC721A _paris,
    address _coordinator,
    bytes32 _keyHash,
    uint64 _subId
  ) ERC721A("TheAssetsClub", "TAC") VRFConsumerBaseV2(_coordinator) {
    coordinator = VRFCoordinatorV2Interface(_coordinator);
    keyHash = _keyHash;
    subId = _subId;
    paris = _paris;

    _initializeOwner(admin);
    _setDefaultRoyalty(treasury, ROYALTIES);
  }

  /**
   * @dev TheAssetsClub collection starts at token 1. This allow to have the token IDs between [1,5777].
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @return The next token ID to be minted.
   * @dev This allow to have the upper bound incase of if we want to iterate over the owners.
   */
  function nextTokenId() external view returns (uint256) {
    return _nextTokenId();
  }

  /**
   * @return The OpenSea Contract-level metadata URI.
   * @dev See full specification here: https://docs.opensea.io/docs/contract-level-metadata
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Allow to change the collection contractURI, most likely due to URI migration to IPFS.
   * Requirements:
   * - sender must be the contract owner
   *
   * @param newContractURI The new contract URI.
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  /**
   * @return The base URI for the tokens.
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * @dev Allow to change the collection base URI, most likely due to URI migration to IPFS.
   * Requirements:
   * - Sender must be the owner of the contract.
   *
   * @param newBaseURI The new contract base URI.
   */
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  /**
   * @notice The number of remaining tokens avaialble for mint.
   * This is a hard limit that the owner cannot change.
   */
  function remaining() public view returns (uint256) {
    return MAXIMUM_MINTS - _totalMinted();
  }

  /**
   * @notice Get the current mint tier.
   */
  function phase() public view virtual returns (Phase) {
    uint256 timestamp = block.timestamp;
    if (timestamp < START_DATE) {
      return Phase.CLOSED;
    }

    if (timestamp < PRIVATE_SALE_END_DATE) {
      return Phase.PRIVATE_SALE;
    }

    if (timestamp < PUBLIC_SALE_END_DATE) {
      return Phase.PUBLIC_SALE;
    }

    return Phase.CLOSED;
  }

  /**
   * @notice Get the price to pay to mint.
   * @param tier The tier to use (OG, WL or PUBLIC). Passing LOCKED will revert.
   * @param quantity The quantity to mint (maximum 3).
   * @return The price in Ether wei.
   */
  function getPrice(Tier tier, uint256 quantity, uint256 skip) public pure returns (uint256) {
    if (quantity == 0 || quantity + skip > MAXIMUM_MINTS) {
      revert InvalidPricing(tier, quantity, skip);
    }

    unchecked {
      // 3 free tokens for the OG, 2 for the access list
      uint256 free = tier == Tier.OG ? 3 : (tier == Tier.ACCESS_LIST ? 2 : 0);
      // skip cannot be greater than free
      free = free >= skip ? free - skip : 0;
      // free cannot be greater than quantity
      free = free >= quantity ? quantity : free;

      return SALE_PRICE * (quantity - free);
    }
  }

  /**
   * @notice Burn a existing token.
   * @dev Requirements:
   * - Sender must be the owner of the token or should have approved the burn.
   *
   * @param tokenId The token id to burn.
   */
  function burn(uint256 tokenId) external {
    _burn(tokenId, true);
  }

  /**
   * @notice Set the mint parameters.
   * @param _merkelRoot The new Merkle Tree root that controls the wait list and the reservations.
   * @param _reserved The total number of reservations.
   * @dev Requirements:
   * - Sender must be the owner.
   * - Mint should not have started yet.
   */
  function setMintParameters(bytes32 _merkelRoot, uint256 _reserved) external onlyOwner {
    merkelRoot = _merkelRoot;
    reserved = _reserved;
  }

  /**
   * @notice Verify if a Merkle proof is valid.
   *
   * @param account The account involved into the verification.
   * @param _type The proof type (0 for claim, 1 for mint).
   * @param data For claim proofs, the number of tokens to claim. For mint proofs, the wl tier.
   * @param proof The Merkle proof.
   * @return true iuf the
   */
  function verifyProof(
    address account,
    Proof _type,
    uint256 data,
    bytes32[] calldata proof
  ) internal view returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, _type, data))));
    return MerkleProofLib.verifyCalldata(proof, merkelRoot, leaf);
  }

  /**
   * @notice Mint tokens for during the private or the public sale.
   * @dev Since holders of a token from "TheAssetsClub at NFT Paris" are considered as members of the access list,
   * they can use a special proof.
   *
   * proof[0] = 0x00000{TheAssetsClubAtNFTParis}
   * proof[1] = 0x00000{tokenId}
   *
   * Requirements:
   * - Sale phase be must either private sale or public sale.
   * - Merkle proof must be valid.
   */
  function mintTo(address to, uint256 quantity, Tier tier, bytes32[] calldata proof) external payable {
    Phase _phase = phase();
    if (_phase == Phase.CLOSED) {
      revert Closed();
    }

    Tier _tier;

    // for TheAssetsClub at NFT Paris holders
    if (proof.length == 2 && bytes32toAddress(proof[0]) == address(paris)) {
      uint256 tokenId = uint256(proof[1]);
      if (paris.ownerOf(tokenId) != to) {
        revert NotParisHolder(tokenId);
      }

      address used = parisUsed[tokenId];
      if (used != address(0) && used != to) {
        revert ParisAlreadyUsed(tokenId);
      }

      parisUsed[tokenId] = to;
      _tier = Tier.ACCESS_LIST;
    }
    // claimed tier is greater than PUBLIC, verify the Merkle proof
    else if (tier > Tier.PUBLIC) {
      if (!verifyProof(to, Proof.MINT, uint256(tier), proof)) {
        revert InvalidMerkleProof(to);
      }

      _tier = tier;
    }

    uint256 _remaining = remaining();

    if (_phase == Phase.PRIVATE_SALE) {
      // Unprivileged users cannot mint during the private sale
      if (_tier == Tier.PUBLIC) {
        revert InsufficientTier(to, tier);
      }

      // during the private sale, remaining tokens do not include reserved ones
      _remaining -= reserved;
    }

    if (_remaining < quantity) {
      revert InsufficientSupply(_remaining, quantity);
    }

    uint256 price = getPrice(tier, quantity, minted[to]);
    if (msg.value < price) {
      revert InsufficientValue(quantity, msg.value, price);
    }

    minted[to] += quantity;
    _mint(to, quantity);
  }

  /**
   * @notice Claim reserved tokens for free.
   * This function only applies to a specific set of privileged members who were personally innvolved with the project.
   * The claimable tokens are only reserved for the private sale, meaning that if a privileged account does not claim
   * his tokens AND the mint sold out, reserved tokens will be lost.
   * @dev Requirements:
   * - Sale phase be must either private sale or public sale.
   * - Merkle proof must be valid.
   * - Claim must be only executed once.
   * - Remaining sypply must be sufficient.
   *
   * @param to The token recipient.
   * @param quantity The amount of tokens to be claimed.
   * @param proof The Merkle proof that will be check against the {merkelRoot}.
   */
  function claimTo(address to, uint256 quantity, bytes32[] calldata proof) external {
    Phase _phase = phase();
    if (_phase == Phase.CLOSED) {
      revert Closed();
    }

    if (!verifyProof(to, Proof.CLAIM, quantity, proof)) {
      revert InvalidMerkleProof(to);
    }

    if (claimed[to]) {
      revert AlreadyClaimed(to, quantity);
    }

    uint256 _remaining = remaining();
    if (_remaining < quantity) {
      revert InsufficientSupply(_remaining, quantity);
    }

    reserved -= quantity;
    claimed[to] = true;
    _mint(to, quantity);
  }

  /**
   * @notice Trigger the reveal.
   * @dev Requirements:
   * - Sender must be the owner of the contract.
   * - Reveal should not have started yet.
   */
  function reveal() external onlyOwner {
    if (revealed) {
      revert OnlyUnrevealed();
    }

    revealed = true;
    requestId = coordinator.requestRandomWords(keyHash, subId, minimumRequestConfirmations, callbackGasLimit, 1);
  }

  /**
   * @dev Receive the entropy from Chainlink VRF coordinator.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory randomWords) internal override {
    if (requestId != _requestId) {
      revert InvalidVRFRequestId(requestId, _requestId);
    }

    seed = randomWords[0];
  }

  /**
   * @notice Send the ether stored on the contract to the owner.
   * @dev Anyone is allow to call this function and pay teh gas for us :)
   */
  function withdraw() external {
    (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
    if (!success) {
      revert WithdrawFailed();
    }
  }

  // ----- Utility functions ----
  /**
   * Convert a bytes32 to address.
   * @param input The bytes32 to convert.
   */
  function bytes32toAddress(bytes32 input) public pure returns (address addr) {
    assembly {
      mstore(0, input)
      addr := mload(0)
    }
  }

  // ----- Operator Filter Registry -----
  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
   * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
   *
   * Overloaded method as instructed the Operator Filter Registry.
   * See: https://github.com/ProjectOpenSea/operator-filter-registry/tree/1bc335867da2695ec447e68cb894a0cfda127bc8
   *
   * @param operator Address to add to the set of authorized operators.
   * @param approved True if the operator is approved, false to revoke approval.
   */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  /**
   * @notice Change or reaffirm the approved address for an token.
   * @dev The zero address indicates there is no approved address. Throws unless `msg.sender` is the current token
   * owner, or an authorized operator of the current owner.
   *
   * Overloaded method as instructed the Operator Filter Registry.
   * See: https://github.com/ProjectOpenSea/operator-filter-registry/tree/1bc335867da2695ec447e68cb894a0cfda127bc8
   *
   * @param operator The new approved token controller.
   * @param tokenId The token to approve.
   */
  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  /**
   * @notice Transfer ownership of an NFT without any check on the destination address.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this
   * token. Throws if `_from` is not the current owner. Throws if `_to` is the zero address. Throws if `_tokenId` is
   * not a valid token.
   *
   * Overloaded method as instructed the Operator Filter Registry.
   * See: https://github.com/ProjectOpenSea/operator-filter-registry/tree/1bc335867da2695ec447e68cb894a0cfda127bc8
   *
   * @param from The current owner of the token.
   * @param to The new owner.
   * @param tokenId The token to transfer.
   */
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @notice Transfers the ownership of an token from one address to another address.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for
   * this token.
   * Throws if `from` is not the current owner.
   * Throws if `to` is the zero address.
   * Throws if `tokenId` is not a valid token.
   *
   * When transfer is complete, this function checks if `_to` is a smart contract (code size > 0).
   * If so, it calls `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   *
   * Overloaded method as instructed the Operator Filter Registry.
   * See: https://github.com/ProjectOpenSea/operator-filter-registry/tree/1bc335867da2695ec447e68cb894a0cfda127bc8
   *
   * @param from The current owner of the token.
   * @param to The new owner.
   * @param tokenId The token to transfer.
   * @param data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
   * @notice Transfers the ownership of an token from one address to another address.
   * @dev This works identically to the other function with an extra data parameter, except this function just sets
   * data to "".
   *
   * Overloaded method as instructed the Operator Filter Registry.
   * See: https://github.com/ProjectOpenSea/operator-filter-registry/tree/1bc335867da2695ec447e68cb894a0cfda127bc8
   *
   * @param from The current owner of the token.
   * @param to The new owner.
   * @param tokenId The token to transfer.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /**
   * @notice IERC165 declaration.
   * @dev Supports the following `interfaceId`s:
   * - IERC165: 0x01ffc9a7
   * - IERC721: 0x80ac58cd
   * - IERC721Metadata: 0x5b5e139f
   * - IERC2981: 0x2a55205a
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
    return super.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
  }
}