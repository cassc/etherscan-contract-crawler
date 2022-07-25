// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AStorage.sol";

contract BASKETBALLNFT is ERC721AUpgradeable, OwnableUpgradeable {
    using ERC721AStorage for ERC721AStorage.Layout;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Binance Regular NFT", "BRNFT");
        __Ownable_init();
    }

    function adminMint(uint256 quantity, address reciever)
        external
        payable
        onlyOwner
    {
        _mint(reciever, quantity);
    }

    function setNameSymbol(string calldata name_, string calldata symbol_)
        external
        onlyOwner
    {
        ERC721AStorage.layout()._name = name_;
        ERC721AStorage.layout()._symbol = symbol_;
    }
}