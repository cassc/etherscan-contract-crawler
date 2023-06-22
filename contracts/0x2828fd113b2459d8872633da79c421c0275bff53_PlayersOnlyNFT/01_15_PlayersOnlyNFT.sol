// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

contract PlayersOnlyNFT is ERC721Tradable{
  constructor(address _proxyRegistryAddress) ERC721Tradable("Players Only NFT", "POF", _proxyRegistryAddress) {  }

  function baseTokenURI() override public pure returns (string memory) {
        return "https://storage.googleapis.com/playersonlydrop/JSON/Final";
  }

}