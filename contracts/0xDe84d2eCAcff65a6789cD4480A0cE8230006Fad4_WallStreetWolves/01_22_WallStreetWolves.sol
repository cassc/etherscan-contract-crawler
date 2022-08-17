// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/****************************************
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ***************************************/

import "./Delegated.sol";
import "./PaymentSplitterMod.sol";
import "./ERC721Staked.sol";
import "./Verify.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IWSWFounders {
  function balanceOf(address _account, uint256 _id)
    external
    view
    returns (uint256);
}

contract WallStreetWolves is
  Delegated,
  ERC721Staked,
  Verify,
  PaymentSplitterMod
{
  using Strings for uint256;

  uint256 public MAX_SUPPLY = 10000;
  uint256 public PRICE = 0.5 ether;

  uint256 public CURRENT_ROUND = 1;
  uint256 public ROUND_SUPPLY = 2500;
  uint256 public ROUND_MINTED = 0;
  uint256 public PRESALE_QUANTITY = 2;
  uint256 public PUBLIC_QUANTITY = 20;

  mapping(address => uint256) private foundersQuantities;
  mapping(uint256 => mapping(address => uint256)) private presaleMinters;

  string private tokenURIPrefix;
  string private tokenURISuffix;

  address private teamAddress = 0x2d2352a56827515FAf6088c4cDf59befb4d0A67a;

  enum SaleState {
    paused,
    founders,
    presale,
    publicsale
  }

  SaleState public saleState = SaleState.paused;

  IWSWFounders public WSWFoundersProxy =
    IWSWFounders(0x48C8eC816F7789C2d4A517fca3D2fa33ac3Cc1c7);

  address[] private splitter = [
    0xed386149321FBd84f0c4e27a1701Ad05eCA32f8A,
    0x2d2352a56827515FAf6088c4cDf59befb4d0A67a,
    0x5B1DC9219786c7929B4684eF8301bdF4F1d67465
  ];
  uint256[] private splitterShares = [3, 85, 12];

  constructor(address _signer)
    ERC721B("Wall Street Wolves", "WSW", 0)
    PaymentSplitterMod(splitter, splitterShares)
  {
    setSigner(_signer);
  }

  //external payable
  fallback() external payable {}

  function airdrop(address _address, uint256 _quantity) public onlyDelegates {
    require(
      totalSupply() + _quantity <= MAX_SUPPLY,
      "airdrop: Invalid quantity."
    );
    for (uint256 i; i < _quantity; ++i) {
      mint1(_address);
    }
  }

  function mint(uint256 _quantity, bytes memory _signature) public payable {
    require(saleState != SaleState.paused, "mint: Sale paused");
    require(totalSupply() + _quantity <= MAX_SUPPLY, "mint: Invalid quantity.");

    if (saleState == SaleState.founders) {
      uint256 balance = WSWFoundersProxy.balanceOf(msg.sender, 0);
      require(
        balance >= _quantity + foundersQuantities[msg.sender],
        "mint: Invalid founders quantity"
      );
      foundersQuantities[msg.sender] += _quantity;
    } else if (saleState == SaleState.presale) {
      require(msg.value >= _quantity * PRICE, "mint: Incorrect ETH sent.");
      require(
        ROUND_MINTED + _quantity <= ROUND_SUPPLY,
        "mint: Invalid quantity"
      );
      require(
        _quantity + presaleMinters[CURRENT_ROUND][msg.sender] <=
          PRESALE_QUANTITY,
        "mint: Invalid quantity."
      );
      require(verify(_quantity, _signature), "mint: Not on presale list.");
      ROUND_MINTED += _quantity;
      presaleMinters[CURRENT_ROUND][msg.sender] += _quantity;
    } else if (saleState == SaleState.publicsale) {
      require(msg.value >= _quantity * PRICE, "mint: Incorrect ETH sent.");
      require(
        ROUND_MINTED + _quantity <= ROUND_SUPPLY,
        "mint: Invalid quantity"
      );
      require(_quantity <= PUBLIC_QUANTITY, "mint: Invalid quantity.");
      ROUND_MINTED += _quantity;
    }

    for (uint256 i; i < _quantity; ++i) {
      mint1(msg.sender);
    }
  }

  function resetRound(
    uint256 _roundSupply,
    uint256 _price,
    uint256 _airdropQuantity
  ) external onlyDelegates {
    ROUND_SUPPLY = _roundSupply;
    ROUND_MINTED = 0;
    PRICE = _price;
    saleState = SaleState.presale;
    CURRENT_ROUND += 1;

    if (_airdropQuantity > 0) {
      airdrop(teamAddress, _airdropQuantity);
    }
  }

  function setVariables(
    uint256 _maxSupply,
    uint256 _price,
    SaleState _saleState,
    uint256 _presaleQuantity,
    uint256 _publicQuantity
  ) external onlyDelegates {
    MAX_SUPPLY = _maxSupply;
    PRICE = _price;
    saleState = _saleState;
    PRESALE_QUANTITY = _presaleQuantity;
    PUBLIC_QUANTITY = _publicQuantity;
  }

  function setTeamAddress(address _newTeamAddress) external onlyDelegates {
    require(teamAddress != _newTeamAddress);
    teamAddress = _newTeamAddress;
  }

  function setSaleState(SaleState _newSaleState) external onlyDelegates {
    require(saleState != _newSaleState);
    saleState = _newSaleState;
  }

  function setWSWFoundersContract(address _wswFounders) external onlyDelegates {
    if (address(WSWFoundersProxy) != _wswFounders)
      WSWFoundersProxy = IWSWFounders(_wswFounders);
  }

  function setRarity(uint256[] memory _tokensToSet, uint8 rarity)
    external
    onlyDelegates
  {
    require(totalSupply() > _tokensToSet.length, "setRarity: invalid length");
    for (uint256 i; i < _tokensToSet.length; ++i) {
      tokens[_tokensToSet[i]].rarity = rarity;
    }
  }

  function setTokenURI(
    string memory _tokenURIPrefix,
    string memory _tokenURISuffix
  ) public onlyDelegates {
    tokenURIPrefix = _tokenURIPrefix;
    tokenURISuffix = _tokenURISuffix;
  }

  function tokenURI(uint256 _tokenId)
    external
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "tokenURI: Query for nonexistent token");
    return
      string(
        abi.encodePacked(tokenURIPrefix, _tokenId.toString(), tokenURISuffix)
      );
  }

  function mint1(address _to) internal {
    uint256 tokenId = _next();
    tokens.push(Token(_to, 1, 1));

    _safeMint(_to, tokenId, "");
  }

  function _mint(address _to, uint256 _tokenId) internal override {
    emit Transfer(address(0), _to, _tokenId);
  }
}