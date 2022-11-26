// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IBaseBridge.sol";

interface IMushrohmBridge is IERC721Receiver, IBaseBridge {
    /* ========== EVENTS ========== */

    event RetryableTicketCreated(uint256 indexed ticketId);

    /* ======== ADMIN FUNCTIONS ======== */

    function setInbox(address _inbox) external;

    function setL2Target(address _l2Target) external;

    function setMushrohmAddress(address _mushrohmAddr) external;

    /* ======== MUTABLE FUNCTIONS ======== */

    function transferMushrohmtoL2(
        uint256 _tokenId,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable returns (uint256);

    function acceptTransferFromL2(uint256 tokenId, address userAddress) external;
}