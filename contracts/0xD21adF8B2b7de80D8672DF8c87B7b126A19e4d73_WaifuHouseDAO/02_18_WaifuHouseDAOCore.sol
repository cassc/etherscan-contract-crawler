// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

import "../Blimpie/PaymentSplitterMod.sol";
import "../Blimpie/Signed.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract WaifuHouseDAOCore is Signed, PaymentSplitterMod, ERC165, IERC721Metadata {
  using Strings for uint256;

  struct Group{
    uint balance;
    uint startToken;
    uint supply;
    uint totalSupply;

    uint startPrice;
    uint floorPrice;

    uint startTime;
    uint floorTime;
  }

  struct Token{
    uint32 baseHearts;
    uint32 epoch;
    address owner;
  }

  uint32 public HEARTS_PERIOD = 604800;

  uint public MAX_ORDER = 2;
  uint public MAX_WALLET = 2;
  uint public TOTAL_SUPPLY = 0;

  Group[] public groups;
  mapping(address => uint) public accessList;
  mapping(address => uint) public balances;
  mapping(uint => Token) public owners;

  uint _offset = 1;
  string private _tokenURIPrefix = "https://waifu-house-dao-api.herokuapp.com/getMetaData?tokenId=";
  string private _tokenURISuffix;

  address[] private addressList = [
    0xBb54229bE98aE4dd54DAfBFaD52c3B5f799d31b3,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    90,
    10
  ];

  constructor()
    Delegated()
    PaymentSplitterMod( addressList, shareList ){
  }


  //interface
  function _burn( uint tokenId ) internal virtual;
  function _mint( address to, uint tokenId ) internal virtual;
  function _transfer( address from, address to, uint tokenId ) internal virtual;
  

  //core
  fallback() external payable {}

  function getGroupCount() external view returns( uint ){
    return groups.length;
  }

  function getHearts( uint tokenId ) public view returns( uint32 hearts ){
    require(_exists(tokenId), "WAIFU: query for nonexistent token");

    uint32 baseHearts = 10;
    if( owners[tokenId].baseHearts > 0 )
      baseHearts = owners[tokenId].baseHearts;

    uint32 extra = (uint32(block.timestamp) - owners[tokenId].epoch) / HEARTS_PERIOD;
    return baseHearts + extra;
  }

  function getPrice( uint id, uint externalTime ) public view returns( uint price ){
    require( id < groups.length, "Invalid group" );

    Group memory group = groups[ id ];
    if( group.startPrice == group.floorPrice )
      return group.floorPrice;

    uint time = externalTime > 0 ? externalTime : block.timestamp;
    if( time < group.startTime )
      return group.startPrice;

    if( time > group.floorTime )
      return group.floorPrice;

    uint difference = group.startPrice - group.floorPrice;
    uint numerator = group.floorTime - time;
    uint denominator = group.floorTime - group.startTime;
    return group.floorPrice + ( difference * numerator / denominator );
  }

  function getTokenGroup( uint tokenId ) external view returns( uint id ){
    require(_exists(tokenId), "WAIFU: query for nonexistent token");

    uint endToken;
    Group memory group;
    for( uint i; i < groups.length; ++i ){
      group = groups[i];
      endToken = group.startToken + group.supply;
      if( group.startToken <= tokenId && tokenId < endToken )
        return i;
    }

    revert( "Token does not exist" );
  }


  //IERC165
  function supportsInterface(bytes4 interfaceId) public view virtual override( ERC165, IERC165 ) returns( bool ){
    return
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }


  //IERC721Metadata
  function name() external pure override returns( string memory ){
    return "Waifu House DAO";
  }

  function symbol() external pure override returns( string memory ){
    return "WAIFU";
  }

  function tokenURI(uint tokenId) external view override returns( string memory ){
    require(_exists(tokenId), "WAIFU: query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }


  //payable
  function mint(uint id, uint quantity, bytes calldata signature) external payable {
    require( id < groups.length,   "Invalid group" );
    require( quantity <= MAX_ORDER, "Order too big" );
    require( balances[ msg.sender ] + quantity <= MAX_WALLET, "Order too big" );

    Group storage group = groups[id];
    require( block.timestamp >= group.startTime,       "Sales are not active" );
    require( group.balance + quantity <= group.supply, "Not enough supply" );

    uint price = getPrice( id, block.timestamp );
    require( msg.value >= price * quantity, "Not enough ETH sent" );

    if( signature.length > 0 ){
      verifySignature( quantity.toString(), signature );
    }
    else{
      require( accessList[ msg.sender ] >= quantity, "Verificaton failed" );
      accessList[ msg.sender ] -= quantity;
    }

    for( uint i; i < quantity; ++i ){
      _mint( msg.sender, group.startToken + group.balance++ );
    }
  }


  //delegated
  function burn( uint[] calldata tokenIds ) external onlyDelegates{
    for(uint i; i < tokenIds.length; ++i ){
      _burn( tokenIds[i] );
    }
  }

  function mintTo(uint[] calldata groupIds, address[] calldata recipients, uint[] calldata quantities ) external payable onlyDelegates{
    require(groupIds.length == recipients.length,   "Must provide equal groupIds and recipients" );
    require(recipients.length == quantities.length, "Must provide equal recipients and quantities" );
    for(uint i; i < groupIds.length; ++i ){
      Group storage group = groups[ groupIds[i] ];
      require(group.balance + quantities[i] <= group.supply, "Not enough supply" );

      for( uint j; j < quantities[i]; ++j ){
        _mint( recipients[i], group.startToken + group.balance++ );
      }
    }
  }

  function resurrect( uint[] calldata tokenIds, address[] calldata recipients ) external onlyDelegates{
    require(tokenIds.length == recipients.length,   "Must provide equal tokenIds and recipients" );
    for(uint i; i < tokenIds.length; ++i ){
      require( !_exists( tokenIds[i] ), "WAIFU: can't resurrect existing token" );
      _mint( recipients[i], tokenIds[i] );
    }
  }


  //delegated
  function addGroup( uint supply, uint totalSupply, uint startPrice, uint floorPrice, uint startTime, uint floorTime ) public onlyDelegates{
    groups.push(Group(
      0,
      _offset + TOTAL_SUPPLY,
      supply,
      totalSupply,

      startPrice,
      floorPrice,

      startTime,
      floorTime
    ));
    TOTAL_SUPPLY += totalSupply;
  }

  function setGroup( uint id, uint supply, uint startPrice, uint floorPrice, uint startTime, uint floorTime ) external onlyDelegates{
    require( id < groups.length, "WAIFU: Invalid group" );

    Group storage group = groups[id];
    require( supply >= group.balance,     "Specified supply is lower than the current balance" );
    require( supply <= group.totalSupply, "Specified supply exceeds total supply" );

    group.supply = supply;
    group.startPrice = startPrice;
    group.floorPrice = floorPrice;
    group.startTime = startTime;
    group.floorTime = floorTime;
  }

  function setAccessList(address[] calldata accounts, uint[] calldata quantities ) external onlyDelegates{
    require(accounts.length == quantities.length,   "Must provide equal accounts and quantities" );
    for(uint i; i < accounts.length; ++i ){
      accessList[ accounts[i] ] = quantities[i];
    }
  }

  function setBaseURI(string memory tokenURIPrefix, string memory tokenURISuffix) external onlyDelegates {
    _tokenURIPrefix = tokenURIPrefix;
    _tokenURISuffix = tokenURISuffix;
  }

  function setHearts(uint[] calldata tokenIds, uint32[] calldata hearts) external onlyDelegates{
    require(tokenIds.length == hearts.length,   "Must provide equal tokenIds and hearts" );
    for(uint i; i < tokenIds.length; ++i ){
      owners[ tokenIds[i] ].baseHearts = hearts[i];
    }
  }

  function setHeartsOptions( uint32 period ) external onlyDelegates{
    HEARTS_PERIOD = period;
  }

  function setMax(uint maxOrder, uint maxWallet) external onlyDelegates{
    MAX_ORDER = maxOrder;
    MAX_WALLET = maxWallet;
  }


  //internal
  function _exists(uint tokenId) internal view returns (bool) {
    return owners[tokenId].owner != address(0);
  }
}