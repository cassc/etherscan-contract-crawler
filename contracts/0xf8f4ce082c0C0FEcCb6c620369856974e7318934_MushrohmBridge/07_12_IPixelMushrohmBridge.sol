// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBaseBridge.sol";

interface IPixelMushrohmBridge is IERC721Receiver, IBaseBridge {
    /* ========== EVENTS ========== */

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    /* ======== ADMIN FUNCTIONS ======== */

    function setPixelMushrohm(address _pixelMushrohm) external;

    function setL1Target(address _l1Target) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function transferPixelMushrohmtoL1(uint256 _tokenId) external returns (uint256);

    function acceptTransferFromL1(uint256 _tokenId, address _targetUser) external;
}