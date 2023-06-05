// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

error PowerPack__PackOpeningIsClosed();
error PowerPack__TransferFailed();
error PowerPack__NotEnoughEthSent();
error PowerPack__ExternalContractsNotSet();
error PowerPack__MintNotOpen();
error PowerPack__NotOnMintList();
error PowerPack__AlreadyMinted();
error PowerPack__OnlyFiatMintAddressCanCall();
error PowerPack__NotOwned();
error PowerPack__QuantityNotAllowed();
error PowerPack__MaxSupplyReached();
error PowerPack__NoContractMint();
error PowerPack__InvalidURI();
error PowerPack__UnequalLengths();
error PowerPack__InvalidAddress();

interface SlotContract {
  function mintToOpenedPack(address to, uint256 packId) external;
}

contract PowerPack is
  ERC721AQueryable,
  ReentrancyGuard,
  Ownable,
  ERC2981,
  UpdatableOperatorFilterer,
  VRFConsumerBaseV2
{
  using ECDSA for bytes32;

  /////////////////////
  // State Variables //
  /////////////////////

  uint16 public constant MAX_SUPPLY = 5000;
  uint16 private constant READER_MAX = 4564;
  uint8 private constant SKETCH_MAX = 192;
  uint8 private constant PANEL_MAX = 144;
  uint8 private constant REDEEMEABLE_MAX = 100;
  uint8 public constant MAX_MINT_MINTLIST = 2;

  /**
   * @notice The maximum number of packs that can be minted at once
   * during the public mint phase.
   * @dev uint8 is used because this value should never exceed 255.
   * While it is possible to mint more than 255 packs at once with ERC721A,
   * transferring tokens from large batches is increasingly expensive for users.
   */
  uint8 public s_maxMintPublic = 5;

  uint256 public s_price = 0.08 ether;
  string private s_baseTokenURI;
  string private s_contractURI;

  /**
   * @notice Whether opening packs is currently allowed.
   */
  bool public s_canOpenPack;

  enum SaleState {
    OFF,
    TEAM,
    STUDIO_BADGE,
    BOBO_BURN,
    MINTLIST,
    PUBLIC
  }

  /**
   * @notice Sets mint phase
   * @dev Use admin setSaleState() to change
   */
  SaleState public s_saleState = SaleState.OFF;

  enum Addresses {
    GENESIS,
    SKETCH,
    READER,
    REDEEMABLE,
    PANELS,
    STUDIO_BADGE,
    FIAT_MINT,
    MINTLIST_SIGNER
  }
  /**
   * @notice Stores addresses
   * @dev Use admin setAddress() to change
   */
  mapping(Addresses => address) private s_addresses;

  struct SlotTwoInfo {
    uint256 packId;
    address mintedTo;
    uint256 randomNumber;
  }

  struct SlotTwoCounter {
    uint16 readerCount;
    uint8 sketchCount;
    uint8 panelCount;
    uint8 redeemableCount;
  }
  /**
   * @notice Tracks count of randomly minted NFTs from opened packs
   */
  SlotTwoCounter private s_slotCounter = SlotTwoCounter(0, 0, 0, 0);

  /**
   * @notice Whether someone has minted during MINTLIST phase
   */
  mapping(address => bool) public s_mintListMinted;

  /**
   * @notice Whether someone has minted during PUBLIC phase
   */
  mapping(address => bool) public s_publicMinted;

  /**
   * @notice Whether studio badge holder has claimed
   * @dev maximum 1 free pack per studio badge
   */
  mapping(uint256 => bool) public s_studioBadgeClaimed;

  /**
   * @notice requestId -> packId
   * @dev used so chainlink callback knows which packId to use
   */
  mapping(uint256 => SlotTwoInfo) private s_requestToSlotTwo;

  // Chainlink VRF Variables
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  uint64 private immutable i_subscriptionId;
  bytes32 private immutable i_gasLane;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  /////////////////////
  // Events          //
  /////////////////////

  /**
   * @dev emitted when a pack is minted
   */
  event PowerPackMinted();

  /**
   * @dev emitted when a pack is opened
   */
  event PackOpened(uint256 indexed packId, uint256 requestId);

  /**
   * @dev emitted when a random slot2 nft is minted after opening pack
   */
  event SlotTwoMinted(uint256 packId, address to, uint256 rand);

  /**
   * @dev emitted when the price is updated
   */
  event PriceUpdated(address operator, uint256 newPrice);

  /**
   * @dev emitted when the base URI is updated
   */
  event BaseURIChanged(address operator, string newBaseURI);

  /**
   * @dev emitted when the contract URI is updated
   */
  event ContractURIChanged(address operator, string newContractURI);

  /**
   * @dev emitted when the maximum number of packs that can be minted at once
   * during the public mint phase is updated
   */
  event MaxMintPublicUpdated(address operator, uint8 newMaxMintPublic);

  ////////////////////
  // Main Functions //
  ////////////////////

  constructor(
    string memory baseURI,
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane,
    uint32 callbackGasLimit
  )
    ERC721A("247 Power Packs: Genesis", "247GenPP")
    UpdatableOperatorFilterer(
      0x000000000000AAeB6D7670E522A718067333cd4E,
      0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
      true
    )
    VRFConsumerBaseV2(vrfCoordinatorV2)
  {
    s_baseTokenURI = baseURI;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_subscriptionId = subscriptionId;
    i_gasLane = gasLane;
    i_callbackGasLimit = callbackGasLimit;
  }

  /**
   * @notice Start pack IDs at 1 instead of 0
   */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   * @notice Opens pack and mints contents
   * @dev s_canOpenPack must be toggled on in order to call
   */
  function openPack(uint256 packId) public nonReentrant {
    if (!s_canOpenPack) {
      revert PowerPack__PackOpeningIsClosed();
    }
    address to = ownerOf(packId);
    if (to != msg.sender) {
      revert PowerPack__NotOwned();
    }
    _burn(packId, true);

    SlotContract genesis = SlotContract(s_addresses[Addresses.GENESIS]);
    genesis.mintToOpenedPack(to, packId);

    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    );

    s_requestToSlotTwo[requestId].packId = packId;
    s_requestToSlotTwo[requestId].mintedTo = to;
    emit PackOpened(packId, requestId);
  }

  /////////////////////////
  // Chainlink Functions //
  /////////////////////////

  /**
   * @dev This is the function that Chainlink VRF node
   * calls to choose which slot2 to mint.
   */
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    uint256 rand = (randomWords[0] % 5000) + 1;
    uint256 packId = s_requestToSlotTwo[requestId].packId;
    address to = s_requestToSlotTwo[requestId].mintedTo;

    s_requestToSlotTwo[requestId].randomNumber = rand;

    if (rand <= READER_MAX) {
      if (s_slotCounter.readerCount < READER_MAX) {
        mintReaderToken(to, packId);
      } else if (s_slotCounter.sketchCount < SKETCH_MAX) {
        mintSketchCard(to, packId);
      } else if (s_slotCounter.panelCount < PANEL_MAX) {
        mintPanel(to, packId);
      } else if (s_slotCounter.redeemableCount < REDEEMEABLE_MAX) {
        mintRedeemable(to, packId);
      } else {
        revert PowerPack__MaxSupplyReached();
      }
    } else if (rand <= READER_MAX + SKETCH_MAX) {
      if (s_slotCounter.sketchCount < SKETCH_MAX) {
        mintSketchCard(to, packId);
      } else if (s_slotCounter.readerCount < READER_MAX) {
        mintReaderToken(to, packId);
      } else if (s_slotCounter.panelCount < PANEL_MAX) {
        mintPanel(to, packId);
      } else if (s_slotCounter.redeemableCount < REDEEMEABLE_MAX) {
        mintRedeemable(to, packId);
      } else {
        revert PowerPack__MaxSupplyReached();
      }
    } else if (rand <= READER_MAX + SKETCH_MAX + REDEEMEABLE_MAX) {
      if (s_slotCounter.panelCount < PANEL_MAX) {
        mintPanel(to, packId);
      } else if (s_slotCounter.readerCount < READER_MAX) {
        mintReaderToken(to, packId);
      } else if (s_slotCounter.sketchCount < SKETCH_MAX) {
        mintSketchCard(to, packId);
      } else if (s_slotCounter.redeemableCount < REDEEMEABLE_MAX) {
        mintRedeemable(to, packId);
      } else {
        revert PowerPack__MaxSupplyReached();
      }
    } else if (rand <= MAX_SUPPLY) {
      if (s_slotCounter.redeemableCount < REDEEMEABLE_MAX) {
        mintRedeemable(to, packId);
      } else if (s_slotCounter.readerCount < READER_MAX) {
        mintReaderToken(to, packId);
      } else if (s_slotCounter.sketchCount < SKETCH_MAX) {
        mintSketchCard(to, packId);
      } else if (s_slotCounter.panelCount < PANEL_MAX) {
        mintPanel(to, packId);
      } else {
        revert PowerPack__MaxSupplyReached();
      }
    } else {
      revert PowerPack__MaxSupplyReached();
    }

    emit SlotTwoMinted(packId, to, rand);
  }

  function mintReaderToken(address to, uint256 packId) private nonReentrant {
    SlotContract readerToken = SlotContract(s_addresses[Addresses.READER]);
    readerToken.mintToOpenedPack(to, packId);
    s_slotCounter.readerCount += 1;
  }

  function mintSketchCard(address to, uint256 packId) private nonReentrant {
    SlotContract sketchCards = SlotContract(s_addresses[Addresses.SKETCH]);
    sketchCards.mintToOpenedPack(to, packId);
    s_slotCounter.sketchCount += 1;
  }

  function mintPanel(address to, uint256 packId) private nonReentrant {
    SlotContract panel = SlotContract(s_addresses[Addresses.PANELS]);
    panel.mintToOpenedPack(to, packId);
    s_slotCounter.panelCount += 1;
  }

  function mintRedeemable(address to, uint256 packId) private nonReentrant {
    SlotContract redeemable = SlotContract(s_addresses[Addresses.REDEEMABLE]);
    redeemable.mintToOpenedPack(to, packId);
    s_slotCounter.redeemableCount += 1;
  }

  ////////////////////
  // Mint Functions //
  ////////////////////

  /**
   * @notice Allows a studio badge holder to mint up to 6 power packs (1st free)
   * @dev Only one transaction allowed per studio badge holder
   */
  function studioBadgeMint(
    uint256 studioBadgeId,
    uint256 quantity
  ) external payable {
    if (s_addresses[Addresses.STUDIO_BADGE] == address(0)) {
      revert PowerPack__ExternalContractsNotSet();
    }
    if (s_saleState != SaleState.STUDIO_BADGE) {
      revert PowerPack__MintNotOpen();
    }
    if (s_studioBadgeClaimed[studioBadgeId]) {
      revert PowerPack__AlreadyMinted();
    }
    if (quantity > 6) {
      revert PowerPack__QuantityNotAllowed();
    }
    if (msg.value < s_price * (quantity - 1)) {
      revert PowerPack__NotEnoughEthSent();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert PowerPack__MaxSupplyReached();
    }
    IERC721A studioBadge = IERC721A(s_addresses[Addresses.STUDIO_BADGE]);
    address to = msg.sender;

    if (to != studioBadge.ownerOf(studioBadgeId)) {
      revert PowerPack__NotOwned();
    }
    s_studioBadgeClaimed[studioBadgeId] = true;
    _safeMint(to, quantity);
    emit PowerPackMinted();
  }

  /**
   * @notice Mints one(maximum) pack to valid mintlist address
   * @dev s_saleState.MINTLIST must be set
   */
  function mintlistMint(
    bytes calldata mlSignature,
    uint256 quantity
  ) external payable {
    if (s_saleState != SaleState.MINTLIST) {
      revert PowerPack__MintNotOpen();
    }
    if (!mlSignatureValid(mlSignature)) {
      revert PowerPack__NotOnMintList();
    }
    if (s_mintListMinted[msg.sender]) {
      revert PowerPack__AlreadyMinted();
    }
    if (quantity > MAX_MINT_MINTLIST) {
      revert PowerPack__QuantityNotAllowed();
    }
    if (msg.value < (s_price * quantity)) {
      revert PowerPack__NotEnoughEthSent();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert PowerPack__MaxSupplyReached();
    }
    s_mintListMinted[msg.sender] = true;
    _safeMint(msg.sender, quantity);
    emit PowerPackMinted();
  }

  function mlSignatureValid(
    bytes calldata mlSignature
  ) internal view returns (bool) {
    if (s_addresses[Addresses.MINTLIST_SIGNER] == address(0)) {
      revert PowerPack__ExternalContractsNotSet();
    }
    return
      s_addresses[Addresses.MINTLIST_SIGNER] ==
      keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          bytes32(uint256(uint160(msg.sender)))
        )
      ).recover(mlSignature);
  }

  /**
   * @notice Mints the number of packs specified
   * @dev s_saleState.PUBLIC must be set
   */
  function publicMint(uint8 quantity) external payable {
    if (s_saleState != SaleState.PUBLIC) {
      revert PowerPack__MintNotOpen();
    }
    if (tx.origin != msg.sender) {
      revert PowerPack__NoContractMint();
    }
    if (s_publicMinted[msg.sender]) {
      revert PowerPack__AlreadyMinted();
    }
    if (quantity > s_maxMintPublic) {
      revert PowerPack__QuantityNotAllowed();
    }
    if (msg.value < (s_price * quantity)) {
      revert PowerPack__NotEnoughEthSent();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert PowerPack__MaxSupplyReached();
    }
    s_publicMinted[msg.sender] = true;
    _safeMint(msg.sender, quantity);
    emit PowerPackMinted();
  }

  /**
   * @notice Mints the number of packs specified to the buyer
   * @dev Only fiat wallet can call
   */
  function fiatMint(uint256 quantity, address to) external {
    if (s_addresses[Addresses.FIAT_MINT] == address(0)) {
      revert PowerPack__ExternalContractsNotSet();
    }
    if (
      !(s_saleState == SaleState.MINTLIST || s_saleState == SaleState.PUBLIC)
    ) {
      revert PowerPack__MintNotOpen();
    }
    if (msg.sender != s_addresses[Addresses.FIAT_MINT]) {
      revert PowerPack__OnlyFiatMintAddressCanCall();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert PowerPack__MaxSupplyReached();
    }
    if (s_saleState == SaleState.MINTLIST) {
      if (quantity > MAX_MINT_MINTLIST) {
        revert PowerPack__QuantityNotAllowed();
      }
      if (s_mintListMinted[to]) {
        revert PowerPack__AlreadyMinted();
      } else {
        s_mintListMinted[to] = true;
      }
    } else if (s_saleState == SaleState.PUBLIC) {
      if (quantity > s_maxMintPublic) {
        revert PowerPack__QuantityNotAllowed();
      }
      if (s_publicMinted[to]) {
        revert PowerPack__AlreadyMinted();
      } else {
        s_publicMinted[to] = true;
      }
    }
    _safeMint(to, quantity);
    emit PowerPackMinted();
  }

  /////////////////////
  // Admin Functions //
  /////////////////////

  function setBaseURI(string memory newUri) external onlyOwner {
    if (bytes(newUri).length == 0) {
      revert PowerPack__InvalidURI();
    }
    s_baseTokenURI = newUri;
    emit BaseURIChanged(msg.sender, newUri);
  }

  /**
   * @notice Sets the contract URI for OpenSea listings
   * @param newContractURI new contract URI
   */
  function setContractURI(string memory newContractURI) external onlyOwner {
    if (bytes(newContractURI).length == 0) {
      revert PowerPack__InvalidURI();
    }
    s_contractURI = newContractURI;
    emit ContractURIChanged(msg.sender, newContractURI);
  }

  /**
   * @notice Allows deployer to airdrop packs
   */
  function airdrop(address to, uint256 quantity) external onlyOwner {
    if (to == address(0)) {
      revert PowerPack__InvalidAddress();
    }
    if (_totalMinted() + quantity > MAX_SUPPLY) {
      revert PowerPack__MaxSupplyReached();
    }
    _safeMint(to, quantity);
    emit PowerPackMinted();
  }

  /**
   * @notice Toggles the ability for packs to be opened
   */
  function toggleCanOpenPack() external onlyOwner {
    if (
      s_addresses[Addresses.GENESIS] == address(0) ||
      s_addresses[Addresses.SKETCH] == address(0) ||
      s_addresses[Addresses.READER] == address(0) ||
      s_addresses[Addresses.REDEEMABLE] == address(0) ||
      s_addresses[Addresses.PANELS] == address(0)
    ) {
      revert PowerPack__ExternalContractsNotSet();
    }
    s_canOpenPack = !s_canOpenPack;
  }

  /**
   * @notice Sets minting phase
   */
  function setSaleState(SaleState newState) external onlyOwner {
    s_saleState = SaleState(newState);
  }

  /**
   * @notice Stores address in contract
   * @dev see Addresses enum for list
   */
  function setAddress(
    Addresses addrToUpdate,
    address newAddr
  ) external onlyOwner {
    if (newAddr == address(0)) {
      revert PowerPack__ExternalContractsNotSet();
    }
    s_addresses[addrToUpdate] = newAddr;
  }

  /**
   * @notice Stores multiple addresses in contract
   * @dev see Addresses enum for list
   */
  function setAddresses(
    Addresses[] calldata addrToUpdate,
    address[] calldata newAddr
  ) external onlyOwner {
    if (addrToUpdate.length != newAddr.length) {
      revert PowerPack__UnequalLengths();
    }
    for (uint256 i = 0; i < addrToUpdate.length; i++) {
      if (newAddr[i] == address(0)) {
        revert PowerPack__ExternalContractsNotSet();
      }
      s_addresses[addrToUpdate[i]] = newAddr[i];
    }
  }

  /**
   * @notice Sets the cost of minting one pack
   */
  function setPrice(uint256 price) external onlyOwner {
    s_price = price;
    emit PriceUpdated(msg.sender, price);
  }

  /**
   * @notice Sets the max quantity for public mint
   */
  function setMaxMintPublic(uint8 newMax) external onlyOwner {
    s_maxMintPublic = newMax;
    emit MaxMintPublicUpdated(msg.sender, newMax);
  }

  /**
   * @notice Withdraws funds to deployer
   */
  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    if (!success) revert PowerPack__TransferFailed();
  }

  ////////////////////
  // View Functions //
  ////////////////////

  /**
   * @notice Returns number of packs opened by a single address
   * @return _numberBurned burned packs = opened packs
   */
  function packsOpened(address addr) external view returns (uint256) {
    return _numberBurned(addr);
  }

  /**
   * @notice Returns total number of packs opened by all
   * @return _totalBurned burned packs = opened packs
   */
  function totalPacksOpened() external view returns (uint256) {
    return _totalBurned();
  }

  /**
   * @return _totalMinted total number of packs minted
   */
  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  /**
   * @notice gets the current address for a given Addresses enum
   * @dev see Addresses enum for list
   * @param addrEnum Addresses enum value to query
   * @return address The address associated with the enum value
   */
  function getAddress(Addresses addrEnum) external view returns (address) {
    return s_addresses[addrEnum];
  }

  /**
   * @notice Returns all addresses stored in contract
   * @dev see Addresses enum for list
   * @return addresses The addresses associated with the enum values
   */
  function getAddresses() external view returns (address[] memory) {
    address[] memory addresses = new address[](8);
    for (uint256 i = 0; i < 8; i++) {
      addresses[i] = s_addresses[Addresses(i)];
    }
    return addresses;
  }

  /**
   * @notice Returns info associated with Chainlink VRF requestId
   */
  function getRequestToSlotTwoInfo(
    uint256 requestId
  ) external view returns (SlotTwoInfo memory) {
    return s_requestToSlotTwo[requestId];
  }

  /**
   * @notice Returns slot2 counter of randomized mints
   */
  function getSlotCounter() external view returns (SlotTwoCounter memory) {
    return s_slotCounter;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return s_baseTokenURI;
  }

  function contractURI() external view returns (string memory) {
    return s_contractURI;
  }

  ///////////////////////
  // Royalty Functions //
  ///////////////////////

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }

  ///////////////////////
  // OpenSea Functions //
  ///////////////////////

  function owner()
    public
    view
    virtual
    override(Ownable, UpdatableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}