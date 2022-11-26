// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "arb-shared-dependencies/contracts/Inbox.sol";
import "arb-shared-dependencies/contracts/Outbox.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IMushrohmBridge.sol";
import "./interfaces/IPixelMushrohmBridge.sol";
import "./types/PixelMushrohmAccessControlled.sol";

contract MushrohmBridge is IMushrohmBridge, PixelMushrohmAccessControlled, ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */

    address public l2Target;
    address public mushrohmAddr;
    IInbox public inbox;

    /* ======== CONSTRUCTOR ======== */

    constructor(address _authority) PixelMushrohmAccessControlled(IPixelMushrohmAuthority(_authority)) {}

    /* ======== ADMIN FUNCTIONS ======== */

    function setInbox(address _inbox) external override onlyOwner {
        inbox = IInbox(_inbox);
    }

    function setL2Target(address _l2Target) external override onlyOwner {
        l2Target = _l2Target;
    }

    function setMushrohmAddress(address _mushrohmAddr) external override onlyOwner {
        mushrohmAddr = _mushrohmAddr;
    }

    // Incase of a problem. Allows admin to transfer stuck NFT back to user
    function transferStuckNFT(uint256 _tokenId) external override onlyPolicy {
        IERC721(mushrohmAddr).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /* ======== MUTABLE FUNCTIONS ======== */

    function transferMushrohmtoL2(
        uint256 _tokenId,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid
    ) external payable override whenNotPaused nonReentrant returns (uint256) {
        require(_tokenId <= 1500, "Mushrohm: Invalid token Id");

        IERC721(mushrohmAddr).safeTransferFrom(msg.sender, address(this), _tokenId);

        bytes memory data = abi.encodeWithSelector(
            IPixelMushrohmBridge.acceptTransferFromL1.selector,
            _tokenId,
            msg.sender
        );
        uint256 ticketId = inbox.createRetryableTicket{value: msg.value}(
            l2Target,
            0,
            _maxSubmissionCost,
            msg.sender,
            msg.sender,
            _maxGas,
            _gasPriceBid,
            data
        );

        emit RetryableTicketCreated(ticketId);
        return ticketId;
    }

    function acceptTransferFromL2(uint256 _tokenId, address _targetUser) external override whenNotPaused nonReentrant {
        require(_tokenId <= 1500, "Mushrohm: Invalid token Id");

        IBridge bridge = inbox.bridge();
        require(msg.sender == address(bridge), "Mushrohm: Sender must be the bridge");
        IOutbox outbox = IOutbox(bridge.activeOutbox());
        address l2Sender = outbox.l2ToL1Sender();
        // Need to make sure this actually stops, hash collisions on the L2 Contract PIN: Security
        require(l2Sender == l2Target, "Mushrohm: L2 sender must be equal to L2 target");

        emit NFTSentToUser(_tokenId, _targetUser, msg.sender);
        IERC721(mushrohmAddr).safeTransferFrom(address(this), _targetUser, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}