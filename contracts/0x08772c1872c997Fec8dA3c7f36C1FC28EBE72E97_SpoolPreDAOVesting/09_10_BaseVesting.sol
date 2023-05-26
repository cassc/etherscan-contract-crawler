// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../external/spool-core/SpoolOwnable.sol";
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/vesting/IBaseVesting.sol";

/**
 * @notice Implementation of the {IBaseVesting} interface.
 *
 * @dev This contract is inherited by the other *Vesting.sol contracts in this folder.
 *      It implements common functions for all of them.
 */
contract BaseVesting is SpoolOwnable, IBaseVesting {
    /* ========== LIBRARIES ========== */

    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice the length of time (in seconds) the vesting is to last for.
    uint256 public immutable vestingDuration;

    /// @notice SPOOL token contract address, the token that is being vested.
    IERC20 public immutable spoolToken;

    /// @notice timestamp of vesting start
    uint256 public start;

    /// @notice timestamp of vesting end
    uint256 public end;

    /// @notice total amount of SPOOL token vested
    uint256 public override total;

    /// @notice map of member to Vest struct (see IBaseVesting)
    mapping(address => Vest) public userVest;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice sets the contracts initial values
     *
     * @dev 
     *
     *  Requirements:
     *  - _spoolToken must not be the zero address
     *
     * @param spoolOwnable the spool owner contract that owns this contract
     * @param _spoolToken SPOOL token contract address, the token that is being vested.
     * @param _vestingDuration the length of time (in seconds) the vesting is to last for.
     */
    constructor(ISpoolOwner spoolOwnable, IERC20 _spoolToken, uint256 _vestingDuration) SpoolOwnable(spoolOwnable) {
        require(_spoolToken != IERC20(address(0)), "BaseVesting::constructor: Incorrect Token");

        spoolToken = _spoolToken;
        vestingDuration = _vestingDuration;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the amount a user can claim at a given point in time.
     *
     * @dev
     *
     * Requirements:
     * - the vesting period has started
     */
    function getClaim()
        external
        view
        hasStarted(true)
        returns (uint256 vestedAmount)
    {
        Vest memory vest = userVest[msg.sender];
        return _getClaim(vest.amount, vest.lastClaim);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Allows a user to claim their pending vesting amount.
     *
     * @dev
     *
     * Requirements:
     *
     * - the vesting period has started
     * - the caller must have a non-zero vested amount
     */
    function claim() external hasStarted(true) returns(uint256 vestedAmount) {
        Vest memory vest = userVest[msg.sender];
        vestedAmount = _getClaim(vest.amount, vest.lastClaim);
        require(vestedAmount != 0, "BaseVesting::claim: Nothing to claim");
        _claim(msg.sender, vestedAmount, vest);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Allows the vesting period to be initiated.
     *
     * @dev  the storage variable "total" contains the total amount of the SPOOL token that is being vested.
     * this is transferred from the SPOOL owner here.
     * 
     * Emits a {VestingInitialized} event from which the start and
     * end can be calculated via it's attached timestamp.
     * 
     * Requirements:
     *
     * - the caller must be the owner
     * - owner has given allowance for "total" to this contract
     */
    function begin() external override onlyOwner hasStarted(false) {
        spoolToken.safeTransferFrom(msg.sender, address(this), total);

        start = block.timestamp;
        end = block.timestamp + vestingDuration;

        emit VestingInitialized(vestingDuration);
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another
     *
     * @dev It allows for transfer of vest to any other address. However, in the case that the receiving address has any vested
     * amount, it first checks for that, and if so, claims on behalf of that user, sending them any pending vested amount.
     * This has to be done to ensure the vesting is fairly distributed.
     *
     * Emits a {Transferred} event indicating the members who were involved in the transfer
     * as well as the amount that was transferred.
     *
     * Requirements:
     * - the vesting period has started
     * - specified transferAmount is not more than the previous member's vested amount
     * 
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function transferVest(Member calldata members, uint256 transferAmount)
        external
        onlyOwner 
        hasStarted(true)
    {
        uint256 prevAmount = uint256(userVest[members.prev].amount);
        require(transferAmount <= prevAmount && transferAmount > 0, "BaseVesting::transferVest: invalid amount specified for transferring vest");

        /** 
         * NOTE 
         * We check if the member has any pending vest amount. 
         * if so: call claim with their address
         * if not: update lastClaim (otherwise, is done inside _claim)
         */
        Vest memory newVest = userVest[members.next];
        uint vestedAmount = _getClaim(newVest.amount, newVest.lastClaim);
        if(vestedAmount != 0) {
            _claim(members.next, vestedAmount, newVest);            
        } else {
            userVest[members.next].lastClaim = uint64(block.timestamp);
        }

        _transferVest(members, transferAmount);

        emit Transferred(members, transferAmount);  
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows a user to claim their pending vesting amount (internal function)
     *
     * @dev Only accessible via the external "claim" function (in which case, msg.sender is used) or the transferVest function,
     * which is only callable by the SPOOL owner
     *
     * Emits a {Vested} event indicating the user who claimed their vested tokens
     * as well as the amount that was vested.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claim(address member, uint256 vestedAmount, Vest memory vest) internal {

        _claimVest(member, vestedAmount, vest);

        emit Vested(member, vestedAmount);

        spoolToken.safeTransfer(member, vestedAmount);

    }

    /**
     * @notice allows owner to set the vesting members and amounts (internal function)
     *
     * @dev Only accessible via the external setVests function located in the inheriting vesting contract.
     *
     * Requirements:
     *
     * - vesting must not already have started
     * - input member and amount arrays must be the same size
     * - values in amounts array must be greater than 0
     *
     * @param members array of addresses to set vesting for
     * @param amounts array of SPOOL token vesting amounts to to be set for each address
     */
    function _setVests(address[] memory members, uint192[] memory amounts)
        internal
        hasStarted(false)
    {
        require(
            members.length == amounts.length,
            "BaseVesting::_setVests: Incorrect Arguments"
        );

        for(uint i = 0; i < members.length; i++){
            for(uint j = (i+1); j < members.length; j++) {
                require(members[i] != members[j], "BaseVesting::_setVests: Members Not Unique");
            }
        }

        int192 totalDiff;
        for (uint i = 0; i < members.length; i++) {
            totalDiff += _setVest(members[i], amounts[i]);
        }

        // if the difference from the previous totals for these members is less than zero, subtract from total.
        if(totalDiff < 0) {
            total -= abs(totalDiff);
        } else {
            total += abs(totalDiff);
        }
    }

    /**
     * @notice allows owner to set the vesting amount for a member (internal function)
     *
     * @dev Only accessible via the internal _setVests function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * Requirements:
     *
     * - amount must be less than uint192 max (the maximum value that can be stored for amount)
     *
     * @param user the user to set vesting for
     * @param amount the SPOOL token vesting amount to be set for this user
     *
     */
    function _setVest(address user, uint192 amount)
        internal
        virtual
        returns (int192 diff)
    {
        diff = int192(amount) - int192(userVest[user].amount);
        userVest[user].amount = amount;
    }

    /**
     * @notice Allows a user to claim their pending vesting amount (internal, virtual function)
     *
     * @dev Only accessible via the internal _claimVest function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claimVest(address member, uint256 vestedAmount, Vest memory vest)
        internal
        virtual
    {
        vest.amount -= uint192(vestedAmount);
        vest.lastClaim = uint64(block.timestamp);

        userVest[member] = vest;
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another (internal, virtual function)
     *
     * @dev Only accessible via the transferVest function.
     * This is a virtual function, it can be overriden by the inheriting vesting contracts.
     *
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function _transferVest(Member memory members, uint256 transferAmount) 
        internal 
        virtual
    {
        userVest[members.prev].amount -= uint192(transferAmount);
        userVest[members.next].amount += uint192(transferAmount); 
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Calculates the amount a user's vest is due. 
     * 
     * @dev
     * To calculate, the following formula is utilized:
     *
     * - (remainingAmount * timeElapsed) / timeUntilEnd
     *
     * Each variable is described as follows:
     *
     * - remainingAmount (amount): Vesting amount remaining. Each claim subtracts from
     * this amount to ensure calculations are properly conducted.
     *
     * - timeElapsed (block.timestamp.sub(lastClaim)): Time that has elapsed since the
     * last claim.
     *
     * - timeUntilEnd (end.sub(lastClaim)): Time remaining for the particular vesting
     * member's total duration.
     *
     * Vesting calculations are relative and always update the last
     * claim timestamp as well as remaining amount whenever they
     * are claimed.
     * 
     * @param amount SPOOL token amount to claim
     * @param lastClaim timestamp of the last time the user claimed
     */
    function _getClaim(uint256 amount, uint256 lastClaim)
        private
        view
        returns (uint256)
    {
        uint256 _end = end;

        if (block.timestamp >= _end) return amount;
        if (lastClaim == 0) lastClaim = start;

        return (amount * (block.timestamp - lastClaim)) / (_end - lastClaim);
    }

    /** @notice check if the vesting has or has not started
     * 
     * @dev uses the "start" storage variable to check if the vesting has started or not (ie. if begin() has been successfully called)
     *
     * @param check boolean to validate if the vesting has or has not started
     */
    function _checkStarted(bool check) private view {                                  
        require(
            check ? start != 0 
                   : start == 0,
            check ? "BaseVesting::_checkStarted: Vesting hasn't started yet" 
                   : "BaseVesting::_checkStarted: Vesting has already started"
        );
    }

    /* ========== HELPERS ========== */
    
    /** 
     * @notice get absolute value of an int192 value
     *
     * @param a signed integer to get absolute value of
     *
     * @return absolute value of input
     */
    function abs(int192 a) internal pure returns (uint192) {
        return uint192(a < 0 ? -a : a);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice hasStarted modifier
     *
     * @dev 
     * 
     * calls _checkStarted private function and continues execution
     *
     * @param check boolean to validate if the vesting has or has not started
     */
    modifier hasStarted(bool check) {
        _checkStarted(check);
        _;
    }
}