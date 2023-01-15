// SPDX-License-Identifier: MIT
//
//
// SuperPosition Reward Claimer created by Ryan Meyers @sreyeMnayR
// Twitter: @sp__to  Web: https://superposition.to
//
//
// Generosity attracts generosity.
//
// The world will be saved by beauty.
//
//

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract DummyERC1155 is ERC1155Burnable {
    constructor (address test_0, address test_1, address test_2) ERC1155("https://superposition.to/mock/{id}.json") {
        _mint(test_0, 1, 123456789, '');
        _mint(test_1, 1, 123456789, '');
        _mint(test_2, 1, 123456789, '');
    }
}