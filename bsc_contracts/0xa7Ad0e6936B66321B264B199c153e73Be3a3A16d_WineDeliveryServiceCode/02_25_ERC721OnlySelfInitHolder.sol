// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts only self initiated token transfers.
 */
abstract contract ERC721OnlySelfInitHolder is IERC721Receiver {

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