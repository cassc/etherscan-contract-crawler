// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HILO is ERC20, Ownable {
    constructor() ERC20("HILO", "HILO") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}