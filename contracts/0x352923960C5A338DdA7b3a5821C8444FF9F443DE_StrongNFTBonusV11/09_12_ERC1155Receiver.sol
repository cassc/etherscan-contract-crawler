// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.9;

import "../interfaces/IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}