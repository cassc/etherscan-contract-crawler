// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LHC is ERC20, Ownable {
    constructor(address to) ERC20("Large Hadron", "LHC") {
        _mint(to, 369000000 * (10 ** 18));
    }

    function destroy() onlyOwner external {
        address owner = owner();
        selfdestruct(payable(owner));
    }
}