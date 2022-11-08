// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken1 is ERC721A, Ownable {
    event BaseURIUpdated(string baseURI);

    string _tokenBaseURI;

    constructor() ERC721A("MyToken1", "MTK") {
        _mintERC2309(msg.sender, 10);
    }

    function safeMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function batchMint(address to, uint256 quantity) public onlyOwner {
        _mintERC2309(to, quantity);
    }
    
    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        _tokenBaseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }
}