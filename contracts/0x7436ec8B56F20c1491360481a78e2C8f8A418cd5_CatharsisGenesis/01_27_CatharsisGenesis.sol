// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";

import "./ERC721Attachment.sol";

import "../Shared/Delegated.sol";
import "../Shared/Merkle.sol";
import "../Shared/Royalties.sol";

//DefaultOperatorFilterer
contract CatharsisGenesis is Delegated, ERC721Attachment, OperatorFilterer, Royalties, Merkle {
  using Address for address;
  using Strings for uint256;

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  enum SaleState{
    NONE,
    PRESALE,
    MAINSALE
  }

  MintConfig public config = MintConfig(
    0.17 ether,
    1984,
    1984,
    1984,

    SaleState.NONE
  );

  bool public isOsEnabled;
  string public tokenURIPrefix;
  string public tokenURISuffix;

  constructor()
    ERC721B("Catharsis: Genesis", "C:GRINGS")
    OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true)
    Royalties( owner(), 500, 10000 )
    // solhint-disable-next-line no-empty-blocks
    {}


  //safety first
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}


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




  //public - payable
  function mint( uint16 quantity, bytes32[] calldata proof ) external payable {
    //checks
    require( quantity > 0, "Must order 1+" );

    MintConfig memory cfg = config;
    Owner memory prev = owners[msg.sender];
    require( quantity <= cfg.maxOrder,                  "Order too big" );
    require( prev.purchased + quantity <= cfg.maxMint,  "Mint limit reached" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value == cfg.ethPrice * quantity,      "Ether sent is not correct" );

    // solhint-disable-next-line no-empty-blocks
    if( cfg.saleState == SaleState.MAINSALE ){}
    else if( cfg.saleState == SaleState.PRESALE ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ),  "Not on the access list" );
    }
    else{
      revert( "Sale is not active" );
    }

    //effects & interactions
    _mintSequential( msg.sender, quantity, true );
  }


  //payable - onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    //checks
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require( totalSupply() + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    unchecked{
      for(uint256 i; i < recipient.length; ++i){
        _mintSequential(recipient[i], quantity[i], false);
      }
    }
  }


  //nonpayable - onlyDelegates
  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( uint8(newConfig.saleState) < 3, "invalid sale state" );

    config = newConfig;
  }

  function setOsStatus(bool isEnabled) external onlyDelegates{
    isOsEnabled = isEnabled;
  }

  function setTokensModels(uint16[] calldata tokenIds, uint16[] calldata models) external onlyDelegates{
    require(tokenIds.length == models.length, "Must provide equal tokenIds and models" );
    unchecked{
      for(uint i = 0; i < tokenIds.length; ++i){
        tokens[tokenIds[i]].model = models[i];
      }
    }
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }


  //nonpayable - onlyDelegates - IAttachmentProvider
  function setAttachmentHandler(address collection, AttachmentHandler calldata handler) external onlyDelegates{
    attachmentHandlers[collection] = handler;
  }


  //nonpayable - onlyOwner
  function setDefaultRoyalty( address receiver, uint16 feeNumerator, uint16 feeDenominator ) external onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }


  //view - IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableB, Royalties) returns (bool) {
    return ERC721EnumerableB.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view - IERC721Metadata
  function tokenURI( uint256 tokenId ) external view returns( string memory ){
    require(_exists(tokenId), "Genesis: query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }


  //withdraw
  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "Genesis: No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //OS overrides
  function approve(address operator, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721B, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override(ERC721B, IERC721)
      onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721B, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }
}