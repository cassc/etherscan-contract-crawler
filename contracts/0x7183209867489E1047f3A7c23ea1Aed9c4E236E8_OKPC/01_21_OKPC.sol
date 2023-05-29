/*
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░██████████░░░░░██████████░░░███████████████░░██████████░░░░░██████████░░░░░
  ░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░███░░░░░██░░░░░
  ░░░░░█████░░░██████████░░░░░██████████░░░░░██████████░░░░░██████████░░█████░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░█████░░                                                            ░░░░░███░░
  ░░░░░░░░░░          ██████████                    ██████████          ░░░█████░░
  ░░░░░███░░        ██          ███               ██          ███       ░░░██░░░░░
  ░░░░░░░░░░     ███               ██          ███               ██     ░░░░░░░░░░
  ░░░█████░░     ███     █████     ██          ███     █████     ██     ░░░░░███░░
  ░░░░░░░░░░     ███       ███     ██   █████  ███       ███     ██     ░░░█████░░
  ░░░░░███░░     ███     █████     ██          ███     █████     ██     ░░░██░░░░░
  ░░░░░░░░░░     ███     █████     ██   █████  ███     █████     ██     ░░░░░░░░░░
  ░░░█████░░        ██          ███               ██          ███       ░░░██░░░░░
  ░░░░░░░░░░          ██████████        █████       ██████████          ░░░█████░░
  ░░░░░███░░                                                            ░░░░░███░░
  ░░░░░░░░░░     █████                                        █████     ░░░░░░░░░░
  ░░░█████░░     █████   █████  █████   █████  █████   █████  █████     ░░░██░░░░░
  ░░░░░░░░░░             █████  █████   █████     ██   █████            ░░░█████░░
  ░░░░░███░░                                                            ░░░░░███░░
  ░░░░░░░░░░                                                            ░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ████████████████████████████████████████████████████████████████████████████████
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░███░░███░░████████░░████████░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░███░░███░░█████░░░░░████████░░███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░░░░████████░░███░░███░░███░░░░░░░████████░░░░░██░░░██░░░██░░░██░░░██░░░██░░░░░
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░


                       scotato.eth, shahruz.eth, cjpais.eth

*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IOKPC} from './interfaces/IOKPC.sol';
import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {SSTORE2} from '@0xsequence/sstore2/contracts/SSTORE2.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IERC2981} from '@openzeppelin/contracts/interfaces/IERC2981.sol';
import {IOKPCMetadata} from './interfaces/IOKPCMetadata.sol';

contract OKPC is IOKPC, ERC721A, IERC2981, Ownable, ReentrancyGuard {
  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   CONFIG                                   */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- MINTING -------------------------------- */
  uint256 public immutable MAX_SUPPLY;
  uint16 private immutable ARTISTS_RESERVED;
  uint16 private immutable TEAM_RESERVED;
  uint16 private immutable MAX_PER_PHASE;
  uint256 public immutable MINT_COST;
  /* --------------------------------- GALLERY -------------------------------- */
  uint8 private constant MAX_ART_PER_ARTIST = 8;
  uint8 private constant MIN_GALLERY_ART = 128;
  uint16 public constant MAX_COLLECT_PER_ART = 512;
  uint256 public constant ART_COLLECT_COST = 0.02 ether;
  /* -------------------------------- ROYALTIES ------------------------------- */
  uint256 private constant ROYALTY = 640;
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  uint256 public clockSpeedMaxMultiplier = 24;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   STORAGE                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- MINTING -------------------------------- */
  Phase public mintingPhase;
  mapping(address => bool) public earlyBirdsMintClaimed;
  mapping(address => bool) public friendsMintClaimed;
  bytes32 private _artistsMerkleRoot;
  bytes32 private _earlyBirdsMerkleRoot;
  bytes32 private _friendsMerkleRoot;
  /* --------------------------------- GALLERY -------------------------------- */
  bool public galleryOpen;
  uint256 public galleryArtCounter;
  uint256 private maxGalleryArt = 512;
  mapping(uint256 => uint256) public galleryArtCollectedCount;
  mapping(uint256 => address) private _galleryArtData;
  mapping(address => uint256) public galleryArtistArtCount;
  mapping(uint256 => uint256) public activeArtForOKPC;
  mapping(uint256 => mapping(uint256 => bool)) public artCollectedByOKPC;
  mapping(uint256 => uint256) public artCountForOKPC;
  mapping(bytes32 => bool) private _galleryArtHashes;
  /* ---------------------------------- PAINT --------------------------------- */
  bool public paintOpen;
  mapping(uint256 => Art) public paintArtForOKPC;
  mapping(uint256 => Commission) public openCommissionForOKPC;
  mapping(address => bool) public denyList;
  /* -------------------------------- RENDERER -------------------------------- */
  address public metadataAddress;
  mapping(uint256 => bool) public useOffchainMetadata;
  /* -------------------------------- PAYMENTS -------------------------------- */
  uint256 public paymentBalanceOwner;
  mapping(address => uint256) public paymentBalanceArtist;
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  mapping(uint256 => ClockSpeedXP) public clockSpeedData;
  /* ------------------------------- EXPANSIONS ------------------------------- */
  address public messagingAddress;
  address public communityAddress;
  address public marketplaceAddress;

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */
  event hello();
  /* --------------------------------- MINTING -------------------------------- */
  event MintingPhaseStarted(Phase phase);
  /* --------------------------------- GALLERY -------------------------------- */
  event ArtChanged(uint256 pcId, uint256 artId);
  event GalleryOpenUpdated(bool open);
  event GalleryArtCreated(uint256 indexed artId, address artist);
  event GalleryArtCollected(uint256 pcId, uint256 artId);
  event GalleryArtSwapped(uint256 pcId1, uint256 pcId2);
  event GalleryArtTransferred(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  );
  event GalleryMaxArtUpdated(uint256 maxGalleryArt);
  /* ---------------------------------- PAINT --------------------------------- */
  event PaintOpenUpdated(bool open);
  event PaintArtCreated(uint256 indexed pcId, address artist);
  event CommissionCreated(uint256 pcId, address artist, uint256 amount);
  event CommissionCompleted(uint256 pcId, address artist, uint256 amount);
  event CommissionCancelled(uint256 pcId);
  /* -------------------------------- RENDERER -------------------------------- */
  event MetadataAddressUpdated(address addr);
  /* -------------------------------- PAYMENTS -------------------------------- */
  event PaymentWithdrawnOwner(uint256 amount);
  event PaymentWithdrawnArtist(address artist, uint256 amount);
  event PaymentReceivedArtist(address artist, uint256 amount);
  event PaymentReceivedOwner(uint256 amount);
  /* ------------------------------- CLOCK SPEED ------------------------------ */
  event ClockSpeedMaxMultiplierUpdated(uint256 maxMultiplier);
  /* ------------------------------- EXPANSIONS ------------------------------- */
  event MessagingAddressUpdated(address messagingAddress);
  event CommunityAddressUpdated(address communityAddress);
  event MarketplaceAddressUpdated(address marketplaceAddress);

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   ERRORS                                   */
  /* -------------------------------------------------------------------------- */
  error NotOKPCOwner();
  error OKPCNotFound();
  error MerkleProofInvalid();
  error InvalidAddress();
  /* --------------------------------- MINTING -------------------------------- */
  error MintPhaseNotOpen();
  error MintTooManyOKPCs();
  error MintAlreadyClaimed();
  error MintMaxReached();
  error MintNotAuthorized();
  /* --------------------------------- GALLERY -------------------------------- */
  error GalleryNotOpen();
  error GalleryMinArtNotReached();
  error GalleryMaxArtReached();
  error GalleryArtNotFound();
  error GalleryArtAlreadyCollected();
  error GalleryArtNotCollected();
  error GalleryArtCollectedMaximumTimes();
  error GalleryArtCannotBeActive();
  error GalleryArtDuplicate();
  error GalleryArtLastCollected();
  /* ---------------------------------- PAINT --------------------------------- */
  error PaintArtDataInvalid();
  error PaintArtNotFound();
  error PaintNotOpen();
  error PaintDenyList();
  error PaintCommissionInvalid();
  error PaintNotCommissionedArtist();
  /* -------------------------------- PAYMENTS -------------------------------- */
  error PaymentAmountInvalid();
  error PaymentBalanceZero();
  error PaymentTransferFailed();
  /* ------------------------------- EXPANSIONS ------------------------------- */
  error NotCommunityAddress();
  error NotMarketplaceAddress();
  error NotOwnerOrCommunity();

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  MODIFIERS                                 */
  /* -------------------------------------------------------------------------- */
  /// @notice Requires the caller to be the owner of the specified pcId.
  modifier onlyOwnerOf(uint256 pcId) {
    if (msg.sender != ownerOf(pcId)) revert NotOKPCOwner();
    _;
  }
  /* --------------------------------- MINTING -------------------------------- */
  /// @notice Requires the current total OKPC supply to be less than the max supply for the current phase.
  modifier onlyIfSupplyMintable() {
    if (
      _currentIndex >
      ARTISTS_RESERVED + TEAM_RESERVED + (uint256(mintingPhase) * MAX_PER_PHASE)
    ) revert MintMaxReached();
    _;
  }
  /// @notice Requires the specified minting phase be active.
  modifier onlyIfMintingPhaseIsSetTo(Phase phase) {
    if (mintingPhase != phase) revert MintPhaseNotOpen();
    _;
  }
  /// @notice Requires the specified minting phase be active or have been active before
  modifier onlyIfMintingPhaseIsSetToOrAfter(Phase minimumPhase) {
    if (mintingPhase < minimumPhase) revert MintPhaseNotOpen();
    _;
  }
  /// @notice Requires the a valid merkle proof for the specified merkle root.
  modifier onlyIfValidMerkleProof(bytes32 root, bytes32[] calldata proof) {
    if (
      !MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender)))
    ) revert MerkleProofInvalid();
    _;
  }
  /// @notice Requires no earlier claims for the caller in the Early Birds mint.
  modifier onlyIfNotAlreadyClaimedEarlyBirds() {
    if (earlyBirdsMintClaimed[msg.sender]) revert MintAlreadyClaimed();
    _;
  }
  /// @notice Requires no earlier claims for the caller in the Friends mint.
  modifier onlyIfNotAlreadyClaimedFriends() {
    if (friendsMintClaimed[msg.sender]) revert MintAlreadyClaimed();
    _;
  }
  /* --------------------------------- GALLERY -------------------------------- */
  /// @notice Requires Gallery to be open.
  modifier onlyIfGalleryOpen() {
    if (!galleryOpen) revert GalleryNotOpen();
    _;
  }
  /// @notice Requires the artId corresponds to existing Gallery art.
  modifier onlyIfGalleryArtExists(uint256 artId) {
    if (artId > galleryArtCounter || artId == 0) revert GalleryArtNotFound();
    _;
  }
  /// @notice Requires the pcId to have artId in its collection already
  modifier onlyIfOKPCHasCollectedGalleryArt(uint256 pcId, uint256 artId) {
    if (!artCollectedByOKPC[pcId][artId]) revert GalleryArtNotCollected();
    _;
  }
  /// @notice Requires the minimum amount of Gallery art to be uploaded already.
  modifier onlyAfterMinimumGalleryArtUploaded() {
    if (galleryArtCounter < MIN_GALLERY_ART) revert GalleryMinArtNotReached();
    _;
  }
  /* ---------------------------------- PAINT --------------------------------- */
  /// @notice Requires Paint to be open.
  modifier onlyIfPaintOpen() {
    if (!paintOpen) revert PaintNotOpen();
    _;
  }
  /* -------------------------------- PAYMENTS -------------------------------- */
  /// @notice Requires msg.value be exactly the specified amount.
  modifier onlyIfPaymentAmountValid(uint256 value) {
    if (msg.value != value) revert PaymentAmountInvalid();
    _;
  }
  /* ------------------------------- EXPANSIONS ------------------------------- */
  /// @notice Requires the caller be the owner or community address.
  modifier onlyOwnerOrCommunity() {
    if (msg.sender != communityAddress && msg.sender != owner())
      revert NotOwnerOrCommunity();
    _;
  }
  /// @notice Requires the caller be the community address.
  modifier onlyCommunity() {
    if (msg.sender != communityAddress) revert NotCommunityAddress();
    _;
  }
  /// @notice Requires the caller be the marketplace address.
  modifier onlyMarketplace() {
    if (msg.sender != marketplaceAddress) revert NotMarketplaceAddress();
    _;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                               INITIALIZATION                               */
  /* -------------------------------------------------------------------------- */
  constructor(
    uint16 artistsReserved,
    uint16 teamReserved,
    uint16 maxPerPhase,
    uint256 mintCost
  ) ERC721A('OKPC', 'OKPC') {
    ARTISTS_RESERVED = artistsReserved;
    TEAM_RESERVED = teamReserved;
    MAX_PER_PHASE = maxPerPhase;
    MAX_SUPPLY = ARTISTS_RESERVED + TEAM_RESERVED + (MAX_PER_PHASE * 3);
    MINT_COST = mintCost;

    emit hello();
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows owner to set a merkle root for Artists.
  /// @param newRoot The new merkle root to set.
  function setArtistsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _artistsMerkleRoot = newRoot;
  }

  /// @notice Allows owner to set a merkle root for Early Birds.
  /// @param newRoot The new merkle root to set.
  function setEarlyBirdsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _earlyBirdsMerkleRoot = newRoot;
  }

  /// @notice Allows owner to set a merkle root for Friends.
  /// @param newRoot The new merkle root to set.
  function setFriendsMerkleRoot(bytes32 newRoot) external onlyOwner {
    _friendsMerkleRoot = newRoot;
  }

  /// @notice Allows the owner to upload initial Gallery art before minting opens.
  /// @param data The data of the art to be uploaded for 128 art pieces
  function addInitialGalleryArt(bytes calldata data) external onlyOwner {
    if (galleryArtCounter > 0) revert GalleryMaxArtReached();
    if (data.length != uint256(MIN_GALLERY_ART) * 128)
      revert PaintArtDataInvalid();

    for (uint256 i; i < MIN_GALLERY_ART; i++) {
      uint256 artId = i + 1;

      (address artist, uint256 data1, uint256 data2, bytes16 title) = abi
        .decode(
          data[i * MIN_GALLERY_ART:artId * MIN_GALLERY_ART],
          (address, uint256, uint256, bytes16)
        );

      if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
      if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
        revert GalleryArtDuplicate();
      if (galleryArtistArtCount[artist] == MAX_ART_PER_ARTIST)
        revert GalleryMaxArtReached();

      unchecked {
        galleryArtistArtCount[artist]++;
      }
      _galleryArtHashes[keccak256(abi.encodePacked(data1, data2))] = true;

      emit GalleryArtCreated(artId, artist);
    }

    _galleryArtData[0] = SSTORE2.write(data);
    galleryArtCounter = MIN_GALLERY_ART;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   MINTING                                  */
  /* -------------------------------------------------------------------------- */
  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows owner to mint 64 OKPCs to a list of 64 artist addresses.
  /// @param addr An array of 64 artist addresses.
  function mintArtists(address[64] calldata addr)
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    nonReentrant
  {
    if (_currentIndex > ARTISTS_RESERVED) revert MintMaxReached();
    for (uint16 i; i < 64; i++) {
      _collectIncludedGalleryArt(_currentIndex);
      _safeMint(addr[i], 1);
    }
  }

  /// @notice Allows owner to mint 64 OKPCs to a list of 4 team addresses.
  /// @param addr An array of 4 team addresses.
  function mintTeam(address[4] calldata addr)
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    nonReentrant
  {
    if (_currentIndex < ARTISTS_RESERVED) revert MintPhaseNotOpen();
    if (_currentIndex > ARTISTS_RESERVED + TEAM_RESERVED)
      revert MintMaxReached();
    for (uint16 i; i < 64; i++) {
      _collectIncludedGalleryArt(_currentIndex);
      _safeMint(addr[i % 4], 1);
    }
  }

  /* ------------------------------- EARLY BIRDS ------------------------------ */
  /// @notice Allows the owner to start the Early Birds minting phase.
  function startEarlyBirdsMint()
    external
    onlyOwner
    onlyAfterMinimumGalleryArtUploaded
    onlyIfMintingPhaseIsSetTo(Phase.INIT)
  {
    if (_currentIndex <= 512) revert MintPhaseNotOpen();
    mintingPhase = Phase.EARLY_BIRDS;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC if you're on the Early Birds list.
  /// @param merkleProof A Merkle proof of the caller's address in the Early Birds list.
  function mintEarlyBirds(bytes32[] calldata merkleProof)
    external
    payable
    onlyIfMintingPhaseIsSetToOrAfter(Phase.EARLY_BIRDS)
    onlyIfValidMerkleProof(_earlyBirdsMerkleRoot, merkleProof)
    onlyIfPaymentAmountValid(MINT_COST)
    onlyIfNotAlreadyClaimedEarlyBirds
    onlyIfSupplyMintable
    nonReentrant
  {
    earlyBirdsMintClaimed[msg.sender] = true;

    _collectIncludedGalleryArt(_currentIndex);

    addToOwnerBalance(MINT_COST - ART_COLLECT_COST);
    addToArtistBalance(
      getGalleryArt(_includedGalleryArtForOKPC(_currentIndex)).artist,
      ART_COLLECT_COST
    );

    _safeMint(msg.sender, 1);
  }

  /* --------------------------------- FRIENDS -------------------------------- */
  /// @notice Allows the owner to start the Friends minting phase.
  function startFriendsMint()
    external
    onlyOwner
    onlyIfMintingPhaseIsSetTo(Phase.EARLY_BIRDS)
  {
    mintingPhase = Phase.FRIENDS;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC if you're on the Friends list.
  /// @param merkleProof A Merkle proof of the caller's address in the Friends list.
  function mintFriends(bytes32[] calldata merkleProof)
    external
    payable
    onlyIfMintingPhaseIsSetToOrAfter(Phase.FRIENDS)
    onlyIfValidMerkleProof(_friendsMerkleRoot, merkleProof)
    onlyIfPaymentAmountValid(MINT_COST)
    onlyIfSupplyMintable
    onlyIfNotAlreadyClaimedFriends
    nonReentrant
  {
    friendsMintClaimed[msg.sender] = true;

    _collectIncludedGalleryArt(_currentIndex);

    addToOwnerBalance(MINT_COST - ART_COLLECT_COST);
    addToArtistBalance(
      getGalleryArt(_includedGalleryArtForOKPC(_currentIndex)).artist,
      ART_COLLECT_COST
    );

    _safeMint(msg.sender, 1);
  }

  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Allows the owner to start the Public minting phase.
  function startPublicMint()
    external
    onlyOwner
    onlyIfMintingPhaseIsSetTo(Phase.FRIENDS)
  {
    mintingPhase = Phase.PUBLIC;
    emit MintingPhaseStarted(mintingPhase);
  }

  /// @notice Mint your OKPC.
  /// @param amount The number of OKPCs to mint. Accepts values between 1 and 8.
  function mint(uint256 amount)
    external
    payable
    onlyIfMintingPhaseIsSetTo(Phase.PUBLIC)
    onlyIfSupplyMintable
    onlyIfPaymentAmountValid(MINT_COST * amount)
    nonReentrant
  {
    if (amount > 8) revert MintTooManyOKPCs();
    if (tx.origin != msg.sender) revert MintNotAuthorized();

    addToOwnerBalance(amount * (MINT_COST - ART_COLLECT_COST));

    for (uint256 i; i < amount; i++) {
      _collectIncludedGalleryArt(_currentIndex + i);
      addToArtistBalance(
        getGalleryArt(_includedGalleryArtForOKPC(_currentIndex + i)).artist,
        ART_COLLECT_COST
      );
    }

    _safeMint(msg.sender, amount);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   GALLERY                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Returns data for the specified Gallery art.
  /// @param artId The artId to look for in the Gallery.
  function getGalleryArt(uint256 artId)
    public
    view
    onlyIfGalleryArtExists(artId)
    returns (Art memory)
  {
    if (artId <= MIN_GALLERY_ART) {
      uint256 artBucket = (artId - 1) / MIN_GALLERY_ART;
      uint256 artBucketOffset = (artId - 1) % MIN_GALLERY_ART;
      (address addr, uint256 data1, uint256 data2, bytes16 title) = abi.decode(
        SSTORE2.read(
          _galleryArtData[artBucket],
          artBucketOffset * 128,
          (artBucketOffset + 1) * 128
        ),
        (address, uint256, uint256, bytes16)
      );
      return Art(addr, title, data1, data2);
    } else {
      (address addr, uint256 data1, uint256 data2, bytes16 title) = abi.decode(
        SSTORE2.read(_galleryArtData[artId]),
        (address, uint256, uint256, bytes16)
      );
      return Art(addr, title, data1, data2);
    }
  }

  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Collect artwork from the Gallery on your OKPC.
  /// @param pcId The id of the OKPC to collect the gallery to.
  /// @param artId The id of the artwork you'd like to collect.
  /// @param makeActive Set to true to switch your OKPC to displaying this art.
  function collectArt(
    uint256 pcId,
    uint256 artId,
    bool makeActive
  )
    external
    payable
    onlyIfGalleryOpen
    onlyOwnerOf(pcId)
    onlyIfGalleryArtExists(artId)
  {
    address artist = getGalleryArt(artId).artist;
    if (msg.sender != artist && msg.value != ART_COLLECT_COST)
      revert PaymentAmountInvalid();
    else if (msg.sender == artist && msg.value > 0)
      revert PaymentAmountInvalid();

    if (msg.value > 0) addToArtistBalance(artist, msg.value);

    _collectGalleryArt(pcId, artId);

    if (makeActive) setGalleryArt(pcId, artId);
  }

  /// @notice Collect multiple Gallery artworks on your OKPC.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC.
  /// @param artIds An array of ids for the art you'd like to collect.
  function collectArt(uint256 pcId, uint256[] calldata artIds)
    external
    payable
    onlyIfGalleryOpen
    onlyOwnerOf(pcId)
  {
    if (msg.value != ART_COLLECT_COST * artIds.length)
      revert PaymentAmountInvalid();

    for (uint256 i; i < artIds.length; i++) {
      if (artIds[i] > galleryArtCounter || artIds[i] == 0)
        revert GalleryArtNotFound();

      addToArtistBalance(getGalleryArt(artIds[i]).artist, ART_COLLECT_COST);

      _collectGalleryArt(pcId, artIds[i]);
    }
  }

  /// @notice Switch the active Gallery art on your OKPC.
  /// @param pcId The id of the OKPC to collect to. You need to own the OKPC.
  /// @param artId A id of the art you'd like to display. If your OKPC has custom art, you can display it by setting this to 0.
  function setGalleryArt(uint256 pcId, uint256 artId)
    public
    onlyOwnerOf(pcId)
    onlyIfOKPCHasCollectedGalleryArt(pcId, artId)
  {
    activeArtForOKPC[pcId] = artId;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, artId);
  }

  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Post new Gallery artwork if you're an OKPC artist.
  /// @param title The title of the artwork.
  /// @param data1 The first part of the art data to be stored.
  /// @param data1 The second part of the art data to be stored.
  /// @param merkleProof A Merkle proof of the caller's address in the Artists list.
  function addGalleryArt(
    bytes16 title,
    uint256 data1,
    uint256 data2,
    bytes32[] calldata merkleProof
  ) external onlyIfValidMerkleProof(_artistsMerkleRoot, merkleProof) {
    if (denyList[msg.sender]) revert PaintDenyList();
    if (galleryArtCounter == maxGalleryArt) revert GalleryMaxArtReached();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
    if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
      revert GalleryArtDuplicate();
    if (galleryArtistArtCount[msg.sender] == MAX_ART_PER_ARTIST)
      revert GalleryMaxArtReached();

    unchecked {
      galleryArtistArtCount[msg.sender]++;
      galleryArtCounter++;
    }
    _galleryArtHashes[keccak256(abi.encodePacked(data1, data2))] = true;

    _galleryArtData[galleryArtCounter] = SSTORE2.write(
      abi.encode(msg.sender, data1, data2, title)
    );

    emit GalleryArtCreated(galleryArtCounter, msg.sender);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Toggles the Gallery interactions on or off.
  function toggleGalleryOpen() external onlyOwner {
    galleryOpen = !galleryOpen;
    emit GalleryOpenUpdated(galleryOpen);
  }

  /// @notice Allows the owner to increase the size of the Gallery.
  /// @param newMaxGalleryArt The new maximum number of Gallery artworks. Must be greater than the previous amount.
  function increaseMaxGalleryArt(uint256 newMaxGalleryArt) external onlyOwner {
    if (maxGalleryArt >= newMaxGalleryArt) revert GalleryMaxArtReached();
    maxGalleryArt = newMaxGalleryArt;
    emit GalleryMaxArtUpdated(maxGalleryArt);
  }

  /// @notice Allows the owner or community to moderate Gallery artwork.
  /// @param artId The id of the Gallery artwork to moderate.
  /// @param title The title for the replacement art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  /// @param artist The address of the artist of the replacement art.
  function moderateGalleryArt(
    uint256 artId,
    bytes16 title,
    uint256 data1,
    uint256 data2,
    address artist
  ) external onlyOwnerOrCommunity {
    if (artId <= 128) revert PaintArtDataInvalid();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();

    Art memory art = getGalleryArt(artId);
    galleryArtistArtCount[art.artist]--;

    unchecked {
      galleryArtistArtCount[artist]++;
    }

    _galleryArtData[artId] = SSTORE2.write(
      abi.encode(artist, data1, data2, title)
    );

    emit GalleryArtCreated(galleryArtCounter, msg.sender);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Collects Gallery artwork to your OKPC.
  /// @param pcId The id of the OKPC to collect to.
  /// @param artId The id of the Gallery art you'd like to collect.
  function _collectGalleryArt(uint256 pcId, uint256 artId) internal {
    if (artCollectedByOKPC[pcId][artId]) revert GalleryArtAlreadyCollected();
    if (galleryArtCollectedCount[artId] == MAX_COLLECT_PER_ART)
      revert GalleryArtCollectedMaximumTimes();

    artCollectedByOKPC[pcId][artId] = true;

    unchecked {
      artCountForOKPC[pcId]++;
      galleryArtCollectedCount[artId]++;
    }

    emit GalleryArtCollected(pcId, artId);
  }

  /// @notice Determines the included Gallery artwork for an OKPC.
  /// @param pcId The id of the OKPC being minted.
  function _includedGalleryArtForOKPC(uint256 pcId)
    internal
    view
    returns (uint256)
  {
    return
      pcId <= 128
        ? pcId
        : (uint256(
          keccak256(
            abi.encodePacked(
              'OKPC',
              pcId,
              blockhash(block.number - 1),
              block.coinbase,
              block.difficulty,
              msg.sender
            )
          )
        ) % galleryArtCounter) + 1;
  }

  /// @notice Collects the included Gallery artwork for an OKPC.
  /// @param pcId The id of the OKPC being minted.
  function _collectIncludedGalleryArt(uint256 pcId) internal {
    uint256 artId = _includedGalleryArtForOKPC(pcId);

    artCountForOKPC[pcId] = 1;
    artCollectedByOKPC[pcId][artId] = true;
    emit GalleryArtCollected(pcId, artId);

    activeArtForOKPC[pcId] = artId;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, artId);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                    PAINT                                   */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Get the Paint art stored on an OKPC.
  /// @param pcId The id of the OKPC to look up.
  function getPaintArt(uint256 pcId) public view returns (Art memory) {
    if (paintArtForOKPC[pcId].artist == address(0)) revert PaintArtNotFound();
    return paintArtForOKPC[pcId];
  }

  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Displays stored Paint art on your OKPC.
  /// @param pcId The id of the OKPC to display. You'll need to own the OKPC.
  function setPaintArt(uint256 pcId) external onlyOwnerOf(pcId) {
    if (paintArtForOKPC[pcId].artist == address(0)) revert PaintArtNotFound();
    activeArtForOKPC[pcId] = 0;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, 0);
  }

  /// @notice Stores and displays stored Paint art on your OKPC.
  /// @param pcId The id of the OKPC to store Paint art on. You'll need to own the OKPC.
  /// @param title The title of the Paint art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  function setPaintArt(
    uint256 pcId,
    bytes16 title,
    uint256 data1,
    uint256 data2
  ) external onlyIfPaintOpen onlyOwnerOf(pcId) {
    _setPaintArt(pcId, title, msg.sender, data1, data2);
  }

  /// @notice Create a commission for another artist to use Paint on your OKPC.
  /// @param pcId The id of the OKPC to use. You'll need to own the OKPC.
  /// @param artist The address of the artist to create a commission for.
  function createCommission(uint256 pcId, address artist)
    external
    payable
    onlyOwnerOf(pcId)
    onlyIfPaintOpen
    nonReentrant
  {
    if (artist == address(0)) revert PaintCommissionInvalid();
    if (msg.sender == artist) revert PaintCommissionInvalid();

    if (openCommissionForOKPC[pcId].artist != address(0))
      cancelCommission(pcId);

    openCommissionForOKPC[pcId] = Commission(artist, msg.value);

    emit CommissionCreated(pcId, artist, msg.value);
  }

  /// @notice Cancels a commission
  /// @param pcId The id of the OKPC to cancel a commission on. You'll need to own the OKPC.
  function cancelCommission(uint256 pcId)
    public
    onlyOwnerOf(pcId)
    onlyIfPaintOpen
  {
    _cancelCommission(pcId);
  }

  /// @notice Cancels a commission. This may be called by the owner of the OKPC or when a token is being transferred.
  /// @param pcId The id of the OKPC to cancel a commission on.
  function _cancelCommission(uint256 pcId) internal nonReentrant {
    if (openCommissionForOKPC[pcId].artist == address(0))
      revert PaintCommissionInvalid();

    uint256 amount = openCommissionForOKPC[pcId].amount;
    delete openCommissionForOKPC[pcId];

    if (amount > 0) {
      (bool success, ) = ownerOf(pcId).call{value: amount}('');
      if (!success) revert PaymentTransferFailed();
    }

    emit CommissionCancelled(pcId);
  }

  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Completes a commission.
  /// @param pcId The id of the OKPC to complete a commission for.
  /// @param title The title of the new art.
  /// @param data1 The first part of the art data to be stored.
  /// @param data2 The second part of the art data to be stored.
  function completeCommission(
    uint256 pcId,
    bytes16 title,
    uint256 data1,
    uint256 data2
  ) external onlyIfPaintOpen nonReentrant {
    if (msg.sender != openCommissionForOKPC[pcId].artist)
      revert PaintNotCommissionedArtist();

    _setPaintArt(pcId, title, msg.sender, data1, data2);

    uint256 amount = openCommissionForOKPC[pcId].amount;
    delete openCommissionForOKPC[pcId];
    if (amount > 0) {
      (bool success, ) = msg.sender.call{value: amount}('');
      if (!success) revert PaymentTransferFailed();
    }

    emit CommissionCompleted(pcId, msg.sender, amount);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Toggles the Paint interactions on or off.
  function togglePaintOpen() external onlyOwner {
    paintOpen = !paintOpen;
    emit PaintOpenUpdated(paintOpen);
  }

  /// @notice Allows the owner to update the deny list status for an address.
  /// @param artist The address of the artist to update.
  /// @param deny Whether to deny the artist or not from submitting Art.
  function setDenyListStatus(address artist, bool deny) external onlyOwner {
    denyList[artist] = deny;
  }

  /// @notice Allows the owner or community to moderate Paint art and revert to collected Gallery art.
  /// @param pcId The OKPC containing the Paint art.
  /// @param artId The Gallery Art to revert to. This must already be owned by the OKPC.
  function moderatePaintArt(uint256 pcId, uint256 artId)
    external
    onlyOwnerOrCommunity
    onlyIfOKPCHasCollectedGalleryArt(pcId, artId)
  {
    if (getPaintArt(pcId).artist == address(0)) revert PaintArtNotFound();

    delete paintArtForOKPC[pcId];

    activeArtForOKPC[pcId] = artId;
    emit ArtChanged(pcId, artId);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Stores and displays Paint art on an OKPC.
  function _setPaintArt(
    uint256 pcId,
    bytes16 title,
    address artist,
    uint256 data1,
    uint256 data2
  ) internal {
    if (denyList[artist]) revert PaintDenyList();
    if (title[0] == bytes1(0x0)) revert PaintArtDataInvalid();
    if (_galleryArtHashes[keccak256(abi.encodePacked(data1, data2))])
      revert GalleryArtDuplicate();

    paintArtForOKPC[pcId].artist = artist;
    paintArtForOKPC[pcId].title = title;
    paintArtForOKPC[pcId].data1 = data1;
    paintArtForOKPC[pcId].data2 = data2;
    emit PaintArtCreated(pcId, artist);

    activeArtForOKPC[pcId] = 0;
    clockSpeedData[pcId].artLastChanged = block.timestamp;
    emit ArtChanged(pcId, 0);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  RENDERER                                  */
  /* -------------------------------------------------------------------------- */
  /* ------------------------------- OKPC OWNERS ------------------------------ */
  /// @notice Toggles the off-chain renderer for your OKPC.
  /// @param pcId The OKPC to toggle.
  function switchOKPCRenderer(uint256 pcId) external onlyOwnerOf(pcId) {
    useOffchainMetadata[pcId] = !useOffchainMetadata[pcId];
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Updates the metadata address for OKPC.
  /// @param addr The new metadata address. Must conform to IOKPCMetadata.
  function setMetadataAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    metadataAddress = addr;
    emit MetadataAddressUpdated(addr);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  PAYMENTS                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- ARTISTS -------------------------------- */
  /// @notice Sends you your full available balance if you're an OKPC artist.
  function withdrawArtistBalance() external nonReentrant {
    uint256 balance = paymentBalanceArtist[msg.sender];
    if (balance == 0) revert PaymentBalanceZero();
    paymentBalanceArtist[msg.sender] = 0;

    (bool success, ) = msg.sender.call{value: balance}('');
    if (!success) revert PaymentBalanceZero();

    emit PaymentWithdrawnArtist(msg.sender, balance);
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Sends you your full available balance if you're the OKPC.
  /// @param withdrawTo The address to send the balance to.
  function withdrawOwnerBalance(address withdrawTo)
    external
    onlyOwner
    nonReentrant
  {
    if (paymentBalanceOwner == 0) revert PaymentBalanceZero();
    uint256 balance = paymentBalanceOwner;
    paymentBalanceOwner = 0;

    (bool success, ) = withdrawTo.call{value: balance}('');
    if (!success) revert PaymentBalanceZero();

    emit PaymentWithdrawnOwner(balance);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Adds funds to the payment balance for the specified address.
  /// @param artist The address to add funds to.
  /// @param amount The amount to add to the balance.
  function addToArtistBalance(address artist, uint256 amount) internal {
    emit PaymentReceivedArtist(artist, amount);
    paymentBalanceArtist[artist] += amount;
  }

  /// @notice Adds funds to the payment balance for the owner.
  /// @param amount The amount to add to the balance.
  function addToOwnerBalance(uint256 amount) internal {
    emit PaymentReceivedOwner(amount);
    paymentBalanceOwner += amount;
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                  ROYALTIES                                 */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice EIP2981 royalty standard
  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * ROYALTY) / 10000);
  }

  /// @notice Receive royalties
  receive() external payable {
    addToOwnerBalance(msg.value);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                 CLOCK SPEED                                */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice Returns the clockspeed for the specified OKPC.
  /// @param pcId The id of the OKPC to look up.
  function clockSpeed(uint256 pcId) public view returns (uint256) {
    uint256 lastBlock = clockSpeedData[pcId].lastSaveBlock;
    if (lastBlock == 0) {
      return 1;
    }
    uint256 delta = block.number - lastBlock;
    uint256 multiplier = delta / 200_000;
    if (multiplier > clockSpeedMaxMultiplier) {
      multiplier = clockSpeedMaxMultiplier;
    }
    uint256 total = clockSpeedData[pcId].savedSpeed +
      ((delta * (multiplier + 1)) / 10_000);
    if (total < 1) total = 1;
    return total;
  }

  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows the owner to update the maximum clockspeed multiplier.
  /// @param multiplier The new max clockspeed multiplier to set.
  function setClockSpeedMaxMultiplier(uint256 multiplier) external onlyOwner {
    clockSpeedMaxMultiplier = multiplier;
    emit ClockSpeedMaxMultiplierUpdated(multiplier);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice Saves clockspeed data. Called before an OKPC is transferred.
  function _saveClockSpeed(uint256 pcId) internal {
    clockSpeedData[pcId].savedSpeed = clockSpeed(pcId);
    clockSpeedData[pcId].lastSaveBlock = block.number;
    unchecked {
      clockSpeedData[pcId].transferCount++;
    }
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                 EXPANSIONS                                 */
  /* -------------------------------------------------------------------------- */
  /* ---------------------------------- ADMIN --------------------------------- */
  /// @notice Allows the owner to update the Messaging address.
  /// @param addr The new Messaging address.
  function setMessagingAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    messagingAddress = addr;
    emit MessagingAddressUpdated(addr);
  }

  /// @notice Allows the owner to update the Community address.
  /// @param addr The new Community address.
  function setCommunityAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    communityAddress = addr;
    emit CommunityAddressUpdated(addr);
  }

  /// @notice Allows the owner to update the Marketplace address.
  /// @param addr The new Marketplace address.
  function setMarketplaceAddress(address addr) external onlyOwner {
    if (addr == address(0)) revert InvalidAddress();
    marketplaceAddress = addr;
    emit MarketplaceAddressUpdated(addr);
  }

  /* ------------------------------- MARKETPLACE ------------------------------ */
  /// @notice Allows the Marketplace contract to transfer art between OKPCs.
  /// @param fromOKPCId The id of the OKPC to transfer from.
  /// @param toOKPCId The id of the OKPC to transfer to.
  /// @param artId The id of the Gallery artwork to transfer.
  function transferArt(
    uint256 fromOKPCId,
    uint256 toOKPCId,
    uint256 artId
  ) external onlyMarketplace onlyIfGalleryArtExists(artId) {
    if (!artCollectedByOKPC[fromOKPCId][artId]) revert GalleryArtNotCollected();

    if (artCollectedByOKPC[toOKPCId][artId])
      revert GalleryArtAlreadyCollected();

    if (artCountForOKPC[fromOKPCId] == 1) revert GalleryArtLastCollected();

    if (activeArtForOKPC[fromOKPCId] == artId)
      revert GalleryArtCannotBeActive();

    artCollectedByOKPC[fromOKPCId][artId] = false;
    artCountForOKPC[fromOKPCId]--;

    artCollectedByOKPC[toOKPCId][artId] = true;
    unchecked {
      artCountForOKPC[toOKPCId]++;
    }
    emit GalleryArtTransferred(fromOKPCId, toOKPCId, artId);
  }

  /// @notice Allows the Marketplace contract to add funds to an artist's withdrawable balance.
  /// @param artist The address to add funds to.
  function addToArtistBalanceFromMarketplace(address artist)
    external
    payable
    onlyMarketplace
  {
    addToArtistBalance(artist, msg.value);
  }

  /// @notice Allows the Marketplace contract to add funds to the owner's withdrawable balance.
  function addToOwnerBalanceFromMarketplace() external payable onlyMarketplace {
    addToOwnerBalance(msg.value);
  }

  /* --------------------------------- ****** --------------------------------- */

  /* -------------------------------------------------------------------------- */
  /*                                   ERC721A                                  */
  /* -------------------------------------------------------------------------- */
  /* --------------------------------- PUBLIC --------------------------------- */
  /// @notice The standard ERC721 tokenURI function. Routes to the Metadata contract.
  function tokenURI(uint256 pcId) public view override returns (string memory) {
    if (!_exists(pcId)) revert OKPCNotFound();
    return IOKPCMetadata(metadataAddress).tokenURI(pcId);
  }

  /* -------------------------------- INTERNAL -------------------------------- */
  /// @notice ERC721A override to start tokenId's at 1 instead of 0.
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /// @notice Overrides _beforeTokenTransfers to update clockspeeds and clear any active commissions.
  function _beforeTokenTransfers(
    address,
    address,
    uint256 startTokenId,
    uint256 quantity
  ) internal override {
    for (uint256 i; i < quantity; i++) {
      uint256 pcId = startTokenId + i;
      _saveClockSpeed(pcId);
      if (openCommissionForOKPC[pcId].artist != address(0))
        _cancelCommission(pcId);
    }
  }

  /* --------------------------------- ****** --------------------------------- */
}