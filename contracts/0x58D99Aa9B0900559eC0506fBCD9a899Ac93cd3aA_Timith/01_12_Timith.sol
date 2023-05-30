// SPDX-License-Identifier: MIT

/*
__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\__/\\\\____________/\\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\________/\\\_        
 _\///////\\\/////__\/////\\\///__\/\\\\\\________/\\\\\\_\/////\\\///__\///////\\\/////__\/\\\_______\/\\\_       
  _______\/\\\___________\/\\\_____\/\\\//\\\____/\\\//\\\_____\/\\\___________\/\\\_______\/\\\_______\/\\\_      
   _______\/\\\___________\/\\\_____\/\\\\///\\\/\\\/_\/\\\_____\/\\\___________\/\\\_______\/\\\\\\\\\\\\\\\_     
    _______\/\\\___________\/\\\_____\/\\\__\///\\\/___\/\\\_____\/\\\___________\/\\\_______\/\\\/////////\\\_    
     _______\/\\\___________\/\\\_____\/\\\____\///_____\/\\\_____\/\\\___________\/\\\_______\/\\\_______\/\\\_   
      _______\/\\\___________\/\\\_____\/\\\_____________\/\\\_____\/\\\___________\/\\\_______\/\\\_______\/\\\_  
       _______\/\\\________/\\\\\\\\\\\_\/\\\_____________\/\\\__/\\\\\\\\\\\_______\/\\\_______\/\\\_______\/\\\_ 
        _______\///________\///////////__\///______________\///__\///////////________\///________\///________\///__
*/
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Timith is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  event MonthlyMinted(uint256 _id, uint256 _expiredTime);
  event LifetimeMinted(uint256 _id);
  event TokenRenewed(uint256 _id, uint256 _expiredTime);
  event TokenLocked(uint256 _id, address _receiver);

  using Strings for uint;
  using Counters for Counters.Counter;
  Counters.Counter public lifetimeMinted;
  Counters.Counter public monthlyMinted;
  struct MintInfo {
    uint256 price;
    uint256 supply;
    bool paused;
  }

  struct RenewalDiscount {
    bytes32 root;
    uint256 discount;
    bool valid;
  }

  struct LockInfo {
    bool locked;
    address receiver;
  }

  enum Phases {
    None,
    Partner,
    Whitelist,
    Public,
    Waitlist
  }

  enum TokenType {
    Monthly,
    Lifetime
  }

  bytes32 public partnerMerkleRoot;
  bytes32 public whitelistMerkleRoot;
  bytes32 public waitlistMerkleRoot;

  string private _tokenURI;

  address private dev = address(0);
  uint256 public renewPrice = 0.1 ether;

  Phases public currentPhase = Phases.None;

  bool public renewalsPaused = false;
  bool public transfersPaused = false;

  mapping(bytes32 => RenewalDiscount) public renewalDiscount;

  mapping(address => bool) public lifetimeEligible;

  mapping(address => bool) public hasMinted;
  mapping(uint256 => uint256) public expiryTime;
  mapping(uint256 => bool) private isLifetime;

  mapping(TokenType => MintInfo) public mintingInfo;
  mapping(uint256 => LockInfo) public lockedTokens;

  constructor() ERC721A("Timith", "TIMITH") {
    mintingInfo[TokenType.Monthly] = MintInfo(0.4 ether, 800, true);
    mintingInfo[TokenType.Lifetime] = MintInfo(1.5 ether, 200, true);

    _tokenURI = "https://timith.io/api/metadata/";
  }

  /**
   *
   *
   * MODIFIERS
   *
   */
  modifier onlyOwnerOrDev() {
    if (dev == address(0)) {
      require(_msgSender() == owner(), "Must be the owner");
    } else {
      require(_msgSender() == owner() || _msgSender() == dev, "Must be the owner or the dev");
    }
    _;
  }

  modifier callerIsUser() {
    require(tx.origin == _msgSender(), "The caller is another contract");
    _;
  }

  modifier lockCheck(uint256 tokenId, address _to) {
    if (lockedTokens[tokenId].locked && lockedTokens[tokenId].receiver != address(0)) {
      require(lockedTokens[tokenId].receiver == _to, "Token is locked. Contact owner in https://discord.gg/timith");
    }
    _;
  }

  modifier validateRenewPrice(bytes32 _key, bytes32[] calldata _proof) {
    if (_key == bytes32(0)) {
      require(msg.value == renewPrice, "Must send equal renew price");
      _;
    } else {
      RenewalDiscount storage discount = renewalDiscount[_key];
      require(discount.valid, "Discount is no longer valid");

      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_proof, discount.root, leaf), "You don't have access to this discount");
      require(msg.value == ((renewPrice * discount.discount) / 10000), "Must send equal renew price");
      _;
    }
  }

  modifier validateRenewToken(uint256 _tokenId) {
    require(!renewalsPaused, "The renewals are paused");
    require(_exists(_tokenId), "This token does not exist");
    require(!checkIfLifetime(_tokenId), "This token is a lifetime subscription");
    _;
  }

  modifier phaseLogicCheck(Phases _phase, bytes32[] calldata _merkleProof) {
    if (currentPhase == Phases.None) revert("You cannot mint during this phase");

    if (currentPhase == Phases.Public) {
      _;
    }

    if (_phase == Phases.Partner) {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, partnerMerkleRoot, leaf), "Invalid Partner proof!");
      _;
    } else if (_phase == Phases.Whitelist) {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Whitelist proof!");
      _;
    } else if (_phase == Phases.Waitlist) {
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, waitlistMerkleRoot, leaf), "Invalid Waitlist proof!");
      _;
    } else {
      revert("Not Eligible");
    }
  }

  modifier mintPriceCheck(TokenType _tokenType) {
    require(msg.value == mintingInfo[_tokenType].price, "Must send correct price");
    _;
  }

  modifier isAbleToMintLifetime() {
    require(!mintingInfo[TokenType.Lifetime].paused, "Lifetime Minting is Paused");
    require(!hasMinted[_msgSender()], "This wallet has already minted");
    require(lifetimeEligible[_msgSender()], "You are not eligable to mint lifetime");
    _;
  }

  modifier isAbleToMintMonthly() {
    require(!mintingInfo[TokenType.Monthly].paused, "Monthly Minting is Paused");
    require(!hasMinted[_msgSender()], "This wallet has already minted");
    _;
  }

  modifier lifetimeSupplyCheck() {
    lifetimeMinted.increment();
    require(lifetimeMinted.current() <= mintingInfo[TokenType.Lifetime].supply, "Lifetime supply has been minted");
    _;
  }

  modifier monthlySupplyCheck() {
    monthlyMinted.increment();
    require(monthlyMinted.current() <= mintingInfo[TokenType.Monthly].supply, "Monthly supply has been minted");
    _;
  }

  /**
   *
   *
   * Owner Functions
   *
   */
  function random() internal view returns (bytes32) {
    return keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp));
  }

  function createDiscount(RenewalDiscount memory discount) public onlyOwner returns (bytes32) {
    bytes32 randKey = random();

    renewalDiscount[randKey] = discount;
    return randKey;
  }

  function removeDiscount(bytes32 key) public onlyOwner {
    renewalDiscount[key].valid = false;
  }

  function vaultMint() public onlyOwner {
    require((lifetimeMinted.current() + 150) <= mintingInfo[TokenType.Lifetime].supply, "Will exceed supply");
    _safeMint(owner(), 150);
    lifetimeMinted._value += 150;
  }

  function setMerkleRoot(Phases _phase, bytes32 _merkleRoot) public onlyOwner {
    if (Phases.Partner == _phase) {
      partnerMerkleRoot = _merkleRoot;
    }
    if (Phases.Whitelist == _phase) {
      whitelistMerkleRoot = _merkleRoot;
    }
    if (Phases.Waitlist == _phase) {
      waitlistMerkleRoot = _merkleRoot;
    }
  }

  function addLifetimeEligibleWallets(address[] calldata _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      lifetimeEligible[_addresses[i]] = true;
    }
  }

  function removeLifetimeEligibleWallets(address[] calldata _addresses) public onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
      lifetimeEligible[_addresses[i]] = false;
    }
  }

  function setPhase(Phases _phase) public onlyOwner {
    require(_phase != currentPhase, "Choose a different phase");
    currentPhase = _phase;
  }

  function getDevWallet() public view onlyOwner returns (address) {
    return dev;
  }

  function withdrawBalance() public onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }

  function setDevWallet(address _devWallet) public onlyOwner returns (address) {
    require(_devWallet != address(0), "Address must no be zero");
    dev = _devWallet;
    return _devWallet;
  }

  function setRenewPrice(uint256 _renewPrice) public onlyOwner returns (uint256) {
    require(renewPrice != _renewPrice, "Pick a different renew Price");
    renewPrice = _renewPrice;
    return _renewPrice;
  }

  function updateMintSupply(TokenType _type, uint256 _supply) public onlyOwner {
    require(mintingInfo[_type].supply != _supply, "Pick a different Supply");
    mintingInfo[_type].supply = _supply;
  }

  function updateMintPauseStatus(TokenType _type, bool _paused) public onlyOwner {
    mintingInfo[_type].paused = _paused;
  }

  function updateMintPrice(TokenType _type, uint256 _price) public onlyOwner {
    mintingInfo[_type].price = _price;
  }

  function setTokenURI(string calldata _newURI) external onlyOwner {
    _tokenURI = _newURI;
  }

  function onlyOwnerMintLifetime(address _receiver) public onlyOwner lifetimeSupplyCheck {
    mint(_receiver, TokenType.Lifetime);
  }

  function onlyOwnerMintMonthly(address _receiver) public onlyOwner monthlySupplyCheck {
    mint(_receiver, TokenType.Monthly);
  }

  function ownerBatchMintMonthly(address[] calldata _addresses) public onlyOwner {
    uint256 quantity = _addresses.length;
    for (uint256 i = 0; i < quantity; ) {
      onlyOwnerMintMonthly(_addresses[i]);
      unchecked {
        ++i;
      }
    }
  }

  function ownerBatchMintLifetime(address[] calldata _addresses) public onlyOwner {
    uint256 quantity = _addresses.length;
    for (uint256 i = 0; i < quantity; ) {
      onlyOwnerMintMonthly(_addresses[i]);
      unchecked {
        ++i;
      }
    }
  }

  function ownerRenewToken(uint256 _tokenId) public onlyOwnerOrDev {
    require(_exists(_tokenId), "This token does not exist");
    require(!checkIfLifetime(_tokenId), "This token is a lifetime subscription");

    _renewToken(_tokenId);
  }

  function ownerBatchRenewToken(uint256[] calldata _batchIds) public onlyOwnerOrDev {
    uint256 tokenIds = _batchIds.length;
    uint256 i = 0;
    for (i; i < tokenIds; ) {
      ownerRenewToken(_batchIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * Pausing renewals are less impactful, but we are keeping pause transfers to be the owner
   */

  function pauseRenewals(bool _paused) external onlyOwnerOrDev returns (bool) {
    renewalsPaused = _paused;
    return _paused;
  }

  function pauseTransfers(bool _paused) external onlyOwner returns (bool) {
    transfersPaused = _paused;
    return _paused;
  }

  function revokeDev() public onlyOwner {
    dev = address(0);
  }

  function lockToken(uint256 _tokenId, address _receiver) public onlyOwnerOrDev {
    require(_receiver != address(0), "Receiver must not be zero address");
    lockedTokens[_tokenId] = LockInfo(true, _receiver);
    emit TokenLocked(_tokenId, _receiver);
  }

  function unLockToken(uint256 _tokenId) public onlyOwnerOrDev {
    lockedTokens[_tokenId] = LockInfo(false, address(0));
    emit TokenLocked(_tokenId, address(0));
  }

  function checkIfLifetime(uint256 _tokenId) public view returns (bool) {
    require(_exists(_tokenId), "Token does not exist");
    return _tokenId <= 150 ? true : isLifetime[_tokenId];
  }

  /**
   *
   *
   * Minting Logic
   *
   */

  function mint(address _receiver, TokenType _tokenType) private {
    uint256 id = _nextTokenId();

    _mintToken(_tokenType, _receiver, id);
  }

  function mint(TokenType _tokenType) private {
    uint256 id = _nextTokenId();

    _mintToken(_tokenType, _msgSender(), id);
  }

  function _mintToken(TokenType _tokenType, address _receiver, uint256 id) private {
    _safeMint(_receiver, 1);
    hasMinted[_receiver] = true;

    if (TokenType.Lifetime == _tokenType) {
      isLifetime[id] = true;
      emit LifetimeMinted(id);
    } else {
      expiryTime[id] = block.timestamp + 30 days;
      emit MonthlyMinted(id, expiryTime[id]);
    }
  }

  function mintMonthly(
    Phases _phase,
    bytes32[] calldata proof
  ) public payable callerIsUser nonReentrant phaseLogicCheck(_phase, proof) mintPriceCheck(TokenType.Monthly) isAbleToMintMonthly monthlySupplyCheck {
    mint(TokenType.Monthly);
  }

  function mintLifetime(
    Phases _phase,
    bytes32[] calldata proof
  ) public payable callerIsUser nonReentrant phaseLogicCheck(_phase, proof) mintPriceCheck(TokenType.Lifetime) isAbleToMintLifetime lifetimeSupplyCheck {
    mint(TokenType.Lifetime);
  }

  /**
   *
   * Renew Logic
   *
   */

  function _renewToken(uint256 _tokenId) private {
    bool tokenExpired = block.timestamp > expiryTime[_tokenId];

    if (tokenExpired) {
      expiryTime[_tokenId] = block.timestamp + 30 days;
    } else {
      expiryTime[_tokenId] += 30 days;
    }
    emit TokenRenewed(_tokenId, expiryTime[_tokenId]);
  }

  function renewToken(
    uint256 _tokenId,
    bytes32 _key,
    bytes32[] calldata _proof
  ) public payable callerIsUser validateRenewToken(_tokenId) validateRenewPrice(_key, _proof) {
    _renewToken(_tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _tokenURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
   *
   * OS Required Overrides
   *
   */

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) lockCheck(tokenId, to) {
    require(!transfersPaused, "Transfers are paused");
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) lockCheck(tokenId, to) {
    require(!transfersPaused, "Transfers are paused");
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override onlyAllowedOperator(from) lockCheck(tokenId, to) {
    require(!transfersPaused, "Transfers are paused");
    super.safeTransferFrom(from, to, tokenId, data);
  }
}