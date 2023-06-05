//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "../PalPool.sol";
import "../utils/SafeMath.sol";
import "../utils/SafeERC20.sol";
import "../utils/IERC20.sol";
import "../tokens/AAVE/IStakedAave.sol";
import {Errors} from  "../utils/Errors.sol";



/** @title PalPoolStkAave Pool contract  */
/// @author Paladin
contract PalPoolStkAave is PalPool {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /** @dev stkAAVE token address */
    address private immutable stkAaveAddress;
    /** @dev AAVE token address */
    address private immutable aaveAddress;
    /** @dev Block number of the last reward claim */
    uint public claimBlockNumber = 0;


    constructor( 
        address _palToken,
        address _controller, 
        address _underlying,
        address _interestModule,
        address _delegator,
        address _palLoanToken,
        address _aaveAddress
    ) PalPool(
            _palToken, 
            _controller,
            _underlying,
            _interestModule,
            _delegator,
            _palLoanToken
        )
    {
        stkAaveAddress = _underlying;
        aaveAddress = _aaveAddress;
    }


    /**
    * @dev Claim AAVE tokens from the AAVE Safety Module and stake them back in the Module
    * @return bool : Success
    */
    function claimFromAave() internal returns(bool) {
        //Load contracts
        IERC20 _aave = IERC20(aaveAddress);
        IStakedAave _stkAave = IStakedAave(stkAaveAddress);

        //Get pending rewards amount
        uint _pendingRewards = _stkAave.getTotalRewardsBalance(address(this));

        //If there is reward to claim
        if(_pendingRewards > 0 && claimBlockNumber != block.number){

            //claim the AAVE tokens
            _stkAave.claimRewards(address(this), _pendingRewards);

            //Stake the AAVE tokens to get stkAAVE tokens
            uint _toStakeAmount = _aave.balanceOf(address(this));
            _aave.safeApprove(stkAaveAddress, _toStakeAmount);
            _stkAave.stake(address(this), _toStakeAmount);

            //update the block number
            claimBlockNumber = block.number;

            return true;
        }
        return true;
    }


    /**
    * @notice Deposit underlying in the Pool
    * @dev Deposit underlying, and mints palToken for the user
    * @param _amount Amount of underlying to deposit
    * @return bool : amount of minted palTokens
    */
    function deposit(uint _amount) public override(PalPool) returns(uint){
        require(claimFromAave());
        return super.deposit(_amount);
    }

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding palToken amount
    * @param _amount Amount of palToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint _amount) public override(PalPool) returns(uint){
        require(claimFromAave());
        return super.withdraw(_amount);
    }

    /**
    * @dev Create a Borrow, deploy a Loan Pool and delegate voting power
    * @param _delegatee Address to delegate the voting power to
    * @param _amount Amount of underlying to borrow
    * @param _feeAmount Amount of fee to pay to start the loan
    * @return uint : amount of paid fees
    */
    function borrow(address _delegatee, uint _amount, uint _feeAmount) public override(PalPool) returns(uint){
        require(claimFromAave());
        return super.borrow(_delegatee, _amount, _feeAmount);
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param _loan Address of the Loan
    * @param _feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address _loan, uint _feeAmount) public override(PalPool) returns(uint){
        require(claimFromAave());
        return super.expandBorrow(_loan, _feeAmount);
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower.
    * If closed before the minimum required length, penalty fees are taken to the non-used fees
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param _loan Address of the Loan
    */
    function closeBorrow(address _loan) public override(PalPool) {
        require(claimFromAave());
        super.closeBorrow(_loan);
    }

    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @dev Kill a non-healthy Loan to collect rewards
    * @param _loan Address of the Loan
    */
    function killBorrow(address _loan) public override(PalPool) {
        require(claimFromAave());
        super.killBorrow(_loan);
    }


    function changeBorrowDelegatee(address _loan, address _newDelegatee) public override(PalPool) {
        require(claimFromAave());
        super.changeBorrowDelegatee(_loan, _newDelegatee);
    }
}