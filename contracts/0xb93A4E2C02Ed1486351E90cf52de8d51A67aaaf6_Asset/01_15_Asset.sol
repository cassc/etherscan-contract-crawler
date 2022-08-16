// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Mintable.sol";


//                          ░▓▓▓▓░▓
//                  ▒▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓
//              ▒▓▓▓▓▓▓▓▓▓  ▓▒▒▒▒▒▒▒▓▓▓▓▓▓▓
//             ░▓▓▓░▓      ▓▓▓▓▓▓▓▓▒ ▓▓▓▓▓▓▓▒
//        ▓▓▓▓             ▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▒
//      ▒▓▓▓▓▒      ▓░▓▓▓  ▓▓▓▓▓▓▓▒   ░▓▓▓▓▓▓▓▓
//     ▓▓▓▓▓    ▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//    ▓▓▓▓    ▓▓▓▓▓▓▓▒▒    ▓▓▓▓ ░░░░░░░░  ▒▓▓▓▓▓▓
//   ▓▓▓▓    ▓▓▓▓▓▓        ▒▓░▒▓▓▓▓▓▓▓▓▓▓▓▒ ▒▓▓▓░
//   ▒▓▓▓   ▒▓▓▓▓     ▒▓▓▓▓▓▓░▒▓▓▒▒▓░▒▒░▓▓▓▓▓▓▓▓▒
//   ░▓▓▓   ▓▓▓▓▓   ▒▓▓▓▓▓▓▓▓░▒▓▓▓▓▓░▒░░▒▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓    ▓▓▓▓▓▓▓▓▓░▒▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓   ▒▓▓▓▓▓▓▓▓▓░▒▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓   ▒▓▓▒  ▓▓▓▓░▒▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓   ▒▓▓▓  ▓▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓   ▒▓▓▓  ▓▓▓▓░▒▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ░▓▓▓   ▓▓▓▓   ▒▓▓▓  ▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓░ ▓▓▓
//   ▒▓▓▓   ▓▓▓▓   ▒▓▓▓  ▓▓▓▓▓▒▓▓▓▓▓▓▓▓▓▓▓▓▓▒▓▓▓▓
//    ▓▓    ░▓▓░   ▓▓▓▓  ▓▓▓░▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//         ░▓▓▓▓   ▓▓▓▓  ▓▓▒             ▒▓▓▓▓▓▓▓
//      ▓▓▓▓▓▓▓   ▓▓▓░   ▒▓▓▓░▓▓▓▓▓▓▓▓▓▓▒ ▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓     ▓▓▓▓   ▓▓▓▓░▒▒▒▒▒▒▒▒▒▓  ▓▓▓░
//   ▒▓▓▒       ▓▓▓▓▒   ▓▓▓░    ▒▓▓▓░▓    ▓▓▓
//            ▒▓▓▓▓▓    ▓▓░   ░▓▓▓▓▓▓▓▒   ▓▓▓
//         ▓▒▓▓▓▓░     ░▓▓▒  ▒▓▓▓▓▓▓▓▓▓   ▓▓▓
//     ▓▒▓▓▓▓▓▓▓      ▓▓▓   ▓▓▓▓▒   ▓▓▓   ▓▓▓
//    ▒▓▓▓▒▓        ▓▓▓▓    ▓▓▓     ▓▓▓   ▓▓▓
//               ▓▓▓▓▓▒   ▓▓▓▓▓     ▓▓▓   ▓▓▓
//            ▓▓▓▓▓▓▒    ▒▓▓▓       ▓▓▓   ▒▓▓▓▒
//       ▓▓▓▓▓▓▓▓▒     ▓▓▓▓▒   ▓▓▓  ▒▓▓▓    ▒▓▓▓
//      ▒▓▓▓▓▒        ▓▓▓▓▓   ▒▓▓▒  ▓▓▓▓▓
//                 ▒▓▓▓▓▓    ▓▓▓▓░   ▒▓▓▓▓▒
//             ▒▓▓▓▓▓▓▒     ▒▓▓▓▓▓    ▒▓▓▓▓
//          ▓▓▓▓▓▓░▓      ▒▓▓▓▓▓▓▓▓
//                     ▓░▓▓▓▒   ▓▓▓▓▒
//                  ▒▓▓▓▓▓▒       ▒▓▓▓
//                  ▒▒▓


contract Asset is ERC721, Mintable {

    string private baseURI; 

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        baseURI = "https://deviantsfactions.com/api/v1/collection/DF/tokens/ERC721/";
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function _baseURI() internal override view virtual returns (string memory) {        
        return baseURI;
    }    

    function contractURI() public view returns (string memory) {        
        return string(abi.encodePacked(baseURI, "0"));        
    }    
    
    function setBaseURI(string memory newBaseURI) onlyOwner external {
        baseURI = newBaseURI;        
    }   

}