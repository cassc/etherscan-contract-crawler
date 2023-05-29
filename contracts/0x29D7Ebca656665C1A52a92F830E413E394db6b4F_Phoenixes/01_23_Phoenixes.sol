// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './Delegated.sol';
import './ERC721Staked.sol';
import './Merkle.sol';
import './Royalties.sol';

contract Phoenixes is Delegated, ERC721Staked, Royalties, Merkle {
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
    0.0888 ether,
       3,
       3,
    8888,

    SaleState.NONE
  );

  address public crossmintProxy = 0xdAb1a1854214684acE522439684a145E62505233;
  address public payee = 0x4d0b3D71F4De4aaF2ea798A20F4EaD55A0F7416F;
  uint256 public supplyPerFaction = 1111;
  string public tokenURIPrefix;
  string public tokenURISuffix;

  mapping(uint256 => uint16) public factionSupply;


  constructor()
    ERC721B("Phoenixes", "PHNX")
    Royalties( owner(), 690, 10000 ){
  }


  //safety first
  receive() external payable {}


  //view
  function getFactionSupply() external view returns(uint[] memory factions){
    factions = new uint[]( 9 );
    factions[0] = config.maxSupply - _supply;
    factions[1] = supplyPerFaction - factionSupply[1];
    factions[2] = supplyPerFaction - factionSupply[2];
    factions[3] = supplyPerFaction - factionSupply[3];
    factions[4] = supplyPerFaction - factionSupply[4];
    factions[5] = supplyPerFaction - factionSupply[5];
    factions[6] = supplyPerFaction - factionSupply[6];
    factions[7] = supplyPerFaction - factionSupply[7];
    factions[8] = supplyPerFaction - factionSupply[8];
  }


  //payable
  function crossMint( uint16 quantity, uint16 factionIdx, address recipient, bytes32[] calldata proof ) external payable {
    require( msg.sender == crossmintProxy );
    _mint( quantity, factionIdx, recipient, proof );
  }

  function mint( uint16 quantity, uint16 factionIdx, bytes32[] calldata proof ) external payable {
    _mint( quantity, factionIdx, msg.sender, proof );
  }


  //onlyDelegates
  function burnFrom(uint256[] calldata tokenIds, address account) external payable onlyDelegates{
    unchecked{
      for(uint i; i < tokenIds.length; ++i ){
        uint256 tokenId = tokenIds[i];
        require( tokens[ tokenId ].stakeStart == 1, "Cannot burn while staked" );
        _burn( account, tokenId );
      }
    }
  }


  function mintTo(uint16[] calldata quantity, uint16[] calldata factions, address[] calldata recipient) external payable onlyDelegates{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint256 totalQuantity = 0;
    unchecked{
      for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
      }
    }
    require( totalSupply() + totalQuantity <= config.maxSupply, "Mint/order exceeds supply" );

    bool randomize;
    uint256 factionIdx;
    bytes memory hashData = _hashData();
    unchecked{
      for(uint256 i; i < recipient.length; ++i){
        owners[recipient[i]].balance += quantity[i];

        factionIdx = factions[i];
        randomize = factionIdx == 0;
        for(uint256 j; j < quantity[i]; ++j){
          if( randomize )
            factionIdx = _randomFaction( hashData, j );
          else
            require( factionSupply[ factionIdx ] + quantity[i] <= supplyPerFaction, "Mint/Order exceeds factoin supply" );

          uint256 tokenId = (factionIdx - 1) * supplyPerFaction + factionSupply[ factionIdx ];
          ++factionSupply[ factionIdx ];
          _mint( recipient[i], tokenId );
        }
      }
    }
  }

  function resurrectFor( uint[] calldata tokenIds, address[] calldata recipient ) external onlyDelegates{
    require(tokenIds.length == recipient.length,   "Must provide equal tokenIds and recipients" );

    unchecked{
      uint256 tokenId;
      for(uint i; i < tokenIds.length; ++i ){
        tokenId = tokenIds[i];
        require( !_exists( tokenId ), "Resurrect token(s) must not exist" );

        --owners[address(0)].balance;
        ++tokens[tokenId].revived;
        _transfer(address(0), recipient[i], tokenId);
      }
    }
  }

  function setConfig( MintConfig calldata newConfig ) external onlyDelegates{
    require( newConfig.maxOrder <= newConfig.maxSupply, "max order must be lte max supply" );
    require( totalSupply() <= newConfig.maxSupply, "max supply must be gte total supply" );
    require( uint8(newConfig.saleState) < 3, "invalid sale state" );

    config = newConfig;
  }

  function setCrossmint( address proxy ) external onlyDelegates{
    crossmintProxy = proxy;
  }

  function setFactionSupply( uint256 newSupply ) external onlyDelegates{
    supplyPerFaction = newSupply;
  }

  function setPayee( address newPayee ) external onlyOwner{
    payee = newPayee;
  }

  function setStakeHandler( IStakeHandler handler ) external onlyDelegates{
    stakeHandler = handler;
  }

  function setTokenURI( string calldata prefix, string calldata suffix ) external onlyDelegates{
    tokenURIPrefix = prefix;
    tokenURISuffix = suffix;
  }

  //onlyOwner
  function setDefaultRoyalty( address receiver, uint16 feeNumerator, uint16 feeDenominator ) external onlyOwner {
    _setDefaultRoyalty( receiver, feeNumerator, feeDenominator );
  }

  //view: IERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721EnumerableB, Royalties) returns (bool) {
    return ERC721EnumerableB.supportsInterface(interfaceId)
      || Royalties.supportsInterface(interfaceId);
  }


  //view: IERC721Metadata
  function tokenURI( uint256 tokenId ) external view returns( string memory ){
    require(_exists(tokenId), "query for nonexistent token");
    return string(abi.encodePacked(tokenURIPrefix, tokenId.toString(), tokenURISuffix));
  }

  function withdraw() external onlyOwner {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }

  //private
  function _mint( uint16 quantity, uint256 factionIdx, address recipient, bytes32[] memory proof ) private {
    require( quantity > 0, "Must order 1+" );
    require( factionIdx < 9, "Invalid faction" );

    MintConfig memory cfg = config;
    Owner memory prev = owners[recipient];
    require( quantity <= cfg.maxOrder,                  "Order too big" );
    require( prev.purchased + quantity <= cfg.maxMint,  "Mint limit reached" );
    require( totalSupply() + quantity <= cfg.maxSupply, "Mint/Order exceeds supply" );
    require( msg.value >= cfg.ethPrice * quantity,      "Ether sent is not correct" );

    if( factionIdx > 0 ){
      require( factionSupply[ factionIdx ] + quantity <= supplyPerFaction, "Mint/Order exceeds faction supply" );
    }


    if( cfg.saleState == SaleState.MAINSALE ){
      //no-op
    }
    else if( cfg.saleState == SaleState.PRESALE ){
      require( _isValidProof( keccak256( abi.encodePacked( recipient ) ), proof ),  "Not on the access list" );
    }
    else{
      revert( "Sale is not active" );
    }

    bytes memory hashData = _hashData();
    bool randomize = factionIdx == 0;
    unchecked{
      owners[recipient] = Owner(
        prev.balance + quantity,
        prev.purchased + quantity
      );

      for(uint256 i; i < quantity; ++i ){
        if( randomize )
          factionIdx = _randomFaction( hashData, i );

        uint256 tokenId = (factionIdx - 1) * supplyPerFaction + factionSupply[ factionIdx ];
        ++factionSupply[ factionIdx ];
        _mint( recipient, tokenId );
      }
    }
  }

  function _hashData() private view returns( bytes memory ){
    //uint160 cbVal = uint160( address(block.coinbase) );
    bytes memory hashData = bytes.concat("", bytes20( address(block.coinbase)));  //160 bits

    //uint40 feeVal = uint40( block.basefee  % type(uint40).max );
    hashData = bytes.concat(hashData, bytes5( uint40( block.basefee  % type(uint40).max )));  //200 bits

    //uint32 limVal = uint32( block.gaslimit % type(uint32).max );
    hashData = bytes.concat(hashData, bytes4( uint32( block.gaslimit % type(uint32).max )));  //232 bits

    //uint40 gasVal =  uint40( tx.gasprice  % type(uint40).max );
    return bytes.concat(hashData, bytes5( uint40( tx.gasprice  % type(uint40).max )));  //272 bits
  }

  function _randomFaction( bytes memory hashData, uint256 index) private view returns( uint256 ){
    uint256 random = _random( hashData, index );
    for( uint256 i; i < 8; ++i ){
      uint256 factionIdx_ = ((random + i) % 8) + 1;
      if( factionSupply[ factionIdx_ ] < supplyPerFaction )
        return factionIdx_;
    }

    revert( "Random failed" );
  }

  function _random(bytes memory hashData, uint256 index) private view returns( uint256 ){
    uint256 blockid = block.number - (gasleft() % type(uint8).max);
    uint256 blkHash = uint256(blockhash( blockid ));
    return uint256(keccak256(
      index % 2 == 1 ?
        abi.encodePacked( blkHash, index, hashData ):
        abi.encodePacked( hashData, index, blkHash )
      ));
  }
}