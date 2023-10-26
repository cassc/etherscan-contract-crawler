// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";

// ⢠⣶⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⣿⣿⠁⠀⠙⢿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠸⣿⣆⠀⠀⠈⢻⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⡿⠿⠛⠻⠿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣀⡀⠀
// ⠀⢻⣿⡆⠀⠀⠀⢻⣷⡀⠀⠀⠀⠀⠀⠀⢀⣴⣾⠿⠿⠿⣿⣿⠀⠀⠀⠀⠀⠈⢻⣷⡀⠀⠀⠀⠀⠀⢀⣠⣶⣿⠿⠛⠋⠉⠉⠻⣿⣦
// ⠀⠀⠻⣿⡄⠀⠀⠀⢿⣧⣠⣶⣾⠿⠿⠿⣿⡏⠀⠀⠀⠀⢹⣿⡀⠀⠀⠀⢸⣿⠈⢿⣷⠀⠀⠀⢀⣴⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⢸⣿
// ⠀⠀⠀⠹⣿⡄⠀⠀⠈⢿⣿⡏⠀⠀⠀⠀⢻⣷⠀⠀⠀⠀⠸⣿⡇⠀⠀⠀⠈⣿⠀⠘⢿⣧⣠⣶⡿⠋⠁⠀⠀⠀⠀⠀⠀⣀⣠⣤⣾⠟
// ⠀⠀⠀⠀⢻⣿⡄⠀⠀⠘⣿⣷⠀⠀⠀⠀⢸⣿⡀⠀⠀⠀⠀⣿⣷⠀⠀⠀⠀⣿⠀⢶⠿⠟⠛⠉⠀⠀⠀⠀⠀⢀⣤⣶⠿⠛⠋⠉⠁⠀
// ⠀⠀⠀⠀⠀⢿⣷⠀⠀⠀⠘⣿⡆⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⢹⣿⠀⠀⠀⠀⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠋⠁⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠘⣿⡇⠀⠀⠀⢸⣷⠀⠀⠀⠀⢿⣷⠀⠀⠀⠀⠈⣿⡇⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⣴⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢻⣿⠀⠀⠀⠀⢿⣇⠀⠀⠀⠸⣿⡄⠀⠀⠀⠀⣿⣷⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⣼⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠘⣿⡇⠀⠀⠀⠸⣿⡀⠀⠀⠀⢿⣇⠀⠀⠀⠀⢸⣿⡀⠀⢠⣿⠇⠀⠀⠀⠀⠀⣼⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⢹⣿⠀⠀⠀⠀⢻⣧⠀⠀⠀⠸⣿⡄⠀⠀⠀⢘⣿⡿⠿⠟⠋⠀⠀⠀⠀⠀⣼⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠈⣿⣇⠀⠀⠀⠈⣿⣄⠀⢀⣠⣿⣿⣶⣶⣶⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⡀⠀⠀⠀⠈⠻⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣧⡀⠀⠀⠀⣀⠀⠀⠀⣴⣤⣄⣀⣀⣀⣠⣤⣾⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣶⣶⣿⡿⠃⠀⠀⠉⠛⠻⠿⠿⠿⠿⢿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract SimpleFactory is BoringFactory, BoringBatchable {
    function transferOwnership(address owned, address newOwner) external {
        IOwnable(owned).transferOwnership(newOwner);
    }

    function exec(address target, bytes calldata data, uint256 value) external payable {
        (bool success, bytes memory result) = target.call{value: value}(data);

        if (!success) { // If call reverts
            // If there is return data, the call reverted without a reason or a custom error.
            if (result.length == 0) revert();
            assembly {
                // We use Yul's revert() to bubble up errors from the target contract.
                revert(add(32, result), mload(result))
            }
        }
    }
}