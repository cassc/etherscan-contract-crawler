// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { console } from "../test/utils/log.sol";

contract ERC1155Receiver {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}

interface IERC1155 {

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

}

contract ERC1155Wrapper is ERC1155Receiver {

    bytes32 private constant ADMIN_SLOT = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    address secretSanta;
    address midLabs;

    mapping(uint256 => bool) public withdrawn;
    mapping(uint256 => bool) public deposited;

    function initialize(address secretSanta_, address midLabs_) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "NOT_ADMIN");

        secretSanta = secretSanta_;
        midLabs     = midLabs_; 
    }

    function transferFrom(address from, address to, uint256 tokenId) external {

        // It's the secret santa calling to withdraw
        if (msg.sender == secretSanta && from == address(secretSanta)) {
            require(!withdrawn[tokenId], "ALREADY_WITHDRAWN");
            withdrawn[tokenId] = true;
            IERC1155(midLabs).safeTransferFrom(address(this), to, 1, 1, "");
        }

        if (msg.sender == secretSanta && to == address(secretSanta)) {
            require(!deposited[tokenId], "ALREADY_DEPOSITED");
            deposited[tokenId] = true;
        }
        
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

}