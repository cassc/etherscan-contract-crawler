// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract NativeWrapper is ERC20BurnableUpgradeable
{
    receive() external payable {}

    function initialize() public initializer {
        __ERC20_init_unchained("Native Wrapper Token", "NATIVE");
        __ERC20Burnable_init_unchained();
    }

    function wrap(
        address receiver
    ) payable public {
        _mint(receiver, msg.value);
    }

    function wrap() payable external {
        wrap(msg.sender);
    }

    function unwrap(
        uint256 amount, 
        address receiver
    ) public {
        _burn(msg.sender, amount);
        (bool sent, ) = payable(receiver).call{value: amount}("");
        require(sent, "Failed to send NATIVE");
    }

    function unwrap(
        uint256 amount
    ) external {
        unwrap(amount, msg.sender);
    }

    uint256[50] private __gap;
}