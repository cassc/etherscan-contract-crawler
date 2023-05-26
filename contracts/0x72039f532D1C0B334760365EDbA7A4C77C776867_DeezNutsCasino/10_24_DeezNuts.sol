// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

contract DeezNuts is ERC721Tradable{
  constructor(address _proxyRegistryAddress) ERC721Tradable("Deez Nuts", "NTS", _proxyRegistryAddress) {  }

  function baseTokenURI() override public pure returns (string memory) {
        return "https://storage.googleapis.com/deeznutsnft/final/Nut";
  }

}