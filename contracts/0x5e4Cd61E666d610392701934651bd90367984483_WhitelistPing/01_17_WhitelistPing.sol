// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../../Common/Merkle.sol";


interface ILlamaBoost{
  function balanceOfBatch(address[2] calldata accounts, uint256[2] calldata id) external view returns(uint256[] memory);
}

interface ILlamaVerse{
  function balanceOf(address) external view returns(uint256);
}

interface ILlamaZoo{
  struct Staker {
    uint256[] stakedLlamas;
    uint256 stakedPixletCanvas;
    uint256 stakedLlamaDraws;
    uint128 stakedSilverBoosts;
    uint128 stakedGoldBoosts;
  }

  function userInfo(address) external view returns (Staker memory);
}

contract WhitelistPing is ERC721AQueryable, OperatorFilterer, Merkle {
  using Address for address;

  enum SaleState{
    NONE,
    LLAMASALE, //1
    LISTSALE,  //2
    PUBLICSALE //3
  }

  struct MintConfig{
    uint64 ethPrice;
    uint64 discPrice;
    uint64 boostPrice;

    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  MintConfig public config = MintConfig(
    0.12 ether, //ethPrice
    0.10 ether, //discPrice
    0.09 ether, //boostPrice
       1,      //maxMint
       3,      //maxOrder
    8000,      //maxSupply

    SaleState.NONE
  );

  uint256 constant MAX_SUPPLY = 8000;
  bool public isOSEnabled = true;
  uint32 public lockReleaseDate;
  string public tokenURIPrefix;
  string public tokenURISuffix;
  ILlamaBoost public llamaBoost = ILlamaBoost(0x0BD4D37E0907C9F564aaa0a7528837B81B25c605);
  ILlamaVerse public llamaVerse = ILlamaVerse(0x9df8Aa7C681f33E442A0d57B838555da863504f3);
  ILlamaZoo public llamaZoo = ILlamaZoo(0x48193776062991c2fE024D9c99C35576A51DaDe0);

  mapping(uint256 => bool) public tokensUsed;

  modifier onlyAllowedOperator(address from) override {
    if (isOSEnabled && from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) override {
    if(isOSEnabled){
      _checkFilterOperator(operator);
    }
    _;
  }

  constructor()
    ERC721A("WhitelistPing", "WLP" )
    OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
  {
    lockReleaseDate = uint32(block.timestamp + 90 days);
  }

  //safety first
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}


  //payable
  function mint(uint16 quantity, bytes32[] calldata proof) external payable {
    MintConfig memory cfg = config;
    require(uint8(cfg.saleState) > 0, "Sale is not active");
    require(_numberMinted( msg.sender ) + quantity <= cfg.maxMint, "Mint/Order exceeds wallet limit");
    require(quantity <= cfg.maxOrder, "Order too big");
    require(totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply");

    uint256 usePrice;
    bool isLlamaverse = cfg.saleState == SaleState.LLAMASALE;
    if(cfg.saleState == SaleState.PUBLICSALE){
      usePrice = _getPrice(msg.sender, cfg.ethPrice);
    }
    else{
      if(_isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof))
        usePrice = _getPrice(msg.sender, cfg.discPrice);
      else
        revert( "Wallet is not on the list" );
    }

    require(msg.value == quantity * usePrice, "Ether sent is not correct");
    _mintBatch(msg.sender, quantity, isLlamaverse);
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient, bool isLlamaverse) external payable onlyDelegates{
    require(quantity.length == recipient.length, "must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    for(uint256 i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    uint256 tokenId = totalSupply();
    require( tokenId + totalQuantity <= config.maxSupply, "mint/order exceeds supply" );

    for(uint256 i = 0; i < recipient.length; ++i){
      _mintBatch( recipient[i], quantity[i], isLlamaverse );
    }
  }

  function setConfig(MintConfig memory newConfig) public onlyDelegates{
    MintConfig memory cfg = config;
    require(totalSupply() <= newConfig.maxSupply, "existing supply must be lte new max supply");
    require(cfg.maxSupply >= newConfig.maxOrder, "existing max supply must be gte new max order");
    require(5 > uint8(newConfig.saleState), "invalid sale state");

    if(newConfig.saleState == SaleState.LLAMASALE)
      require(newConfig.maxSupply <= 4000, "supply exceeds llamaverse limit");
    else
      require(newConfig.maxSupply <= MAX_SUPPLY, "supply exceeds global limit");

    config = newConfig;
  }


  function setLlamaSale() external onlyDelegates{
    MintConfig memory tempConfig = MintConfig(
      0.12 ether, //ethPrice
      0.10 ether, //discPrice
      0.09 ether, //boostPrice
         1,       //maxMint
         1,       //maxOrder
      4000,       //maxSupply

      SaleState.LLAMASALE
    );
    setConfig(tempConfig);
  }

  function setListSale() external onlyDelegates{
    MintConfig memory tempConfig = MintConfig(
      0.12 ether, //ethPrice
      0.10 ether, //discPrice
      0.09 ether, //boostPrice
         1,       //maxMint
         1,       //maxOrder
      8000,       //maxSupply

      SaleState.LISTSALE
    );
    setConfig(tempConfig);
  }

  function setPublicSale() external onlyDelegates{
    MintConfig memory tempConfig = MintConfig(
      0.12 ether, //ethPrice
      0.10 ether, //discPrice
      0.09 ether, //boostPrice
         3,       //maxMint
         3,       //maxOrder
      8000,       //maxSupply

      SaleState.PUBLICSALE
    );
    setConfig(tempConfig);
  }

  function setLlamaProxies(ILlamaBoost boost, ILlamaVerse verse, ILlamaZoo zoo) external onlyDelegates{
    llamaBoost = boost;
    llamaVerse = verse;
    llamaZoo = zoo;
  }

  function setLockExpiration(uint32 timestamp) external onlyDelegates{
    if (lockReleaseDate == 0) 
      lockReleaseDate = timestamp;
    else if(timestamp != 0 && timestamp < lockReleaseDate)
      lockReleaseDate = timestamp;
  }

  function setOsStatus(bool isEnabled) external onlyDelegates{
    isOSEnabled = isEnabled;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }


  //view
  function getPrice(address account) public view returns(uint256) {
    if(config.saleState == SaleState.LLAMASALE)
      return _getPrice(account, config.discPrice);
    else if(config.saleState == SaleState.LISTSALE)
      return _getPrice(account, config.discPrice);
    else
      return _getPrice(account, config.ethPrice);
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) public view override(IERC721A, ERC721A) returns( string memory ) {
    require(_exists(tokenId), "query for nonexistent token");
    return bytes(tokenURIPrefix).length > 0 ?
      string(abi.encodePacked(tokenURIPrefix, _toString(tokenId), tokenURISuffix)) :
      "";
  }


  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "no funds available");

    uint256 totalBalance = address(this).balance;
    uint256 payeeBalanceTwo   = totalBalance * 25 / 1000;
    uint256 payeeBalanceOne   = totalBalance - payeeBalanceTwo;

    Address.sendValue(payable(owner()), payeeBalanceOne);
    Address.sendValue(payable(0x39A29810e18F65FD59C43c8d2D20623C71f06fE1), payeeBalanceTwo);
  }


  //internal
  function _countLlamaBoost(address account) private view returns(uint256) {
    if(address(llamaBoost) != address(0)){
      uint256[] memory counts = llamaBoost.balanceOfBatch([account, account], [uint256(1), uint56(2)]);
      return counts[0] + counts[1];
    }
    else
      return 0;
  }

  function _countLlamaVerse(address account) private view returns(uint256) {
    if(address(llamaVerse) != address(0))
      return llamaVerse.balanceOf(account);
    else
      return 0;
  }

  function _countLlamaZooBoost(address account) private view returns(uint256) {
    if(address(llamaZoo) != address(0)){
      ILlamaZoo.Staker memory staker = llamaZoo.userInfo(account);
      return staker.stakedSilverBoosts + staker.stakedGoldBoosts;
    }
    else
      return 0;
  }

  function _countLlamaZooVerse(address account) private view returns(uint256) {
    if(address(llamaZoo) != address(0)){
      return llamaZoo.userInfo(account).stakedLlamas.length;
    }
    else
      return 0;
  }

  function _getPrice(address account, uint256 maxPrice) internal view returns(uint256) {
    if(maxPrice == config.ethPrice){
      if(_countLlamaVerse(account) > 0)
        maxPrice = config.discPrice;
      else if(_countLlamaZooVerse(account) > 0)
        maxPrice = config.discPrice;
    }

    if(maxPrice == config.discPrice){
      if(_countLlamaBoost(account) > 0)
        maxPrice = config.boostPrice;
      else if(_countLlamaZooBoost(account) > 0)
        maxPrice = config.boostPrice;
    }

    return maxPrice;
  }

  function _mintBatch(address to, uint16 quantity, bool isLlamaVerse) internal {
    uint256 tokenId;
    while( quantity > 0 ){
      tokenId = _nextTokenId();

      if( quantity > 4 ){
        _mint( to, 5 );
        if( isLlamaVerse )
          _setExtraDataAt( tokenId, 1 );

        quantity -= 5;
      }
      else{
        _mint( to, quantity );
        if( isLlamaVerse )
          _setExtraDataAt( tokenId, 1 );

        break;
      }
    }
  }


  //OS overrides
  function approve(address operator, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(IERC721A, ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A) onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function transferFrom(address from, address to, uint256 tokenId)
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperator(from)
  {
    if( uint32(block.timestamp) < lockReleaseDate && _ownershipAt( tokenId ).extraData > 0 )
      revert( "Private sale tokens temporarily locked" );

    super.transferFrom(from, to, tokenId);
  }
}