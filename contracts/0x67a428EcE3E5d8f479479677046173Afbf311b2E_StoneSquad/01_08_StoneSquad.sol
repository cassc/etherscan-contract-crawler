// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract StoneSquad is ERC721A, Ownable, ReentrancyGuard {
    
    using Strings for uint256;
    bytes32 public merkleRoot;
    
    //Constructor
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public wlMaxSupply;
    uint256 public maxMintAmountPerTx;
    
    //Whitelist
    bool public paused = true;
    bool public whitelistMintEnabled = false;
    

    //URI Path
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    //Paymet Splitter - DeFi 
    address payable public payments;
    address[] public payees;    

    //Balance
    uint256 totalBalance;


    event WhitelistMinted(address minter,uint256 amount);
    event minted(address minter,uint256 amount);
    event amountReleased();

    constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _wlMaxSupply,
    uint256 _maxMintAmountPerTx,
    address _payments,
    address[] memory _payees
  ) ERC721A(_tokenName, _tokenSymbol) {
    maxSupply = _maxSupply;    
    wlMaxSupply = _wlMaxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    payees = _payees;
    payments = payable(_payments);    
    cost = 0.06 ether;   
  }
  modifier checkPaymentAddress(address withdrawAddress){
    bool status=false;
    for(uint i=0;i<payees.length;i++){
      if(payees[i]==withdrawAddress){
        status = true;
      }
    }
    require(status,"Not Valid Address to Withdraw");
    _;
  }
  modifier mintCompliance(uint256 _mintQuantity) {
    require(_mintQuantity > 0 && _mintQuantity <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintQuantity < maxSupply, 'Max supply exceeded!');
    _;
  }
   modifier whitelistMintCompliance(uint256 _mintQuantity) {
    require(_mintQuantity > 0 && _mintQuantity <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintQuantity < wlMaxSupply, 'Max Whitelist Supply exceeded!');
    _;
  }
   modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
  
  modifier checkWalletAddress(){
    require(tx.origin == msg.sender,"Invalid Wallet Address");
    _;
  }
  function getMinted() public view returns (uint256){
    return totalSupply();
  }
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
  function setPublicCost() public onlyOwner {
    cost = 0.069 ether;
  }
  function setWlCost() public onlyOwner {
    cost = 0.06 ether;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
  function whitelistVerify(bytes32[] calldata _merkleProof) checkWalletAddress() public view returns(bool){
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);    
  }
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable whitelistMintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) checkWalletAddress() {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not active!');    
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');    
    totalBalance += msg.value;
    _safeMint(_msgSender(), _mintAmount);
    emit WhitelistMinted(_msgSender(), _mintAmount);
    
  }
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) checkWalletAddress(){
    require(!paused, 'The contract is paused!');
    totalBalance += msg.value;
    _safeMint(_msgSender(), _mintAmount);
    emit minted(_msgSender(), _mintAmount);
  }
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
  function transferOwner(address newOwner) public onlyOwner{
    transferOwnership(newOwner);
  }
  //  function _startTokenId() internal view virtual override returns (uint256) {
  //   return 1;
  // }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }  
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }
  function setMaxSupply(uint256 _maxSupply)public onlyOwner{
    maxSupply = _maxSupply;
  }
  function setWLMaxSupply(uint256 _wlMaxSupply)public onlyOwner{
    wlMaxSupply = _wlMaxSupply;
  }
  function getMaxSupply() public view returns(uint256){
    return maxSupply;
  }
  function getWLMaxSupply() public view returns(uint256){
    return wlMaxSupply;
  }
  function currentBalance() public view returns(uint256){
    return address(this).balance;
  }
  function getTotalBalance() public view returns(uint256)
  {
    return totalBalance;
  }
  
  function withdraw() public checkPaymentAddress(msg.sender) nonReentrant {
    require(address(this).balance>0,"Release amount should be greater than zero");
    (bool success, ) = payable(payments).call{value: address(this).balance}("");     
    require(success);    
    emit amountReleased();
  }
}