//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AOPM is ERC20Burnable, Ownable {
    constructor(address _ownerAddress)
        ERC20("Open Platform Metaversity", "OPM")
        Ownable()
    {
        _mint(_ownerAddress, 30000000 ether);
        _transferOwnership(_ownerAddress);
    }
}