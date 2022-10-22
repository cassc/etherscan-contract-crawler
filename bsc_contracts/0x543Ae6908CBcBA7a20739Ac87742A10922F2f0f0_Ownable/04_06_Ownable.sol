// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC173.sol";
import "./OwnableInternal.sol";

/**
 * @title ERC173 - Ownable
 * @notice Ownership access control facet based on EIP-173 which would be already included as a core facet in Flair's Diamond contract.
 *
 * @custom:type eip-2535-facet
 * @custom:category Access
 * @custom:provides-interfaces IERC173
 */
contract Ownable is IERC173, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}