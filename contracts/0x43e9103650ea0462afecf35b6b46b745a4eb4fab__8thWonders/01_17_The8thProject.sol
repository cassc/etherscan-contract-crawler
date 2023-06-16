// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import './Blimpie/Delegated.sol';
import './Blimpie/ERC721EnumerableLite.sol';
import './Blimpie/PaymentSplitterMod.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract _8thWonders is Delegated, ERC721EnumerableLite, PaymentSplitterMod {
  using Strings for uint;

  uint public MAX_ORDER      = 20;
  uint public MAX_SUPPLY     = 1111;
  uint public MAINSALE_PRICE = 0.06 ether;
  uint public PRESALE_PRICE  = 0.05 ether;

  bool public isMintActive   = false;
  bool public isPresaleActive   = false;
  mapping(address=>uint) public accessList;

  string private _tokenURIPrefix = '';
  string private _tokenURISuffix = '';

  address[] private addressList = [
    0x627137FC6cFa3fbfa0ed936fB4B5d66fB383DBE8,
    0x31727A6d264a60bFd6A637505f87AEe4e1e3b1A9
  ];

  uint[] private shareList = [
    70,
    30
  ];

  constructor()
    Delegated()
    ERC721B("8th Wonders", "8THWONDERS", 0)
    PaymentSplitterMod( addressList, shareList ){
  }

  //public view
  fallback() external payable {}

  function tokenURI(uint tokenId) external view override returns (string memory) {
    require(_exists(tokenId), "Query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //public payable
  function presale( uint quantity ) external payable {
    require( isPresaleActive,               "Presale is not active"     );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= PRESALE_PRICE * quantity, "Ether sent is not correct" );
    require( accessList[msg.sender] > 0,    "Not authorized"            );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    accessList[msg.sender] -= quantity;

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }

  function mint( uint quantity ) external payable {
    require( isMintActive,                  "Sale is not active"        );
    require( quantity <= MAX_ORDER,         "Order too big"             );
    require( msg.value >= MAINSALE_PRICE * quantity, "Ether sent is not correct" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }


  //delegated payable
  function burnFrom( address owner, uint[] calldata tokenIds ) external payable onlyDelegates{
    for(uint i; i < tokenIds.length; ++i ){
      require( _exists( tokenIds[i] ), "Burn for nonexistent token" );
      require( _owners[ tokenIds[i] ] == owner, "Owner mismatch" );
      _burn( tokenIds[i] );
    }
  }

  function mintTo(uint[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    uint supply = totalSupply();
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _mint( recipient[i], supply++ );
      }
    }
  }


  //delegated nonpayable
  function resurrect( uint[] calldata tokenIds, address[] calldata recipients ) external onlyDelegates{
    require(tokenIds.length == recipients.length,   "Must provide equal tokenIds and recipients" );

    address to;
    uint tokenId;
    address zero = address(0);
    for(uint i; i < tokenIds.length; ++i ){
      to = recipients[i];
      require(recipients[i] != address(0), "resurrect to the zero address" );

      tokenId = tokenIds[i];
      require( !_exists( tokenId ), "can't resurrect existing token" );

      
      _owners[tokenId] = to;
      // Clear approvals
      _approve(zero, tokenId);
      emit Transfer(zero, to, tokenId);
    }
  }

  function setAccessList(address[] calldata accounts, uint[] calldata quantities) external onlyDelegates{
    require(accounts.length == quantities.length, "Must provide equal accounts and quantities" );
    for(uint i; i < accounts.length; ++i){
      accessList[ accounts[i] ] = quantities[i];
    }
  }

  function setActive(bool isPresaleActive_, bool isMintActive_) external onlyDelegates{
    require( isPresaleActive != isPresaleActive_ || isMintActive != isMintActive_, "New value matches old" );
    isPresaleActive = isPresaleActive_;
    isMintActive = isMintActive_;
  }

  function setBaseURI(string calldata newPrefix, string calldata newSuffix) external onlyDelegates{
    _tokenURIPrefix = newPrefix;
    _tokenURISuffix = newSuffix;
  }

  function setMax(uint maxOrder, uint maxSupply) external onlyDelegates{
    require( MAX_ORDER != maxOrder || MAX_SUPPLY != maxSupply, "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
    MAX_ORDER = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrice(uint presalePrice, uint mainsalePrice ) external onlyDelegates{
    require( PRESALE_PRICE != presalePrice || MAINSALE_PRICE != mainsalePrice, "New value matches old" );
    PRESALE_PRICE = presalePrice;
    MAINSALE_PRICE = mainsalePrice;
  }


  //owner
  function addPayee(address account, uint256 shares_) external onlyOwner {
    _addPayee(account, shares_);
  }

  function setPayee( uint index, address account, uint newShares ) external onlyOwner {
    _setPayee(index, account, newShares);
  }


  //internal
  function _burn(uint tokenId) internal override {
    address curOwner = ERC721B.ownerOf(tokenId);

    // Clear approvals
    _approve(owner(), tokenId);
    _owners[tokenId] = address(0);
    emit Transfer(curOwner, address(0), tokenId);
  }

  function _mint(address to, uint tokenId) internal override {
    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }
}