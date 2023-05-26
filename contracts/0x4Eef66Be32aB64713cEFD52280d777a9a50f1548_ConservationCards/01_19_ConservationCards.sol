// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC1155, IERC1155, IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import {Merkle2} from "./Common/Merkle2.sol";
import {Royalties} from "./Common/Royalties.sol";

contract ConservationCards is ERC1155, DefaultOperatorFilterer, Merkle2, Royalties {
  enum SaleState {
    CLOSED,
    ALLOWLIST,
    PUBLIC,
    COMBINED
  }

  struct Token{
    uint64 ethPrice;
    uint64 discPrice;
    uint16 balance;
    uint16 supply;

    bool isMintActive;

    string name;
    string uri;
  }

  bool public isOsEnabled;
  string public name;
  SaleState public saleState;
  string public symbol;
  uint256 public totalMinted;
  Token[] public tokens;


  modifier onlyAllowedOperator(address from) override {
    if (isOsEnabled && from != _msgSender()) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) override {
    if(isOsEnabled){
      _checkFilterOperator(operator);
    }
    _;
  }


  constructor()
    ERC1155("")
    Royalties(0x17Aa054107181D576d2b52366a4a199D7FA2fAF3, 10, 100)
  {
    isOsEnabled = true;
    name = "Conservation Cards";
    symbol = "CC";
    setMerkleRoot(0x2a562e9f360bb35e629dce27d1ba09f397ae0ef73569d70e7d4f5776afb5eea7);

    bool isMintEnabled = false;
    setToken(0, Token(0, 0, 0, 0, false, "", ""));
    setToken(1, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0299  ether,
      balance:          0,
      supply:       10000,
      isMintActive: false,
      name:           "1",
      uri:             ""
    }));

    setToken(2, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "2",
      uri:             ""
    }));

    setToken(3, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "3",
      uri:             ""
    }));

    setToken(4, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "4",
      uri:             ""
    }));

    setToken(5, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "5",
      uri:             ""
    }));

    setToken(6, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "6",
      uri:             ""
    }));

    setToken(7, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "7",
      uri:             ""
    }));

    setToken(8, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "8",
      uri:             ""
    }));
    
    setToken(9, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "9",
      uri:             ""
    }));

    setToken(10, Token({
      ethPrice:         0.0299  ether,
      discPrice:        0.0279  ether,
      balance:          0,
      supply:       10000,
      isMintActive: isMintEnabled,
      name:           "10",
      uri:             ""
    }));
  }


  // view
  function exists(uint256 id) public view returns(bool) {
    return id < tokens.length;
  }

  // view
  function supportsInterface(bytes4 interfaceId) public pure override(ERC1155, Royalties) returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC1155).interfaceId
      || interfaceId == type(IERC1155MetadataURI).interfaceId
      || interfaceId == type(IERC2981).interfaceId;
  }

  function totalSupply(uint256 id) external view returns(uint256){
    require( exists( id ), "CC: Specified token (id) does not exist" );
    return tokens[id].supply;
  }

  function uri(uint256 id) public view override returns(string memory){
    require( exists( id ), "CC: Specified token (id) does not exist" );
    return tokens[id].uri;
  }


  //payable
  function mintBatch(
    uint256[] calldata tokenIds,
    uint256[] calldata quantities,
    bytes32[] calldata proof
  ) external payable{
    require(tokenIds.length == quantities.length, "CC: Unbalanced request");


    bool isAllowlist = false;
    if(saleState != SaleState.PUBLIC){
      if(saleState == SaleState.CLOSED)
        revert("CC: All sales are closed");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      isAllowlist = _isValidProof(leaf, proof);
      if(saleState == SaleState.ALLOWLIST && !isAllowlist)
        revert("CC: Allowlist sales are closed");
    }


    uint256 totalPrice = 0;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      uint256 tokenId = tokenIds[i];
      require(tokenId < tokens.length, "CC: Nonexistant token");
      
      Token storage token = tokens[tokenId];
      require(token.isMintActive, "CC: Token disabled");

      uint16 quantity = uint16(quantities[i]);
      require(token.balance + quantity < token.supply, "CC: transaction exceeds supply");

      totalMinted += quantity;
      token.balance += quantity;
      if(isAllowlist)
        totalPrice += (token.discPrice * quantity);
      else
        totalPrice += (token.ethPrice * quantity);
    }
    

    require(msg.value == totalPrice, "CC: Ether sent is not correct" );
    _mintBatch(msg.sender, tokenIds, quantities, "");
  }

  // onlyDelegates
  function mintTo(
    address[] calldata accounts,
    uint256[] calldata ids,
    uint256[] calldata quantities
  ) external payable onlyDelegates {
    require( accounts.length == ids.length,   "CC: Must provide equal accounts and ids" );
    require( ids.length == quantities.length, "CC: Must provide equal ids and quantities");
    for(uint256 i; i < ids.length; ++i ){
      totalMinted += quantities[i];
      _mint(accounts[i], ids[i], quantities[i], "");
    }
  }


  // onlyEOA
  function setActive(uint256[] calldata ids, bool[] calldata isActive) external onlyEOA{
    require(ids.length == isActive.length, "CC: Unbalanced request");

    for(uint256 i = 0; i <ids.length; ++i){
      tokens[ids[i]].isMintActive = isActive[i];
    }
  }

  function setOsStatus(bool isEnabled) external onlyEOA{
    isOsEnabled = isEnabled;
  }

  function setSaleState(SaleState newState) external onlyEOA{
    saleState = newState;
  }

  function setToken(uint256 id, Token memory token) public onlyEOA{
    require( id < tokens.length || id == tokens.length, "CC: Invalid token id" );
    if( id == tokens.length )
      tokens.push();


    Token memory prev = tokens[id];
    require(prev.balance <= token.supply, "CC: Specified supply is lower than current balance" );

    tokens[id] = Token({
      ethPrice:  token.ethPrice,
      discPrice: token.discPrice,
      balance: prev.balance,
      supply: token.supply,

      isMintActive: token.isMintActive,

      name: token.name,
      uri:  token.uri
    });

    emit URI(token.uri, id);
  }

  // onlyOwner
  function setDefaultRoyalty(address receiver, uint16 feeNumerator, uint16 feeDenominator) public onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }

  function withdraw() external onlyOwner {
    (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
    require(success, "CC: Withdraw error");
  }


  // view: OS overrides
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override onlyAllowedOperator(from) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}