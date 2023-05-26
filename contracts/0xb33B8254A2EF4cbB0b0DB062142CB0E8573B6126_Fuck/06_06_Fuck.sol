pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fuck is ERC20, Ownable {
    constructor() ERC20("Fuck", "FUCK") {
        _mint(msg.sender, 420690000000000 * 10 ** decimals());
    }
}