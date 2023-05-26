// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Tradable.sol";

contract BrokeBoyz is ERC721Tradable{
  constructor(address _proxyRegistryAddress) ERC721Tradable("BrokeBoyz", "BBZ", _proxyRegistryAddress) {  }

  function baseTokenURI() override public pure returns (string memory) {
        return "https://storage.googleapis.com/brokeboyz/";
  }

}



// https://storage.googleapis.com/brokeboyz/bblockg1.png

// https://storage.googleapis.com/brokeboyz/bblockg1.json


// **
// Rest of naming structures will be the exact same URL above but the name at the end will be formatted like this:
// bblockg <- B-Block (good)
// bblocke <- B-Block (evil)
// mintpass <-mint pass
// tessg <- Tess (good)
// tesse <- Tess (evil)
// rooseveltg <- Roosevelt (good)
// roosevelte <- Roosevelt (evil)