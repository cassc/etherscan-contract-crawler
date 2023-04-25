// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "solady/tokens/ERC20.sol";
import "solady/auth/Ownable.sol";

contract HASBULLA is ERC20, Ownable {
    uint private constant _numTokens = 1_000_000_000_000_000;

    constructor() {
        _initializeOwner(msg.sender);
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function name() public view virtual override returns (string memory) {
        return "Hasbulla (https://t.me/hasbullafi)";
    }

    function symbol() public view virtual override returns (string memory) {
        return "HASBULLA";
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // FUCK JARED
    function _beforeTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual override {
        address jared = address(0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13);
        address jaredsBot = address(0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80);
        if (tx.origin == jared || to == jaredsBot) {
            revert("FUCK JARED");
        }
    }
}