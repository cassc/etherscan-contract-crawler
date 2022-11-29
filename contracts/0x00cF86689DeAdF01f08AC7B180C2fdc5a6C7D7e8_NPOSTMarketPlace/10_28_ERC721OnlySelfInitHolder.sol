// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts only self initiated token transfers.
 */
abstract contract ERC721OnlySelfInitHolder is IERC721ReceiverUpgradeable {

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (operator == address(this)) {
            return this.onERC721Received.selector;
        }
        return bytes4(0);
    }
}