// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/****************************************
 * @author: hammm.eth                   *
 * @team:   GoldenX                     *              
 ****************************************/

import "./ERC721Batch.sol"; 
import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LoresLittleVillains is ERC721Batch, Delegated, PaymentSplitterMod {
  using Strings for uint256;
  using ECDSA for bytes32;

  address private _signer;

  uint256 public _maxSupply = 777;
  uint256 public _price = 0.07 ether;
  uint256 public _maxMint = 3;

  uint256 public _maxAirdrop = 111;
  uint256 public _airdropped = 0;

  mapping (address => uint256) public _presaleCount;

  enum SaleState {
    paused,
    preSale,
    publicSale
  }

  SaleState public saleState = SaleState.paused;

  string private _URIbase = "https://llv-metadata.s3.amazonaws.com/metadata/";
  string private _URIsuffix = ".json";

  constructor()
    ERC721B("LoresLittleVillains", "LLV", 0)
  {
    _addPayee(0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A, 10);
    _addPayee(0x8b19ea4890F8ebe4C2860116A90b3B46D83b3828, 90);
  }

  fallback() external payable {}

  function verify( uint256 quantity, bytes calldata signature ) private view returns ( bool ) {
    address signerCheck = getSigner( msg.sender, quantity.toString(), signature );

    if (signerCheck == _signer) {
      return true;
    } 
    return false;
  }

  function getSigner( address toAccount, string memory quantity, bytes memory signature ) private view returns ( address ) {
    bytes32 hash = createHash( toAccount, quantity );
    return hash.toEthSignedMessageHash().recover( signature );
  }

  function createHash( address toAccount, string memory quantity ) private view returns ( bytes32 ) {
    return keccak256( abi.encodePacked( address(this), toAccount, quantity ) );
  }
  
  function setSigner( address signer ) external onlyOwner{
    _signer = signer;
  }

  function mint( uint256 quantity, bytes calldata signature ) external payable {
    require( saleState != SaleState.paused, "Mint: Sale is currently paused." );

    uint256 supply = totalSupply();
    require( msg.value >= _price * quantity, "Mint: ETH Sent Is Incorrect." );
    require( quantity + supply <= _maxSupply, "Mint: Total supply exceeded" );
    require( quantity + (supply - _airdropped) <= (_maxSupply - _maxAirdrop), "Mint: Purchased supply exceeded" );
    require( quantity <= _maxMint, "Mint: Invalid quantity" );

    if (saleState == SaleState.preSale) {
      require( verify(quantity, signature), "Mint: Invalid Address." );
      require( _presaleCount[msg.sender] + quantity <= 3, "Mint: Exceeding presale allowance." );
      _presaleCount[msg.sender] += quantity;
    }

    for (uint256 i; i < quantity; ++i) { 
      mint1(msg.sender);
    }
  }

  function mintTo ( uint256[] calldata quantity, address[] calldata recipient ) external payable onlyDelegates { 
    require( quantity.length == recipient.length, "mintTo: Must provide equal quantities and recipients" );

    uint256 supply = totalSupply();
    uint256 sum = 0;
    for(uint q; q < quantity.length; ++q){
      sum += quantity[q];
    }
    require( sum + supply <= _maxSupply, "mintTo: Total supply exceeded" );
    require( sum + _airdropped <= _maxAirdrop, "mintTo: Airdrop supply exceeded" );

    for(uint r; r < recipient.length; ++r){
      for(uint q; q < quantity[r]; ++q){
        mint1( recipient[r] );
      }
    }
    
    _airdropped += sum;
  }
 
  function setConfig(uint256 newMaxSupply, uint256 newPrice, uint256 newMaxMint, uint256 newMaxAirdrop) external onlyDelegates {
    if (_maxSupply != newMaxSupply) {
      require(totalSupply() < newMaxSupply, "setConfig: Max supply must be greater than current supply.");
      _maxSupply = newMaxSupply;
    }
    
    if (_price != newPrice) {
      _price = newPrice;
    }

    if (_maxMint != newMaxMint) {
      require( newMaxMint >= 0, "setConfig: Invalid newMaxMint" );
      _maxMint = newMaxMint;
    }

    if (_maxAirdrop != newMaxAirdrop) {
      _maxAirdrop = newMaxAirdrop;
    }
  }

  function setBaseURI ( string memory newURIbase, string memory newURIsuffix ) external onlyDelegates {
    _URIbase = newURIbase;
    _URIsuffix = newURIsuffix;
  }

  function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
    require(_exists(tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked(_URIbase, tokenId.toString(), _URIsuffix));
  }

  function setSaleState (SaleState newSaleState) external onlyDelegates {
    require( saleState != newSaleState, "setSaleState: Cannot be current sale state" );
    saleState = newSaleState;
  }

  function mint1( address to ) internal {
    uint tokenId = _next();
    tokens.push(Token(to));

    _safeMint( to, tokenId, "" );
  }

  function _mint(address to, uint tokenId) internal override {
    emit Transfer(address(0), to, tokenId);
  }
}