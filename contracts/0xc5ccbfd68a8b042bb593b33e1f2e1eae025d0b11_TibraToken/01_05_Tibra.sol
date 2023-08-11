pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TibraToken is ERC20 {
    constructor() ERC20("TibraToken", "TIB") {
        _mint(msg.sender, 12000000 * 10 ** decimals());
    }
}