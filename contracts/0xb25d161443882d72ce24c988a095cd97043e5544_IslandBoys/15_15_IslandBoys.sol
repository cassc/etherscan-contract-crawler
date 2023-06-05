// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

contract IslandBoys is ERC721Tradable{
  string baseTokenURL;

  constructor(address _proxyRegistryAddress) ERC721Tradable("Island Boys", "ISB", _proxyRegistryAddress) { 
    baseTokenURL = "https://storage.googleapis.com/islandboysnft/Reveal/JSON/";
   }

  function baseTokenURI() override public view returns (string memory) {
        return baseTokenURL;
  }

  function setBaseTokenURI(string memory newUri) public onlyOwner {
    baseTokenURL = newUri;
  } 


}