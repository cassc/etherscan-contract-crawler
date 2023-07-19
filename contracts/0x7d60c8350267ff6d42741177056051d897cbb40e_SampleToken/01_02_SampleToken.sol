// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@solmate/tokens/ERC20.sol";

contract SampleToken is ERC20("SAMPLE_TOKEN", "ST", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}