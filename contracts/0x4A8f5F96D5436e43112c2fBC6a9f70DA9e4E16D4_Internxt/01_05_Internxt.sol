pragma solidity ^0.8.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Internxt is ERC20 {

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 111929454291701);
    }
}