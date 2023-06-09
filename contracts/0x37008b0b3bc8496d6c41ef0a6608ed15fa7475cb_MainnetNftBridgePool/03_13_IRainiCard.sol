// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

pragma solidity ^0.8.0;

abstract contract IRainiCard is IERC1155 {
  struct TokenVars {
    uint128 cardId;
    uint32 level;
    uint32 number;
    bytes1 mintedContractChar;
  }

  struct Card {
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint16 maxMintsPerAddress;
    uint32 maxSupply; // number of base tokens mintable
    uint32 allocation; // number of base tokens mintable with points on this contract
    uint32 mintTimeStart; // the timestamp from which the card can be minted
    bool locked;
    address subContract;
  }
  
  mapping(uint256 => TokenVars) public tokenVars;
  
  mapping(uint256 => Card) public cards;

  uint256 public maxTokenId;

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) virtual external;

  function mint(address _to, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number) virtual external;

  function getTotalBalance(address _address) virtual external view returns (uint256[][] memory amounts);

  function getTotalBalance(address _address, uint256 _cardCount) virtual external view returns (uint256[][] memory amounts);

  function burn(address _owner, uint256 _tokenId, uint256 _amount) virtual external;
}