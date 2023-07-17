// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Context } from "lib/openzeppelin-contracts/contracts/utils/Context.sol";

/// @notice Provides information about the current execution context, including the
/// sender of the transaction and its data. While these are generally available
/// via msg.sender and msg.data, they should not be accessed in such a direct
/// manner, since when dealing with meta-transactions the account sending and
/// paying for execution may not be the actual sender (as far as an application
/// is concerned).
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
abstract contract MetaTxContext is Context {
    /// @notice Allows the recipient contract to retrieve the original sender
    /// in the case of a meta-transaction sent by the relayer
    /// @dev Required since the msg.sender in metatx will be the relayer's address
    /// @return sender Address of the original sender
    function _msgSender() internal view virtual override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
    }
}