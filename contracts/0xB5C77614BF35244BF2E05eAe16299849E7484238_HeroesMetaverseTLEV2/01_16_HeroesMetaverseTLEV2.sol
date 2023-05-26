// SPDX-License-Identifier: MIT
// Heroes of the Metaverse: The Last Essence V2

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

interface IHeroesMetaverseTLE {
  function balanceOf(address) external view returns (uint256);
}

contract HeroesMetaverseTLEV2 is ERC721A, Ownable, VRFConsumerBaseV2, KeeperCompatibleInterface {
  // VRF V2
  VRFCoordinatorV2Interface COORDINATOR;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords = 1;
  uint256 public chainlinkRequestId;
  bytes32 public chainlinkKeyHash;
  uint64 private chainlinkSubscriptionId;

  // Contract
  uint256 public immutable maxSupply;
  string public constant provenance = "eaafaca161f3508ddafa27006834e0911d1dd932f36567f4b626cc138d3e8b0a";
  address public heroesContract = 0x1ecD6F0624cc9F20b30913bc081f94E1A7004271;

  // Mint
  uint256 public constant maxTokensPerWallet = 1;
  uint256 public constant commonHeroMultiplier = 2;
  uint256 public constant luckyHeroMultiplier = 3;
  uint256 public constant holderMultiplier = 10;

  // Token
  mapping(uint256 => string) gender;
  uint256 public offset;

  // Reservations
  uint256 public immutable amountForDevs;
  uint256 public immutable amountForProject; // MKT, gifts, givaways, etc
  uint256 public immutable maxBatchSize;

  // Operations
  string public baseURI;
  string private preRevealURI;
  bool public isMintOpen = false;
  bool public isHolderMintOn = false;
  bool public isGenderSwapOn = false;
  bool public revealed = false;
  address regentAddress;
  uint256 public withdrawInterval = 604800; // Week long in seconds
  uint256 public lastWithdraw;
  uint256 public regentInterval = 7776000; // 3 months in seconds
  uint256 public lastRegent;
  mapping(address => bool) public luckyHeroClaimed;

  constructor(
    uint256 _maxSupply,
    uint256 _amountForDevs,
    uint256 _amountForProject,
    uint256 _maxBatchSize,
    string memory _preRevealURI,
    address _vrfCoordinator,
    address _heroesContract
  ) ERC721A("HeroesMetaverseTLEV2", "HOTM") VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    require(_amountForProject + _amountForDevs <= _maxSupply, "HOTM.constructor: Max supply should be higher than amount for devs");
    maxSupply = _maxSupply;
    amountForDevs = _amountForDevs;
    amountForProject = _amountForProject;
    maxBatchSize = _maxBatchSize;
    regentAddress = msg.sender;
    preRevealURI = _preRevealURI;
    lastWithdraw = block.timestamp;
    heroesContract = _heroesContract;
  }

  /* Modifiers */

  modifier availableReq(uint256 _quantity) {
    require(totalSupply() + _quantity <= maxSupply, "HOTM.mint: All heroes recruited");
    _;
  }

  function _baseMintReq(uint256 _quantity, bool _isHolder) internal view availableReq(_quantity) {
    require(isMintOpen || _isHolder, "HOTM.mint: Open only for OG holders");
    bool notMinted = _numberMinted(msg.sender) == 0;
    uint256 mintQty = _numberMinted(msg.sender);
    require(
      ((notMinted && luckyHeroClaimed[msg.sender] == false) ||
        (_isHolder && mintQty == luckyHeroMultiplier && luckyHeroClaimed[msg.sender] == true)),
      "HOTM.mint: Already Minted"
    );
  }

  /* Minting */

  function mint() external {
    require(isMintOpen || isHolderMintOn, "HOTM.mint: Mint is not live");
    uint256 prevMinted = IHeroesMetaverseTLE(heroesContract).balanceOf(msg.sender);
    uint256 quantity = prevMinted > 0 ? prevMinted * holderMultiplier : commonHeroMultiplier;
    _baseMintReq(quantity, prevMinted > 0);
    _safeMint(msg.sender, quantity);
  }

  function luckyHeroMint(address _luckyHeroAddress) external onlyOwner availableReq(luckyHeroMultiplier) {
    require(luckyHeroClaimed[_luckyHeroAddress] == false, "HOTM.mint: Already claimed");
    _safeMint(_luckyHeroAddress, luckyHeroMultiplier);
    luckyHeroClaimed[_luckyHeroAddress] = true;
  }

  function devMint(uint256 _quantity, address _devAddress) external onlyOwner availableReq(_quantity) {
    require(_quantity % maxBatchSize == 0, "HOTM.devMint: Can only mint a multiple of the maxBatchSize");
    uint256 numChunks = _quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(_devAddress, maxBatchSize);
    }
  }

  /* Operations */

  function setBaseURI(string calldata baseUri_) external onlyOwner {
    baseURI = baseUri_;
  }

  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return baseURI;
  }

  function setOpenMint(bool _isOn) external onlyOwner {
    isMintOpen = _isOn;
  }

  function setHolderMint(bool _isOn) external onlyOwner {
    isHolderMintOn = _isOn;
  }

  function setGenderSwapOn(bool _isOn) external onlyOwner {
    isGenderSwapOn = _isOn;
  }

  /* Reveal Operations */
  function setChainlinkConfig(bytes32 _keyhash, uint64 _subscriptionId) external onlyOwner {
    chainlinkKeyHash = _keyhash;
    chainlinkSubscriptionId = _subscriptionId;
  }

  function startReveal(string memory baseUri_) external onlyOwner {
    require(!revealed, "HOTM.Reveal: Already Revealed");
    baseURI = baseUri_;
    chainlinkRequestId = COORDINATOR.requestRandomWords(
      chainlinkKeyHash,
      chainlinkSubscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(uint256, uint256[] memory _randomWords) internal override {
    require(!revealed, "HOTM.Reveal: Already Revealed");
    revealed = true;
    offset = (_randomWords[0] % totalSupply());
  }

  function withdraw() public {
    if (regentAddress != owner()) {
      payable(regentAddress).transfer((address(this).balance * 1) / 100);
    }
    payable(owner()).transfer(address(this).balance);
  }

  function setRegent(address _regentAddress) public onlyOwner {
    require(_regentAddress != regentAddress, "HOTM.setRegent: No regent rules forever");
    regentAddress = _regentAddress;
  }

  function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
    return 1;
  }

  /* Hero Operations */

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
    if (!revealed) return preRevealURI;
    string memory baseUri_ = _baseURI();
    uint256 shiftedTokenId = getShiftedToken(_tokenId);
    return
      bytes(baseUri_).length != 0
        ? string(abi.encodePacked(baseUri_, getGender(_tokenId), "_", Strings.toString(shiftedTokenId), ".json"))
        : "";
  }

  function getShiftedToken(uint256 _tokenId) public view returns (uint256) {
    return (_tokenId + offset) % totalSupply();
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function toggleGender(uint256 tokenId) external {
    require(isGenderSwapOn, "HOTM.toggleGender: Gender swap is not live");
    require(ownerOf(tokenId) == _msgSender(), "HOTM.toggleGender: You are not the owner");

    gender[tokenId] = compareStrings(getGender(tokenId), "male") ? "female" : "male";
  }

  function getGender(uint256 tokenId) public view returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return bytes(gender[tokenId]).length != 0 ? gender[tokenId] : "male";
  }

  function checkUpkeep(
    bytes calldata
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory
    )
  {
    upkeepNeeded = (block.timestamp - lastWithdraw) > withdrawInterval || (block.timestamp - lastRegent) > regentInterval;
  }

  // We use this to do auto-withdraws so the Regent keeps receiving eth periodically and to kick automatically for new elections
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    if ((block.timestamp - lastWithdraw) > withdrawInterval) {
      lastWithdraw = block.timestamp;
      withdraw();
    }
    if ((block.timestamp - lastRegent) > regentInterval) {
      lastRegent = block.timestamp;
      setRegent(owner());
    }
  }
}