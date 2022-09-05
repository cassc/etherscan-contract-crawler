// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './tokens/ERC721A.sol';
import './libraries/SSTORE2Map.sol';

import './SigmoidThreshold.sol';
import './RarityCompositingEngine.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract Merge is ERC721A, ERC2981, Ownable {
  using Strings for uint256;
  uint256 public MAX_MINTING_PER_BLOCK = 3;

  uint256 public deployDate;
  bool public isActive;
  SigmoidThreshold public curve;

  // Price Vars
  uint256 public a0;
  uint256 public b0;
  uint256 public c0;
  uint256 public d0;

  // Rarity Vars
  uint256 public a1;
  uint256 public b1;
  uint256 public c1;
  uint256 public d1;

  address public treasury;
  address public boostToken;

  // RCE
  RarityCompositingEngine public rce;

  uint256 public boostTokenBaseAmount = 1000;
  mapping(uint256 => uint256) public rarityTokenMap; // tokenID => rarityScore

  bool public emergencyShutdown = false;
  mapping(bytes32 => uint256) public blockMintingGuardMap; // hash(address + block number) => numMinted
  mapping(address => bool) public blacklistMap; // hash(address) => boolean

  event ChangedIsActive(bool isActive);
  event ChangedEmergencyShutdown(bool shutdown);

  struct DeployMergeNFTConfig {
    string name;
    string symbol;
    address treasury;
    address boostToken;
    address rce;
    address curve;
    uint256 a0;
    uint256 b0;
    uint256 c0;
    uint256 d0;
    uint256 a1;
    uint256 b1;
    uint256 c1;
    uint256 d1;
  }

  struct SetCurveParams {
    uint256 a0;
    uint256 b0;
    uint256 c0;
    uint256 d0;
    uint256 a1;
    uint256 b1;
    uint256 c1;
    uint256 d1;
  }

  constructor(DeployMergeNFTConfig memory config) ERC721A() {
    _name = config.name;
    _symbol = config.symbol;
    a0 = config.a0;
    b0 = config.b0;
    c0 = config.c0;
    d0 = config.d0;
    a1 = config.a1;
    b1 = config.b1;
    c1 = config.c1;
    d1 = config.d1;
    boostToken = config.boostToken;
    curve = SigmoidThreshold(config.curve);
    deployDate = block.timestamp;
    treasury = config.treasury;
    rce = RarityCompositingEngine(config.rce);
    //_transferOwnership(config.treasury);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getTokenBalance(address token, address userAddress)
    public
    view
    returns (uint256)
  {
    return IERC721(token).balanceOf(userAddress);
  }

  function currentIndex() public view returns (uint256) {
    return _currentIndex;
  }

  function setIsActive(bool _isActive) public onlyOwner {
    isActive = _isActive;
    emit ChangedIsActive(isActive);
  }

  function setEmergencyShutdown(bool shutdown) public onlyOwner {
    emergencyShutdown = shutdown;
    emit ChangedEmergencyShutdown(shutdown);
  }

  function setBlacklist(address[] memory _list) public onlyOwner {
    for (uint256 i = 0; i < _list.length; ++i) {
      blacklistMap[_list[i]] = true;
    }
  }

  function setRoyalty(uint96 newRoyaltyFraction) public onlyOwner {
    _setDefaultRoyalty(treasury, newRoyaltyFraction);
  }

  function setMaxMinting(uint256 _max) public onlyOwner {
    MAX_MINTING_PER_BLOCK = _max;
  }

  function setDeployDate(uint256 _date) public onlyOwner {
    deployDate = _date;
  }

  function setBoostToken(address _boostToken) public onlyOwner {
    boostToken = _boostToken;
  }

  function setBoostTokenBaseAmount(uint256 _amount) public onlyOwner {
    boostTokenBaseAmount = _amount;
  }

  function setTreasury(address _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setRCE(address _rce) public onlyOwner {
    rce = RarityCompositingEngine(_rce);
  }

  function setCurve(address _curve) public onlyOwner {
    curve = SigmoidThreshold(_curve);
  }

  function setCurveParams(SetCurveParams memory config) public onlyOwner {
    a0 = config.a0;
    b0 = config.b0;
    c0 = config.c0;
    a1 = config.a1;
    b1 = config.b1;
    c1 = config.c1;
  }

  // X variable in graph. Curve is tuned to
  function numSecondsSinceDeploy() public view returns (uint256) {
    return (block.timestamp - deployDate);
  }

  function isMergeByDifficulty() public view virtual returns (bool) {
    return (block.difficulty > (2**64)) || (block.difficulty == 0);
  }

  modifier onlyIsActive() {
    require(isActive, 'minting needs to be active to mint');
    _;
  }

  modifier onlyIsNotShutdown() {
    require(!emergencyShutdown, 'emergency shutdown is in place');
    _;
  }

  modifier onlyIsNotMerge() {
    require(
      !isMergeByDifficulty(),
      'minting needs to be done before Proof of Stake'
    );
    _;
  }

  function getBoostScore(address userAddress) external view returns (uint256) {
    uint256 balance = getTokenBalance(boostToken, userAddress);
    uint256 maxBalance = balance >= 16 ? 16 : balance;
    return maxBalance * boostTokenBaseAmount;
  }

  function getRarityScoreForToken(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    uint256 curr = tokenId;
    if (_startTokenId() <= curr && curr < _currentIndex) {
      while (true) {
        if (rarityTokenMap[curr] != 0) {
          return rarityTokenMap[curr];
        }
        curr--;
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  function getCurrentRarityScore(address userAddress)
    public
    view
    returns (uint256)
  {
    SigmoidThreshold.CurveParams memory config;
    config._x = numSecondsSinceDeploy();
    config.minX = a1;
    config.maxX = b1;
    config.minY = c1;
    config.maxY = d1;
    uint256 rarity = curve.getY(config);
    try this.getBoostScore(userAddress) returns (uint256 boost) {
      return rarity + boost;
    } catch {
      return rarity;
    }
  }

  function getCurrentPrice() public view returns (uint256) {
    SigmoidThreshold.CurveParams memory config;
    config._x = numSecondsSinceDeploy();
    config.minX = a0;
    config.maxX = b0;
    config.minY = c0;
    config.maxY = d0;
    uint256 price = curve.getY(config);
    return price; // in GWEI
  }

  function contractURI() public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              _name,
              '", "description": "A Proof of Beauty project. Fully on-chain generative statues to remember the MERGE.',
              '", "external_link": "https://merge.pob.studio/',
              '", "image": "https://merge.pob.studio/assets/logo.png" }'
            )
          )
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'URI query for nonexistent token');
    uint256 rarityScore = getRarityScoreForToken(tokenId);
    bytes memory seed = abi.encodePacked(rarityScore, tokenId);
    (, uint16[] memory attributeIndexes) = rce.getRarity(rarityScore, seed);
    string memory image = rce.getRender(attributeIndexes);

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name": "Statue #',
              tokenId.toString(),
              '", "description": "',
              'A Proof of Beauty project. Fully on-chain generative statues to remember the MERGE.',
              '", "image": "',
              image,
              '", "aspect_ratio": "1',
              '", "attributes": ',
              rce.getAttributesJSON(attributeIndexes),
              '}'
            )
          )
        )
      );
  }

  function mint(address to, uint256 numMints)
    public
    payable
    onlyIsActive
    onlyIsNotMerge
    onlyIsNotShutdown
  {
    bytes32 blockNumHash = keccak256(abi.encode(block.number, msg.sender));
    require(
      blockMintingGuardMap[blockNumHash] + numMints <= MAX_MINTING_PER_BLOCK,
      'exceeded max number of mints'
    );
    require(!blacklistMap[msg.sender], 'caller is blacklisted');
    uint256 totalPrice = getCurrentPrice() * numMints;
    require(totalPrice <= msg.value, 'insufficient funds to pay for mint');
    uint256 currentRarityScore = getCurrentRarityScore(msg.sender);
    rarityTokenMap[_currentIndex] = currentRarityScore;
    blockMintingGuardMap[blockNumHash] =
      blockMintingGuardMap[blockNumHash] +
      numMints;
    _mint(to, numMints, '', false);
    treasury.call{value: totalPrice}('');
    payable(msg.sender).transfer(msg.value - totalPrice);
  }
}