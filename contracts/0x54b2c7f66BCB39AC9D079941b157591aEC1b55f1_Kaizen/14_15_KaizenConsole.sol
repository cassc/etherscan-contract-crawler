// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KaizenConsole is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public notRevealedUri;

    constructor(
        string memory _initNotRevealedUri
    ) ERC721A("KAIZENCONSOLE", "KZNC") {
        setNotRevealedURI(_initNotRevealedUri);
    }

    function gift(address receiverAddress, uint256 ammount) public onlyOwner {
        require(ammount > 0, "KAIZENCONSOLE : Need to gift at least 1 NFT");
        _safeMint(receiverAddress, ammount);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      return notRevealedUri;
    }
}