// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.11;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EinstienToken is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
    }

    receive() external payable {
        // do nothing
    }

    /// @notice you can claim the ETH in this token if you have 5% of the supply. Use your big brain to figure out how to get this.
    function claimETH() external {
        require(balanceOf(msg.sender) >= totalSupply() / 5);
        burn();
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice burn baby burn
    function burn() public {
        _burn(msg.sender, balanceOf(msg.sender));
    }
}