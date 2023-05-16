// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of ERC1155 to add a name
 */
abstract contract ERC1155Metadata is ERC1155 {
    string private _name;

    constructor(string memory name_) {
        _name = name_;
    }

    /**
     * @dev the name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
}