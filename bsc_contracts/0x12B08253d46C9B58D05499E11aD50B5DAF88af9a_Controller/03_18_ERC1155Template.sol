// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC1155Template is ERC1155, Ownable{

    using Strings for uint256;

    string private _name;

    string private _symbol;

    string private _uri;

    constructor(string memory name_, string memory symbol_, string memory uri_) ERC1155("") {
        _name = name_;
        _symbol = symbol_;
        _uri = uri_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setURI(string memory uri_) public onlyOwner{
        _uri = uri_;
    }

    function baseURI() public view returns(string memory){
        return _uri;
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner{
        _mint(to, id, amount, data);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }

    function uri(uint256 id) public view override returns (string memory){
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, "{id}")) : "";
    }

}