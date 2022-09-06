// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Merkle.sol";

contract MysticsUniverse is ERC721A, ERC2981, Merkle {
  using Address for address;

  enum SaleState{
    NONE,
    PRESALE,
    MAINSALE
  }

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  MintConfig public config = MintConfig(
    0.059 ether, //ethPrice
        1,       //maxMint
        1,       //maxOrder
     5000,       //maxSupply

    SaleState.NONE
  );

  string public tokenURIPrefix = "";
  string public tokenURISuffix = "";

  string private _contractURI = "https://mysticsuniverse.io/contract.json";

  constructor()
    ERC721A("Mystics Universe", "MU" ){
    setDefaultRoyalty( address(this), 500 );
  }

  //safety first
  receive() external payable {}


  //payable
  function mintSingle( bytes32[] calldata proof ) external payable {
    MintConfig memory cfg = config;
    require( _numberMinted( msg.sender ) < cfg.maxMint, "Only 1 per wallet" );
    require( totalSupply() < cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value == cfg.ethPrice, "Ether sent is not correct" );

    if( cfg.saleState == SaleState.PRESALE ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ), "You are not on the access list" );
    }
    else{
      require( cfg.saleState == SaleState.MAINSALE, "sale is not active" );
    }

    _mint( msg.sender, 1 );
  }


  function mintX( uint16 quantity, bytes32[] calldata proof ) external payable {
    MintConfig memory cfg = config;
    require( _numberMinted( msg.sender ) + quantity <= cfg.maxMint, "Only 1 per wallet" );
    require( quantity <= cfg.maxOrder, "Order too big" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value == quantity * cfg.ethPrice, "Ether sent is not correct" );

    if( cfg.saleState == SaleState.PRESALE ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ), "You are not on the access list" );
    }
    else{
      require( cfg.saleState == SaleState.MAINSALE, "sale is not active" );
    }

    _mintBatch( msg.sender, quantity );
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    for(uint256 i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    uint256 tokenId = totalSupply();
    require( tokenId + totalQuantity <= config.maxSupply, "mint/order exceeds supply" );

    for(uint256 i = 0; i < recipient.length; ++i){
      _mintBatch( recipient[i], quantity[i] );
    }
  }

  function setConfig( MintConfig calldata config_ ) external onlyDelegates{
    require( config.maxOrder <= config.maxSupply, "max order must be lte max supply" );
    require( totalSupply()   <= config.maxSupply, "max supply must be gte total supply" );
    require( uint8(config.saleState) < 3, "invalid sale state" );

    config = config_;
  }

  function setContractURI( string memory newContractURI ) external onlyDelegates {
    _contractURI = newContractURI;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  //view: OS
  function contractURI() external view returns( string memory ){
    return _contractURI;
  }

  //view: IERC165
  function supportsInterface( bytes4 interfaceId ) public view override( ERC721A, ERC2981 ) returns( bool ){
    return ERC721A.supportsInterface( interfaceId ) || ERC2981.supportsInterface( interfaceId );
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) public view override returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return bytes(tokenURIPrefix).length > 0 ?
      string(abi.encodePacked(tokenURIPrefix, _toString(tokenId), tokenURISuffix)) :
      "";
  }


  //onlyOwner
  function setDefaultRoyalty( address receiver, uint96 feeNumerator ) public onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator );
  }


  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "no funds available");

    uint256 totalBalance = address(this).balance;
    uint256 payeeBalanceTwo   = totalBalance * 16 / 100;
    uint256 payeeBalanceThree = totalBalance *  5 / 100;
    uint256 payeeBalanceOne   = totalBalance - ( payeeBalanceTwo + payeeBalanceThree );

    Address.sendValue(payable(0xb3684fa4cFe8faDFD19058bf9fe38E550403DA5B), payeeBalanceOne);
    Address.sendValue(payable(0x64263E7Fb96b45a6fdfB9dFaE1B002dDFCA1f47E), payeeBalanceTwo);
    Address.sendValue(payable(0x729BaB42701A8F988602e40aC75619d1F21e4a2f), payeeBalanceThree);
  }


  //internal
  function _mintBatch( address to, uint256 quantity ) internal {
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