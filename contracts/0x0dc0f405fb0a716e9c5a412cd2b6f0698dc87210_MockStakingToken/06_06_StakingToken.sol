pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockStakingToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol
    ) payable ERC20(name, symbol) {}

    function mint(uint256 amount, address to) external {
        _mint(to, amount);
    }
}