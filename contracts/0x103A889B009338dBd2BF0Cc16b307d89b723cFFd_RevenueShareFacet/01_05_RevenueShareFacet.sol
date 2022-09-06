// SPDX-License-Identifier: MIT
/// Adapted from OpenZepplin's PaymentSplitter contract https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol
pragma solidity 0.8.13;

import '@openzeppelin/contracts/utils/Address.sol';
import { LibDiamond } from "../../shared/libraries/LibDiamond.sol";
import { AppStorage, Modifiers} from "../libraries/LibAppStorage.sol";

error AccountAlreadyHasShares();
error AccountHasNoShares();
error AccountNotDuePayment();
error PayeesArrayEmpty();
error ParamArrayLengthsDoNotMatch();
error SharesMustBeMoreThanZero();
error ZeroAddress();

contract RevenueShareFacet is Modifiers {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);

    /// Add payee addresses with shares
    function addPayees(address[] memory payees, uint256[] memory revenueShares) external onlyEditor{
        if (payees.length <= 0)
            revert PayeesArrayEmpty();
        if(payees.length != revenueShares.length)
            revert ParamArrayLengthsDoNotMatch();

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], revenueShares[i]);
        }
    }

    /// Edit a payee in case of wallet corruption
    function editPayee(address oldAddress, address newAddress) external onlyEditor {
        s._shares[newAddress] = s._shares[oldAddress];
        delete s._shares[oldAddress];
    }

    /// Withdraw revenue to the contract owner's address only if there is extra 
    /// after funds have been released
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(LibDiamond.contractOwner()), balance);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) external virtual {
        if(s._shares[account] <= 0)
            revert AccountHasNoShares();

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        if(payment <= 0)
            revert AccountNotDuePayment();

        s._released[account] += payment;
        s._totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256) {
        if(s._shares[account] <= 0)
            revert AccountHasNoShares();
        return s._shares[account];
    } 

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return s._released[account];
    }

     /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return s._totalReleased;
    }  

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return s._totalShares;
    }

    /**
     * @dev Add a new payee to the contract.
     */
    function _addPayee(address account, uint256 revenueShares) private {
        if(account <= address(0))
            revert ZeroAddress();
        if(revenueShares <= 0)
            revert SharesMustBeMoreThanZero();
        if(s._shares[account] > 0)
            revert AccountAlreadyHasShares();
            
        s._shares[account] = revenueShares;
        s._totalShares = s._totalShares + revenueShares;
        emit PayeeAdded(account, revenueShares);   
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * s._shares[account]) / s._totalShares - alreadyReleased;
    }
}