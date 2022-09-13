// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title BaseERC20
 *
 * @notice The BaseERC20 is a simple token template based on OpenZeppelin implementation
 * with total token supply initially minted to a single treasury.
 */
contract BaseERC20 is ERC20Burnable {
    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(initialOwner, initialSupply);
    }
}