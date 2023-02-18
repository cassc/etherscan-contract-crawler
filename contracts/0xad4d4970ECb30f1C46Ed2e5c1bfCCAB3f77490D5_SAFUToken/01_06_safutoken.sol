pragma solidity =0.8.14;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SAFUToken is ERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint initialMint
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, initialMint);
    }
}