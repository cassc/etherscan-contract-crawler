// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LightYears.sol";
import "./Pausable.sol";

contract TimedSelectionMinter is Pausable {
    uint256 private constant PRESELECTIONS = 2;
    uint256 private constant SELECTION_TICKETS = 98;

    /// @notice ERC-721 contract that is used as passes
    /// @dev should start numbering its tokens from ID 1
    IERC721 public passes;

    /// @notice ERC-721 contract that mints tokens by ID in response to selections
    /// @dev must implement mint(address, uint256)
    LightYears public lightYears;

    /// @notice Address where used passes are sent
    address public passDestination;

    /// @notice Whether or not a given pass has already been claimed
    /// @dev Provides a check against passes recirculating after going to the `passDestination`
    mapping(uint256 => bool) public passClaimed;

    /// @notice The start time for the mint, i.e. when the owner of Pass 1 can make their selection
    uint256 public selectionMintStartTime;

    /// @notice The end of the selection period, after which the contract owner can mint on behalf of pass holders
    uint256 public selectionMintDeadline;

    /// @notice The number of selections that unlock per day
    uint256 public selectionUnlocksPerDay;

    /// @notice The time between passes unlocking, in seconds
    uint256 public selectionUnlockOffset = 15 minutes;

    uint256 private pauseStart;
    uint256 private pastPauseUnlocks;
    uint256 private preselectCount;

    bool private selectionStarted;

    /// @notice An event to be emitted upon selection for the benefit of the UI
    event Selection(address recipient, uint256 passId, uint256 selectedTokenId);

    /// @notice An error returned when the selection has already started.
    error AlreadyStarted();

    constructor(
        IERC721 passes_,
        LightYears lightYears_,
        address destination,
        uint256 startTime,
        uint256 selectionDeadline,
        uint256 unlocksPerDay,
        uint256 unlockOffsetInSeconds
    ) {
        // CHECKS inputs
        require(passes_.supportsInterface(0x80ac58cd), "Pass contract must implement ERC-721");
        require(
            lightYears_.supportsInterface(0x40c10f19),
            "Light Years contract must implement mint(address, uint256)"
        );
        require(destination != address(0), "Final pass destination must not be the zero address");
        require(startTime > block.timestamp, "The start time cannot be in the past");
        require(
            unlocksPerDay > 0 && unlocksPerDay <= SELECTION_TICKETS,
            "Unlocks per day must be between 1 and the number of selection passes"
        );
        require(
            unlockOffsetInSeconds >= 5 minutes && unlockOffsetInSeconds <= 12 hours,
            "Unlock offset must be between 5 minutes and 12 hours"
        );
        require(
            unlocksPerDay * unlockOffsetInSeconds <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        uint256 selectionDays = (SELECTION_TICKETS + unlocksPerDay - 1) / unlocksPerDay;
        require(
            selectionDeadline >= startTime + 1 days * selectionDays,
            "Selection deadline must be a full day after selection has ended"
        );
        // EFFECTS
        passes = passes_;
        lightYears = lightYears_;
        passDestination = destination;
        selectionMintStartTime = startTime;
        selectionMintDeadline = selectionDeadline;
        selectionUnlocksPerDay = unlocksPerDay;
        selectionUnlockOffset = unlockOffsetInSeconds;
    }

    modifier beforeSelection() {
        if (selectionStarted) revert AlreadyStarted();
        _;
    }

    // TICKET HOLDER FUNCTIONS

    /// @notice Allows the owner of the specified `passes` token to select a token to mint
    /// @dev Can only be called after the pass is unlocked
    /// @param passId The pass being redeemed. The caller must be the owner of the pass or an approved operator.
    /// @param selectedTokenId The unminted token that the sender has chosen to mint
    function select(uint256 passId, uint256 selectedTokenId) external whenNotPaused {
        // CHECKS inputs
        require(passId <= unlockedUpTo(), "Wait for your selection slot");
        require(!passClaimed[passId], "Pass has already been claimed");

        // CHECKS permissions
        // With safe INTERACTIONS: use view function of known contract
        address passHolder = passes.ownerOf(passId);
        address operator = msg.sender;
        require(
            operator == passHolder ||
                passes.isApprovedForAll(passHolder, operator) ||
                passes.getApproved(passId) == operator ||
                // Allow selections by the contract owner after the deadline
                (block.timestamp >= selectionMintDeadline && operator == owner()),
            "Caller is not pass owner or approved"
        );

        // EFFECTS
        selectionStarted = true;
        passClaimed[passId] = true;

        emit Selection(passHolder, passId, selectedTokenId);

        // INTERACTIONS: reverts if selectedTokenId has already been minted
        lightYears.mint(passHolder, selectedTokenId);
        passes.transferFrom(passHolder, passDestination, passId);
    }

    // OWNER FUNCTIONS

    /// @notice Allows the contract owner to preselect a token to mint without a pass
    /// @dev The number of tokens mintable with this method is limited by `PRESELECTIONS`
    /// @param selectedTokenId The unminted token that will be minted
    function preselect(uint256 selectedTokenId) external onlyOwner {
        // CHECKS inputs
        require(preselectCount < PRESELECTIONS, "Preselections have all been minted");

        // EFFECTS
        preselectCount++;
        emit Selection(owner(), SELECTION_TICKETS + preselectCount, selectedTokenId);

        // INTERACTIONS: reverts if selectedTokenId has already been minted
        lightYears.mint(owner(), selectedTokenId);
    }

    /// @notice Update the passes contract address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setPasses(IERC721 passes_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(passes_.supportsInterface(0x80ac58cd), "Pass contract must implement ERC-721");
        // EFFECTS
        passes = passes_;
    }

    /// @notice Update the Light Years contract address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setLightYears(LightYears lightYears_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            lightYears_.supportsInterface(0x40c10f19),
            "Light Years contract must implement mint(address, uint256)"
        );
        // EFFECTS
        lightYears = lightYears_;
    }

    /// @notice Update the pass destination address
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setPassDestination(address passDestination_) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(passDestination_ != address(0), "Final pass destination must not be the zero address");
        // EFFECTS
        passDestination = passDestination_;
    }

    /// @notice Pause this contract
    /// @dev Can only be called by the contract `owner`
    function pause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.pause();

        // More EFFECTS
        pauseStart = block.timestamp;
    }

    /// @notice Resume this contract
    /// @dev Can only be called by the contract `owner`. Any selection slots that were during the pause will be pushed
    ///  back, which may require adding more selection blocks to complete the selection process.
    function unpause() public override {
        // CHECKS + EFFECTS: `Pausable` handles checking permissions and setting pause state
        super.unpause();

        // More EFFECTS
        if (block.timestamp > selectionMintStartTime) {
            unchecked {
                // Unchecked arithmetic: pauseStart is a timestamp, selectionUnlockOffset guaranteed to be smaller
                uint256 lastCompletePass = unadjustedMintUpTo(pauseStart - selectionUnlockOffset);
                uint256 unpausePass = unadjustedMintUpTo(block.timestamp);
                // Unchecked arithmetic: RHS never negative. `pastPauseUnlocks` cannot overflow as each pause unlock
                // represents either a unique call to unpause() or a passing of `selectionUnlockOffset` seconds.
                pastPauseUnlocks += unpausePass - lastCompletePass;
            }
        }
    }

    /// @notice Update the start time for the mint
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionMintStartTime(uint256 startTime) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(startTime > block.timestamp, "The start time cannot be in the past");
        // EFFECTS
        selectionMintStartTime = startTime;
    }

    function setSelectionMintDeadline(uint256 deadline) external onlyOwner beforeSelection {
        // CHECKS inputs
        uint256 selectionDays = (SELECTION_TICKETS + selectionUnlocksPerDay - 1) / selectionUnlocksPerDay;
        require(
            deadline >= selectionMintStartTime + 1 days * selectionDays,
            "Selection deadline must be a full day after selection has ended"
        );
        // EFFECTS
        selectionMintDeadline = deadline;
    }

    /// @notice Update number of selections that unlock per day
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionUnlocksPerDay(uint256 unlocksPerDay) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            unlocksPerDay > 0 && unlocksPerDay <= SELECTION_TICKETS,
            "Unlocks per day must be between 1 and the number of selection passes"
        );
        require(
            unlocksPerDay * selectionUnlockOffset <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        // EFFECTS
        selectionUnlocksPerDay = unlocksPerDay;
    }

    /// @notice Update the time between passes unlocking
    /// @dev Can only be called by the contract `owner`. Reverts if selections have already been made.
    function setSelectionUnlockOffset(uint256 offsetInSeconds) external onlyOwner beforeSelection {
        // CHECKS inputs
        require(
            offsetInSeconds >= 5 minutes && offsetInSeconds <= 12 hours,
            "Unlock offset must be between 5 minutes and 12 hours"
        );
        require(
            selectionUnlocksPerDay * offsetInSeconds <= 1 days,
            "Unlock offset must allow unlocks per day to complete within 24 hours"
        );
        // EFFECTS
        selectionUnlockOffset = offsetInSeconds;
    }

    // VIEW FUNCTIONS

    /// @notice Query the highest pass id that can currently mint
    function unlockedUpTo() public view returns (uint256 passId) {
        passId = unadjustedMintUpTo(block.timestamp);

        // Handle repeated early pauses edge case
        if (pastPauseUnlocks > passId) return 0;

        unchecked {
            // Unchecked arithmetic: already compared values to prevent underflow
            passId -= pastPauseUnlocks;
        }

        if (passId > SELECTION_TICKETS) {
            return SELECTION_TICKETS;
        }
    }

    /// @notice Query the time that the given `passId` will be able to mint
    /// @dev Times in the past may be inaccurate if the contract has previously been paused
    function unlockTime(uint256 passId) external view returns (uint256 unlockTimestamp) {
        // CHECKS input
        require(passId > 0 && passId <= SELECTION_TICKETS, "Invalid pass ID");

        // Compute output
        unchecked {
            // Unchecked arithmetic: switching to zero-indexed. Cannot underflow due to previous checks.
            passId--;
        }
        passId += pastPauseUnlocks;

        unlockTimestamp =
            selectionMintStartTime +
            // Divide before multiply: divide computes completed days
            ((passId / selectionUnlocksPerDay) * 1 days) +
            (selectionUnlockOffset * (passId % selectionUnlocksPerDay));
    }

    /// @notice Query for all times that `passId` holders will be able to mint
    /// @dev Array index === passId - 1
    function unlockTimes() external view returns (uint256[SELECTION_TICKETS] memory unlockTimestamps) {
        uint256 _selectionMintStartTime = selectionMintStartTime;
        uint256 _selectionUnlocksPerDay = selectionUnlocksPerDay;
        uint256 _selectionUnlockOffset = selectionUnlockOffset;
        uint256 _pastPauseUnlocks = pastPauseUnlocks;
        for (uint256 passSlot = _pastPauseUnlocks; passSlot < SELECTION_TICKETS + _pastPauseUnlocks; passSlot++) {
            unlockTimestamps[passSlot - _pastPauseUnlocks] =
                _selectionMintStartTime +
                ((passSlot / _selectionUnlocksPerDay) * 1 days) +
                (_selectionUnlockOffset * (passSlot % _selectionUnlocksPerDay));
        }
        return unlockTimestamps;
    }

    // PRIVATE FUNCTIONS

    function unadjustedMintUpTo(uint256 timestamp) private view returns (uint256 passId) {
        if (timestamp < selectionMintStartTime) return 0;

        unchecked {
            // Unchecked arithmetic: already compared values to prevent underflow
            uint256 elapsedTime = timestamp - selectionMintStartTime;
            uint256 elapsedDays = elapsedTime / (1 days);
            uint256 lastDayUnlocks = Math.min(
                selectionUnlocksPerDay,
                // Unchecked arithmetic: sum guaranteed to be less than (1 days)
                1 + ((elapsedTime % (1 days)) / selectionUnlockOffset)
            );
            // Unchecked arithmetic: passId will be less than timestamp
            passId = elapsedDays * selectionUnlocksPerDay + lastDayUnlocks;
        }
    }
}