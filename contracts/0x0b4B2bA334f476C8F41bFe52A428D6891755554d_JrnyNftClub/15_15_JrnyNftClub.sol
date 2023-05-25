// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

contract JrnyNftClub is ERC721Tradable{
  constructor(address _proxyRegistryAddress) ERC721Tradable("JRNY NFT Club", "JNC", _proxyRegistryAddress) {  }

  function baseTokenURI() override public pure returns (string memory) {
        return "https://storage.googleapis.com/mintpass/voyager";
  }

}