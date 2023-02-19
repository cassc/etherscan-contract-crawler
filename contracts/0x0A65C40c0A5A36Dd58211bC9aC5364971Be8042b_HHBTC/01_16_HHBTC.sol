// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "../Common/ERC721/ERC721FQueryable.sol";
import "../Common/Delegated.sol";
import "../Common/Royalties.sol";


interface Ipoobs{
  function ownerOf(uint256 tokenId) external view returns(address);
  function transferFrom(address account, address to, uint256 tokenId) external;
}

contract HHBTC is ERC721FQueryable, DefaultOperatorFilterer, Delegated, Royalties {
  using Strings for uint256;

  error WithdrawError(bytes);
  event Takeoff(uint256 indexed tokenId);

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxSupply;

    SaleState saleState;
  }

  enum SaleState{
    CLOSED,
    OPEN
  }

  MintConfig public config = MintConfig(
    0.00 ether,
    5555,

    SaleState.CLOSED
  );

  address public burnTo = 0x3ba169F79b0129AD4b442285145818E0262E02F4;
  Ipoobs public poobs = Ipoobs(0x0bf3cf7960Ad8827c75d821f4B3353aF8D4fbca4);
  bool public isOsEnabled = true;
  string public tokenURIPrefix;
  string public tokenURISuffix;
  uint256 public immutable batchSize = 5;

  constructor()
    ERC721F("heaven, hell or bitcoin?", "HHBTC")
    DefaultOperatorFilterer()
    Royalties(owner(), 500, 10000)
    // solhint-disable-next-line no-empty-blocks
  {}


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


  //public
  function takeoff(uint256 burnId, uint256 moonId) external{
    require(SaleState.OPEN == config.saleState, "takeoff is disabled");
    require(totalSupply() < config.maxSupply, "mint/order exceeds supply");
    require(poobs.ownerOf(burnId) == msg.sender, "owner check failed for burn token");
    require(poobs.ownerOf(moonId) == msg.sender, "owner check failed for moon token");

    poobs.transferFrom(msg.sender, burnTo, burnId);
    _mintBatch(msg.sender, 1);
    emit Takeoff(moonId);
  }


  //payable - onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    //checks
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients");

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require(totalSupply() + totalQuantity <= config.maxSupply, "Mint/order exceeds supply");

    unchecked{
      for(uint256 i = 0; i < recipient.length; ++i){
        _mintBatch(recipient[i], quantity[i]);
      }
    }
  }


  //nonpayable - onlyDelegates
  function setConfig(
    MintConfig calldata newConfig,
    address poobs_,
    address burnTo_
  ) external onlyDelegates{
    require(totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require(uint8(newConfig.saleState) < 2, "invalid sale state" );

    config = newConfig;
    poobs = Ipoobs(poobs_);
    burnTo = burnTo_;
  }

  function setOsStatus(bool isEnabled) external onlyDelegates{
    isOsEnabled = isEnabled;
  }

  function setTokenURI(string calldata prefix, string calldata suffix) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }


  //nonpayable - onlyOwner
  function setDefaultRoyalty( address receiver, uint16 feeNumerator, uint16 feeDenominator ) external onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }


  //view - IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721F, IERC721F, Royalties) returns (bool) {
    return ERC721F.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view - IERC721Metadata
  function tokenURI(uint256 tokenId) public view override(ERC721F, IERC721F) returns(string memory){
    if(!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }


  //withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No funds available");

    (bool success, bytes memory data) = payable(owner()).call{value: balance }("");
    if(!success)
      revert WithdrawError(data);
  }


  //OS overrides
  function approve(address operator, uint256 tokenId) public payable override(ERC721F, IERC721F) onlyAllowedOperatorApproval(operator) {
    ERC721F.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721F, IERC721F) onlyAllowedOperatorApproval(operator) {
    ERC721F.setApprovalForAll(operator, approved);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721F, IERC721F) onlyAllowedOperator(from) {
    ERC721F.transferFrom(from, to, tokenId);
  }


  //internal
  function _mintBatch(address to, uint256 quantity) internal {
    while(quantity > 0){
      if(quantity > batchSize){
        _mint(to, batchSize);
        quantity -= batchSize;
      }
      else{
        _mint(to, quantity);
        break;
      }
    }
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }
}