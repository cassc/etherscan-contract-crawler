// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IMegNFT.sol";

import "./utils/OpenseaDelegate.sol";

abstract contract MegNFT is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, IMegNFT {
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PREMIUM_ROLE = keccak256("PREMIUM_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

  mapping(uint256 => uint256) private _ownTime;

  string public standardUri;
  string public premiumUri;

  address public proxyRegistryAddress;
  bool public isOpenSeaProxyActive;

  mapping(uint256 => uint256) public landType;
  mapping(uint256 => uint256) public time;

  uint256 public maximumPremiumCapacity;
  uint256 public maximumTotalCapicity;

  uint256 public totalLands;
  uint256 public totalPremiumLands;
  string public genesisUri;

  mapping(address => uint256) public walletCount;
  // @dev Price against each round
  uint256 public price;

  uint256[] public startDate;
  uint256[] public endDate;

  uint256 public round1Id;
  uint256 public round1EndId;

  uint256 public round2Id;
  uint256 public round2EndId;

  struct Promocode {
    uint256 maxCount;
    uint256 currentCount;
    uint256 discountPercentage;
  }
  mapping(address => Promocode) public promos;

  /// @dev Validator role
  bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

  /// @dev Time to get the NFT
  uint256 public receiveWindow;
  address public wallet;

  event Buy(address indexed user, uint256 id);
  event Buy(address indexed user, uint256[] ids);
  event Buy(address indexed user, uint256 _fromId, uint256 _toId);
  event CollectETHs(address sender, uint256 balance);
  event ChangeMintableNFT(address mintableNFT);

  event SetURI(string _standardUri, string _premiumUri, string _genesisUri);

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return
      _interfaceId == type(IMegNFT).interfaceId ||
      //_interfaceId == type(IMegCreator).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * @dev Upgradable initializer
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _standardUri URI string
   * @param _premiumUri URI string
   */
  function __MegNFT_init(
    string memory _name,
    string memory _symbol,
    string memory _standardUri,
    string memory _premiumUri
  ) internal initializer {
    __Ownable_init();
    __AccessControl_init();
    __ERC721_init(_name, _symbol);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    standardUri = _standardUri;
    premiumUri = _premiumUri;
    maximumTotalCapicity = 178_929;
    maximumPremiumCapacity = 35_786;

    _setupRole(VALIDATOR_ROLE, _msgSender());
    wallet = 0xad9E57901CF8a4346EB0964fA35B4209d2Da93e2;

    for (uint256 i = 0; i < 3; i++) {
      startDate.push(0);
      endDate.push(0);
    }
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (landType[tokenId] == 1) {
      return premiumUri;
    }

    if (landType[tokenId] == 2) {
      return standardUri;
    }

    return genesisUri;

  }

  /**
   * @notice Active opensea proxy - Emergency case
   * @dev This function is only callable by owner
   * @param _proxyRegistryAddress Address of opensea proxy
   * @param _isOpenSeaProxyActive Active opensea proxy by assigning true value
   */
  function activeOpenseaProxy(address _proxyRegistryAddress, bool _isOpenSeaProxyActive) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   * @dev This function is only callable by owner
   * @param _standardUri String of uri
   * @param _premiumUri String of uri
   */
  function setURI(
    string memory _standardUri,
    string memory _premiumUri,
    string memory _genesisUri
  ) external onlyOwner {
    standardUri = _standardUri;
    premiumUri = _premiumUri;
    genesisUri = _genesisUri;

    emit SetURI(_standardUri, _premiumUri, _genesisUri);
  }

  /**
   * @dev Mint a new NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _id Token id
   */
  function mint(address _to, uint256 _id) external override onlyRole(MINTER_ROLE) {
    _mint(_to, _id);
    time[_id] = block.timestamp;
    landType[_id] = 0;
    round1Id += 1;
  }

  /**
   * @dev Mint number of nft
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _count Total amount
   */
  function mintTo(address _to, uint256 _count) external override onlyRole(MINTER_ROLE) {
    for(uint256 i; i < _count; i++) {
      _mint(_to, round1Id);
      time[round1Id] = block.timestamp;
      landType[round1Id] = 0;
      round1Id += 1;
    }
  }

  /**
   * @dev Mint a Bulk NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _ids Ids to change types
   */
  function bulkMint(address _to, uint256[] memory _ids) external override onlyRole(MINTER_ROLE) {
    for (uint256 i = 0; i < _ids.length; i++) {
      _mint(_to, _ids[i]);
      time[_ids[i]] = block.timestamp;
      landType[_ids[i]] = 0;
    }
    round1Id += _ids.length;
  }

  /**
   * @dev Mint a Bulk NFT
   * @dev This function is only callable by owner
   * @param _to Address of the token owner
   * @param _fromId Mint from this ID
   * @param _toId Mint to this ID
   */
  function bulkMint(
    address _to,
    uint256 _fromId,
    uint256 _toId
  ) external override onlyRole(MINTER_ROLE) {
    for (uint256 i = _fromId; i <= _toId; i++) {
      _mint(_to, i);
      time[i] = block.timestamp;
      landType[i] = 0;
    }

    round1Id += _toId - _fromId + 1;
  }

  /**
   * @dev Change to premium NFT
   * @dev This function is only callable by premium role
   * @param _id Token id
   */
  function changeLandToPremium(uint256 _id) external override onlyRole(PREMIUM_ROLE) {
    landType[_id] = 1;
  }

  /**
   * @dev Bulk change to premium NFT
   * @dev This function is only callable by premium role
   * @param _ids Ids to change types
   */
  function bulkChangeLandToPremium(uint256[] memory _ids) external override onlyRole(PREMIUM_ROLE) {
    for (uint256 i = 0; i < _ids.length; i++) {
      landType[_ids[i]] = 1;
    }
  }

  /**
   * @dev Change to standard
   * @dev This function is only callable by premium role
   * @param _id Token id
   */
  function changeLandToStandard(uint256 _id) external override onlyRole(PREMIUM_ROLE) {
    landType[_id] = 2;
  }

  /**
   * @dev Bulk change to standard NFT
   * @dev This function is only callable by premium role
   * @param _ids Ids to change types
   */
  function bulkChangeLandToStandard(uint256[] memory _ids) external override onlyRole(PREMIUM_ROLE) {
    for (uint256 i = 0; i < _ids.length; i++) {
      landType[_ids[i]] = 2;
    }
  }

  /**
   * @dev Change to genesis
   * @dev This function is only callable by premium role
   * @param _id Token id
   */
  function changeLandToGenesis(uint256 _id) external override onlyRole(PREMIUM_ROLE) {
    landType[_id] = 0;
  }

  /**
   * @dev Bulk change to genesis NFT
   * @dev This function is only callable by premium role
   * @param _ids Ids to change types
   */
  function bulkChangeLandToGenesis(uint256[] memory _ids) external override onlyRole(PREMIUM_ROLE) {
    for (uint256 i = 0; i < _ids.length; i++) {
      landType[_ids[i]] = 0;
    }
  }

  /**
   * @notice Burn an NFT
   * @dev Burn an NFT by the token owner and Burner role
   * @param _id Token id
   */
  function burn(uint256 _id) external override {
    require(ownerOf(_id) == _msgSender() || hasRole(BURNER_ROLE, _msgSender()), "Only owner");
    _burn(_id);
  }

  /**
   * @dev Get own Time
   * @param _id token ID
   */
  function getOwnTime(uint256 _id) external view returns (uint256) {
    return _ownTime[_id];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   * @param _account Address of Owner
   * @param _operator Address of operator
   */
  function isApprovedForAll(address _account, address _operator) public view override returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (isOpenSeaProxyActive && address(proxyRegistry.proxies(_account)) == _operator) {
      return true;
    }

    return hasRole(APPROVER_ROLE, _operator) || super.isApprovedForAll(_account, _operator);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `_to` cannot be the zero address.
   * - `_tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal override {
    if (_tokenId <= 303) require(block.timestamp > time[_tokenId] + 365 days, "No Time");
    super._transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `_tokenId` must not exist.
   * - `_to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address _to, uint256 _tokenId) internal override {
    _ownTime[_tokenId] = block.timestamp;
    super._mint(_to, _tokenId);
  }

  /**
   * @dev Set wallet by owner
   * @param _wallet Wallet address
   */
  function setWallet(address _wallet) external onlyOwner {
    wallet = _wallet;
  }

  function withdrawFunds() external {
    payable(wallet).transfer(address(this).balance);
  }

  /**
   * @dev Update round ids
   * @dev This function is only callable by owner
   * @param _round1Id Start Id
   * @param _round1EndId End id
   */
  function setRound1Id(uint256 _round1Id, uint256 _round1EndId) external onlyOwner {
    round1Id = _round1Id;
    round1EndId = _round1EndId;
  }

  /**
   * @dev Update round 2 ids
   * @dev This function is only callable by owner
   * @param _round2Id Start Id
   * @param _round2EndId End id
   */
  function setRound2Id(uint256 _round2Id, uint256 _round2EndId) external onlyOwner {
    round2Id = _round2Id;
    round2EndId = _round2EndId;
  }

  /**
   * @dev Update Price
   * @dev This function is only callable by owner
   * @param _price New price of NFTs
   */
  function updatePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /**
   * @dev Update Date
   * @dev This function is only callable by owner
   * @param _start New start date of round
   * @param _end New end date of round
   * @param _round The round to update dates for
   */
  function updateDates(
    uint256 _start,
    uint256 _end,
    uint256 _round
  ) external onlyOwner {
    startDate[_round] = _start;
    endDate[_round] = _end;
  }

  /**
   * @dev Mint a new NFT for Round 1
   * @param _amount amount of NFT to buy
   */
  function round1Buy(uint256 _amount) public payable {
    require(block.timestamp >= startDate[1] && block.timestamp <= endDate[1], "Invalid time to buy");
    require(round1Id + _amount <= round1EndId, "not in the range");
    require(walletCount[msg.sender] + _amount <= 9, "max limit exceeded");
    if(promos[msg.sender].maxCount!=0){
      require(promos[msg.sender].maxCount - promos[msg.sender].currentCount >= _amount,"max limit exceed");

      uint256 discountedPrice = price - ((price * promos[msg.sender].discountPercentage) / 100);
      require(msg.value >= (discountedPrice * _amount), "invalid price");
      promos[msg.sender].currentCount = promos[msg.sender].currentCount + _amount;
    }else{
      require(msg.value >= price * _amount, "invalid price");
    }
    walletCount[msg.sender] = walletCount[msg.sender] + _amount;

    for (uint256 id = round1Id; id < round1Id + _amount; id++) {
      _ownTime[id] = block.timestamp;
      _mint(msg.sender, id);
    }

    round1Id = round1Id + _amount;
  }

  /**
   * @dev Mint a new NFT for Round 2
   * @param _amount amount of NFT
   */
  function round2Buy(uint256 _amount) public payable {
    require(block.timestamp >= startDate[2] && block.timestamp <= endDate[2], "Invalid time to buy");
    require(round2Id + _amount <= round2EndId, "not in the range");
    require(walletCount[msg.sender] + _amount <= 9, "max limit exceeded");
    if(promos[msg.sender].maxCount!=0){
      require(promos[msg.sender].maxCount - promos[msg.sender].currentCount >= _amount,"max limit exceed");

      uint256 discountedPrice = price - ((price * promos[msg.sender].discountPercentage) / 100);
      require(msg.value >= (discountedPrice * _amount), "invalid price");
      promos[msg.sender].currentCount = promos[msg.sender].currentCount + _amount;
    }else{
      require(msg.value >= price * _amount, "invalid price");
    }
    walletCount[msg.sender] = walletCount[msg.sender] + _amount;

    for (uint256 id = round2Id; id < round2Id + _amount; id++) {
      _ownTime[id] = block.timestamp;
      _mint(msg.sender, id);
    }

    round2Id = round2Id + _amount;
  }

  function updatePromo(
    address user,
    uint maxCount,
    uint percent
  ) public onlyOwner {
    promos[user] = Promocode(maxCount, 0, percent);
  }
}