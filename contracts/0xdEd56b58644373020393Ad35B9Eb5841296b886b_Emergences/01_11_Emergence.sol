// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Emergences is ERC1155, Ownable {
    uint256 public constant Emergence = 1;

    constructor()
        ERC1155(
            "https://ipfs.io/ipfs/bafybeiaetq465sjk5b5hlfpg7r434ipnhle7lppk326mywa7jwdoegkv4y/{id}.json"
        )
    {}


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function airdropMask(
        address[] memory _to,
        uint256[] memory _id,
        uint256[] memory _amount
    ) public onlyOwner {
        require(
            _to.length == _id.length,
            "Receivers and IDs are different length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _id[i], _amount[i], "");
        }
    }

}