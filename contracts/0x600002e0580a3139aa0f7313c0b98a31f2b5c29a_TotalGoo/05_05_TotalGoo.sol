// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {IArtGobblers} from "./IArtGobblers.sol";

/// @author philogy <https://github.com/philogy>
contract TotalGoo {
    string public constant name = "Total GOO (virtual + token)";
    string public constant symbol = "tGOO";

    IArtGobblers public constant artGobblers =
        IArtGobblers(0x60bb1e2AA1c9ACAfB4d34F71585D7e959f387769);

    IERC20 public immutable goo =
        IERC20(0x600000000a36F3cD48407e35eB7C5c910dc1f7a8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        // Ensure Etherscan recognizes contract as ERC20.
        emit Transfer(address(0), address(uint160(0xdead)), 1);
        emit Transfer(address(uint160(0xdead)), address(0), 1);
    }

    function balanceOf(address _addr) external view returns (uint256) {
        return artGobblers.gooBalance(_addr) + goo.balanceOf(_addr);
    }
}