// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 *      _____                     ______ __  __ _____   ______          ________ _____  ______ _____
 *     |_   _|                   |  ____|  \/  |  __ \ / __ \ \        / /  ____|  __ \|  ____|  __ \
 *       | |     __ _ _ __ ___   | |__  | \  / | |__) | |  | \ \  /\  / /| |__  | |__) | |__  | |  | |
 *       | |    / _` | '_ ` _ \  |  __| | |\/| |  ___/| |  | |\ \/  \/ / |  __| |  _  /|  __| | |  | |
 *      _| |_  | (_| | | | | | | | |____| |  | | |    | |__| | \  /\  /  | |____| | \ \| |____| |__| |
 *     |_____|  \__,_|_| |_| |_| |______|_|  |_|_|     \____/   \/  \/   |______|_|  \_\______|_____/
 *      _____   ______          __         __  __          _   _    _____ _____ _________     __
 *     |  __ \ / __ \ \        / /        |  \/  |   /\   | \ | |  / ____|_   _|__   __\ \   / /
 *     | |__) | |  | \ \  /\  / /  __  __ | \  / |  /  \  |  \| | | |      | |    | |   \ \_/ /
 *     |  ___/| |  | |\ \/  \/ /   \ \/ / | |\/| | / /\ \ | . ` | | |      | |    | |    \   /
 *     | |    | |__| | \  /\  /     >  <  | |  | |/ ____ \| |\  | | |____ _| |_   | |     | |
 *     |_|     \____/   \/  \/     /_/\_\ |_|  |_/_/    \_\_| \_|  \_____|_____|  |_|     |_|
 *
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}