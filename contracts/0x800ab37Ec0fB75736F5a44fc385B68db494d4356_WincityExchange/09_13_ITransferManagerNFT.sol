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
 * @title ITransferManagerNFT
 * @notice Interface for ERC tokens manager
 */
interface ITransferManagerNFT {
    function transferNFT(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) external;
}