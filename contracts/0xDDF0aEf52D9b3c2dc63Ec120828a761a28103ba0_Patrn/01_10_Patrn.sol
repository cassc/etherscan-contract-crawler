// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Patrn is ERC1155, Ownable {

    // Empty constructor means there's no base URI by default
    constructor() ERC1155("") {}

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Specify URI for artwork X & mint N copies for artist + patrons
    function mintArtwork (
        uint256 id,
        uint256 copies
    ) public onlyOwner {
        _mint(msg.sender, id, copies, "");
    }

    // Transfer artwork X to recipient Y
    function transferArtwork (
        uint256 id,
        address recipient
    ) public onlyOwner {
        _safeTransferFrom(msg.sender, recipient, id, 1, "");
    }

    // Specify a new base URI for item metadata
    function setBaseURI (
        string memory new_uri
    ) public onlyOwner {
        _setURI(new_uri);
    }
}