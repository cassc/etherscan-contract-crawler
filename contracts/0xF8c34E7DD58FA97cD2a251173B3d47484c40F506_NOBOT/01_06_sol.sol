// SPDX-License-Identifier: MIT
 
/*
 
NOBOT Coin | $NOBOT


// NOBOT is the first and only memecoin to be fully *for the community* with an ever-growing black list of bots!
// Hate being front-run by jaredfromsubway but still want to FOMO into the latest memecoin?! NOBOT is the answer!

@NOBOTERC20


*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NOBOT is ERC20, Ownable {
    mapping(address => bool) public isBot;

    constructor() ERC20("NOBOT", "NOBOT") {
        uint256 initialSupply = 10000000000 * 10 ** 18;
        _mint(msg.sender, initialSupply);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!isBot[_msgSender()], "Transfer denied: sender is a bot.");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!isBot[sender], "Transfer denied: sender is a bot.");
        return super.transferFrom(sender, recipient, amount);
    }

    function addBotToList(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            isBot[bots[i]] = true;
        }
    }

    function removeFromBotList(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            isBot[bots[i]] = false;
        }
    }
}