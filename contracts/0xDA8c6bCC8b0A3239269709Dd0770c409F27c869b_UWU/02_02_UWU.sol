// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solady/tokens/ERC20.sol";

contract UWU is ERC20 {
    uint private constant _numTokens = 69_000_000_000_000;

    constructor() {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function name() public view virtual override returns (string memory) {
        return unicode"UωU";
    }

    function symbol() public view virtual override returns (string memory) {
        return "UwU";
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function renounceOwnership() public {}
}