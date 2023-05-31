// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Blimpie/ERC1155Base.sol';

contract WeedGangPresents is ERC1155Base{
  constructor()
    ERC1155Base( "Weed Gang Presents", "WGP" ){
    setToken( 0, "PLAYERS CLUB BLACK CARD", "https://gateway.pinata.cloud/ipfs/QmQMn76epc8fAiRAaphFaRVTAkqGZaxtBMcpFKsnd3nSPS", 960,
      false, 1 ether,
      false, 1 ether );
  }
}