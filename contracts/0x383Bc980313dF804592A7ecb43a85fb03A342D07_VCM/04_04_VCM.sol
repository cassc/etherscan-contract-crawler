// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VCM is ERC20, Ownable {
    constructor() ERC20("VinylChloride", "VCM", 18) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * (10**18));
    }
}