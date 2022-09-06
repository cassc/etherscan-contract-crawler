// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//------------------------------------------------------------------------------
/*

░██████╗░██╗░░░██╗░█████╗░██╗░░░░░██╗███████╗██╗███████╗██████╗░  ██████╗░███████╗██╗░░░██╗░██████╗
██╔═══██╗██║░░░██║██╔══██╗██║░░░░░██║██╔════╝██║██╔════╝██╔══██╗  ██╔══██╗██╔════╝██║░░░██║██╔════╝
██║██╗██║██║░░░██║███████║██║░░░░░██║█████╗░░██║█████╗░░██║░░██║  ██║░░██║█████╗░░╚██╗░██╔╝╚█████╗░
╚██████╔╝██║░░░██║██╔══██║██║░░░░░██║██╔══╝░░██║██╔══╝░░██║░░██║  ██║░░██║██╔══╝░░░╚████╔╝░░╚═══██╗
░╚═██╔═╝░╚██████╔╝██║░░██║███████╗██║██║░░░░░██║███████╗██████╔╝  ██████╔╝███████╗░░╚██╔╝░░██████╔╝
░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░  ╚═════╝░╚══════╝░░░╚═╝░░░╚═════╝░
*/
//------------------------------------------------------------------------------
// Author: orion (@OrionDevStar)
//------------------------------------------------------------------------------

import "./ERC721/ERC721QDUltra.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DreamSocietyNFT is ERC721QDUltra, Ownable  {
  using Strings for uint256;
  using ECDSA for bytes32;  

  //NFT cost
  uint128 constant public presaleCost1 = 0.12 ether;
  uint128 constant public presaleCost2 = 0.15 ether;
  uint128 constant public publicCost = 0.16 ether;

  //erc721 metadata
  string constant private _name   = "Dream Society";
  string constant private _symbol = "DS";

  //verification address
  address constant private _signer = 0xe05655869a11FEbD52F7686bE1B2B48c40f7E613;

  //project max info
  uint16 constant private _maxSupply  = 8888;
  uint8  constant private _maxOwner   = 200; 
  uint8  constant private _maxPersale = 3;

  //QD payment
  uint256 private QDpayment = 2.8 ether;

  //NFT project stage.
  uint32 public freeMintDate = 1658671200;
  uint32 public presaleMint1Date = 1658671200;
  uint32 public presaleMint2Date = 1658685600;
  uint32 public publicMintDate = 1658700000;
  
  

  //track mint count per address
  uint256 private _ownerMints   = 0;
  mapping (address => uint256) private _mintsPresale1;
  mapping (address => uint256) private _mintsPresale2;
  mapping (address => uint256) private _mintsPublic;
  mapping (address => uint256) private _mintsFree;

  //NFT URI
  string private _projectURI;
  string private _projectHiddenURI; 
  bool   private _revealed = false;
  
  //payees shares for the project
  address[] private _payees;
  uint[] private _payeesShares;

  //Admin Addresses
  address[2] private _adminAddresses;

  //track mint count for sequencial projects
  uint16 private _currentTokenId; 

  constructor(
    uint16 initialTokenId_,
    string memory projectURI_,
    address[] memory payees_,
    uint[] memory payeesShares_
   ) 
    ERC721(_name, _symbol)
   {
    _projectURI = projectURI_;
    _payees = payees_;
    _payeesShares = payeesShares_;
    _currentTokenId = initialTokenId_ - 1;
    _ownerMints = 16;
    for (uint16 i = 0; i < _ownerMints; i++) {
        _currentTokenId++;
        _safeMint(msg.sender, _currentTokenId);
    }
    addTotalSupply(_ownerMints);
    _adminAddresses = [0x89a31e7658510Cfd960067cb97ddcc7Ece3c70C0, msg.sender];
  }

  //-------------------------------------------------------------------------
  // modifiers
  //-------------------------------------------------------------------------
  modifier onlyAdmin() {
    require(isAdmin(), "caller not admin");
    _;
  }  

  //-------------------------------------------------------------------------
  // internal
  //-------------------------------------------------------------------------
  function isAdmin() internal view returns(bool) {
    for(uint16 i = 0; i < _adminAddresses.length; i++){
      if(_adminAddresses[i] == msg.sender)
        return true;
    }
    return false;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _projectURI;
  }

  //standart mint verification used by other functions
  function _mintNFT(address _to, uint256 _quantity, uint128 _price, uint256 _minted) internal {
      require(_quantity * _price <= msg.value, "Insufficient funds.");
      require(_quantity + _currentTokenId <= _maxSupply,"Purchase exceeds available supply.");
      require(_quantity + _minted <= _maxPersale, "Invalid mint amount!"); 
      for (uint16 i = 0; i < _quantity; i++) {
          _currentTokenId++;
          _safeMint(_to, _currentTokenId);
      }
      addTotalSupply(_quantity);
  }

  /*
   * checks the hash message with the spected hash message in the 
   * contract and compere the signature with the signer
  */
  function _checkHash(bytes32 _hash, bytes memory _signature, address _account ) internal view returns (bool) {
      bytes32 senderHash = _senderMessageHash();
      if (senderHash != _hash) {
          return false;
      }
      return _hash.recover(_signature) == _account;
  } 

  function _senderMessageHash() internal view returns (bytes32) {
      bytes32 message = keccak256(
          abi.encodePacked(
              "\x19Ethereum Signed Message:\n32",
              keccak256(abi.encodePacked(address(this), msg.sender))
          )
      );
      return message;
  }    

  //-------------------------------------------------------------------------
  // public
  //-------------------------------------------------------------------------
  // @dev mint the _quantity to the message.sender
  // @param _quantity is the quantity that will be minted
  function publicMint(uint256 _quantity) public payable  {
      require(isPublicSale(), "Presale mint not available.");
      _mintNFT(msg.sender, _quantity, publicCost, _mintsPublic[msg.sender]);
      _mintsPublic[msg.sender] += _quantity;
  }

  // @dev mint the _quantity to the message.sender
  // @param _quantity is the quantity that will be minted
  function freeMint(uint256 _quantity, bytes32 _hash, bytes memory _signature) public payable  {
      require(_checkHash(_hash, _signature, _signer), "Address is not on Presale List");
      require(isFreesale(), "Presale mint not available.");
      _mintNFT(msg.sender, _quantity, 0 ether,_mintsFree[msg.sender]+2);
      _mintsFree[msg.sender] += _quantity;
  }

  // @dev mint the _quantity to the message.sender
  // @param _quantity is the quantity that will be minted
  function presaleMint1(uint256 _quantity, bytes32 _hash, bytes memory _signature) public payable {
      require(_checkHash(_hash, _signature, _signer), "Address is not on Presale List");
      require(isPresale1(), "Presale mint not available.");
      _mintNFT(msg.sender, _quantity, presaleCost1,_mintsPresale1[msg.sender]);
      _mintsPresale1[msg.sender] += _quantity;
  }  

  // @dev mint the _quantity to the message.sender
  // @param _quantity is the quantity that will be minted
  function presaleMint2(uint256 _quantity, bytes32 _hash, bytes memory _signature) public payable {
      require(_checkHash(_hash, _signature, _signer), "Address is not on Presale List");
      require(isPresale2(), "Presale mint not available.");
      _mintNFT(msg.sender, _quantity, presaleCost2,_mintsPresale2[msg.sender]);
      _mintsPresale2[msg.sender] += _quantity;
  }

  // @dev show the correct URI for the token, using the _tokenId, shows the _projectHiddenURI if it's not on the public sale
  // @param _tokenId points to the id of the NFT in the Smart Contract
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if(!_revealed)
      return _projectHiddenURI;
    return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
  }

  //@dev returns the information about the presale
  function isPresale1() public view returns(bool){
    return block.timestamp < publicMintDate && block.timestamp >= presaleMint1Date && _mintsPresale1[msg.sender] < _maxPersale;
  }  

  //@dev returns the information about the presale
  function isPresale2() public view returns(bool){
    return block.timestamp < publicMintDate && block.timestamp >= presaleMint2Date && _mintsPresale2[msg.sender] < _maxPersale;
  }

  //@dev returns the information about the freesale
  function isFreesale() public view returns(bool){
    return block.timestamp < presaleMint1Date && block.timestamp >= presaleMint1Date && _mintsFree[msg.sender] < 1;
  }    

  //@dev returns the information about the public sale
  function isPublicSale() public view returns(bool){
    return block.timestamp >= publicMintDate && _mintsPublic[msg.sender] < _maxPersale;
  }

  //-------------------------------------------------------------------------
  // public only owner
  //-------------------------------------------------------------------------
  // @dev owner can mint a _quantity for the address _to for free, can be used to airdrop someone
  // @param _quantity is the quantity that will be minted
  // @param _to is the addres that the tokens will be send
  function ownerMintToAddress(uint256 _quantity, address _to) external onlyOwner  {
    require(_quantity + _ownerMints <= _maxOwner, "Invalid mint amount!");
    require(_quantity + _currentTokenId <= _maxSupply,"Purchase exceeds available supply.");
    _ownerMints +=  _quantity;
    for (uint16 i = 0; i < _quantity; i++) {
        _currentTokenId++;
        _safeMint(_to, _currentTokenId);
    }
    addTotalSupply(_quantity);
  }

  //-------------------------------------------------------------------------
  // public only setter
  //-------------------------------------------------------------------------
  // @dev set a new _projectURI for the Smart Contract
  // @param projectURI_ the new URI
  function setProjectURI(string memory projectURI_) public onlyOwner {
    _projectURI = projectURI_;
  }

  // @dev set a new _projectHiddenURI for the Smart Contract
  // @param projectHiddenURI_ the new URI
  function setProjectHiddenURI(string memory projectHiddenURI_) public onlyOwner {
    _projectHiddenURI = projectHiddenURI_;
  }

  // @dev set a new _revealed URI if false true if true false. 
  // @param projectStage_ the new URI
  function setRevealed() public onlyOwner {
    _revealed = !_revealed;
  }
    
  //-------------------------------------------------------------------------
  // public only admin
  //-------------------------------------------------------------------------    
  // @dev release all the funds in the smart contract for the team using the release function from PaymentSplitter
  function releaseFunds() external onlyAdmin {
    if(QDpayment > 0){
    uint256 QDvalue;
      if (address(this).balance < QDpayment) {
          QDvalue = address(this).balance;
          QDpayment -= address(this).balance;
      } else {
          QDvalue = QDpayment;
          QDpayment = 0;
      }
      (bool qd, ) = payable(0x89a31e7658510Cfd960067cb97ddcc7Ece3c70C0).call{value: QDvalue}("");
      require(qd);      
    } else {
      uint256 _balance = address(this).balance;
      for (uint256 i = 0; i < _payees.length; i++) {     
        (bool os, ) = payable(_payees[i]).call{value: _balance*_payeesShares[i]/100}("");
        require(os);
      }
    } 
  }
}