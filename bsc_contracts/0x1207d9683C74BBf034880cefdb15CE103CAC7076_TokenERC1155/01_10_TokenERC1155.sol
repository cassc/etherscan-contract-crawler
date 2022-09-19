// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenERC1155 is ERC1155, Ownable {

    string public name;
    string public symbol;

    mapping(uint => string) public tokenHashs;
    constructor(string memory _name, string memory _symbol, string memory newuri) ERC1155(newuri) {
        name = _name;
        symbol = _symbol;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data, string memory _hash) public onlyOwner {
        tokenHashs[id] = _hash;
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    public
    onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
    function uri(uint _tokenId) public view override returns (string memory) {
        return bytes(super.uri(_tokenId)).length > 0 ? string(abi.encodePacked(super.uri(_tokenId), tokenHashs[_tokenId])) : "";
    }
}