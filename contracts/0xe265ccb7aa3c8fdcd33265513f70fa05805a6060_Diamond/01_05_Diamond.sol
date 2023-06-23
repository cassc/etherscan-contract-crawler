pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Diamond is ERC20 {
    constructor() ERC20("Diamond", "DIAMOND", 0xb9A8c89caae2Bd72490F59caC5a21bFF812333B0, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, 210000000 * (10 ** 18));
    }
}