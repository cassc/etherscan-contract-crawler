// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/mintable/IERC20MintableExtension.sol";
import "./IERC20MintableOwnable.sol";

/**
 * @title ERC20 - Mint as owner
 * @notice Allow minting as contract owner with no restrictions.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:required-dependencies IERC20MintableExtension
 * @custom:provides-interfaces IERC20MintableOwnable
 */
contract ERC20MintableOwnable is IERC20MintableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC20MintableOwnable
     */
    function mintByOwner(address to, uint256 amount) public virtual onlyOwner {
        IERC20MintableExtension(address(this)).mintByFacet(to, amount);
    }

    /**
     * @inheritdoc IERC20MintableOwnable
     */
    function mintByOwner(address[] calldata tos, uint256[] calldata amounts) public virtual onlyOwner {
        IERC20MintableExtension(address(this)).mintByFacet(tos, amounts);
    }
}