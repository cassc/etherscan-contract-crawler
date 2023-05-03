//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./MGYREWARD.sol";
import "./ERC4906.sol";

contract MGYERC721A is Ownable,ERC4907A, ReentrancyGuard, ERC2981,OperatorFilterer,ERC4906{

  //Project Settings
  uint256 public wlMintPrice;//wl.price.
  uint256 public wlMintPrice1;//wl1.price.
  uint256 public wlMintPrice2;//wl2.price.
  uint256 public psMintPrice;//publicSale. price.
  uint256 public bmMintPrice;//Burn&MintSale. price.
  uint256 public hmMintPrice;//Hold&MintSale. price.
  uint256 public maxMintsCapPerWL;//WhitelistSale.max mint cap per wallet.
  uint256 public maxMintsPerPS;//publicSale.max mint num per wallet.
  uint256 public maxMintsPerBM;//Burn&MintSale.max mint num per wallet.
  uint256 public maxMintsPerHM;//Hold&MintSale.max mint num per wallet.
  uint256 public otherContractCount;//Hold(burn)&MintSale must hold otherContract count.
  uint256 public otherContractCountGenesis;//burn&MintSale must hold otherContractGenesis count.
  
  uint256 public maxSupply;//max supply
  address payable internal _withdrawWallet;//withdraw wallet
  bool public isSBTEnabled;//SBT(can not transfer.only owner) mode enable.

  //URI
  mapping(uint256 => string) internal _revealUri;//by Season
  mapping(uint256 => string) internal _baseTokenURI;//by Season
  //flags
  bool public isWlEnabled;//WL enable.
  mapping(uint256 => bool) public isWlNumDisabled;//WL,1,2 disable.
  bool public isPsEnabled;//PublicSale enable.
  bool public isBmEnabled;//Burn&MintSale enable.
  bool public isHmEnabled;//Hold&MintSale enable.
  bool public isStakingEnabled;//Staking enable.
  mapping(uint256 => bool) internal _isRevealed;//reveal enable.by Season.
  //mint records.
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _wlMinted;//wl.minted num by wallet.by Season.by reset index
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _wlMinted1;//wl1.minted num by wallet.by Season.by reset index
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _wlMinted2;//wl2.minted num by wallet.by Season.by reset index
  mapping(uint256 => mapping(address => uint256)) internal _psMinted;//PublicSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(address => uint256)) internal _bmMinted;//Burn&MintSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(address => uint256)) internal _hmMinted;//Hold&MintSale.mint num by wallet.by Season.
  mapping(uint256 => mapping(uint256 => bool)) internal _otherTokenidUsed;//Hold&MintSale.otherCOntract's tokenid used .by Season.
  uint256 internal _wlResetIndex;   //_wlMinted value reset index.

  //Season value.
  uint256 internal _seasonCounter;   //Season Counter.
  mapping(uint256 => uint256) public seasonStartTokenId;//Start tokenid by Season.

  //contract status.for UI/UX frontend.
  uint256 internal _contractStatus;

  //merkleRoot
  bytes32 internal _merkleRoot;//whitelist
  bytes32 internal _merkleRoot1;//whitelist1
  bytes32 internal _merkleRoot2;//whitelist2
  //custom token uri
  mapping(uint256 => string) internal _customTokenURI;//custom tokenURI by tokenid
  //metadata file extention
  string internal _extension;
  //otherContract
  address public otherContract;//with Burn&MintSale or Hold&Mint.
  MGYERC721A internal _otherContractFactory;//otherContract's factory
  address public otherContractGenesis;//with Burn&MintSaleWithGenesis.
  MGYERC721A internal _otherContractGenesisFactory;//otherContractGenesis's factory
  //staking
  mapping(uint256 => uint256) internal _stakingStartedTimestamp; // tokenId -> staking start time (0 = not staking).
  mapping(uint256 => uint256) internal _stakingTotalTime; // tokenId -> cumulative staking time, does not include current time if staking
  mapping(uint256 => uint256) internal _claimedLastTimestamp; // tokenId -> last claimed timestamp
  uint256 internal constant NULL_STAKED = 0;
  address public rewardContract;//reward contract address
  MGYREWARD internal _rewardContractFactory;//reward Contract's factory
  uint256 public stakingStartTimestamp;//staking start timestamp
  uint256 public stakingEndTimestamp;//staking end timestamp
  //Opensea Filter
  bool public operatorFilteringEnabled;

  constructor (
      string memory _name,
      string memory _symbol
  ) ERC721A (_name,_symbol) {
    seasonStartTokenId[_seasonCounter] = _startTokenId();
    _extension = "";
    _registerForOperatorFiltering();
  }
  //start from 1.adjust for bueno.
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external virtual onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }
  //for ERC2981,ERC721A.ERC4907A,ERC4906
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4907A, ERC2981, ERC4906) returns (bool) {
    return(
      ERC721A.supportsInterface(interfaceId) || 
      ERC4907A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId) ||
      ERC4906.supportsInterface(interfaceId) 
    );
  }
  //for ERC2981 Opensea
  function contractURI() external view virtual returns (string memory) {
        return _formatContractURI();
  }
  //make contractURI
  function _formatContractURI() internal view returns (string memory) {
    (address receiver, uint256 royaltyFraction) = royaltyInfo(0,_feeDenominator());//tokenid=0
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
                '{"seller_fee_basis_points":', Strings.toString(royaltyFraction),
                ', "fee_recipient":"', Strings.toHexString(uint256(uint160(receiver)), 20), '"}'
            )
          )
        )
      )
    );
  }
  //set owner's wallet.withdraw to this wallet.only owner.
  function setWithdrawWallet(address _owner) external virtual onlyOwner {
    _withdrawWallet = payable(_owner);
  }

  //set maxSupply.only owner.
  function setMaxSupply(uint256 _maxSupply) external virtual onlyOwner {
    require(totalSupply() <= _maxSupply, "Lower than _currentIndex.");
    maxSupply = _maxSupply;
  }
  //set wl price.only owner.
  function setWlPrice(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice = newPrice;
  }
  //set wl1 price.only owner.
  function setWlPrice1(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice1 = newPrice;
  }
  //set wl2 price.only owner.
  function setWlPrice2(uint256 newPrice) external virtual onlyOwner {
    wlMintPrice2 = newPrice;
  }
  //set public Sale price.only owner.
  function setPsPrice(uint256 newPrice) external virtual onlyOwner {
    psMintPrice = newPrice;
  }
  //set Burn&MintSale price.only owner.
  function setBmPrice(uint256 newPrice) external virtual onlyOwner {
    bmMintPrice = newPrice;
  }
  //set Hold&MintSale price.only owner.
  function setHmPrice(uint256 newPrice) external virtual onlyOwner {
    hmMintPrice = newPrice;
  }
  //set reveal.only owner.current season.
  function setReveal(bool bool_) external virtual onlyOwner {
    _isRevealed[_seasonCounter] = bool_;
  }
  //set reveal.only owner.by season.
  function setRevealBySeason(bool bool_,uint256 _season) external virtual onlyOwner {
    _isRevealed[_season] = bool_;
  }

  //return _isRevealed.current season.
  function isRevealed() external view virtual returns (bool){
    return _isRevealed[_seasonCounter];
  }
  //return _isRevealed.by season.
  function isRevealedBySeason(uint256 _season) external view virtual returns (bool){
    return _isRevealed[_season];
  }

  //return _wlMinted.current season.
  function wlMinted(address _address) external view virtual returns (uint256){
    return _wlMinted[_seasonCounter][_address][_wlResetIndex];
  }
  //return _wlMinted.by season.
  function wlMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _wlMinted[_season][_address][_wlResetIndex];
  }
  //return _wlMinted.current season.
  function wlMinted1(address _address) external view virtual returns (uint256){
    return _wlMinted1[_seasonCounter][_address][_wlResetIndex];
  }
  //return _wlMinted.by season.
  function wlMintedBySeason1(address _address,uint256 _season) external view virtual returns (uint256){
    return _wlMinted1[_season][_address][_wlResetIndex];
  }
  //return _wlMinted.current season.
  function wlMinted2(address _address) external view virtual returns (uint256){
    return _wlMinted2[_seasonCounter][_address][_wlResetIndex];
  }
  //return _wlMinted.by season.
  function wlMintedBySeason2(address _address,uint256 _season) external view virtual returns (uint256){
    return _wlMinted2[_season][_address][_wlResetIndex];
  }

  //return _psMinted.current season.
  function psMinted(address _address) external view virtual returns (uint256){
    return _psMinted[_seasonCounter][_address];
  }
  //return _psMinted.by season.
  function psMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _psMinted[_season][_address];
  }

  //return _bmMinted.current season.
  function bmMinted(address _address) external view virtual returns (uint256){
    return _bmMinted[_seasonCounter][_address];
  }
  //return _bmMinted.by season.
  function bmMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _bmMinted[_season][_address];
  }

  //return _hmMinted.current season.
  function hmMinted(address _address) external view virtual returns (uint256){
    return _hmMinted[_seasonCounter][_address];
  }
  //return _hmMinted.by season.
  function hmMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _hmMinted[_season][_address];
  }

  //set WhitelistSale's max mint Cap num.only owner.
  function setWlMaxMintsCap(uint256 _max) external virtual onlyOwner {
    maxMintsCapPerWL = _max;
  }
  //set PublicSale's max mint num.only owner.
  function setPsMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerPS = _max;
  }
  //set Burn&MintSale's max mint num.only owner.
  function setBmMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerBM = _max;
  }
  //set Hold&MintSale's max mint num.only owner.
  function setHmMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerHM = _max;
  }
  //set otherContract count with Hold(burn)&Mint.only owner.
  function setOtherContractCount(uint256 _count) external virtual onlyOwner {
    otherContractCount = _count;
  }
  //set _otherTokenidUsed with Hold&Mint.only owner.
  function setOtherTokenidUsed(uint256 _tokenId,bool bool_) external virtual onlyOwner {
    require(_otherContractFactory.ownerOf(_tokenId) != address(0), "nonexistent token");
    _otherTokenidUsed[_seasonCounter][_tokenId] = bool_;
  }
  //set _otherTokenidUsed with Hold&Mint by season .only owner.
  function setOtherTokenidUsedBySeason(uint256 _tokenId,bool bool_,uint256 _season) external virtual onlyOwner {
    require(_otherContractFactory.ownerOf(_tokenId) != address(0), "nonexistent token");
    _otherTokenidUsed[_season][_tokenId] = bool_;
  }
  //return _otherTokenidUsed
  function getOtherTokenidUsed(uint256 _tokenId) external view virtual returns (bool){
    return _otherTokenidUsed[_seasonCounter][_tokenId];
  }
  //return _otherTokenidUsed.by Season
  function getOtherTokenidUsedBySeason(uint256 _tokenId,uint256 _season) external view virtual returns (bool){
    return _otherTokenidUsed[_season][_tokenId];
  }
    
  //set WLsale.only owner.
  function setWhitelistSale(bool bool_) external virtual onlyOwner {
    isWlEnabled = bool_;
  }
  //set disable WLsale.only owner.
  function setDisabledPartWhitelistSale(uint256 _wlNum,bool bool_) external virtual onlyOwner {
    isWlNumDisabled[_wlNum] = bool_;
  }
  //set Publicsale.only owner.
  function setPublicSale(bool bool_) external virtual onlyOwner {
    isPsEnabled = bool_;
  }
  //set Burn&MintSale.only owner.
  function setBurnAndMintSale(bool bool_) external virtual onlyOwner {
    isBmEnabled = bool_;
  }
  //set Hold&MintSale.only owner.
  function setHoldAndMintSale(bool bool_) external virtual onlyOwner {
    isHmEnabled = bool_;
  }

  //set MerkleRoot.only owner.
  function setMerkleRoot(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot = merkleRoot_;
  }
  //set MerkleRoot.only owner.
  function setMerkleRoot1(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot1 = merkleRoot_;
  }
  //set MerkleRoot.only owner.
  function setMerkleRoot2(bytes32 merkleRoot_) external virtual onlyOwner {
    _merkleRoot2 = merkleRoot_;
  }
  //isWhitelisted
  function isWhitelisted(address address_, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) external view virtual returns (bool) {
    (bool ret,) = _isWhitelisted(address_,maxmint_,proof_,proof1_,proof2_);
    return(ret);
  }
  function _isWhitelisted(address address_,uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) internal view  returns (bool,uint256) {
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return(true,0); 
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_)) return(true,1); 
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)) return(true,2); 
    return(false,9999);
  }
  //get WL maxMints.
  function getWhitelistedMaxMints(address address_, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) external view virtual returns (uint256) {
    return(_getWhitelistedMaxMints(address_, maxmint_, proof_, proof1_, proof2_));
  }
  function _getWhitelistedMaxMints(address address_, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) internal view  returns (uint256) {
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return maxmint_;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_)) return maxmint_;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)) return maxmint_;
    return 0;
  }
  //have you WL?
  function hasWhitelistedOneWL(address address_,uint256 maxmint_, bytes32[] calldata proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_));
  }
  function _hasWhitelistedOneWL(address address_,uint256 maxmint_,bytes32 root_, bytes32[] calldata proof_) internal view returns (bool) {
    if(maxmint_ > maxMintsCapPerWL)return false;//check exceed maxmint cap
    bytes32 _leaf = keccak256(abi.encodePacked(address_,maxmint_));
    return(root_ != 0x0 && MerkleProof.verifyCalldata(proof_,root_,_leaf));
  }
  //have you WL1?
  function hasWhitelistedOneWL1(address address_,uint256 maxmint_,bytes32[] calldata proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof_));
  }
  //have you WL2?
  function hasWhitelistedOneWL2(address address_,uint256 maxmint_,bytes32[] calldata proof_) external view virtual returns (bool) {
    return(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof_));
  }
  //get WL price.
  function getWhitelistedPrice(address address_, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) external view virtual returns (uint256) {
    return(_getWhitelistedPrice(address_, maxmint_, proof_, proof1_, proof2_));
  }
  function _getWhitelistedPrice(address address_, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) internal view  returns (uint256) {
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return wlMintPrice;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof1_)) return wlMintPrice1;
    if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof2_)) return wlMintPrice2;
    return 9999 ether;
  }
  
  //get WL all status
  function getWhitelistedStatus(uint256 wlNum_,address address_, uint256 maxmint_,bytes32[] calldata proof_) external view returns (bool,uint256,uint256,bool,uint256) {
    if(wlNum_ == 0){
      if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot,proof_)) return(isWlNumDisabled[0],wlMintPrice,_wlMinted[_seasonCounter][address_][_wlResetIndex],true,maxmint_);
      else return(isWlNumDisabled[0],wlMintPrice,_wlMinted[_seasonCounter][address_][_wlResetIndex],false,0);
    }else if(wlNum_ == 1){
      if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot1,proof_)) return(isWlNumDisabled[1],wlMintPrice1,_wlMinted1[_seasonCounter][address_][_wlResetIndex],true,maxmint_);
      else return(isWlNumDisabled[1],wlMintPrice1,_wlMinted1[_seasonCounter][address_][_wlResetIndex],false,0);
    }else if(wlNum_ == 2){
      if(_hasWhitelistedOneWL(address_,maxmint_,_merkleRoot2,proof_))return(isWlNumDisabled[2],wlMintPrice2,_wlMinted2[_seasonCounter][address_][_wlResetIndex],true,maxmint_);
      else return(isWlNumDisabled[2],wlMintPrice2,_wlMinted2[_seasonCounter][address_][_wlResetIndex],false,0);
    }
    return (false, 0, 0, false, 0);
  }
  

  //set SBT mode Enable. only owner.Noone can transfer. only contract owner can transfer.
  function setSBTMode(bool bool_) external virtual onlyOwner {
    isSBTEnabled = bool_;
  }
  //override for SBT mode.only owner can transfer. or mint or burn.
  function _beforeTokenTransfers(address from_,address to_,uint256 startTokenId_,uint256 quantity_) internal virtual override {
    require(!isSBTEnabled || msg.sender == owner() || from_ == address(0) || to_ == address(0) ,"SBT mode Enabled: token transfer while paused.");

    //check tokenid transfer
    for (uint256 tokenId = startTokenId_; tokenId < startTokenId_ + quantity_; tokenId++) {
      //check staking
      require(!isStakingEnabled || _stakingStartedTimestamp[tokenId] == NULL_STAKED,"Staking now.: token transfer while paused.");

      //unstake if staking
      if (_stakingStartedTimestamp[tokenId] != NULL_STAKED) {
        //accum current time
        uint256 deltaTime = block.timestamp - _stakingStartedTimestamp[tokenId];
        _stakingTotalTime[tokenId] += deltaTime;
        //no longer staking
        _stakingStartedTimestamp[tokenId] = NULL_STAKED;
        _claimedLastTimestamp[tokenId] = NULL_STAKED;

      }
    }
    super._beforeTokenTransfers(from_, to_, startTokenId_, quantity_);
  }

  //set HiddenBaseURI.only owner.current season.
  function setHiddenBaseURI(string memory uri_) external virtual onlyOwner {
    _revealUri[_seasonCounter] = uri_;
  }
  //set HiddenBaseURI.only owner.by season.
  function setHiddenBaseURIBySeason(string memory uri_,uint256 _season) external virtual onlyOwner {
    _revealUri[_season] = uri_;
  }

  //return _nextTokenId
  function getCurrentIndex() external view virtual returns (uint256){
    return _nextTokenId();
  }
  //return status.
  function getContractStatus() external view virtual returns (uint256){
    return _contractStatus;
  }
  //set status.only owner.
  function setContractStatus(uint256 status_) external virtual onlyOwner {
    _contractStatus = status_;
  }
  //return wlResetIndex.
  function getWlResetIndex() external view virtual returns (uint256){
    return _wlResetIndex;
  }
  //reset _wlMinted.only owner.
  function resetWlMinted() external virtual onlyOwner {
    _wlResetIndex++;
  }
  //return Season.
  function getSeason() external view virtual returns (uint256){
    return _seasonCounter;
  }
  //increment next Season.only owner.
  function incrementSeason() external virtual onlyOwner {
    //pause all sale
    isWlEnabled = false;
    isPsEnabled = false;
    isBmEnabled = false;
    isHmEnabled = false;
    //reset tree
    _merkleRoot = 0x0;
    _merkleRoot1 = 0x0;
    _merkleRoot2 = 0x0;
    //increment season
    _seasonCounter++;
    seasonStartTokenId[_seasonCounter] = _nextTokenId();//set start tonkenid for next Season.
  }
  //return season by tokenid.
  function getSeasonByTokenId(uint256 _tokenId) external view virtual returns(uint256){
    return _getSeasonByTokenId(_tokenId);
  }
  //return season by tokenid.
  function _getSeasonByTokenId(uint256 _tokenId) internal view returns(uint256){
    require(_exists(_tokenId), "Season query for nonexistent token");
    uint256 nextStartTokenId = 10000000000;//start tokenid for next season.set big tokenid.
    for (uint256 i = _seasonCounter; i >= 0; i--) {
      if(seasonStartTokenId[i] <= _tokenId && _tokenId < nextStartTokenId) return i;
      nextStartTokenId = seasonStartTokenId[i];
    }
    return 0;//can not reach here.
  }

  //set BaseURI at after reveal. only owner.current season.
  function setBaseURI(string memory uri_) external virtual onlyOwner {
    _baseTokenURI[_seasonCounter] = uri_;
  }
  //set BaseURI at after reveal. only owner.by season.
  function setBaseURIBySeason(string memory uri_,uint256 _season) external virtual onlyOwner {
    _baseTokenURI[_season] = uri_;
  }

  //set custom tokenURI at after reveal. only owner.
  function setCustomTokenURI(uint256 _tokenId,string memory uri_) external virtual onlyOwner {
    require(_exists(_tokenId), "URI query for nonexistent token");
    _customTokenURI[_tokenId] = uri_;
  }
  function getCustomTokenURI(uint256 _tokenId) external view virtual returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    return(_customTokenURI[_tokenId]);
  }
  //retuen BaseURI.internal.current season.
  function _currentBaseURI(uint256 _season) internal view returns (string memory){
    return _baseTokenURI[_season];
  }
  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A,IERC721A) returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    uint256 _season = _getSeasonByTokenId(_tokenId);//get season.
    if(_isRevealed[_season] == false) return _revealUri[_season];
    if(bytes(_customTokenURI[_tokenId]).length != 0) return _customTokenURI[_tokenId];//custom URI
    return string(abi.encodePacked(_currentBaseURI(_season), Strings.toString(_tokenId), _extension));
  }

  //common mint.transfer to _address.
  function _commonMint(address _address,uint256 _amount) internal virtual { 
    require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");

    _safeMint(_address, _amount);
  }
  //owner mint.transfer to _address.only owner.
  function ownerMint(uint256 _amount, address _address) external virtual onlyOwner {
    _commonMint(_address, _amount);
  }
  //WL mint.
  function whitelistMint(uint256 _amount, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) external payable virtual nonReentrant {
    uint256 wlNum = _whitelistMintCheck(_amount, maxmint_, proof_, proof1_, proof2_);
    _whitelistMintCheckValue(_amount, maxmint_, proof_, proof1_, proof2_);
    unchecked{
      if(wlNum == 0)      _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] += _amount;
      else if(wlNum == 1) _wlMinted1[_seasonCounter][msg.sender][_wlResetIndex] += _amount;
      else                _wlMinted2[_seasonCounter][msg.sender][_wlResetIndex] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //WL check.except value.
  function _whitelistMintCheck(uint256 _amount, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) internal virtual returns(uint256) {
    require(isWlEnabled, "whitelistMint is Paused");
    (bool isWL,uint256 wlNum) = _isWhitelisted(msg.sender, maxmint_,proof_, proof1_, proof2_);
    require(isWL, "You are not whitelisted!");
    require(!isWlNumDisabled[wlNum],"Now part of whitelist disabled.");
    uint256 maxMints = _getWhitelistedMaxMints(msg.sender, maxmint_, proof_, proof1_, proof2_);
    require(maxMints >= _amount, "whitelistMint: Over max mints per wallet");
    if(wlNum == 0)      require(maxMints >= _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] + _amount, "You have no whitelistMint left");
    else if(wlNum == 1) require(maxMints >= _wlMinted1[_seasonCounter][msg.sender][_wlResetIndex] + _amount, "You have no whitelistMint1 left");
    else                require(maxMints >= _wlMinted2[_seasonCounter][msg.sender][_wlResetIndex] + _amount, "You have no whitelistMint2 left");
    return (wlNum);
  }
  //WL check.Only Value.for optional free mint.
  function _whitelistMintCheckValue(uint256 _amount, uint256 maxmint_, bytes32[] calldata proof_, bytes32[] calldata proof1_, bytes32[] calldata proof2_) internal virtual {
    uint256 price = _getWhitelistedPrice(msg.sender, maxmint_, proof_, proof1_, proof2_);
    require(msg.value == price * _amount, "ETH value is not correct");
  }
  //Public mint.
  function publicMint(uint256 _amount) external payable virtual nonReentrant {
    require(isPsEnabled, "publicMint is Paused");
    require(maxMintsPerPS >= _amount, "publicMint: Over max mints per wallet");
    require(maxMintsPerPS >= _psMinted[_seasonCounter][msg.sender] + _amount, "You have no publicMint left");
    _publicMintCheckValue(_amount);
    require(tx.origin == msg.sender,"publicMint: Caller is contract.");

    unchecked{
      _psMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //Public check.Only Value.for optional free mint.
  function _publicMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == psMintPrice * _amount, "ETH value is not correct");
  }
  //set otherContract.only owner
  function setOtherContract(address _addr) external virtual onlyOwner {
    otherContract = _addr;
    _otherContractFactory = MGYERC721A(otherContract);
  }
  
  //Burn&MintSale mint.
  function _burnAndMint(uint256 _amount,uint256[] calldata _tokenids) internal virtual {
    require(isBmEnabled, "Burn&MintSale is Paused");
    require(maxMintsPerBM >= _amount, "Burn&MintSale: Over max mints per wallet");
    require(maxMintsPerBM >= _bmMinted[_seasonCounter][msg.sender] + _amount, "You have no Burn&MintSale left");
    _burnAndMintCheckValue(_amount);
    require(otherContract != address(0),"not set otherContract.");
    require(otherContractCount != 0 ,"not set otherContractCount.");
    require( _tokenids.length == (otherContractCount * _amount),"amount must be multiple of other contract count.");
    //check tokens owner , used.
    for (uint256 i = 0; i < _tokenids.length; i++) {
      require(_otherContractFactory.ownerOf(_tokenids[i]) == msg.sender,"You are not owner of this tokenid.");
      _otherContractFactory.burn(_tokenids[i]);//must approval.
    }
    
    unchecked{
      _bmMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //BM check.Only Value.for optional free mint.
  function _burnAndMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == bmMintPrice * _amount, "ETH value is not correct");
  }
 //Burn&MintSale mint. external
  function burnAndMint(uint256 _amount,uint256[] calldata _tokenids) external payable virtual nonReentrant {
    require(otherContractGenesis == address(0),"can not set otherContractGenesis.");
    require(otherContractCountGenesis == 0 ,"can not set otherContractCountGenesis.");
    _burnAndMint(_amount,_tokenids);
  }
  //set otherContractGenesis.only owner
  function setOtherContractGenesis(address _addr) external virtual onlyOwner {
    otherContractGenesis = _addr;
    _otherContractGenesisFactory = MGYERC721A(otherContractGenesis);
  }
  //set otherContractGenesis count with burn&Mint.only owner.
  function setOtherContractCountGenesis(uint256 _count) external virtual onlyOwner {
    otherContractCountGenesis = _count;
  }
  //Burn&MintSale with GenesisNFT mint.
  function burnAndMintWithGenesis(uint256 _amount,uint256[] calldata _tokenids,uint256[] calldata _tokenidGenesis) external payable virtual nonReentrant {
    require(otherContractGenesis != address(0),"not set otherContractGenesis.");
    require(otherContractCountGenesis > 0 ,"not set otherContractCountGenesis.");
    require(_tokenidGenesis.length >= otherContractCountGenesis,"You have not enough Genesis.");
    for (uint256 i = 0; i < _tokenidGenesis.length; i++) {
      require(_otherContractGenesisFactory.ownerOf(_tokenidGenesis[i]) == msg.sender,"You are not owner of this tokenidGenesis.");
    }
    _burnAndMint(_amount,_tokenids);
  }
  
  //Hold&MintSale mint.
  function holdAndMint(uint256 _amount,uint256[] calldata _tokenids) external payable virtual nonReentrant {
    require(isHmEnabled, "Hold&MintSale is Paused");
    require(maxMintsPerHM >= _amount, "Hold&MintSale: Over max mints per wallet");
    require(maxMintsPerHM >= _hmMinted[_seasonCounter][msg.sender] + _amount, "You have no Hold&MintSale left");
    _holdAndMintCheckValue(_amount);
    require(otherContract != address(0),"not set otherContract.");
    require(otherContractCount != 0 ,"not set otherContractCount.");
    require( _tokenids.length == (otherContractCount * _amount),"amount must be multiple of other contract count.");
    //check tokens owner , used.
    for (uint256 i = 0; i < _tokenids.length; i++) {
      require(_otherContractFactory.ownerOf(_tokenids[i]) == msg.sender,"You are not owner of this tokenid.");
      require(!_otherTokenidUsed[_seasonCounter][_tokenids[i]] ,"This other tokenid is Used.");
      _otherTokenidUsed[_seasonCounter][_tokenids[i]] = true;
    }

    unchecked{
      _hmMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //HM check.Only Value.for optional free mint.
  function _holdAndMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == hmMintPrice * _amount, "ETH value is not correct");
  }

  //burn
  function burn(uint256 tokenId) external virtual {
    _burn(tokenId, true);
  }

  //widraw ETH from this contract.only owner. 
  function withdraw() external payable virtual onlyOwner nonReentrant{
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    bool os;
    if(_withdrawWallet != address(0)){//if _withdrawWallet has.
      (os, ) = payable(_withdrawWallet).call{value: address(this).balance}("");
    }else{
      (os, ) = payable(owner()).call{value: address(this).balance}("");
    }
    require(os);
    // =============================================================================
  }
  //return wallet owned tokenids.it used high gas and running time.
  function walletOfOwner(address owner) external view virtual returns (uint256[] memory) {
    //copy from tokensOfOwner in ERC721AQueryable.sol 
    unchecked {
      uint256 tokenIdsIdx = 0;
      address currOwnershipAddr = address(0);
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; i++) {
        ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          tokenIds[tokenIdsIdx++] = i;
        }
      }
      return tokenIds;
    }
  }
  //set Staking enable.only owner.
  function setStakingEnable(bool bool_) external virtual onlyOwner {
    isStakingEnabled = bool_;
    if(bool_){
      stakingStartTimestamp = block.timestamp;
      stakingEndTimestamp = NULL_STAKED;
    }else{
      stakingEndTimestamp = block.timestamp;
    }
  }
  //get staking information.
  function _getStakingInfo(uint256 _tokenId) internal view virtual returns (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ){
    require(_exists(_tokenId), "nonexistent token");

    currentStakingTime = 0;
    startTimestamp = _stakingStartedTimestamp[_tokenId];

    if (startTimestamp != NULL_STAKED) {  // is staking
      currentStakingTime = block.timestamp - startTimestamp;
    }
    totalStakingTime = currentStakingTime + _stakingTotalTime[_tokenId];
    isStaking = startTimestamp != NULL_STAKED;
    claimedLastTimestamp = _claimedLastTimestamp[_tokenId];
  }
  //get staking information.
  function getStakingInfo(uint256 _tokenId) external view virtual returns (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ){
    (startTimestamp, currentStakingTime, totalStakingTime, isStaking, claimedLastTimestamp) = _getStakingInfo(_tokenId);
  }
  
  //toggle staking status
  function _toggleStaking(uint256 _tokenId) internal virtual {
    require(ownerOf(_tokenId) == msg.sender,"You are not owner of this tokenid.");
    require(_exists(_tokenId), "nonexistent token");

    uint256 startTimestamp = _stakingStartedTimestamp[_tokenId];

    if (startTimestamp == NULL_STAKED) { 
      //start staking
      require(isStakingEnabled, "Staking closed");
      _stakingStartedTimestamp[_tokenId] = block.timestamp;
    } else { 
      //start unstaking
      _stakingTotalTime[_tokenId] += block.timestamp - startTimestamp;
      _stakingStartedTimestamp[_tokenId] = NULL_STAKED;
      _claimedLastTimestamp[_tokenId] = NULL_STAKED;
    }
  }
  //toggle staking status
  function toggleStaking(uint256[] calldata _tokenIds) external virtual {
    uint256 num = _tokenIds.length;

    for (uint256 i = 0; i < num; i++) {
      uint256 tokenId = _tokenIds[i];
      _toggleStaking(tokenId);
    }
  }
  //set rewardContract.only owner
  function setRewardContract(address _addr) external virtual onlyOwner {
    rewardContract = _addr;
    _rewardContractFactory = MGYREWARD(rewardContract);
  }

  //claim reward
  function _claimReward(uint256 _tokenId) internal virtual {
    require(ownerOf(_tokenId) == msg.sender,"You are not owner of this tokenid.");
    require(_exists(_tokenId), "nonexistent token");

    //get staking infomation
    (uint256 startTimestamp, uint256 currentStakingTime, uint256 totalStakingTime, bool isStaking,uint256 claimedLastTimestamp ) = _getStakingInfo(_tokenId);
    uint256 _lastTimestamp = block.timestamp;
    
    _claimedLastTimestamp[_tokenId] = _lastTimestamp; //execute before claimReward().Warning for slither.
    //call reword. other contract 
    _rewardContractFactory.claimReward(stakingStartTimestamp, stakingEndTimestamp, _tokenId, startTimestamp,  currentStakingTime,  totalStakingTime,  isStaking,  claimedLastTimestamp,  _lastTimestamp);

  }
  //claim reward
  function claimReward(uint256[] calldata _tokenIds) external virtual nonReentrant{
    require(isStakingEnabled, "Staking closed");//only staking period
    uint256 num = _tokenIds.length;

    for (uint256 i = 0; i < num; i++) {
      uint256 tokenId = _tokenIds[i];
      _claimReward(tokenId);
    }
  }

  //Opensea filter
  function setApprovalForAll(address operator, bool approved) public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator){
    super.setApprovalForAll(operator, approved);
  }
  function approve(address operator, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator){
    super.approve(operator, tokenId);
  }
  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from){
    super.transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from){
    super.safeTransferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A,IERC721A) onlyAllowedOperator(from){
    super.safeTransferFrom(from, to, tokenId, data);
  }
  function setOperatorFilteringEnabled(bool value) public onlyOwner {
      operatorFilteringEnabled = value;
  }
  function _operatorFilteringEnabled() internal view override returns (bool) {
      return operatorFilteringEnabled;
  }

  //ERC4906
  function metadataUpdate(uint256 _tokenId) external virtual onlyOwner {
    emit MetadataUpdate(_tokenId);
  }
  function batchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId) external virtual onlyOwner {            
    emit BatchMetadataUpdate( _fromTokenId, _toTokenId);
  }
  
}