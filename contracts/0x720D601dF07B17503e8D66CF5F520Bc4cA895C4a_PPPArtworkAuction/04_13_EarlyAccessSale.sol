// SPDX-License-Identifier: MIT
// Copyright (c) 2022 - 2023 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract PatronPass is IERC721 {
    function logPassUse(uint256 tokenId, uint256 projectId) external virtual;

    function passUses(uint256 tokenId, uint256 projectId) external view virtual returns (uint256);

    function projectInfo(uint256 projectId) external view virtual returns (address, address, string memory);
}

contract EarlyAccessSale is Ownable {
    /// @notice Timestamp when this auction starts allowing minting
    uint256 public startTime;

    /// @notice Duration of the early access period where minting is limited to pass holders
    uint256 public earlyAccessDuration;

    /// @notice The contract that is used to gate minting during the early access period
    PatronPass public passes;

    /// @notice The project id for this auction in `passes`
    uint256 internal passProjectId;

    /// @notice Whether or not this contract is paused
    /// @dev The exact meaning of "paused" will vary by contract, but in general paused contracts should prevent most
    ///  interactions from non-owners
    bool public isPaused = false;
    uint256 private pauseStart;
    uint256 internal pastPauseDelay;

    event Paused();
    event Unpaused();

    /// @notice An error returned when the auction has already started
    error AlreadyStarted();
    /// @notice An error returned when the auction has not yet started
    error NotYetStarted();

    /// @notice An error returned when minting during early access without a pass
    error EarlyAccessWithoutPass();

    error ContractIsPaused();
    error ContractNotPaused();

    constructor(uint256 startTime_, uint256 earlyAccessDuration_) {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "Start time cannot be in the past");
        require(earlyAccessDuration_ >= 60 * 5, "Early access must last at least 5 minutes");
        require(earlyAccessDuration_ <= 60 * 60 * 24, "Early access must not last longer than 24 hours");

        // EFFECTS
        startTime = startTime_;
        earlyAccessDuration = earlyAccessDuration_;
    }

    modifier started() {
        if (!isStarted()) revert NotYetStarted();
        _;
    }
    modifier unstarted() {
        if (isStarted()) revert AlreadyStarted();
        _;
    }

    modifier publicMint() {
        if (!isPublic()) revert EarlyAccessWithoutPass();
        _;
    }

    modifier whenPaused() {
        if (!isPaused) revert ContractNotPaused();
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) revert ContractIsPaused();
        _;
    }

    // OWNER FUNCTIONS

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public virtual whenNotPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = true;
        pauseStart = block.timestamp;
        emit Paused();
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`
    function unpause() public virtual whenPaused onlyOwner {
        // EFFECTS (checks already handled by modifiers)
        isPaused = false;
        emit Unpaused();

        // See if pastPauseDelay needs updated
        if (block.timestamp <= startTime) {
            return;
        }
        // Find the amount time the auction should have been live, but was paused
        unchecked {
            // Unchecked arithmetic: computed value will be < block.timestamp and >= 0
            if (pauseStart < startTime) {
                pastPauseDelay = block.timestamp - startTime;
            } else {
                pastPauseDelay += (block.timestamp - pauseStart);
            }
        }
    }

    /// @notice Update the auction start time
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setStartTime(uint256 startTime_) external unstarted onlyOwner {
        // CHECKS inputs
        require(startTime_ >= block.timestamp, "New start time cannot be in the past");
        // EFFECTS
        startTime = startTime_;
    }

    /// @notice Update the duration of the early access period
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setEarlyAccessDuration(uint256 duration) external unstarted onlyOwner {
        // CHECKS inputs
        require(duration >= 60 * 5, "Early access must last at least 5 minutes");
        require(duration <= 60 * 60 * 24, "Early access must not last longer than 24 hours");

        // EFFECTS
        earlyAccessDuration = duration;
    }

    /// @notice Update the pass contract for the early access period
    /// @dev Can only be called by the contract `owner`. Reverts if the auction has already started.
    function setPassContract(PatronPass passContract, uint256 projectId) external unstarted onlyOwner {
        // CHECKS inputs
        (address projectMinter, , ) = passContract.projectInfo(projectId);
        require(projectMinter == address(this), "Specified pass project is not configured for this auction");

        // EFFECTS
        passes = passContract;
        passProjectId = projectId;

        if (isStarted()) {
            // If setting the contract started the auction, then we need to pretend we were paused up to this point
            unchecked {
                // Unchecked arithmetic: startTime <= block.timestamp because the auction has started
                pastPauseDelay = block.timestamp - startTime;
            }
        }
    }

    // VIEW FUNCTIONS

    /// @notice Query if the early access period has ended
    function isPublic() public view returns (bool) {
        return isStarted() && block.timestamp >= (startTime + pastPauseDelay + earlyAccessDuration);
    }

    /// @notice Query if this contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if `interfaceID` is implemented and is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x7f5828d0 || // ERC-173 Contract Ownership Standard
            interfaceId == 0x01ffc9a7; // ERC-165 Standard Interface Detection
    }

    // INTERNAL FUNCTIONS

    function isStarted() internal view virtual returns (bool) {
        return address(passes) != address(0) && (isPaused ? pauseStart : block.timestamp) >= startTime;
    }

    function timeElapsed() internal view returns (uint256) {
        if (!isStarted()) return 0;
        unchecked {
            // pastPauseDelay cannot be greater than the time passed since startTime
            if (!isPaused) {
                return block.timestamp - startTime - pastPauseDelay;
            }

            // pastPauseDelay cannot be greater than the time between startTime and pauseStart
            return pauseStart - startTime - pastPauseDelay;
        }
    }
}