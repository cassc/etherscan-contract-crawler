// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@oz/token/ERC20/ERC20.sol";
import "@oz/access/AccessControl.sol";
import "@oz/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @title Auxo ERC20 Token (AUXO)
 * @notice Auxo has the following key properties:
 *    1) Implements the full ERC20 standard, including optional fields name, symbol and decimals
 *    2) Implements gasless approval via EIP-712 and the `.permit` method
 *    3) Can be minted only by accounts with the MINTER_ROLE
 *    4) Has a DEFAULT_ADMIN_ROLE that can grant additional accounts MINTER_ROLE
 *    5) Unless revoked, grants DEFAULT_ADMIN and MINTER roles to the deployer of the contract
 */
contract Auxo is ERC20, AccessControl, ERC20Permit {
    /// @notice contract that handles locks of staked AUXO tokens, in exchange for ARV
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Auxo", "AUXO") ERC20Permit("Auxo") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}