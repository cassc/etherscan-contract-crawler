// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import './NftLab-ERC721.base.sol';

//    |\__/,|   (`\
//  _.|o o  |_   ) )
// -(((---(((--------

// Menacing punks: https://discord.gg/RWRs29SpnT
// nftlab: https://discord.gg/kH7Gvnr2qp

contract MenacingPunkContract is NftLabERC721 {
  /** Maintain wallets */
  mapping(address => uint256) public holders;
  /** Pre-sale state */
  bool public is_presale_active = false;

  constructor(
    string memory name,
    string memory symbol,
    uint8 mb,
    uint16 mt,
    uint256 price,
    string memory URI,
    address[] memory shareholders,
    uint256[] memory shares
  ) NftLabERC721(name, symbol, mb, mt, price, URI, shareholders, shares) {}

  /** Class Methods */
  function addHolders(address[] memory wallets, uint8[] memory count)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < wallets.length; i++) {
      holders[wallets[i]] = count[i];
    }
  }

  function preMint() external payable {
    require(is_presale_active, 'Presale is not yet active.');
    require(
      holders[msg.sender] > 0,
      'Wallet is not whitelisted or has already redeemed.'
    );
    for (uint256 i = 0; i < holders[msg.sender]; i++) {
      _safeMint(msg.sender, totalSupply());
    }
    holders[msg.sender] = 0;
  }

  /** Setters */
  function setPresaleState(bool val) external onlyOwner {
    is_presale_active = val;
  }
}