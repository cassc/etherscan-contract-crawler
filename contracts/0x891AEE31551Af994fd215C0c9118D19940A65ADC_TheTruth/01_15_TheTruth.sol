// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";

import "../../Common/ERC721/ERC721FQueryable.sol";
import "../../Common/Delegated.sol";
import "../../Common/Royalties.sol";


interface IFelineFiendz{
  function burnFrom( address account, uint[] calldata tokenIds ) external;
  function isOwnerOf( address account, uint[] calldata tokenIds ) external view returns( bool );
}

contract TheTruth is ERC721FQueryable, OperatorFilterer, Delegated, Royalties {
  using Strings for uint256;

  error WithdrawError(bytes);

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  enum SaleState{
    CLOSED,
    OPEN
  }

  MintConfig public config = MintConfig(
    0.0069 ether,
    3888,
    3888,
    3888,

    SaleState.CLOSED
  );

  IFelineFiendz public FIENDZ = IFelineFiendz(0xAcfA101ECE167F1894150e090d9471aeE2dD3041);
  bool public isOsEnabled = true;
  string public tokenURIPrefix;
  string public tokenURISuffix;
  uint256 public immutable batchSize = 5;

  constructor()
    ERC721F("The Truth", "PSY")
    OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
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
  function forge(uint256 mergeId, uint256 burnId) external{
    require(SaleState.OPEN == config.saleState, "Forging is disabled");
    require(totalSupply() < config.maxSupply, "Mint/order exceeds supply");

    uint256[] memory allTokens = new uint256[](2);
    allTokens[0] = mergeId;
    allTokens[1] = burnId;
    require(FIENDZ.isOwnerOf(msg.sender, allTokens), "Owner check failed");

    uint256[] memory burnTokens = new uint256[](1);
    burnTokens[0] = burnId;
    FIENDZ.burnFrom(msg.sender, burnTokens);

    _mint(msg.sender, 1);
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
  function setConfig(MintConfig calldata newConfig) external onlyDelegates{
    require(newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require(totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require(uint8(newConfig.saleState) < 3, "invalid sale state" );

    config = newConfig;
  }

  function setFiendz(IFelineFiendz newAddress) external onlyDelegates{
    FIENDZ = newAddress;
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