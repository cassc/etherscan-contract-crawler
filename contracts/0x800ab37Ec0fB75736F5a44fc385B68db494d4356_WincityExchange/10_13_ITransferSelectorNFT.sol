// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 *  __          _______ _   _  _____ _____ _________     __
 *  \ \        / /_   _| \ | |/ ____|_   _|__   __\ \   / /
 *   \ \  /\  / /  | | |  \| | |      | |    | |   \ \_/ /
 *    \ \/  \/ /   | | | . ` | |      | |    | |    \   /
 *     \  /\  /   _| |_| |\  | |____ _| |_   | |     | |
 *      \/  \/   |_____|_| \_|\_____|_____|  |_|     |_|
 *
 * @author Wincity | Antoine Duez
 * @title ITransferSelectorNFT
 * @notice Interface for transfer selector of ERC tokens manager.
 */
interface ITransferSelectorNFT {
    function transferManagerSelectorForCollection(address collection)
        external
        view
        returns (address);
}