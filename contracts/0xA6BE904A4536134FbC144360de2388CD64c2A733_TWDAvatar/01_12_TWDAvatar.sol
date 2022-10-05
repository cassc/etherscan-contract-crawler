/*
╭━━━╮╱╱╱╱╱╱╱╱╱╱╱╱╱╱╭━━━╮╱╱╱╱╱╱╱╱╭╮
┃╭━╮┃╱╱╱╱╱╱╱╱╱╱╱╱╱╱┃╭━╮┃╱╱╱╱╱╱╱╭╯╰╮
┃┃╱┃┣━┳━━┳━╮╭━━┳━━╮┃┃╱╰╋━━┳╮╭┳━┻╮╭╯
┃┃╱┃┃╭┫╭╮┃╭╮┫╭╮┃┃━┫┃┃╱╭┫╭╮┃╰╯┃┃━┫┃
┃╰━╯┃┃┃╭╮┃┃┃┃╰╯┃┃━┫┃╰━╯┃╰╯┃┃┃┃┃━┫╰╮
╰━━━┻╯╰╯╰┻╯╰┻━╮┣━━╯╰━━━┻━━┻┻┻┻━━┻━╯
╱╱╱╱╱╱╱╱╱╱╱╱╭━╯┃
╱╱╱╱╱╱╱╱╱╱╱╱╰━━╯
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./utils/cryptography/MerkleProof.sol";
import "./utils/cryptography/MerkleUtils.sol";
import "./utils/Terms.sol";
import "./utils/Uri.sol";

contract TWDAvatar is ERC721A, IERC2981, Ownable, ReentrancyGuard, Terms, Uri {
  string public PROVENANCE_HASH;
  string public SEED_PHRASE_HASH;
  uint32 public MAX_MINT_BATCH = 20;

  string constant TOKEN_SYMBOL = "TWD-AVATAR";
  string constant TOKEN_NAME = "TWD Avatar";
  uint32 constant ROYALTY_PCT = 10;
  uint32 constant MAX_SUPPLY = 5000;

  uint256 public price = 0.06 ether;
  uint256 public discountPrice = 0.04 ether;

  bytes32 public merkleRoot;
  mapping(address => uint256) private _alreadyMinted;

  address public beneficiary;
  address public royalties;

  struct SaleConfig {
    uint32 endTime;
    uint32 tier1StartTime;
    uint32 tier2StartTime;
    uint32 noLimitStartTime;
    uint32 publicStartTime;
  }

  struct MsgConfig {
    string BAD_AMOUNT;
    string MAX_MINT_BATCH;
    string MAX_SUPPLY;
    string QUANTITY;
  }

  struct MintEntity {
    address to;
    uint256 quantity;
  }

  enum PhaseType {
    DEFAULT,
    PRESALE,
    TIER1,
    TIER2,
    NOLIMIT,
    PUBLIC,
    CLOSED
  }

  PhaseType private phase = PhaseType.DEFAULT;

  SaleConfig public saleConfig;
  MsgConfig private msgConfig;

  event MintListTier(uint8 tier);

  constructor(
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A(TOKEN_NAME, TOKEN_SYMBOL) {
    royalties = _royalties;
    beneficiary = royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
    termsURI = "ipfs://Qmbv7aLanDrHKgpZHjcuEaVQB5Em6qPGUJK3ydQdtzzuro";

    msgConfig = MsgConfig(
      "Incorrect amount paid",
      "Max minting batch will be exceeded",
      "Max supply will be exceeded",
      "Insufficient quantity left to mint"
    );

    // Tier 1 starts Tue Oct 04 2022 15:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.tier1StartTime = 1664910000;
    // Tier 2 starts Wed Oct 05 2022 09:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.tier2StartTime = 1664974800;
    // No Limit starts Wed Oct 05 2022 13:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.noLimitStartTime = 1664989200;
    // Public sale starts Wed Oct 05 2022 15:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.publicStartTime = 1664996400;
    // Sale ends Fri Oct 07 2022 15:00:00 GMT-0400 (Eastern Daylight Time)
    saleConfig.endTime = 1665169200;
  }

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setSeedPhraseHash(string calldata hash) public onlyOwner {
    SEED_PHRASE_HASH = hash;
  }

  function setPrice(uint256 value) public onlyOwner {
    price = value;
  }

  function setDiscountPrice(uint256 value) public onlyOwner {
    discountPrice = value;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

  function setPhase(PhaseType _phase) public onlyOwner {
    phase = _phase;
  }

  function getPhase() public view returns (PhaseType) {
    if (phase != PhaseType.DEFAULT) {
      return phase;
    }

    uint256 blockTimestamp = block.timestamp;

    if (blockTimestamp >= saleConfig.endTime) {
      return PhaseType.CLOSED;
    } else if (blockTimestamp >= saleConfig.publicStartTime) {
      return PhaseType.PUBLIC;
    } else if (blockTimestamp >= saleConfig.noLimitStartTime) {
      return PhaseType.NOLIMIT;
    } else if (blockTimestamp >= saleConfig.tier2StartTime) {
      return PhaseType.TIER2;
    } else if (blockTimestamp >= saleConfig.tier1StartTime) {
      return PhaseType.TIER1;
    }

    return PhaseType.PRESALE;
  }

  function getPrice() public view returns (uint256) {
    if (getPhase() <= PhaseType.NOLIMIT) {
      return discountPrice;
    }

    return price;
  }

  function getTierFromPhase() public view returns (uint8) {
    PhaseType currentPhase = getPhase();

    if (currentPhase == PhaseType.TIER1) {
      return 1;
    } else if (currentPhase == PhaseType.TIER2) {
      return 2;
    } else if (currentPhase == PhaseType.NOLIMIT) {
      return 3;
    }

    return 0;
  }

  function setTier1StartTime(uint32 time) external onlyOwner {
    saleConfig.tier1StartTime = time;
  }

  function setTier2StartTime(uint32 time) external onlyOwner {
    saleConfig.tier2StartTime = time;
  }

  function setNoLimitStartTime(uint32 time) external onlyOwner {
    saleConfig.noLimitStartTime = time;
  }

  function setPublicStartTime(uint32 time) external onlyOwner {
    saleConfig.publicStartTime = time;
  }

  function setSaleEndTime(uint32 time) external onlyOwner {
    saleConfig.endTime = time;
  }

  /**
   * Check if public sale is active
   */
  function isPublicActive() public view returns (bool) {
    return getPhase() == PhaseType.PUBLIC;
  }

  /**
   * Check if VIP sale is active
   */
  function isListActive() public view returns (bool) {
    PhaseType currentPhase = getPhase();

    return currentPhase >= PhaseType.TIER1 && currentPhase <= PhaseType.NOLIMIT;
  }

  /**
   * Get start time of sale
   */
  function getStartTime() public view returns (uint256) {
    return saleConfig.tier1StartTime;
  }

  /**
   * Gets the Base URI of the token API
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * Set the root of the merkle tree
   */
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  /**
   * Override start token to 1
   */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
   * Mint next available token(s) to addres using ERC721A _safeMint
   */
  function _internalMint(address to, uint256 quantity) private {
    require(totalSupply() + quantity <= MAX_SUPPLY, msgConfig.MAX_SUPPLY);

    _safeMint(to, quantity);
  }

  /**
   * @dev Throws if the account is not allowed to mint.
   */
  modifier allowedToMint(uint256 maxQuantity) {
    PhaseType currentPhase = getPhase();
    bool isTier1 = currentPhase == PhaseType.TIER1 && maxQuantity >= 5;
    bool isTier2 = currentPhase >= PhaseType.TIER2 && maxQuantity >= 1;

    require(isTier1 || isTier2, "Not allowed to mint during this phase");
    _;
  }

  /**
   * @dev Checks the account's max allowed to mint by phase
   */
  function checkMaxQuantity(
    address sender,
    uint256 quantity,
    uint256 maxQuantity
  ) private view returns (bool) {
    PhaseType currentPhase = getPhase();

    if (currentPhase >= PhaseType.NOLIMIT) {
      return true;
    } else {
      return quantity <= maxQuantity - _alreadyMinted[sender];
    }
  }

  /**
   * Allowlist Mint
   */
  function mintList(
    uint256 quantity,
    bytes32[] calldata merkleProof,
    uint256 maxQuantity
  ) public payable nonReentrant allowedToMint(maxQuantity) {
    address sender = _msgSender();
    require(isListActive(), "Sale Closed");
    require(
      checkMaxQuantity(sender, quantity, maxQuantity),
      msgConfig.QUANTITY
    );
    require(quantity <= MAX_MINT_BATCH, msgConfig.MAX_MINT_BATCH);
    require(msg.value == discountPrice * quantity, msgConfig.BAD_AMOUNT);
    require(
      MerkleUtils.verifyWithQuantity(
        merkleRoot,
        merkleProof,
        sender,
        maxQuantity
      ),
      "Invalid proof"
    );

    _alreadyMinted[sender] += quantity;
    _internalMint(sender, quantity);

    emit MintListTier(getTierFromPhase());
  }

  /**
   * Mint to all addresses
   */
  function mint(uint256 quantity) public payable nonReentrant {
    address sender = _msgSender();
    require(isPublicActive(), "Public sale is not active");
    require(quantity <= MAX_MINT_BATCH, msgConfig.MAX_MINT_BATCH);
    require(msg.value == price * quantity, msgConfig.BAD_AMOUNT);

    _internalMint(sender, quantity);
  }

  /**
   * Owner can mint to specified address
   */
  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount);
  }

  /**
   * Return total amount from an array of mint entities
   */
  function _totalAmount(MintEntity[] memory entities)
    private
    pure
    returns (uint256)
  {
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < entities.length; i++) {
      totalAmount += entities[i].quantity;
    }

    return totalAmount;
  }

  /**
   * Air Drop multiple addresses with number to mint for each
   */
  function airDrop(MintEntity[] memory entities) public onlyOwner {
    uint256 amount = _totalAmount(entities);
    require(totalSupply() + amount <= MAX_SUPPLY, msgConfig.MAX_SUPPLY);

    for (uint256 i = 0; i < entities.length; i++) {
      _internalMint(entities[i].to, entities[i].quantity);
    }
  }

  function withdraw() public onlyOwner {
    require(
      beneficiary != address(0),
      "beneficiary needs to be set to perform this function"
    );
    payable(beneficiary).transfer(address(this).balance);
  }

  /**
   * Supporting ERC721, IER165
   * https://eips.ethereum.org/EIPS/eip-165
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * Setting up royalty standard: IERC2981
   * https://eips.ethereum.org/EIPS/eip-2981
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address, uint256 royaltyAmount)
  {
    _tokenId; // silence solc unused parameter warning
    royaltyAmount = (_salePrice / 100) * ROYALTY_PCT;
    return (royalties, royaltyAmount);
  }
}