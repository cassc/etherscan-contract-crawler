// SPDX-License-Identifier: Unlicense
// Creatoor: Scroungy Labs
// BurningZeppelin Contracts (last updated v0.0.1) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.9;

//   ____                                                          ________                                        ___
//  /\  _`\                              __                       /\_____  \                                      /\_ \      __
//  \ \ \L\ \   __  __   _ __    ___    /\_\     ___       __     \/____//'/'      __    _____    _____      __   \//\ \    /\_\     ___
//   \ \  _ <' /\ \/\ \ /\`'__\/' _ `\  \/\ \  /' _ `\   /'_ `\        //'/'     /'__`\ /\ '__`\ /\ '__`\  /'__`\   \ \ \   \/\ \  /' _ `\
//    \ \ \L\ \\ \ \_\ \\ \ \/ /\ \/\ \  \ \ \ /\ \/\ \ /\ \L\ \      //'/'___  /\  __/ \ \ \L\ \\ \ \L\ \/\  __/    \_\ \_  \ \ \ /\ \/\ \
//     \ \____/ \ \____/ \ \_\ \ \_\ \_\  \ \_\\ \_\ \_\\ \____ \     /\_______\\ \____\ \ \ ,__/ \ \ ,__/\ \____\   /\____\  \ \_\\ \_\ \_\
//      \/___/   \/___/   \/_/  \/_/\/_/   \/_/ \/_/\/_/ \/___L\ \    \/_______/ \/____/  \ \ \/   \ \ \/  \/____/   \/____/   \/_/ \/_/\/_/
//                                                         /\____/                         \ \_\    \ \_\
//                                                         \_/__/                           \/_/     \/_/
//   ____                                      __                  ____                        __                                __
//  /\  _`\                                   /\ \__              /\  _`\                     /\ \__                            /\ \__
//  \ \,\L\_\     ___ ___       __      _ __  \ \ ,_\             \ \ \/\_\    ___     ___    \ \ ,_\   _ __     __       ___   \ \ ,_\    ____
//   \/_\__ \   /' __` __`\   /'__`\   /\`'__\ \ \ \/              \ \ \/_/_  / __`\ /' _ `\   \ \ \/  /\`'__\ /'__`\    /'___\  \ \ \/   /',__\
//     /\ \L\ \ /\ \/\ \/\ \ /\ \L\.\_ \ \ \/   \ \ \_              \ \ \L\ \/\ \L\ \/\ \/\ \   \ \ \_ \ \ \/ /\ \L\.\_ /\ \__/   \ \ \_ /\__, `\
//     \ `\____\\ \_\ \_\ \_\\ \__/.\_\ \ \_\    \ \__\              \ \____/\ \____/\ \_\ \_\   \ \__\ \ \_\ \ \__/.\_\\ \____\   \ \__\\/\____/
//      \/_____/ \/_/\/_/\/_/ \/__/\/_/  \/_/     \/__/               \/___/  \/___/  \/_/\/_/    \/__/  \/_/  \/__/\/_/ \/____/    \/__/ \/___/

import "../../utils/introspection/IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/******************/