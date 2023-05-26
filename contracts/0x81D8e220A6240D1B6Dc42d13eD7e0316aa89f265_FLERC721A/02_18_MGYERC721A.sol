//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
//import "hardhat/console.sol";

contract MGYERC721A is Ownable,ERC721A, ReentrancyGuard, MerkleProof, ERC2981{

  //Project Settings
  uint256 public wlMintPrice;//wl.price.
  uint256 public psMintPrice;//publicSale. price.
  uint256 public maxMintsPerWL;//wl.max mint num per wallet.
  uint256 public maxMintsPerPS;//publicSale.max mint num per wallet.
  uint256 public maxSupply;//max supply
  address payable internal _withdrawWallet;//withdraw wallet

  //URI
  string internal _revealUri;
  string internal _baseTokenURI;
  //flags
  bool public isWlEnabled;//WL enable.
  bool public isPsEnabled;//PublicSale enable.
  bool internal _isRevealed;//reveal enable.
  //mint records.
  mapping(address => uint256) internal  _wlMinted;//wl.mint num by wallet.
  mapping(address => uint256) internal _psMinted;//PublicSale.mint num by wallet.

  constructor (
      string memory _name,
      string memory _symbol
  ) ERC721A (_name,_symbol) {
  }
  //start from 1.djust for bueno.
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }
  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external virtual onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }
  //for ERC2981
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
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
  //set reveal.only owner.
  function setReveal(bool bool_) external virtual onlyOwner {
    _isRevealed = bool_;
  }
  //retuen _isRevealed.
  function isRevealed() external view virtual returns (bool){
    return _isRevealed;
  }
  //retuen _wlMinted
  function wlMinted(address _address) external view virtual returns (uint256){
    return _wlMinted[_address];
  }
  //retuen _psMinted
  function psMinted(address _address) external view virtual returns (uint256){
    return _psMinted[_address];
  }

  //set wl's max mint num.only owner.
  function setWlMaxMints(uint256 _max) external virtual onlyOwner {
    maxMintsPerWL = _max;
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
    _setMerkleRoot(merkleRoot_);
  }

  //set HiddenBaseURI.only owner.
  function setHiddenBaseURI(string memory uri_) external virtual onlyOwner {
    _revealUri = uri_;
  }
  //return _currentIndex
  function getCurrentIndex() external view virtual returns (uint256){
    return _currentIndex;
  }

  //set BaseURI at after reveal. only owner.
  function setBaseURI(string memory uri_) external virtual onlyOwner {
    _baseTokenURI = uri_;
  }
  //retuen BaseURI.internal.
  function _currentBaseURI() internal view returns (string memory){
    return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    if(_isRevealed == false) {
    return _revealUri;
    }
    return string(abi.encodePacked(_currentBaseURI(), Strings.toString(_tokenId), ""));//deleted .json. adjust for bueno
  }

  //owner mint.transfer to _address.only owner.
  function ownerMint(uint256 _amount, address _address) external virtual onlyOwner { 
    require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");

    _safeMint(_address, _amount);
  }
  //WL mint.
  function whitelistMint(uint256 _amount, bytes32[] memory proof_) external payable virtual nonReentrant {
    require(isWlEnabled, "whitelistMint is Paused");
    require(isWhitelisted(msg.sender, proof_), "You are not whitelisted!");
    require(maxMintsPerWL >= _amount, "whitelistMint: Over max mints per wallet");
    require(maxMintsPerWL >= _wlMinted[msg.sender] + _amount, "You have no whitelistMint left");
    require(msg.value == wlMintPrice * _amount, "ETH value is not correct");
    require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");

    _wlMinted[msg.sender] += _amount;
    _safeMint(msg.sender, _amount);
  }
  //Public mint.
  function publicMint(uint256 _amount) external payable virtual nonReentrant {
    require(isPsEnabled, "publicMint is Paused");
    require(maxMintsPerPS >= _amount, "publicMint: Over max mints per wallet");
    require(maxMintsPerPS >= _psMinted[msg.sender] + _amount, "You have no publicMint left");
    require(msg.value == psMintPrice * _amount, "ETH value is not correct");
    require((_amount + totalSupply()) <= (maxSupply), "No more NFTs");
      
    _psMinted[msg.sender] += _amount;
    _safeMint(msg.sender, _amount);
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
  //return wallet owned tokenids.
  function walletOfOwner(address _address) external view virtual returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    //search from all tonkenid. so spend high gas values.attention.
    uint256 tokenindex = 0;
    for (uint256 i = _startTokenId(); i < _currentIndex; i++) {
      if(_address == this.tryOwnerOf(i)) tokenIds[tokenindex++] = i;
    }
    return tokenIds;
  }
  //try catch vaersion ownerOf. I have a error at burned tokenid.so need to try catch.  only external.
  function tryOwnerOf(uint256 tokenId) external view  virtual returns (address) {
    try this.ownerOf(tokenId) returns (address _address) {
      return(_address);
    } catch {
        return (address(0));//return 0x0 if error.
    }
  }


}