// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract GabaInu is ERC721A, Ownable {
    bool minted;
    string baseURI;

    constructor() ERC721A("Gaba Inu", "GabaInu") {
        baseURI = "ipfs://QmbZwdrgQUmwB5v4cR7M44U7AWm5G1zXxyvZuMsnk7mKzy/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner() {
        baseURI = newURI;
    }

    function mint() external payable {
        require(!minted, "Mint already completed");
        _mint(msg.sender, 500);
        minted = true;
    }
}