// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract FashionLeagueFirstFall is ERC1155, Ownable, ERC1155Supply { 
    string public name = "Fashion League First Fall";
    string public symbol = "FLFF";
    // max number of tokens
    uint256 constant tokenLimit = 521;

    // token URI
    string baseURI;
    string URISuffix;

    constructor() ERC1155("") {
        URISuffix = ".json";
    }
    
    // set new uri string without suffix
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), _URISuffix()));
    }
    // returns uri suffix
    function _URISuffix() internal view returns (string memory) {
        return URISuffix;
    }
    // set new uri suffix
    function setURISuffix(string memory _suffix) public onlyOwner {
        URISuffix = _suffix;
    }

    // batch mint
    function batchMint(uint256 _quantity) public onlyOwner {
        require(_quantity <= tokenLimit - totalSupply(1), "batchMint exceeds max");
        _mint(msg.sender, 1, _quantity, "");
    }

    /*
    Specify an array of addresses (receivers) that will receive 1 token of
    specific token id:
    batchTransfer(["0x123...", "0xabc...", ...]
    e.g. batchTransfer(["0x123...", "0xabc...");
    would transfer 1 token to each address 0x123..., 0xabc... etc.
    */
    function batchTransfer(address[] memory _addresses) public {
        uint256 leng = _addresses.length;
        require(balanceOf(msg.sender, 1) >= leng, "insufficient type quantity");
        for(uint256 i = 0; i < leng; i++) {
            address _address = _addresses[i];
            safeTransferFrom(msg.sender, _address, 1, 1, "");
        }
    }



    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}