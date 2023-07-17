// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.20;

import {ERC1155} from "../lib/solmate/src/tokens/ERC1155.sol";
import {Collision} from "./Collision.sol";

contract Research is ERC1155 {
    address immutable angel;

    Collision public collision;

    string public name = "Angel Matter Research";
    string public symbol = "AMR";

    constructor() {
        angel = msg.sender;
        collision = new Collision();
    }

    function mint(address to, uint256 id) external {
        require(msg.sender == angel);
        _mint(to, id, 1, "");
    }

    function uri(uint256 id) public view override returns (string memory) {
        return collision.uri(id);
    }
}