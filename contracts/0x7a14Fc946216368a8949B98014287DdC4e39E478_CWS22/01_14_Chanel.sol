// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//                                        *
//                                    *********
//                              ********************
//                           ***************************
//                           ***************************
//                           ***************************
//                           ***************************
//                           ***************************
//                           ***************************
//                           ***************************
//                               *******************
//                                   ***********
//                                        *
//
//
//                          *                           *
//                     ***********                 ***********
//                 ********************       ********************
//              ************************** *************************
//                   ******************************************
//                       **********************************
//                           **************************
//                               ******************
//                                    *********
//            ***                         *                        ***
//        ***********                                          ***********
//   ********************                                  ********************
//****************************                         ****************************
//    ****************************               ***************************
//         ****************************       ***************************
//             *************************** **************************
//                  ************|Developed by BEE3™|************
//                       **********************************
//                           **************************
//                                *****************
//                                    ********
//                                        *
//
//
//                           *                         *
//                           ******               ******
//                           *********         *********
//                           ************* *************
//                           ***************************
//                           ***************************
//                           ***************************
//                               *******************
//                                    ********
//                                        *

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CWS22 is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    string private baseExtension = '.json';
    uint256 private maxSupply = 89;
    uint256 private supplyMinted;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Wilderness Seminar 2022", "CWS22") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://nftstorage.link/ipfs/bafybeic2r52wdri4d3gkikc2rwkaz2pei4kn7j2omcl2wxzaftg5eimzxq/";
    }

    function safeMint(address to) public onlyOwner {
        require(maxSupply > supplyMinted, "No more NFTs to mint");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        supplyMinted++;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}