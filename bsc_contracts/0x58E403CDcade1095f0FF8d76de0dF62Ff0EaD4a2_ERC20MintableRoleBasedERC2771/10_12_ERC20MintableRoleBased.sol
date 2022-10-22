// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/mintable/IERC20MintableExtension.sol";
import "./IERC20MintableRoleBased.sol";

/**
 * @title ERC20 - Mint as role
 * @notice Allow minting for senders with MINTER_ROLE to mint new tokens (supports ERC20A).
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension
 * @custom:provides-interfaces IERC20MintableRoleBased
 */
contract ERC20MintableRoleBased is IERC20MintableRoleBased, AccessControlInternal {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @inheritdoc IERC20MintableRoleBased
     */
    function mintByRole(address to, uint256 amount) public virtual onlyRole(MINTER_ROLE) {
        IERC20MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC20MintableRoleBased
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) public virtual onlyRole(MINTER_ROLE) {
        IERC20MintableExtension(address(this)).mintByFacet(tos, amounts);
    }
}