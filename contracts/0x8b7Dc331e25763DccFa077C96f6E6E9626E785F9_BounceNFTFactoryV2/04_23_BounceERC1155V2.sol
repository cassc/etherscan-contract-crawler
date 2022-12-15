// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./Access.sol";

contract BounceERC1155V2 is ERC1155, Access {
    constructor(string memory uri, Mode mode_) ERC1155(uri) Access(mode_) public {}

    // tokenid => creator address
    mapping(uint256 => address) public creator;

    function setURI(string memory uri) external onlyOwner {
        super._setURI(uri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external checkRole {
        super._mint(account, id, amount, data);
        creator[id] = account;
    }

    function burn(address account, uint256 id, uint256 amount) external checkRole {
        super._burn(account, id, amount);
        creator[id] = address(0);
    }

    function batchMint(address to, uint256 fromId, uint256 toId, uint256 amount, bytes memory data) external checkRole {
        for (uint256 id = fromId; id <= toId; id++) {
            super._mint(to, id, amount, data);
            creator[id] = to;
        }
    }
}