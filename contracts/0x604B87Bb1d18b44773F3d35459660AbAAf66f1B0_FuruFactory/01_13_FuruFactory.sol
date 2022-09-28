// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Merkle.sol";

contract FuruFactory is ERC721A, ERC2981, Merkle{
  using Address for address;

  enum SaleState{
    NONE,
    WHITELIST,
    ALLOWLIST,
    _3,
    PUBLIC
  }

  struct MintConfig{
    uint64 ethPrice;
    uint16 maxMint;
    uint16 maxOrder;
    uint16 maxSupply;

    SaleState saleState;
  }

  MintConfig public config = MintConfig(
    0.27 ether, //ethPrice
       2,       //maxMint
       2,       //maxOrder
     750,       //maxSupply

    SaleState.NONE
  );

  uint256 public currentPhase = 0;
  string public contractURI = "https://furufactory.com/web3/contract.json";
  string public tokenURIPrefix = "https://furufactory.com/web3/placeholder.json?";
  string public tokenURISuffix = "";
  address payable public treasury = payable(0x2E5F975a1b1439B8806f34E2cAA6729D97fBF434);

  MintConfig[] public phases;

  constructor()
    Delegated()
    ERC721A( "Furu Factory", "FF" ){
    setDefaultRoyalty( treasury, 850 );

    //page 0 - paused
    phases.push(MintConfig(
      0.27 ether, //ethPrice
        2,        //maxMint
        2,        //maxOrder
      750,        //maxSupply

      SaleState.NONE
    ));

    //phase 1 - WL
    phases.push(MintConfig(
      0.27 ether, //ethPrice
         2,        //maxMint
         2,        //maxOrder
       750,        //maxSupply

      SaleState.WHITELIST
    ));

    //phase 2 - paused
    phases.push(MintConfig(
      0.29 ether, //ethPrice
         1,       //maxMint
         1,       //maxOrder
       750,       //maxSupply

      SaleState.NONE
    ));

    //phase 3 - AL
    phases.push(MintConfig(
      0.29 ether, //ethPrice
         1,       //maxMint
         1,       //maxOrder
       750,       //maxSupply

      SaleState.ALLOWLIST
    ));
  }

  //safety first
  receive() external payable {}


  //payable
  function mint( uint16 quantity, bytes32[] calldata proof ) external payable{
    MintConfig memory cfg = config;
    require( _numberMinted( msg.sender ) + quantity <= cfg.maxMint, "Wallet limit exceeded" );
    require( quantity <= cfg.maxOrder, "Order too big" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value == quantity * cfg.ethPrice, "Ether sent is not correct" );

    if( cfg.saleState == SaleState.WHITELIST ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ), "You are not on the access list" );
    }
    else if( cfg.saleState == SaleState.ALLOWLIST ){
      require( _isValidProof( keccak256( abi.encodePacked( msg.sender ) ), proof ), "You are not on the access list" );
    }
    else{
      revert( "sale is not active" );
    }

    _mintBatch( msg.sender, quantity );
  }


  //onlyDelegates
  function mintTo(uint16[] calldata quantity, address[] calldata recipient) external payable onlyDelegates{
    require( quantity.length == recipient.length, "must provide equal quantities and recipients" );

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

  function nextPhase( bytes32 merkleRoot_ ) external onlyDelegates{
    ++currentPhase;
    require( currentPhase < phases.length, "invalid phase" );

    config = phases[ currentPhase ];
    setMerkleRoot( merkleRoot_ );
  }

  function setConfig( MintConfig calldata config_ ) external onlyDelegates{
    require( config_.maxOrder <= config_.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= config_.maxSupply, "max supply must be gte total supply" );
    require( uint8(config_.saleState) < 5, "invalid sale state" );

    config = config_;
  }

  function setContractURI( string memory newContractURI ) external onlyDelegates{
    contractURI = newContractURI;
  }

  function setPhase( uint256 phaseId, MintConfig calldata config_ ) external onlyDelegates{
    require( config_.maxOrder <= config_.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= config_.maxSupply, "max supply must be gte total supply" );
    require( uint8(config_.saleState) < 5, "invalid sale state" );

    if( phaseId == phases.length ){
      phases.push( config_ );
    }
    else if( phaseId < phases.length ){
      phases[ phaseId ] = config_;
    }
    else{
      revert( "invalid phaseId" );
    }
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    require( bytes(prefix).length > 0, "invalid prefix" );
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  function setTreasury( address payable newAddress ) external onlyOwner {
    treasury = newAddress;
  }


  //onlyOwner
  function withdraw() external onlyDelegates{
    uint256 totalBalance = address(this).balance;
    require(totalBalance > 0, "no funds available");

    Address.sendValue(treasury, totalBalance);
  }


  //onlyOwner
  function setDefaultRoyalty( address receiver, uint96 feeNumerator ) public onlyOwner{
    _setDefaultRoyalty( receiver, feeNumerator );
  }


  //view: IERC165
  function supportsInterface( bytes4 interfaceId ) public view override( ERC721A, ERC2981 ) returns( bool ){
    return ERC721A.supportsInterface( interfaceId ) || ERC2981.supportsInterface( interfaceId );
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) public view override returns( string memory ){
    require( _exists(tokenId), "query for nonexistent token" );
    return bytes(tokenURIPrefix).length > 0 ?
      string(abi.encodePacked(tokenURIPrefix, _toString(tokenId), tokenURISuffix)) :
      "";
  }


  //private
  function _mintBatch( address to, uint256 quantity ) private{
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