// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./ERC721B.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

error OverMaxSupply();
error WrongEtherValue();

contract MistWalkers is ERC721B, Ownable {
    using Strings for uint256;

    // collection specific parameters
    string private baseURI;

    uint256 public constant SUPPLY = 300;
    uint256 public constant PRICE = 0.03 ether;

    constructor() ERC721B("MistWalkers", "Mist") {}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function publicMint(uint256 qty) external payable {
        if ((_owners.length + qty) > SUPPLY) revert OverMaxSupply();
        if (msg.value < PRICE * qty) revert WrongEtherValue();

        _safeMint(msg.sender, qty);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
}