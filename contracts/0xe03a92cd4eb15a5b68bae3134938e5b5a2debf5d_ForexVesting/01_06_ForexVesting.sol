// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*                                                *\
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
\*                                                 */

contract ForexVesting is Ownable {
    using SafeERC20 for IERC20;

    /** @dev Canonical FOREX token address */
    address public immutable FOREX;
    /** @dev The vesting period in seconds at which the FOREX supply for each
             participant is accrued as claimable each second according to their
             vested value */
    uint256 public immutable vestingPeriod;
    /** @dev Minimum delay (in seconds) between user claims. */
    uint256 public immutable minimumClaimDelay;
    /** @dev Date from which participants can claim their immediate value, and
             from which the vested value starts accruing as claimable */
    uint256 public claimStartDate;
    /** @dev Mapping of (participant address => participant vesting data) */
    mapping(address => Participant) public participants;
    /** @dev Total funds required by contract. Used for asserting the contract
             has been correctly funded after deployment */
    uint256 public immutable forexSupply;

    /** @dev Vesting data for participant */
    struct Participant {
        /* Amount initially claimable at any time from the claimStartDate */
        uint256 claimable;
        /* Total vested amount released in equal amounts throughout the
                 vesting period. */
        uint256 vestedValue;
        /* Date at which the participant last claimed FOREX */
        uint256 lastClaimDate;
    }

    event ParticipantAddressChanged(
        address indexed previous,
        address indexed current
    );

    constructor(
        address _FOREX,
        uint256 _vestingPeriod,
        uint256 _minimumClaimDelay,
        address[] memory participantAddresses,
        uint256[] memory initiallyClaimable,
        uint256[] memory vestedValues
    ) {
        // Assert that the minimum claim delay is greater than zero seconds.
        assert(_minimumClaimDelay > 0);
        // Assert that the vesting period is a multiple of the minimum delay.
        assert(_vestingPeriod % _minimumClaimDelay == 0);
        // Assert all array lengths match.
        uint256 length = participantAddresses.length;
        assert(length == initiallyClaimable.length);
        assert(length == vestedValues.length);
        // Initialise immutable variables.
        FOREX = _FOREX;
        vestingPeriod = _vestingPeriod;
        minimumClaimDelay = _minimumClaimDelay;
        uint256 _forexSupply = 0;
        // Initialise participants mapping.
        for (uint256 i = 0; i < length; i++) {
            participants[participantAddresses[i]] = Participant({
                claimable: initiallyClaimable[i],
                vestedValue: vestedValues[i],
                lastClaimDate: 0
            });
            _forexSupply += initiallyClaimable[i] + vestedValues[i];
        }
        forexSupply = _forexSupply;
    }

    /**
     * @dev Transfers claimable FOREX to participant.
     */
    function claim() external {
        require(isClaimable(), "Funds not yet claimable");
        Participant storage participant = participants[msg.sender];
        require(
            block.timestamp >= participant.lastClaimDate + minimumClaimDelay,
            "Must wait before next claim"
        );
        uint256 cutoffTime = getLastCutoffTime(msg.sender);
        uint256 claimable = _balanceOf(msg.sender, cutoffTime);
        if (claimable == 0) return;
        // Reset vesting period for accruing new FOREX.
        // This starts at the claim date and then is incremented in
        // a value multiple of minimumClaimDelay.
        participant.lastClaimDate = cutoffTime;
        // Clear initial claimable amount if claiming for the first time.
        if (participant.claimable > 0) participant.claimable = 0;
        // Transfer tokens.
        IERC20(FOREX).safeTransfer(msg.sender, claimable);
    }

    /**
     * @dev Returns the last valid claim date for a participant.
     *      The difference between this value and the participant's
     *      last claim date is the actual claimable amount that
     *      can be transferred so that the minimum delay also enforces
     *      a minimum FOREX claim granularity.
     * @param account The participant account to fetch the cutoff time for.
     */
    function getLastCutoffTime(address account) public view returns (uint256) {
        Participant storage participant = participants[account];
        uint256 lastClaimDate = getParticipantLastClaimDate(participant);
        uint256 elapsed = block.timestamp - lastClaimDate;
        uint256 remainder = elapsed % minimumClaimDelay;
        if (elapsed > remainder) {
            // At least one cutoff time has passed.
            return lastClaimDate + elapsed - remainder;
        } else {
            // Next cutoff time not yet reached.
            return lastClaimDate;
        }
    }

    /**
     * @dev Returns the parsed last claim date for a participant.
     *      Instead of returning the default date of zero, it returns
     *      the claim start date.
     * @param participant The storage pointer to a participant.
     */
    function getParticipantLastClaimDate(Participant storage participant)
        private
        view
        returns (uint256)
    {
        return
            participant.lastClaimDate > claimStartDate
                ? participant.lastClaimDate
                : claimStartDate;
    }

    /**
     * @dev Returns the accrued FOREX balance for an participant.
     *      This amount may not be fully claimable yet.
     * @param account The participant to fetch the balance for.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf(account, block.timestamp);
    }

    /**
     * @dev Returns the claimable FOREX balance for an participant.
     * @param account The participant to fetch the balance for.
     * @param cutoffTime The time to fetch the balance from.
     */
    function _balanceOf(address account, uint256 cutoffTime)
        public
        view
        returns (uint256)
    {
        if (!isClaimable()) return 0;
        Participant storage participant = participants[account];
        uint256 lastClaimed = getParticipantLastClaimDate(participant);
        uint256 vestingCompleteDate = claimStartDate + vestingPeriod;
        // Prevent elapsed from passing the vestingPeriod value.
        uint256 elapsed = cutoffTime > vestingCompleteDate
            ? vestingCompleteDate - lastClaimed
            : cutoffTime - lastClaimed;
        uint256 accrued = (participant.vestedValue * elapsed) / vestingPeriod;
        return participant.claimable + accrued;
    }

    /**
     * @dev Withdraws FOREX for the contract owner.
     * @param amount The amount of FOREX to withdraw.
     */
    function withdrawForex(uint256 amount) external onlyOwner {
        IERC20(FOREX).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Changes the address for a participant. The new address
     *      will be eligible to claim the currently claimable funds
     *      from the previous address, plus all the accrued funds
     *      until the end of the vesting period.
     * @param previous The previous participant address to be changed.
     * @param current The current participant address to be eligible for claims.
     */
    function changeParticipantAddress(address previous, address current)
        external
        onlyOwner
    {
        require(current != address(0), "Current address cannot be zero");
        require(previous != current, "Addresses are the same");
        Participant storage previousParticipant = participants[previous];
        require(
            doesParticipantExist(previousParticipant),
            "Previous participant does not exist"
        );
        Participant storage currentParticipant = participants[current];
        require(
            !doesParticipantExist(currentParticipant),
            "Next participant already exists"
        );
        currentParticipant.claimable = previousParticipant.claimable;
        currentParticipant.vestedValue = previousParticipant.vestedValue;
        currentParticipant.lastClaimDate = previousParticipant.lastClaimDate;
        delete participants[previous];
        emit ParticipantAddressChanged(previous, current);
    }

    /**
     * @dev Returns whether the participant exists.
     * @param participant Pointer to the participant object.
     */
    function doesParticipantExist(Participant storage participant)
        private
        view
        returns (bool)
    {
        return participant.claimable > 0 || participant.vestedValue > 0;
    }

    /**
     * @dev Enables FOREX claiming from the next block.
     *      Can only be called once.
     */
    function enableForexClaims() public onlyOwner {
        assert(claimStartDate == 0);
        claimStartDate = block.timestamp + 1;
    }

    /**
     * Returns whether the contract is currently claimable.
     */
    function isClaimable() private view returns (bool) {
        return claimStartDate != 0 && block.timestamp >= claimStartDate;
    }
}