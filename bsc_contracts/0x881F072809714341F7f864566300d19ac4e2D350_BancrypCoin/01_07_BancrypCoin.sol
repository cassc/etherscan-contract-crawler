pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BancrypCoin is ERC20, ERC20Burnable {

    constructor() ERC20("Bancryp Coin", "BNP") {
        _mint(msg.sender, 297000000 * 10 ** decimals());
    }


}