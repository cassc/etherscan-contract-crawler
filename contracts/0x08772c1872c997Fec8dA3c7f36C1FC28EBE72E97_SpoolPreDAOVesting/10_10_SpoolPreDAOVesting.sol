// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BaseVesting.sol";

import "../interfaces/vesting/ISpoolPreDAOVesting.sol";

/**
 * @notice Implementation of the {ISpoolPreDAOVesting} interface.
 *
 * @dev This contract inherits BaseVesting, this is where most of the functionality is located.
 *      It overrides some functions where necessary.
 */
contract SpoolPreDAOVesting is BaseVesting, ISpoolPreDAOVesting {
    IERC20Mintable public immutable voSPOOL;

    /**
     * @notice sets the contracts initial values
     *
     * @param spoolOwnable the spool owner contract that owns this contract
     * @param _voSPOOL Voting SPOOL token contract
     * @param _spool SPOOL token contract address, the token that is being vested.
     * @param _vestingDuration the length of time (in seconds) the vesting is to last for.
     */
    constructor(ISpoolOwner spoolOwnable, IERC20Mintable _voSPOOL, IERC20 _spool, uint256 _vestingDuration)        
        BaseVesting(spoolOwnable, _spool, _vestingDuration)
    {
        voSPOOL = _voSPOOL;
    }

    /**
     * @notice Allows vests to be set. 
     *
     * @dev
     * internally calls _setVests function on BaseVesting.                        
     *                                                                            
     * Can be called an arbitrary number of times before `begin()` is called 
     * on the base contract.                                               
     * 
     * Requirements:
     *
     * - the caller must be the owner
     *
     * @param members array of addresses to set vesting for
     * @param amounts array of SPOOL token vesting amounts to to be set for each address
     */
    function setVests(
        address[] calldata members,
        uint192[] calldata amounts
    ) external onlyOwner {

        _setVests(members, amounts);
    }

    /**
     * @notice allows owner to set the vesting amount for a member (internal, override function)
     *
     * @dev overrides BaseVesting _setVest function. mints "amount" voting SPOOL tokens to user 
     * before calling _setVest in BaseVesting.
     *
     * If user has a previous vest amount set, we need to burn that amount of voSPOOL also. Then 
     * the current vest amount is minted in voSPOOL.
     *
     * @param user the user to set vesting for
     * @param amount the SPOOL token vesting amount to be set for this user
     *
     */
    function _setVest(address user, uint192 amount)
        internal
        override
        returns (int192)
    {
        uint192 previousAmount = userVest[user].amount;
        if(previousAmount > 0) 
        { 
            voSPOOL.burn(user, previousAmount);
        }
        voSPOOL.mint(user, amount);
        return BaseVesting._setVest(user, amount);
    }

    /**
     * @notice Allows a user to claim their pending vesting amount (internal, override function)
     *
     * @dev overrides BaseVesting _claimVest function. burns "amount" voting SPOOL tokens from user 
     * before calling _claimVest in BaseVesting.
     *
     * @param member address to claim for
     * @param vestedAmount amount to claim
     * @param vest vesting info for "member"
     */
    function _claimVest(address member, uint256 vestedAmount, Vest memory vest)
        internal
        override
    {
        voSPOOL.burn(member, vestedAmount);
        BaseVesting._claimVest(member, vestedAmount, vest);
    }

    /**
     * @notice Allows owner to transfer all or part of a vest from one address to another (internal, override function)
     *
     * @dev 
     * overrides BaseVesting _transferVest function. burns "transferAmount" voting SPOOL tokens from previous user, 
     * mints same amount to next user, and calls  _transferVest in BaseVesting.
     *
     * @param members members list - "prev" for member to transfer from, "next" for member to transfer to
     * @param transferAmount amount of SPOOL token to transfer
     */
    function _transferVest(Member memory members, uint256 transferAmount) 
        internal 
        override
    {
        voSPOOL.burn(members.prev, transferAmount);
        voSPOOL.mint(members.next, transferAmount);
        BaseVesting._transferVest(members, transferAmount);
    }
}