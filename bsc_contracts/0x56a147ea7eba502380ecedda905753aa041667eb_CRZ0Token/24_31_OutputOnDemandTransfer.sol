// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../base/BaseOfferToken.sol";
import "hardhat/console.sol";

contract OutputOnDemandTransfer is BaseOfferSale {
    // Use safe math for add and sub
    using SafeMath for uint256;

    // Create a structure to save our payments
    struct Payment {
        // The total amount the user bought in tokens
        uint256 totalAmount;
        // The total amount the user has received in tokens
        uint256 totalPaid;
    }

    // A reference to the token were selling
    BaseOfferToken private baseToken;
    
    // A map of address to payment
    mapping(address => Payment) private mapPayments;

    // A reference to the emitter of the offer
    address private aEmitter;

    /**
     * @dev Investment with ERC20 token
     */
    constructor(address _emitter, address _tokenAddress)
        public
        BaseOfferSale()
    {
        aEmitter = _emitter;
        baseToken = BaseOfferToken(_tokenAddress);
    }

    function _initialize() internal override {
        require(_msgSender() == address(baseToken), "Only call from token");
    }

    function _investOutput(address _investor, uint256 nOutputAmount)
        internal
        virtual
        override
    {
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));

        // calculate how many tokens we can sell
        uint256 nRemainingBalance = nBalance.sub(nTotalSold);

        // make sure we're not selling more than we have
        require(
            nOutputAmount <= nRemainingBalance,
            "Offer does not have enough tokens to sell"
        );

        // read the payment data from our map
        Payment memory payment = mapPayments[_investor];

        // increase the amount of tokens this investor has purchased
        payment.totalAmount = payment.totalAmount.add(nOutputAmount);

        mapPayments[_investor] = payment;
    }

    function _finishSale() internal virtual override {
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));

        if (getSuccess()) {
            // calculate how many tokens we have not sold
            uint256 nRemainingBalance = nBalance.sub(nTotalSold);

            // return remaining tokens to owner
            baseToken.transfer(aEmitter, nRemainingBalance);
        } else {
            // return all tokens to owner
            baseToken.transfer(aEmitter, nBalance);
        }
    }

    function cashoutTokens(address _investor) external override returns (bool) {
        require(_msgSender() == address(baseToken), "Call only from token");

        // wait till the offer is successful to allow transfer
        if (!bSuccess) {
            return false;
        }

        // read the token sale data for that address
        Payment storage payment = mapPayments[_investor];

        // nothing to be paid
        if (payment.totalAmount == 0) {
            return false;
        }

        // calculate the remaining tokens
        uint256 nRemaining = payment.totalAmount.sub(payment.totalPaid);

        // make sure there's something to be paid
        if (nRemaining == 0) {
            return false;
        }

        // transfer to requested user
        baseToken.transfer(_investor, nRemaining);

        // mark that we paid the user in fully
        payment.totalPaid = payment.totalAmount;

        return true;
    }

    function getTotalBought(address _investor)
        public
        view
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalAmount;
    }

    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalPaid;
    }

    function getToken() public view returns (address token) {
        return address(baseToken);
    }
}