// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/DefaultOperatorFiltererUpgradeable.sol";

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

//  $$$$$$\  $$$$$$$\  $$$$$$$$\ $$$$$$$$\ $$$$$$$\ $$$$$$$$\
// $$  __$$\ $$  __$$\ $$  _____|$$  _____|$$  __$$\\____$$  |
// $$ /  \__|$$ |  $$ |$$ |      $$ |      $$ |  $$ |   $$  /
// $$ |      $$$$$$$  |$$$$$\    $$$$$\    $$$$$$$  |  $$  /
// $$ |      $$  __$$< $$  __|   $$  __|   $$  ____/  $$  /
// $$ |  $$\ $$ |  $$ |$$ |      $$ |      $$ |      $$  /
// \$$$$$$  |$$ |  $$ |$$$$$$$$\ $$$$$$$$\ $$ |     $$$$$$$$\
//  \______/ \__|  \__|\________|\________|\__|     \________|

/**
 * @dev upgradable {ERC721} token with staking functionality.
 */
contract CreepzByOverlord is
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  DefaultOperatorFiltererUpgradeable,
  ERC721Upgradeable
{
  using Strings for uint256;

  // Base URI
  string private _creepzBaseURI;

  // Royalty info
  address private royaltyAddress;
  uint256 private constant ROYALTY_SIZE = 750;
  uint256 private constant ROYALTY_DENOMINATOR = 10000;

  // Creepz v1 contract address
  address private creepzV1Address;
  address public globalOperator;

  // Pauses transfers & claims
  bool public isPaused;
  bool public isClaimPaused;

  // Sets if user can transfer while staked
  bool private canTransferWhileStaked;

  /**
  @dev tokenId to staked timestamp. This is the timestamp at which the token was staked.
  */
  mapping(uint256 => uint256) public stakedAtTimestamp;

  event Stake(uint256 indexed tokenId);
  event Unstake(
    uint256 indexed tokenId,
    uint256 stakedAtTimestamp,
    uint256 removedFromStakeAtTimestamp
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   * @param _royaltyAddress Address to receive royalties.
   * @param _baseURI Base URI for the token metadata.
   * @param _creepzV1Address Address of the Creepz v1 contract.
   */
  function initialize(
    address _royaltyAddress,
    string memory _baseURI,
    address _creepzV1Address
  ) external initializer {
    royaltyAddress = _royaltyAddress;
    _creepzBaseURI = _baseURI;
    creepzV1Address = _creepzV1Address;
    isClaimPaused = true;

    __ERC721_init("Creepz by OVERLORD", "CBC");
    __Ownable_init();
    __ReentrancyGuard_init();
    DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
  }

  /**
   * @dev function to stake tokens. Can be called by tokenOwner only.
   * @param tokenIds array of tokenIds to stake.
   */
  function stake(uint256[] calldata tokenIds) external nonReentrant {
    require(tokenIds.length < 100, "C:MT");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(ownerOf(tokenId) == _msgSender(), "C:!O");
      require(stakedAtTimestamp[tokenId] == 0, "C:TS");
      stakedAtTimestamp[tokenId] = block.timestamp;
      emit Stake(tokenId);
    }
  }

  /**
   * @dev function to unstake tokens. Can be called by tokenOwner only.
   * @param tokenIds array of tokenIds to unstake.
   */
  function unstake(uint256[] calldata tokenIds) external nonReentrant {
    require(tokenIds.length < 100, "C:MT");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint256 tokenStakedAtTimestamp = stakedAtTimestamp[tokenId];

      require(ownerOf(tokenId) == _msgSender(), "C:!O");
      require(tokenStakedAtTimestamp != 0, "C:TS");
      stakedAtTimestamp[tokenId] = 0;
      emit Unstake(tokenId, tokenStakedAtTimestamp, block.timestamp);
    }
  }

  /**
   * @dev public function to calculate the stake of multiple tokens.
   * @param tokenIds array of tokenIds to calculate stake for.
   */
  function calculateStakeForMultipleTokens(
    uint256[] calldata tokenIds
  ) external view returns (uint256 totalAccumulated) {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      if (stakedAtTimestamp[tokenId] != 0) {
        totalAccumulated += block.timestamp - stakedAtTimestamp[tokenId];
      }
    }
  }

  /**
   * @dev function to transfer tokens while staked. Can be called by tokenOwner only.
   * @param to address to transfer tokens to.
   * @param tokenIds array of tokenIds to transfer.
   */
  function transferWhileStaked(
    address to,
    uint256[] calldata tokenIds
  ) external nonReentrant {
    require(tokenIds.length > 0, "C:NT");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(ownerOf(tokenId) == _msgSender(), "C:!O");
      canTransferWhileStaked = true;
      _transfer(_msgSender(), to, tokenId);
      canTransferWhileStaked = false;
    }
  }

  /**
   * @dev function to remove creepz from soft stake by admin.
   * @param tokenIds array of tokenIds to remove from soft stake.
   */
  function ownerRemoveFromSoftStake(
    uint256[] calldata tokenIds
  ) external nonReentrant onlyOwner {
    require(tokenIds.length > 0, "C:NT");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      uint256 tokenStakedAtTimestamp = stakedAtTimestamp[tokenId];
      stakedAtTimestamp[tokenId] = 0;
      emit Unstake(tokenId, tokenStakedAtTimestamp, block.timestamp);
    }
  }

  /**
   * @dev Function to airdrop tokens. Only owner can call this function.
   */
  function airdrop(
    address[] calldata recipients,
    uint256[] calldata tokenIds
  ) external onlyOwner {
    require(recipients.length == tokenIds.length, "C:WL");

    for (uint256 i = 0; i < recipients.length; i++) {
      _mint(recipients[i], tokenIds[i]);
      stakedAtTimestamp[tokenIds[i]] = block.timestamp;
    }
  }

  /**
   * @dev Function to exchange your v1 tokens to v2.
   */
  function claim(uint256[] calldata tokenIds) external nonReentrant {
    require(!isClaimPaused, "C:CP");
    require(tokenIds.length <= 50, "C:WL");

    for (uint256 i = 0; i < tokenIds.length; i++) {
      IERC721(creepzV1Address).transferFrom(
        _msgSender(),
        address(this),
        tokenIds[i]
      );
      _mint(_msgSender(), tokenIds[i]);
      stakedAtTimestamp[tokenIds[i]] = block.timestamp;
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    require(_exists(tokenId));

    return
      string(abi.encodePacked(_creepzBaseURI, tokenId.toString(), ".json"));
  }

  /**
   * @dev See {ERC-2981: NFT Royalty Standard}.
   */
  function royaltyInfo(
    uint256,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    uint256 amount = (_salePrice * ROYALTY_SIZE) / ROYALTY_DENOMINATOR;
    return (royaltyAddress, amount);
  }

  /**
   * @dev Sets the base URI of metadata. Should end with "/".
   * @param newBaseURI New base URI of metadata.
   */
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _creepzBaseURI = newBaseURI;
  }

  /**
   * @dev Pauses or unpauses transfers.
   */
  function pause(bool _isPaused) external onlyOwner {
    isPaused = _isPaused;
  }

  /**
   * @dev Pauses or unpauses claim.
   */
  function pauseClaim(bool _isPaused) external onlyOwner {
    isClaimPaused = _isPaused;
  }

  /**
   * @dev Sets the global operator.
   */
  function setGlobalOperator(address _operator) external onlyOwner {
    globalOperator = _operator;
  }

  /**
   * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  /**
   * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  /**
   * @dev Overwrites basic ERC721 functions to activate DefaultOperatorFilterer.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /**
  @dev Block transfers while staked.
  */
  function _beforeTokenTransfer(
    address from,
    address,
    uint256 tokenId /* firstTokenId */,
    uint256
  ) internal view override {
    require(stakedAtTimestamp[tokenId] == 0 || canTransferWhileStaked, "C:TS");
    if (from != address(0)) {
      require(!isPaused, "C:TP");
    }
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view override returns (bool) {
    address owner = ERC721Upgradeable.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender ||
      spender == globalOperator);
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}