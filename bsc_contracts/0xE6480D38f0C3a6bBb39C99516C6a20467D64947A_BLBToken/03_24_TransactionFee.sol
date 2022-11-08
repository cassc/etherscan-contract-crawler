// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Administration.sol";

/**
 * @title deduct the transaction fee of every token transfer and send it to a third address.
 */
abstract contract TransactionFee is ERC20, Administration {


    uint256 feeFraction; // numerator of transaction fee which denominator is 1,000,000
    uint256 feeAmount;   // independent transaction fee for every token transfer
    address feeReceiver; // address of the fee receiver

    /**
     * @dev emits when the admin sets a new transaction fee plan.
     */
    event SetTransactionFee(
        uint256 _feeAmount,
        uint256 _feeFraction, 
        address _feeReceiver
    );

    /**
     * @notice set amount or fraction and receiver of BLB transaction fees.
     *
     * @notice if transaction receiver is zero address, the transaction fee will be burned.
     *
     * @notice requirement:
     *  - Only the owner of the contract can call this function.
     *  - one of the feeAmount or feeFraction must be zero.
     *  - fee fraction can be a maximum of 50,000 which equals 10% of the transactions
     * 
     * @dev emits a SetTransactionFee event
     */
    function setTransactionFee(
        uint256 _feeAmount,
        uint256 _feeFraction, 
        address _feeReceiver
    ) public onlyRole(TRANSACTION_FEE_SETTER) {
        require(
            _feeFraction == 0 || _feeAmount == 0,
            "TransactionFee: Cannot set feeAmount and feeFraction at the same time"
        );
        require(
            _feeFraction <= 10 ** 5, 
            "TransactionFee: Up to 10% transactionFee can be set"
        );
        feeAmount = _feeAmount;
        feeFraction = _feeFraction;
        feeReceiver = _feeReceiver;

        emit SetTransactionFee(_feeAmount, _feeFraction, _feeReceiver);
    }

    /**
     * @return feeAmount numerator of transaction fee which denominator is 1,000,000.
     * @return feeFraction independent transaction fee for every token transfer.
     * @return feeReceiver address of the fee receiver.
     */
    function feeDetails() public view returns(uint256, uint256, address) {
        return (feeAmount, feeFraction, feeReceiver);
    }

    /**
     * @return fee corresponding to the transferring amount for every transaction.
     * @notice if there is a fee amount, the transaction fee is not proportional to the
     *  transfering amount.
     */
    function transactionFee(uint256 transferingAmount) public view returns(uint256 fee) {
        if(feeAmount > 0)
            fee = feeAmount;
        else if( feeFraction > 0)
            fee = transferingAmount * feeFraction / 10 ** 6;
    }

    /**
     * @notice deducts the transaction fee from the caller.
     * @notice it will be not deducted if the caller has the minter role.
     * @notice the transaction fee is sent to the fee receiver.
     * @notice if the fee receiver is zero address, fee tokens are burned.
     */
    function _payTransactionFee(address caller, uint256 amount) internal {
        if(!hasRole(MINTER_ROLE, caller)) {
            if(feeFraction > 0 || feeAmount > 0) {
                uint256 _transactionFee = transactionFee(amount);
                _pureTransfer(caller, feeReceiver, _transactionFee);
            }
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        _payTransactionFee(_msgSender(), amount);

        super._beforeTokenTransfer(from, to, amount);
    }
}