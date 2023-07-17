// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Infinity is ERC721URIStorage, Ownable {

    // Number of tokens minted in this collection
    uint256 public minted;

    // Locks minting and URI updating
    bool public locked;

    constructor(address initOwner) ERC721("INFINITY","INF") {
        transferOwnership(initOwner);
    }

    function batchMint(string[] memory uris, address receiver) public onlyOwner {
        require(!locked, "Locked");
        for (uint256 i=0; i<uris.length; i++) {
            _safeMint(receiver, minted);
            _setTokenURI(minted, uris[i]);
            minted++;
        }
    }

    function batchURIUpdate(uint256[] memory tokenIds, string[] memory uris) public onlyOwner {
        require(!locked, "Locked");
        for (uint256 i=0; i<uris.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);
        }
    }

    function lock() public onlyOwner {
        locked = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "ar://";
    }

}