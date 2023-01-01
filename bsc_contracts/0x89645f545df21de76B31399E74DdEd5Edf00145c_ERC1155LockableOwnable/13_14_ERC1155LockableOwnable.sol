// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/lockable/IERC1155LockableExtension.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155LockableOwnable.sol";

/**
 * @title ERC1155 - Lock as owner
 * @notice Allow locking tokens as the contract owner.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155LockableExtension
 * @custom:provides-interfaces IERC1155LockableOwnable
 */
contract ERC1155LockableOwnable is IERC1155LockableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC1155LockableOwnable
     */
    function lockByOwner(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual onlyOwner {
        IERC1155LockableExtension(address(this)).lockByFacet(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableOwnable
     */
    function lockByOwner(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual onlyOwner {
        IERC1155LockableExtension(address(this)).lockByFacet(accounts, ids, amounts);
    }

    /**
     * @inheritdoc IERC1155LockableOwnable
     */
    function unlockByOwner(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual onlyOwner {
        IERC1155LockableExtension(address(this)).unlockByFacet(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableOwnable
     */
    function unlockByOwner(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual onlyOwner {
        IERC1155LockableExtension(address(this)).unlockByFacet(accounts, ids, amounts);
    }
}