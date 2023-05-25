// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IMintableToken.sol";

contract LoomToken is AccessControl, ERC20Burnable, IMintableToken {
    using Address for address;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 public constant INITIAL_SUPPLY = 1000000000; // 1 billion

    constructor(address _tokenSwap) ERC20("Loom Token", "LOOM") {
        require(
            _tokenSwap != address(0) && _tokenSwap.isContract(),
            "LoomToken: invalid contract address"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // fund the token swap contract
        _mint(_tokenSwap, INITIAL_SUPPLY * 1e18);
    }

    /**
     * @notice Mints `amount` tokens for `to`.
     *
     * Requirements:
     *
     * - The caller must have the `MINTER` role.
     */
    function mint(address to, uint256 amount) external override {
        require(hasRole(MINTER_ROLE, msg.sender), "LoomToken: not authorized");
        _mint(to, amount);
    }
}