//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract P2D is ERC20Burnable, Ownable {
    constructor(address _ownerAddress)
        ERC20("Play to Donate", "P2D")
        Ownable()
    {
        _mint(_ownerAddress, 300000000 ether);
        _transferOwnership(_ownerAddress);
    }
}