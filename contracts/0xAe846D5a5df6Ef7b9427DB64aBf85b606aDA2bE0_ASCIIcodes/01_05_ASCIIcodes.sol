// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//    _____    __________________ .___.___                 .___             
//   /  _  \  /   _____/\_   ___ \|   |   | ____  ____   __| _/____   ______
//  /  /_\  \ \_____  \ /    \  \/|   |   |/ ___\/  _ \ / __ |/ __ \ /  ___/
// /    |    \/        \\     \___|   |   \  \__(  <_> ) /_/ \  ___/ \___ \ 
// \____|__  /_______  / \______  /___|___|\___  >____/\____ |\___  >____  >
//         \/        \/         \/             \/           \/    \/     \/ 

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ASCIIcodes is ERC721A, Ownable {
    uint256 public maxSupply = 800;
    uint256 public cost = .004 ether;
    uint256 public maxPerTx = 4;

    string public baseURI =
        "ipfs://QmXtvZNT8ZJC8AzEAhaUgt4jdwFNNX4BtFy9BeckKiMWnp/";
    bool public sale = false;

    error SaleNotActive();
    error MaxSupplyReached();
    error MaxPerTxReached();
    error NotEnoughETH();

    constructor() payable ERC721A("ASCIIcodes", "ASCIIcode") {}

    function mint(uint256 _amount) external payable {
        if (!sale) revert SaleNotActive();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount > maxPerTx) revert MaxPerTxReached();
        if (msg.value < cost * _amount) revert NotEnoughETH();

        _mint(msg.sender, _amount);
    }

    function ownerMint(address receiver, uint256 _amount) external onlyOwner {
        _mint(receiver, _amount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        maxSupply = _newSupply;
    }

    function toggleSale() external onlyOwner {
        sale = !sale;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}