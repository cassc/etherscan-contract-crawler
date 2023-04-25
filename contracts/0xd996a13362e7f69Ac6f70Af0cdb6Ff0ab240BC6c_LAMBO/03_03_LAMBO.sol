// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract LAMBO is ERC20, Ownable {
    uint private constant _numTokens = 1_000_000_000_000_000;

    constructor() {
        _initializeOwner(msg.sender);
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function name() public view virtual override returns (string memory) {
        return "Lambo Finance";
    }

    function symbol() public view virtual override returns (string memory) {
        return "LAMBO";
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}