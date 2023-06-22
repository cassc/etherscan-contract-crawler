// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC721, IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC721Batch} from "../Common/ERC721/IERC721Batch.sol";

import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import {Delegated} from "../Common/Delegated.sol";
import {Merkle2} from "../Common/Merkle2.sol";
import {PaymentSplitterInt} from "../Common/PaymentSplitterInt.sol";
import {Royalties} from "../Common/Royalties.sol";

import {Futurists721, FuturistsBatch} from "./FuturistsBase.sol";


contract Futurists is FuturistsBatch, DefaultOperatorFilterer, Delegated, Merkle2, Royalties, PaymentSplitterInt {
  error InvalidSupply(uint8 code);
  error InvalidToken();
  error NoBalance();
  error NotListed();
  error NotImplemented();
  error OperatorDenied();
  error OrderExceedsAllowance(uint8 code);
  error OrderExceedsSupply();
  error ReservationExceeded();
  error SalesClosed();
  error Unbalanced();
  error UnequalPayment();


  modifier onlyAllowedOperator(address from) override {
    if (isOsEnabled && from != msg.sender) {
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

  modifier onlyCrossmint(){
    if(msg.sender != crossmintOperator) revert OperatorDenied();

    _;
  }


  constructor()
    Royalties(address(this), 10, 100)
    Merkle2()
  {
    _addPayee(0x2C2c46cc75E9cD8f877cee6fcF2b632B4a41cd53, 97);
    _addPayee(0xa2EE77DF4fa9937af91998207cb2576Bd8192cBE,  1);
    _addPayee(0xeb264F44a80e7F0225DAb0fb904223E20CD7fC71,  1);
    _addPayee(0x3C073A4763501E1Cc330Ad45c3e140f744E3035F,  1);
  }

  function crossmint(address recipient, uint16[] calldata tokenIds) external payable onlyCrossmint{
    bytes32[] memory proof;
    _mint(tokenIds, recipient, proof);
  }

  function mint(uint16[] calldata tokenIds, bytes32[] calldata proof) external payable {
    _mint(tokenIds, msg.sender, proof);
  }


  // onlyDelegates
  function mintTo(uint16[][] calldata tokenIds, address[] calldata recipients, bool isReserved) external payable onlyDelegates {
    if(tokenIds.length != recipients.length) revert Unbalanced();

    uint16 total = 0;
    for(uint256 i = 0; i < recipients.length; ++i){
      total += uint16(tokenIds[i].length);
    }


    if(range.supply + reserved + total > CONFIG.maxSupply)
      revert OrderExceedsSupply();

    if(isReserved){
      if(range.supply + total > CONFIG.maxSupply)
        revert OrderExceedsSupply();

      if(total <= reserved)
        reserved -= total;
      else
        revert ReservationExceeded();
    }
    else{
      if(range.supply + reserved + total > CONFIG.maxSupply)
        revert OrderExceedsSupply();
    }

    for(uint256 i = 0; i < recipients.length; ++i){
      address recipient = recipients[i];
      uint16[] memory ids = tokenIds[i];
      for(uint16 j = 0; j < ids.length; ++j){
        _mintSpecific(ids[j], recipient, false);
      }
    }
  }

  function setOsStatus(bool isEnabled) external onlyDelegates{
    isOsEnabled = isEnabled;
  }


  // onlyEOA
  function setConfig(MintConfig calldata newConfig) external onlyEOA {
    if(newConfig.maxSupply < range.supply)
      revert InvalidSupply(1);

    if(newConfig.maxSupply > MAX_SUPPLY)
      revert InvalidSupply(2);

    CONFIG = newConfig;
  }

  function setCrossmint(address operator) external onlyEOA{
    crossmintOperator = operator;
  }

  function setReserved(uint16 newReserved) external onlyEOA {
    reserved = newReserved;
  }

  function setTokenURI(
    string calldata prefix,
    string calldata suffix
  ) external onlyEOA {
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  function setVouchers(address[] calldata accounts, uint16[] calldata quantities) external onlyEOA {
    if(accounts.length != quantities.length) revert Unbalanced();

    for(uint256 i = 0; i < accounts.length; ++i){
      owners[accounts[i]].vouchers = quantities[i];
    }
  }


  // onlyOwner
  function setDefaultRoyalty(address receiver, uint16 feeNumerator, uint16 feeDenominator) public onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }

  function withdraw() external onlyOwner {
    uint256 count = _payeeLength();
    for(uint256 i = 0; i < count; ++i){
      release(payable(payee(i)));
    }
  }


  //OS overrides
  function approve(address operator, uint256 tokenId) public override(Futurists721, IERC721) onlyAllowedOperatorApproval(operator) {
    Futurists721.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(Futurists721, IERC721) onlyAllowedOperatorApproval(operator) {
    Futurists721.setApprovalForAll(operator, approved);
  }

  function _transfer(address from, address to, uint256 tokenId) internal override(Futurists721) onlyAllowedOperator(from) {
    Futurists721._transfer(from, to, tokenId);
  }


  // view
  function supportsInterface(bytes4 interfaceId) public pure override(ERC165, Royalties, IERC165) returns(bool){
    return interfaceId == type(IERC165).interfaceId
      || interfaceId == type(IERC721).interfaceId
      || interfaceId == type(IERC721Enumerable).interfaceId
      || interfaceId == type(IERC721Metadata).interfaceId
      || interfaceId == type(IERC2981).interfaceId;
  }

  function tokenURI(uint256 tokenId) external view returns(string memory){
    return string.concat(tokenURIPrefix, Strings.toString(tokenId), tokenURISuffix);
  }


  // private
  function _mint(
    uint16[] calldata tokenIds,
    address recipient,
    bytes32[] memory proof
  ) private {
    MintConfig memory config = CONFIG;
    if(config.saleState & uint8(SaleState.PUBLIC) == uint8(SaleState.PUBLIC)){
      //ok
    }
    else if(config.saleState & uint8(SaleState.ALLOWLIST) == uint8(SaleState.ALLOWLIST)){
      bytes32 leaf = keccak256(abi.encodePacked(recipient));
      if(!_isValidProof(leaf, proof))
        revert NotListed();
    }
    else{
      revert SalesClosed();
    }


    uint16 tokenCount = uint16(tokenIds.length);
    if(range.supply + reserved + tokenCount > config.maxSupply)
      revert OrderExceedsSupply();


    uint16 paid = 0;
    uint16 free = owners[recipient].vouchers;
    if(free > 0){
      if(tokenCount > free)
        paid = tokenCount - free;
      else
        free = tokenCount;

      owners[recipient].vouchers -= free;
    }
    else{
      paid = tokenCount;
    }


    if(paid > config.maxOrder)
      revert OrderExceedsAllowance(1);

    if(owners[recipient].purchased + paid > config.maxWallet)
      revert OrderExceedsAllowance(2);

    if(paid * config.ethPrice != msg.value)
      revert UnequalPayment();

    for(uint256 i = 0; i < tokenCount; ++i){
      uint16 tokenId = tokenIds[i];
      if(tokenId < 1 || tokenId > config.maxSupply)
        revert InvalidToken();

      _mintSpecific(tokenIds[i], recipient, i >= free);
    }
  }
}