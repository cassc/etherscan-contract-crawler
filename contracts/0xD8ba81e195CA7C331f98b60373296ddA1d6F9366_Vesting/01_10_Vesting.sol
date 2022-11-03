// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MINU.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./signature/SignatureVerify.sol";

error ClaimingIsFinished();
error ClaimingPhaseNotStarted();
error ClaimingPhaseForSystemNotStarted();

contract Vesting is Ownable, SignatureVerify {
    uint8 constant MAX_LOCK_PERIODS_BY_USERS = 3;
    uint8 constant MAX_LOCK_PERIODS_BY_SYSTEM = 6;
    // uint32 constant LOCK_PERIOD = 30 days;
    // todo for test
    uint32 constant LOCK_PERIOD = 3600;
    uint32 constant PERCENTAGE_SHARE = 33_00000;
    uint32 constant MAX_PERCENTAGE_SHARE = 100_00000;

    bool public isFinishedClaiming;
    uint256 public vestingTotalSupply;
    uint256 public claimStartDate;

    MINU public minuToken;

    mapping(address => uint8) public numberOfTimesClaimedByAddress;

    modifier onlyIfClaimingIsNotFinished() {
        if (isFinishedClaiming) {
            revert ClaimingIsFinished();
        }
        _;
    }

    constructor(uint256 initialSupply, address signer) SignatureVerify(signer) {
        vestingTotalSupply = initialSupply;
        claimStartDate = block.timestamp;
    }

    /**
     * @notice initVestingAddress a function for init vesting contract.
     */
    function initVestingAddress(address _minuAddress) public onlyOwner {
        minuToken = MINU(_minuAddress);
    }

    /**
     * @notice claimByUser function for users.
     * @dev Function for sending erc20 tokens
     * @param amount the sum of all tokens that can be claimed by the user
     * @param signature signature of system
     */
    function claimByUser(uint256 amount, bytes calldata signature)
        public
        onlyIfClaimingIsNotFinished
    {
        checkClaimRequest(_msgSender(), address(this), amount, signature);

        uint256 availableTokensForClaim = getAvailableTokenForClaim(amount);

        if (availableTokensForClaim <= 0) {
            revert ClaimingPhaseNotStarted();
        }
        numberOfTimesClaimedByAddress[_msgSender()] = getCurrenClaimPhase();

        minuToken.transfer(_msgSender(), availableTokensForClaim);
    }

    /**
     * @notice claimBySystem a function that allows all tokens to be claimed after 6 months by the system.
     */
    function claimBySystem() public onlyOwner onlyIfClaimingIsNotFinished {
        isFinishedClaiming = true;

        uint256 allowedTime = claimStartDate +
            (LOCK_PERIOD * MAX_LOCK_PERIODS_BY_SYSTEM);

        if (allowedTime > block.timestamp) {
            revert ClaimingPhaseForSystemNotStarted();
        }

        uint256 balanceOfTokens = minuToken.balanceOf(address(this));
        minuToken.transfer(_msgSender(), balanceOfTokens);
    }

    /**
     * @notice getCurrenClaimPhase returns the current month for the users claim.
     * @return returns the current month for the users claim.
     */
    function getCurrenClaimPhase() public view returns (uint8) {
        if (block.timestamp > claimStartDate + LOCK_PERIOD * 3) {
            return 3;
        } else if (block.timestamp > claimStartDate + LOCK_PERIOD * 2) {
            return 2;
        } else if (block.timestamp > claimStartDate + LOCK_PERIOD) {
            return 1;
        } else return 0;
    }

    /**
     * @notice getPercentageShare returns the percentage of a number.
     * @param totalCount total number for claim of user
     * @param allowedPhasesQuantity number of available phases
     * @return returns the percentage of a number
     */
    function getPercentageShare(uint256 totalCount, uint8 allowedPhasesQuantity)
        internal
        view
        returns (uint256)
    {
        if (getCurrenClaimPhase() == 3 && allowedPhasesQuantity == 3) {
            return totalCount;
        } else if (getCurrenClaimPhase() == 3 && allowedPhasesQuantity == 2) {
            return totalCount - getPercentByMonth(totalCount, 1);
        } else if (getCurrenClaimPhase() == 3 && allowedPhasesQuantity == 1) {
            return totalCount - getPercentByMonth(totalCount, 2);
        }
        return getPercentByMonth(totalCount, allowedPhasesQuantity);
    }

    /**
     * @notice getAvailableTokenForClaim returns the possible number of tokens for claim.
     * @param amount total number for claim of user
     * @return returns the possible number of tokens for claim
     */
    function getAvailableTokenForClaim(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint8 allowedPhasesQuantity = getCurrenClaimPhase() -
            numberOfTimesClaimedByAddress[_msgSender()];
        if (allowedPhasesQuantity <= 0) {
            return 0;
        }
        return getPercentageShare(amount, allowedPhasesQuantity);
    }

    /**
     * @notice getAlreadyClaimedTokens returns the number of tokens that the user has already branded.
     * @param amount total number for claim of user
     * @return the number of tokens that the user has already branded
     */
    function getAlreadyClaimedTokens(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint8 alreadyClaimed = numberOfTimesClaimedByAddress[_msgSender()];
        if (alreadyClaimed == 0) {
            return 0;
        } else if (alreadyClaimed == 3) {
            return amount;
        } else {
            return getPercentByMonth(amount, alreadyClaimed);
        }
    }

    /**
     * @notice getLockedTokens returns the number of tokens that are currently blocked.
     * @param amount total number for claim of user
     * @return the number of tokens that are currently blocked
     */
    function getLockedTokens(uint256 amount) public view returns (uint256) {
        uint256 lockedTokens = amount -
            getAvailableTokenForClaim(amount) -
            getAlreadyClaimedTokens(amount);
        return lockedTokens;
    }

    /**
     * @notice getPercentByMonth return percent share by month.
     * @param totalCount total number for claim of user
     * @param monthNumber month number for claim
     * @return percent share by month
     */
    function getPercentByMonth(uint256 totalCount, uint8 monthNumber)
        private
        pure
        returns (uint256)
    {
        return
            (totalCount * PERCENTAGE_SHARE * monthNumber) /
            MAX_PERCENTAGE_SHARE;
    }
}