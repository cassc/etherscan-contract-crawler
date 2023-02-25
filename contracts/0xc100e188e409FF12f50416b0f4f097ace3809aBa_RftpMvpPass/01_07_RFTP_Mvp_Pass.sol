//SPDX-License-Identifier: MIT

/*************************************
*                                    *
*     developed by brandneo GmbH     *
*        https://brandneo.de         *
*                                    *
**************************************/

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RftpMvpPass is ERC721A, ERC721AQueryable, Ownable {
    string  public baseURI;
    uint256 public maxSupply = 77;

    constructor(string memory contractBaseURI) ERC721A ("RFTP MVP PASS", "RFTPM") {
        baseURI = contractBaseURI;
    }

    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function mint(address wallet, uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= maxSupply, "Not enough supply");

        _safeMint(wallet, quantity);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        address owner = payable(msg.sender);

        bool success;

        (success,) = owner.call{value : (amount)}("");
        require(success, "Transaction Unsuccessful");
    }
}