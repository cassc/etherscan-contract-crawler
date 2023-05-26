/*
                                   ./((((.
                               ((&&&&&&&&&&&((
                             (&&&&@@@@&&&&&&&&&(
                           (&&&@@@@@@@@@&&&&&&&&&(
                         #(&&@@@@@@@@@@@&&&&&&&&&&(
                        (#&&@@@@@@@@@@@@&&&&&&&&&&&(        /(((#%%&&%#((,
     /((#%%%%#(((/     *(&&@@@@@@@@@@@&&&&&&&&&&&&&&(  ((%&&&&&@@@@@@&&&&&&((
  (#&&&&@@@@@@@@&&&&#(#(&&&@@@@@@@@@@&&&&&&&&&&&&&&&%&&&&&&@@@@@@@@@@@&&&&&&%(
 (&&&&&@@@@@@@@@@@@@&&&&&&&&@@@@@@&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@&&&&&&&&&(
 (&&&&&@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@&&&&&&&&&&#(
 (&&&&&&&&@@@@@@@@@@@&&&%#(%%(#&&&&&&&&&&&&&&&&&&&&&&&&&@@@@@&&&&&&&&&&&&&&#(
  (&&&&&&&&&&&&&&&&&&&%#(%%%(%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
    (&&&&&&&&&&&&&&&&%(%&&(%%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&((
      (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(
         ((&&&&&&&&&&&&&&&&&%#((%&&&&&&&&&&&&&&#((#%%%&&&%(&&&&&&&&((
           (#&&&&&&&&%(&&&%%%%%%%%&&&&&(&(#&&&&%%%%%%%%&&&(&&&&&&&&&&((
        ((&&&&&&&&&&&&(&&&%%%%%%%%&&&&&&&&&&&&&&%%%%%%&&&((&&&&&&&&&&&&(*
      ,#&&&&&&&&&&&&&&((&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(((((&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&((((((&&&&&&&&&&&&&&&&&&&&&&&&#((%&&&&&&&&&&&&&&&&&(
    (&&&&&&&&&&&&&&&&&&&&&%((&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&%(
    (&&&&&&&&&&&&&&&&&&&&&&&#&&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&&&&&&&&&&&(
     (&&&&&&&&&&&&&&&&&&&&&&&(&&&&&&&&&&&(&&&&&@@@&&%(&&&&&&&&&&&&&&&&&&&&#.
      (%&&&&&&&&&&&&&&&&&&&&&%(&@@@@@@&&&((&&&@@@&&&((&&&&&&&&&&&&&&&&&&&(.
         *(%&&&&&&&&&&&&&&&&&(((%&&&&&&(*   /((((/   (&&&&&&&&&&&&&&&&%(
                *(((((((/,                             /((#%%%%#((((/
 - XxStarChadxX -
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol"; 

contract Starcatchers is ERC721A, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint;

  uint128 public  _releaseTimestamp = 0;
  uint64  public  immutable _maxSupply = 10000;
  uint64  private immutable _maxMintAmountPerTx = 4;
  bool    private _treasuryMint;
  string  public  _baseTokenURI;

  address public constant xDev      = 0x9B54D1714f85a192723A36f1e8DE9E81dbcBBB1F;
  address public constant xTreasury = 0x370f75a63F438186DbfECfD27cD75a5023bEa737;
  address public constant xVault    = 0x02874867a6D48713D9cf275b7324B790E9C1f7Ee;

  /**
   * @dev Tiers used for timed release based on addressStarlist.
   * See {constructor} for initial values.
   * If a user has no tier set they inherit 0.
   */
  struct Tier {
    uint128 wenOffset;
    uint64  priceWei;
    uint64  maxAllowed;
  }
  mapping(uint => Tier) public Tiers;
  mapping(address => uint) public addressStarlist;
  mapping(address => uint) public addressMintBalance;

  constructor(
    uint128 releaseTimestamp
  ) ERC721A("Starcatchers", "STAR") {
    _releaseTimestamp = releaseTimestamp;

    Tiers[5] = Tier(0, 0.0888 ether, _maxMintAmountPerTx);
    Tiers[4] = Tier(0, 0.0888 ether, _maxMintAmountPerTx-1);
    Tiers[3] = Tier(0, 0.0999 ether, _maxMintAmountPerTx-1);
    Tiers[2] = Tier(86400, 0.0999 ether, _maxMintAmountPerTx-2);
    Tiers[1] = Tier(86400, 0.111 ether, _maxMintAmountPerTx-2);
    Tiers[11] = Tier(172800, 0.111 ether, _maxMintAmountPerTx-2);
    Tiers[12] = Tier(259200, 0.111 ether, _maxMintAmountPerTx-2);
    Tiers[0] = Tier(604800, 0.111 ether, _maxMintAmountPerTx-2);
  }

  function mintCompliance(
    uint quantity,
    Tier storage t
  ) 
    private
  {
    require(
      msg.value == t.priceWei * quantity,
      "Incorrect payment"
    );
    require(
      quantity > 0 && quantity <= t.maxAllowed,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= _maxSupply,
      "Maximum supply exceeded"
    );
    require(
      block.timestamp > (_releaseTimestamp + t.wenOffset),
      "It is not yet your time"
    );
  }

  /**
   * @dev minting function, balance tracking only relevant for Starlist.
   * TX validation done inside {mintCompliance}.
   */
  function ascend_h2d(
    uint8 quantity
  )
    public
    payable
  {
    mintCompliance(quantity, Tiers[0]);
    _safeMint(msg.sender, quantity);
  }

  /**
   * @dev starlist minting function
   */
  function ascend_starlist_abf(
    uint8 quantity
  )
    public
    payable
  {
    Tier storage _t = Tiers[addressStarlist[msg.sender]];
    mintCompliance(quantity, _t);
    require(
      addressMintBalance[msg.sender] + quantity <= _t.maxAllowed,
      "Starlist threshold exceeded"
    );
    addressMintBalance[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function setTier(uint8 tierId, uint128 wenOffset, uint64 priceWei, uint64 maxAllowed)
    public
    onlyOwner
  {
    require(
      maxAllowed <= _maxMintAmountPerTx,
      "MaxAllowed parameter exceeds _maxMintAmountPerTx"
    );
    Tiers[tierId] = Tier(wenOffset, priceWei, maxAllowed);
  }

  function setReleaseTimestamp(uint128 releaseTimestamp)
    public
    onlyOwner
  {
    _releaseTimestamp = releaseTimestamp;
  }

  function setBaseURI(string memory baseURI)
    public
    onlyOwner
  {
    _baseTokenURI = baseURI;
  }

  function setStarlist(address[] calldata _users, uint8 tier)
    public
    onlyOwner
  {
    for (uint i = 0; i < _users.length; i++) {
      addressStarlist[_users[i]] = tier;
    }
  }

  function treasuryMint(uint quantity)
    public
    onlyOwner
  {
    require(
      !_treasuryMint,
      "Treasury mint can only be done once"
    );
    require(
      quantity > 0,
      "Invalid mint amount"
    );
    require(
      totalSupply() + quantity <= _maxSupply,
      "Maximum supply exceeded"
    );
    _safeMint(msg.sender, quantity);
    _treasuryMint = true;
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    uint total = address(this).balance;
    uint devCut = total * 5 / 100;
    uint vaultCut = total * 35 / 100;
    Address.sendValue(payable(xDev), devCut);
    Address.sendValue(payable(xVault), vaultCut);
    Address.sendValue(payable(xTreasury), address(this).balance);
  }

  function tokenURI(uint _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
  }

  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
  {
    return _baseTokenURI;
  }
}