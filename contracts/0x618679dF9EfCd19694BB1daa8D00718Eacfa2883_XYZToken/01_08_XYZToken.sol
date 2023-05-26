// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XYZToken is ERC20Burnable, Ownable {
    uint256 private constant SUPPLY = 1_000_000_000 * 10**18;

    constructor() public ERC20("XYZ Governance Token", "XYZ") {
        _mint(msg.sender, SUPPLY);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }
}