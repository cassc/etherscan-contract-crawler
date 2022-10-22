// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/ownable/OwnableInternal.sol";
import "../../extensions/lockable/IERC721LockableExtension.sol";
import "./IERC721LockableOwnable.sol";

/**
 * @title ERC721 - Lock as owner
 * @notice Allow locking tokens as the contract owner.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721LockableExtension
 * @custom:provides-interfaces IERC721LockableOwnable
 */
contract ERC721LockableOwnable is IERC721LockableOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function lockByOwner(uint256 id) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).lockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function lockByOwner(uint256[] memory ids) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).lockByFacet(ids);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function unlockByOwner(uint256 id) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).unlockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableOwnable
     */
    function unlockByOwner(uint256[] memory ids) public virtual onlyOwner {
        IERC721LockableExtension(address(this)).unlockByFacet(ids);
    }
}