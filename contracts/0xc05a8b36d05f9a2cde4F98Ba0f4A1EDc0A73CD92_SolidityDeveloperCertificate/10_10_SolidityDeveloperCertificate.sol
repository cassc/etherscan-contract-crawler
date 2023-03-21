// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolidityDeveloperCertificate is ERC721 {
    constructor() ERC721("Solidity Developer Certificate", "SDC") {
        _safeMint(_msgSender(), 0);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafkreicyn3oc2jpjeklv7pavdgdvuhryilq6267ram6uyxrp3jihjrusny.ipfs.nftstorage.link/";
    }
}