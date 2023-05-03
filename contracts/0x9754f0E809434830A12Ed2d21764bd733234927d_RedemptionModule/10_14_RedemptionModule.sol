// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IERC173.sol";
import "./I721BeforeTransfersModule.sol";

interface IPassport {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract RedemptionModule is IERC173, I721BeforeTransfersModule, AccessControl, DefaultOperatorFilterer {
    address private convenienceOwner;

    bool public paused;
    uint256 public lockDuration;
    IPassport public passport;
    mapping(uint256 => uint256) public redemptions; // tokenID -> timestamp redeemed

    event Redeemed(address indexed redeemer, uint256[] tokenIds);
    event LockDurationUpdated(uint256 lockDuration);
    event PausedStatusUpdated(bool paused);

    modifier notPaused() {
        require(!paused, "Redemption: paused");
        _;
    }

    // -------- constructor --------

    constructor(uint256 _lockDuration, address _passport) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        lockDuration = _lockDuration;
        passport = IPassport(_passport);
        paused = true;
        convenienceOwner = msg.sender;
    }

    // -------- setters --------

    function setLockDuration(uint256 _lockDuration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lockDuration = _lockDuration;

        emit LockDurationUpdated(_lockDuration);
    }

    function setPaused(bool _paused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = _paused;

        emit PausedStatusUpdated(_paused);
    }

    // -------- overrides --------

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
    }

    /// @notice returns the address of the current convenienceOwner
    /// @dev not used for access control, used by services that require a single owner account
    /// @return convenienceOwner address
    function owner() external view returns (address) {
        return convenienceOwner;
    }

    function transferOwnership(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldOwner = convenienceOwner;
        convenienceOwner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // -------- external --------

    /// @notice redeem token. Can only redeem once
    /// @param tokenIds List of tokens to redeem. Must own token
    function redeem(uint256[] memory tokenIds) external notPaused {
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(redemptions[tokenId] == 0, "Redemption: token already redeemed");
            require(msg.sender == passport.ownerOf(tokenId), "Redemption: caller is not owner");
            redemptions[tokenId] = block.timestamp;
        }
        emit Redeemed(msg.sender, tokenIds);
    }

    /// @notice check if token is timelocked after redemption
    function beforeTokenTransfers(
        address sender,
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 quantity
    ) external view {
        // https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol#L51
        // logic from OS modifier
        if (from != sender) {
            _checkFilterOperator(sender);
        }
        uint256 endTokenId = startTokenId + quantity;
        for (uint256 i = startTokenId; i < endTokenId; ++i) {
            require(block.timestamp >= redemptions[i] + lockDuration, "Redemption: token still locked");
        }
    }
}