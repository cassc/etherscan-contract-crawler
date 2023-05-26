// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

contract StakeborgToken is ERC20Burnable {
    uint256 private constant SUPPLY = 20000000 * 10**18;

    constructor(address distributor)
        public
        ERC20("Stakeborg Standard", "STANDARD")
    {
        _mint(distributor, SUPPLY);
    }
}