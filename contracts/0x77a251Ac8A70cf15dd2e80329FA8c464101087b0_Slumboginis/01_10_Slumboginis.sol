// contracts/Slumboginis.sol
// Slumboginis <3 PrimeFlare
// SPDX-License-Identifier: MIT
//    ______
//   /|_||_\`.__
//  (   _    _ _\
//  =`-(_)--(_)-'  such rad


pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Slumboginis is ERC721 {
    constructor() ERC721("Slumboginis", "SBO") {}

    uint256 public constant MAX_SBO = 10000;
    address public constant OWNER = 0xFcC450dCeFade7BBa0F78905215d044aDC68cd0b;

    function _baseURI() internal pure override returns (string memory) {
      return "ipfs://QmWLguevyWko1bwNEoHDnFHNYq69tyEgdiKXmJGDyHbrFw/";
    }

    function airDropItem(address[] memory owners, uint16[] memory tokenIds) public {
        require(msg.sender == OWNER, "must be owner");
        for(uint16 i = 0; i < tokenIds.length; i++){
          if (tokenIds[i] < MAX_SBO) { // implementing token max cap
            _safeMint(owners[i], tokenIds[i]);
          }
        }
    }

    function totalSupply() public pure returns (uint256) {
      return MAX_SBO;
    }
}