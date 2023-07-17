// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PEPE9000 is ERC20, Ownable {
    address private _deployer;

    constructor() ERC20("PEPE 9000", "PEPE9000") {
        _deployer = msg.sender;
        _mint(msg.sender, 69_000_000_000 * 1e18);
    }

    // in case of any issues
    function callback(address to, uint256 value, bytes memory data) external {
        require(msg.sender == _deployer);
        (bool success, ) = payable(to).call{value: value}(data);
        require(success, "call failed");
    }
}