/**
 *Submitted for verification at BscScan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestToken {
    // Definicje nazwy, symbolu i ilości tokenów
    string public constant name = "Test2 Token";
    string public constant symbol = "TXT";
    uint256 public totalSupply;

    // Struktura tokena
    struct Token {
        uint256 id;
        string imageUrl;
    }

    // Mapa, która trzyma informacje o każdym tokenie
    mapping (uint256 => Token) public tokens;

    // Zmienna, która trzyma informacje o właścicielu tokena
    mapping (uint256 => address) public tokenOwner;

    // Konstruktor, który inicjalizuje totalSupply
    constructor() public {
        totalSupply = 100;
    }

    // Funkcja mint, która pozwala na dodanie tokenu do systemu
    function mintWithImage(uint256 _tokenId, string memory _imageUrl) public {
        require(tokenOwner[_tokenId] == address(0), "Token already exists");
        tokenOwner[_tokenId] = msg.sender;
        tokens[_tokenId] = Token(_tokenId, _imageUrl);
        totalSupply++;
    }

    // Zaimplementowanie interfejsu ERC721
    function totalSupplyValue() external view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < totalSupply; i++) {
            if (tokenOwner[i] == _owner) {
                balance++;
            }
        }
        return balance;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return tokenOwner[_tokenId];
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this token");
        require(tokenOwner[_tokenId] != address(0), "Token does not exist");
        tokenOwner[_tokenId] = _to;
    }

    function takeOwnership(uint256 _tokenId) external {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this token");
        require(tokenOwner[_tokenId] != address(0), "Token does not exist");
        tokenOwner[_tokenId] = address(0);
    }
}