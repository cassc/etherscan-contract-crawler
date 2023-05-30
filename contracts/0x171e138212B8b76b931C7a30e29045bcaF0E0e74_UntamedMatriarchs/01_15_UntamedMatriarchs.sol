// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/************************
 * @author: squeebo_nft *
 ************************/

import "./Blimpie/Delegated.sol";
import "./Blimpie/ERC721EnumerableLite.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC721Proxy{
  function balanceOf( address owner ) external view returns ( uint );
  function ownerOf( uint tokenId ) external view returns ( address owner );
  function walletOfOwner( address owner ) external view returns ( uint[] calldata );
}

interface GFInterface {
  function groupBalances(uint id, address owner) external view returns (uint);
}

contract UntamedMatriarchs is Delegated, ERC721EnumerableLite {
  using Strings for uint;

  uint public MAX_ORDER  = 20;
  uint public MAX_SUPPLY = 7000;
  address public GF_CONTRACT = 0x8744C9F3C2DCA15b306fEFCB1175Ecb22Ecbe01F;
  address public UE_CONTRACT = 0x613E5136a22206837D12eF7A85f7de2825De1334;
  address public UC_CONTRACT = 0x7870cc63b6B1AF0AED0D6Dd7c1eFB39300b773eB;

  uint public basePrice = 0.030 ether;
  uint public discPrice = 0.035 ether;
  uint public fullPrice = 0.040 ether;
  
  bool public isPaidsaleActive;
  bool public isWhitelistActive;
  bool public isUntamedActive;

  mapping( uint => bool ) public isUsedUE;
  mapping( uint => bool ) public isUsedUC;
  mapping( address => uint ) public wlClaim;

  string private _tokenURIPrefix = '';
  string private _tokenURISuffix = '';

  constructor()
    Delegated()
    ERC721B( "Untamed Matriarchs", "UM", 0 ){
  }

  //external
  fallback() external payable {}
  receive() external payable {}

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), _tokenURISuffix));
  }

  /**
   * (1) Phase 1: Public Sale
   **/
  function mint( uint quantity ) external payable{
    require( isPaidsaleActive,                 "Paid sale is not active" );
    require( quantity <= MAX_ORDER,            "Order too big"           );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,  "Order exceeds supply"    );

    uint grapes;
    uint elephants = _countElephants( msg.sender );
    if( elephants < 10 ){
      grapes = _countGrapes( msg.sender );
    }

    uint price = fullPrice;
    if( elephants >= 10 || grapes >= 5 )
      price = basePrice;
    else if( elephants > 0 || grapes > 0 )
      price = discPrice;

    require( msg.value >= price * quantity, "Ether sent is not correct" );
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  /**
   * (2) Phase 2: Whitelist Claim
   **/
  function whitelistClaim( uint quantity ) external {
    require( isWhitelistActive,         "Free claims are not active" );
    require( quantity <= wlClaim[ msg.sender ], "Whitelist expended" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,  "Order exceeds supply" );

    wlClaim[ msg.sender ] -= quantity;
    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  /**
   * (3) Phase 3: Untamed Claim
   **/
  function untamedClaim( uint quantity, uint[] calldata ueTokens, uint[] calldata ucTokens ) external{
    require( isUntamedActive,                 "Presale is not active" );
    require( quantity <= ueTokens.length / 2, "Not enough Elephants (A)" );
    require( quantity <= ucTokens.length,     "Not enough Companions (A)" );

    uint supply = totalSupply();
    require( supply + quantity <= MAX_SUPPLY,   "Order exceeds supply" );
    _requireUeIntersection( ueTokens, quantity * 2 );
    _requireUcIntersection( ucTokens, quantity );

    for(uint i; i < quantity; ++i){
      _safeMint( msg.sender, supply++, "" );
    }
  }

  //delegated
  function mintTo(address[] calldata recipient, uint[] calldata quantity) external payable onlyDelegates {
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity;
    for(uint i; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    uint supply = totalSupply();
    require( totalQuantity + supply <= MAX_SUPPLY, "Mint/order exceeds supply" );

    for(uint i; i < recipient.length; ++i){
      for(uint j; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }
  
  function setActive( bool paidsaleActive, bool whitelistActive, bool untamedActive ) external onlyDelegates{
    require( isPaidsaleActive != paidsaleActive ||
      isWhitelistActive != whitelistActive ||
      isUntamedActive != untamedActive, "New values match old" );
    isPaidsaleActive  = paidsaleActive;
    isWhitelistActive = whitelistActive;
    isUntamedActive   = untamedActive;
  }

  function setBaseURI(string calldata newBaseURI, string calldata newSuffix) external onlyDelegates{
    _tokenURIPrefix = newBaseURI;
    _tokenURISuffix = newSuffix;
  }

  function setContracts( address gfAddress, address ueAddress, address ucAddress ) external onlyDelegates {
    require( GF_CONTRACT != gfAddress ||
      UE_CONTRACT != ueAddress ||
      UC_CONTRACT != ucAddress, "New values match old" );
    GF_CONTRACT = gfAddress;
    UE_CONTRACT = ueAddress;
    UC_CONTRACT = ucAddress;
  }

  function setMax(uint maxOrder, uint maxSupply) external onlyOwner{
    require( MAX_ORDER  != maxOrder ||
      MAX_SUPPLY != maxSupply,   "New value matches old" );
    require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );

    MAX_ORDER  = maxOrder;
    MAX_SUPPLY = maxSupply;
  }

  function setPrices( uint basePrice_, uint discPrice_, uint fullPrice_ ) external onlyDelegates {
    require( basePrice != basePrice_ ||
      discPrice != discPrice_ ||
      fullPrice != fullPrice_, "New values match old" );
    basePrice = basePrice_;
    discPrice = discPrice_;
    fullPrice = fullPrice_;
  }

  function setWhitelist( address[] calldata wallets, uint[] calldata quantities ) external onlyDelegates {
    require(wallets.length > 0, "Must provide at least 1 wallet");
    require(wallets.length == quantities.length, "Must provide equal wallets and quantities");
    for( uint i; i < wallets.length; ++i ){
      wlClaim[ wallets[i] ] = quantities[ i ];
    }
  }


  //onlyOwner
  function withdraw() external {
    require(address(this).balance >= 0, "No funds available");
    Address.sendValue(payable(owner()), address(this).balance);
  }


  //private
  function _countElephants( address account ) private view returns( uint ){
    return IERC721Proxy( UE_CONTRACT ).balanceOf( account );
  }

  function _countGrapes( address account ) private view returns( uint ){
    return GFInterface( GF_CONTRACT ).groupBalances( 1, account );
  }

  function _requireUcIntersection(uint[] memory needles, uint needed) private {
    uint needle;
    IERC721Proxy ucProxy = IERC721Proxy( UC_CONTRACT );
    uint[] memory ucWallet = ucProxy.walletOfOwner( msg.sender );
    for(uint i; i < needles.length; ++i ){
      needle = needles[i];
      if( isUsedUC[ needle ] )
        continue;

      bool found;
      for(uint j; j < ucWallet.length; ++j ){
        if( isUsedUC[ ucWallet[j] ] )
          continue;


        if( needle == ucWallet[j] ){
          found = true;
          isUsedUC[ needle ] = true;
          if( --needed == 0 )
            return;
          else
            break;
        }
      }


      if( !found && needle < 7500 ){
        try ucProxy.ownerOf( needle ) returns( address ){}
        catch{
          isUsedUC[ needle ] = true;
          if( --needed == 0 )
            return;
        }
      }
    }

    revert( "Not enough Companions (B)" );
  }

  function _requireUeIntersection(uint[] memory needles, uint needed) private {
    uint needle;
    uint[] memory ucWallet = IERC721Proxy( UE_CONTRACT ).walletOfOwner( msg.sender );
    for(uint i; i < needles.length; ++i ){
      needle = needles[i];
      if( isUsedUE[ needle ] )
        continue;

      for(uint j; j < ucWallet.length; ++j ){
        if( isUsedUE[ ucWallet[j] ] )
          continue;


        if( needle == ucWallet[j] ){
          isUsedUE[ needle ] = true;
          if( --needed == 0 )
            return;
          else
            break;
        }
      }
    }

    revert( "Not enough Elephants (B)" );
  }
}