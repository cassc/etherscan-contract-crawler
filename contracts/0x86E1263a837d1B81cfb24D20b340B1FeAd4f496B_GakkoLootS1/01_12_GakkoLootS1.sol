// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./IGakkoLoot.sol";
import "../Common/Delegated.sol";


contract GakkoLootS1 is ERC721AQueryable, OperatorFilterer, Delegated {
  using Address for address;

  bool public isEnabled = true;
  bool public isOSEnabled = true;
  uint256 public maxSupply = 5555;
  string public tokenURIPrefix;
  string public tokenURISuffix;
  mapping(uint16 => bool) public tokensClaimed;

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
    Delegated()
    ERC721A("Gakko Loot S1", "LOOT1" )
    OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
  // solhint-disable-next-line no-empty-blocks
  {}


  function handleClaims(address owner, TokenList calldata list) external onlyDelegates{
    require(isEnabled, "claims disabled");
    require(totalSupply() + list.length <= maxSupply, "claim exceeds supply");
    _mintBatch(owner, list.length);
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "must provide equal quantities and recipients" );

    unchecked {
      uint256 totalQuantity = 0;
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
      require(totalSupply() + totalQuantity <= maxSupply, "mint/order exceeds supply" );      

      for(uint256 i = 0; i < recipient.length; ++i){
        _mintBatch(recipient[i], quantity[i]);
      }
    }
  }

  function setConfig(bool isEnabled_, uint256 supply_) public onlyDelegates{
    isEnabled = isEnabled_;
    maxSupply = supply_;
  }

  function setOsStatus(bool isOSEnabled_) external onlyDelegates{
    isOSEnabled = isOSEnabled_;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
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
    super.transferFrom(from, to, tokenId);
  }


  // internal
  function _mintBatch(address to, uint16 quantity) internal {
    while( quantity > 0 ){
      if( quantity > 4 ){
        _mint( to, 5 );
        quantity -= 5;
      }
      else{
        _mint( to, quantity );
        break;
      }
    }
  }
}