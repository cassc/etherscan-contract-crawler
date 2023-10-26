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
import "../interfaces/IhPAL.sol";
import {Errors} from  "../utils/Errors.sol";



/** @title PalPoolhPal contract  */
/// @author Paladin
contract PalPoolhPal is PalPool {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT256 = type(uint256).max;

    /** @dev hPAL token address */
    address private immutable hPalAddress;
    /** @dev PAL token address */
    address private immutable palAddress;
    /** @dev Block number of the last reward claim */
    uint public claimBlockNumber = 0;


    constructor( 
        address _palToken,
        address _controller, 
        address _underlying,
        address _interestModule,
        address _delegator,
        address _palLoanToken,
        address _palAddress
    ) PalPool(
            _palToken, 
            _controller,
            _underlying,
            _interestModule,
            _delegator,
            _palLoanToken
        )
    {
        hPalAddress = _underlying;
        palAddress = _palAddress;

        // Max Approve for hPAL
        IERC20(_palAddress).safeIncreaseAllowance(_underlying, MAX_UINT256);
    }


    /**
    * @notice Claim PAL tokens from hPAL and stake them back in hPAL
    * @dev Claim PAL tokens from hPAL and stake them back in hPAL
    * @return bool : Success
    */
    function claimPal() public returns(bool) {
        if(block.number == claimBlockNumber) return true;

        //Load contracts
        IERC20 _pal = IERC20(palAddress);
        IhPAL _hpal = IhPAL(hPalAddress);

        //Claim all available rewards from hPAL
        _hpal.claim(MAX_UINT256);

        //Check the current balance in PAL of this contract
        uint256 _currentPalBalance = _pal.balanceOf(address(this));

        //If the contract holds PAL, stake them into hPAL
        if(_currentPalBalance > 0){

            //Stake them
            _hpal.stake(_currentPalBalance);

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
        require(claimPal());
        return super.deposit(_amount);
    }

    /**
    * @notice Withdraw underliyng token from the Pool
    * @dev Transfer underlying token to the user, and burn the corresponding palToken amount
    * @param _amount Amount of palToken to return
    * @return uint : amount of underlying returned
    */
    function withdraw(uint _amount) public override(PalPool) returns(uint){
        require(claimPal());
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
        require(claimPal());
        return super.borrow(_delegatee, _amount, _feeAmount);
    }

    /**
    * @notice Transfer the new fees to the Loan, and expand the Loan
    * @param _loan Address of the Loan
    * @param _feeAmount New amount of fees to pay
    * @return bool : Amount of fees paid
    */
    function expandBorrow(address _loan, uint _feeAmount) public override(PalPool) returns(uint){
        require(claimPal());
        return super.expandBorrow(_loan, _feeAmount);
    }

    /**
    * @notice Close a Loan, and return the non-used fees to the Borrower.
    * If closed before the minimum required length, penalty fees are taken to the non-used fees
    * @dev Close a Loan, and return the non-used fees to the Borrower
    * @param _loan Address of the Loan
    */
    function closeBorrow(address _loan) public override(PalPool) {
        require(claimPal());
        super.closeBorrow(_loan);
    }

    /**
    * @notice Kill a non-healthy Loan to collect rewards
    * @dev Kill a non-healthy Loan to collect rewards
    * @param _loan Address of the Loan
    */
    function killBorrow(address _loan) public override(PalPool) {
        require(claimPal());
        super.killBorrow(_loan);
    }


    function changeBorrowDelegatee(address _loan, address _newDelegatee) public override(PalPool) {
        require(claimPal());
        super.changeBorrowDelegatee(_loan, _newDelegatee);
    }
}