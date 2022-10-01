//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC4907A.sol";
import "hardhat/console.sol";

contract MGYERC721A is Ownable,ERC4907A, ReentrancyGuard, ERC2981{

  //Project Settings
  uint256 public wlMintPrice;//wl.price.
  uint256 public psMintPrice;//publicSale. price.
  uint256 public maxMintsPerWL;//wl.max mint num per wallet.
  uint256 public maxMintsPerWL1;//wl1.max mint num per wallet.
  uint256 public maxMintsPerWL2;//wl2.max mint num per wallet.
  uint256 public maxMintsPerPS;//publicSale.max mint num per wallet.
  uint256 public maxSupply;//max supply
  address payable internal _withdrawWallet;//withdraw wallet
  bool public isSBTEnabled;//SBT(can not transfer.only owner) mode enable.

  //URI
  mapping(uint256 => string) internal _revealUri;//by Season
  mapping(uint256 => string) internal _baseTokenURI;//by Season
  //flags
  bool public isWlEnabled;//WL enable.
  bool public isPsEnabled;//PublicSale enable.
  mapping(uint256 => bool) internal _isRevealed;//reveal enable.by Season.
  //mint records.
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _wlMinted;//wl.mint num by wallet.by Season.by reset index
  mapping(uint256 => mapping(address => uint256)) internal _psMinted;//PublicSale.mint num by wallet.by Season.
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

  constructor (
      string memory _name,
      string memory _symbol
  ) ERC721A (_name,_symbol) {
    seasonStartTokenId[_seasonCounter] = _startTokenId();
  }
  //start from 1.adjust for bueno.
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }
  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external virtual onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }
  //for ERC2981,ERC721A.ERC4907A
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC4907A, ERC2981) returns (bool) {
    return(
      ERC721A.supportsInterface(interfaceId) || 
      ERC4907A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId)
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
  //set public Sale price.only owner.
  function setPsPrice(uint256 newPrice) external virtual onlyOwner {
    psMintPrice = newPrice;
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

  //return _psMinted.current season.
  function psMinted(address _address) external view virtual returns (uint256){
    return _psMinted[_seasonCounter][_address];
  }
  //return _psMinted.by season.
  function psMintedBySeason(address _address,uint256 _season) external view virtual returns (uint256){
    return _psMinted[_season][_address];
  }

  //set wl's max mint num.only owner.
  function setWlMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerWL = _max;
  }
  //set wl's max mint num.only owner.
  function setWlMaxMints1(uint256 _max) external virtual onlyOwner {
    maxMintsPerWL1 = _max;
  }
  //set wl's max mint num.only owner.
  function setWlMaxMints2(uint256 _max) external virtual onlyOwner {
    maxMintsPerWL2 = _max;
  }
  //set PublicSale's max mint num.only owner.
  function setPsMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerPS = _max;
  }
    
  //set WLsale.only owner.
  function setWhitelistSale(bool bool_) external virtual onlyOwner {
    isWlEnabled = bool_;
  }

  //set Publicsale.only owner.
  function setPublicSale(bool bool_) external virtual onlyOwner {
    isPsEnabled = bool_;
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
  function isWhitelisted(address address_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external view virtual returns (bool) {
    return(_isWhitelisted(address_,proof_,proof1_,proof2_));
  }
  function _isWhitelisted(address address_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal view  returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_));
    return(
          _hasWhitelistedOneWL(proof_,_leaf)   || 
          _hasWhitelistedOneWL1(proof1_,_leaf) ||
          _hasWhitelistedOneWL2(proof2_,_leaf)
    );
  }
  //get WL maxMints sum.
  function getWhitelistedMaxMints(address address_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external view virtual returns (uint256) {
    return(_getWhitelistedMaxMints(address_, proof_, proof1_, proof2_));
  }
  function _getWhitelistedMaxMints(address address_, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal view  returns (uint256) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_));
    uint256 num = 0;
    if(_hasWhitelistedOneWL(proof_,_leaf))   {unchecked {num += maxMintsPerWL;}}
    if(_hasWhitelistedOneWL1(proof1_,_leaf)) {unchecked {num += maxMintsPerWL1;}}
    if(_hasWhitelistedOneWL2(proof2_,_leaf)) {unchecked {num += maxMintsPerWL2;}}
    return(num);
  }
  //have you WL?
  function hasWhitelistedOneWL(address address_,bytes32[] memory proof_) external view virtual returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_));
    return(_hasWhitelistedOneWL(proof_,_leaf));
  }
  function _hasWhitelistedOneWL(bytes32[] memory proof_,bytes32 leaf_ ) internal view  returns (bool) {
    return(_merkleRoot != 0x0 && MerkleProof.verify(proof_,_merkleRoot,leaf_));
  }
  //have you WL1?
    function hasWhitelistedOneWL1(address address_,bytes32[] memory proof_) external view virtual returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_));
    return(_hasWhitelistedOneWL1(proof_,_leaf));
  }
  function _hasWhitelistedOneWL1(bytes32[] memory proof_,bytes32 leaf_ ) internal view  returns (bool) {
    return(_merkleRoot1 != 0x0 && MerkleProof.verify(proof_,_merkleRoot1,leaf_));
  }
  //have you WL2?
  function hasWhitelistedOneWL2(address address_,bytes32[] memory proof_) external view virtual returns (bool) {
    bytes32 _leaf = keccak256(abi.encodePacked(address_));
    return(_hasWhitelistedOneWL2(proof_,_leaf));
  }
  function _hasWhitelistedOneWL2(bytes32[] memory proof_,bytes32 leaf_ ) internal view  returns (bool) {
    return(_merkleRoot2 != 0x0 && MerkleProof.verify(proof_,_merkleRoot2,leaf_));
  }

  //set SBT mode Enable. only owner.Noone can transfer. only contract owner can transfer.
  function setSBTMode(bool bool_) external virtual onlyOwner {
    isSBTEnabled = bool_;
  }
  //override for SBT mode.only owner can transfer. or mint or burn.
  function _beforeTokenTransfers(address from_,address to_,uint256 startTokenId_,uint256 quantity_) internal virtual override {
    require(!isSBTEnabled || msg.sender == owner() || from_ == address(0) || to_ == address(0) ,"SBT mode Enabled: token transfer while paused.");
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
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
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
  function whitelistMint(uint256 _amount, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) external payable virtual nonReentrant {
    _whitelistMintCheck(_amount, proof_, proof1_, proof2_);
    _whitelistMintCheckValue(_amount);
    unchecked{
      _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] += _amount;
    }
    _commonMint(msg.sender, _amount);
  }
  //WL check.except value.
  function _whitelistMintCheck(uint256 _amount, bytes32[] memory proof_, bytes32[] memory proof1_, bytes32[] memory proof2_) internal virtual {
    require(isWlEnabled, "whitelistMint is Paused");
    require(_isWhitelisted(msg.sender, proof_, proof1_, proof2_), "You are not whitelisted!");
    uint256 maxMints = _getWhitelistedMaxMints(msg.sender, proof_, proof1_, proof2_);
    require(maxMints >= _amount, "whitelistMint: Over max mints per wallet");
    require(maxMints >= _wlMinted[_seasonCounter][msg.sender][_wlResetIndex] + _amount, "You have no whitelistMint left");
  }
  //WL check.Only Value.for optional free mint.
  function _whitelistMintCheckValue(uint256 _amount) internal virtual {
    require(msg.value == wlMintPrice * _amount, "ETH value is not correct");
  }
  //Public mint.
  function publicMint(uint256 _amount) external payable virtual nonReentrant {
    require(isPsEnabled, "publicMint is Paused");
    require(maxMintsPerPS >= _amount, "publicMint: Over max mints per wallet");
    require(maxMintsPerPS >= _psMinted[_seasonCounter][msg.sender] + _amount, "You have no publicMint left");
    require(msg.value == psMintPrice * _amount, "ETH value is not correct");

    unchecked{
      _psMinted[_seasonCounter][msg.sender] += _amount;
    }
    _commonMint(msg.sender, _amount);
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
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(owner);
      uint256[] memory tokenIds = new uint256[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
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
}