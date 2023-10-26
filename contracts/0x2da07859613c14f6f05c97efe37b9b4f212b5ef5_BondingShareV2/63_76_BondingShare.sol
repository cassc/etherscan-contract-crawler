// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC1155Ubiquity.sol";

contract BondingShare is ERC1155Ubiquity {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _manager) ERC1155Ubiquity(_manager, "URI") {}
}