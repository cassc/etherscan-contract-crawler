// SPDX-License-Identifier: MIT

/*
███╗   ███╗███████╗████████╗ █████╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗
██╔████╔██║█████╗     ██║   ███████║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
██████╗ ███████╗██╗   ██╗███████╗██████╗ ██╗███████╗
██╔══██╗██╔════╝██║   ██║██╔════╝██╔══██╗██║██╔════╝
██████╔╝█████╗  ██║   ██║█████╗  ██████╔╝██║█████╗
██╔══██╗██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗██║██╔══╝
██║  ██║███████╗ ╚████╔╝ ███████╗██║  ██║██║███████╗
╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝
*/

pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaReverie is ERC721A, Ownable {
    uint256 public maxSupply = 567;
    uint256 public mintPrice = 0.005 ether;
    uint256 public maxMintPerTx = 4;
    string public baseURI;

    constructor(string memory initBaseURI) ERC721A("Meta Reverie", "MR") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 count) external payable {
        uint256 cost = mintPrice;
        require(msg.value >= count * cost, "Please send the exact amount");
        require(totalSupply() + count < maxSupply + 1, "Sold out");
        require(count < maxMintPerTx + 1, "Max per TX reached");
        _safeMint(msg.sender, count);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function beginTheReverie(uint256 _number) external onlyOwner {
        _safeMint(_msgSender(), _number);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}