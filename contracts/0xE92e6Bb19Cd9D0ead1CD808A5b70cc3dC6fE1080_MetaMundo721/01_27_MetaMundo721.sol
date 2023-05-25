// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract MetaMundo721 is ERC721Creator {
    // contractAddress
    string private contractAddress;
    // baseURI
    string public baseURI;

    constructor(string memory name, string memory symbol, string memory uri_) ERC721Creator(name, symbol) {
        contractAddress = toString(address(this));
        baseURI = string(abi.encodePacked(uri_, contractAddress, '/'));
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : '';
    }
}