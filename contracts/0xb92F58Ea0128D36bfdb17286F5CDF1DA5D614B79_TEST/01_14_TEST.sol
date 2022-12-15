// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.1;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract TEST is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private baseURI = "";
    string private baseExtension = ".json";

    bool public paused = true;              // 是否開啟 mint 開關

    constructor( string memory _deployURI ) ERC721("Test Only", "TOY") {
        uint256 supply = totalSupply();
        baseURI = _deployURI;
        console.log("start supply num : ", supply);
        console.log("baseURI : ", baseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /* Start Mint */
    function startMint() public onlyOwner {
        paused = false;
    }

    /* Pause Mint */
    function stopMint() public onlyOwner {
        paused = true;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

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