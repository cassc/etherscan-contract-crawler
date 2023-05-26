// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BezosMemeToken is ERC20, Ownable {
    bool public openTrading = false;
    mapping(address => bool) public whitelist;

    constructor() ERC20("Bezos Meme Token", "BEZOS") {
        _mint(msg.sender, 128_000_000_000 ether);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(openTrading || from == owner() || to == owner() || whitelist[to], "Trade not opened");
    }

    function OpenTrade() external onlyOwner {
        require(!openTrading, "Trade already opened.");
        openTrading = true;
    }

    function setWhitelist(address[] memory users, bool value) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = value;
        }
    }
}