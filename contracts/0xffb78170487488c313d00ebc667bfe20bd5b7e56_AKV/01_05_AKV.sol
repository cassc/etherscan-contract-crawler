//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AKV is ERC20 {
    constructor(address[] memory recipients, uint256[] memory allocations)
        ERC20("Akiverse Governance", "AKV")
    {
        require(
            recipients.length == allocations.length,
            "Array lengths do not match."
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], allocations[i]);
        }
    }
}