// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../base/IOffer.sol";
import "../../LiqiBRLToken.sol";
import "../../base/BaseOfferToken.sol";

contract CRZ0Offer is Ownable, IOffer {
    // R$15,00
    uint256 public constant RATE_PHASE_1 = 1750;
    // R$16,00
    uint256 public constant RATE_PHASE_2 = 1875;
    // R$17,50
    uint256 public constant RATE_PHASE_3 = 2000;
    // R$18,75
    uint256 public constant RATE_PHASE_4 = 2125;
    // Minimum of 72000 to sell
    uint256 public constant MIN_TOTAL_TOKEN_SOLD = 79200 * 1 ether;
    // Total amount of tokens to be sold
    uint256 public constant TOTAL_TOKENS = 316800 * 1 ether;
    // Total amount to sell to end rate 1
    uint256 public constant RATE_AMOUNT_PHASE_1 = 79200 * 1 ether;
    // Total amount to sell to end rate 2
    uint256 public constant RATE_AMOUNT_PHASE_2 = 158400 * 1 ether;
    // Total amount to sell to end rate 3
    uint256 public constant RATE_AMOUNT_PHASE_3 = 237600 * 1 ether;

    // If the offer has been initialized by the owner
    bool private bInitialized;
    // If the success condition has been met
    bool private bSuccess;
    // If the offer has finished the sale of tokens
    bool private bFinished;

    // A counter of the total amount of tokens sold
    uint256 internal nTotalSold;

    // The date the offer finishSale function was called
    uint256 internal nFinishDate;

    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;
    // A reference to the emitter of the offer
    address private aEmitter;
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

    constructor(
        address _emitter,
        address _brlTokenContract,
        address _tokenAddress
    ) public {
        aEmitter = _emitter;
        brlToken = LiqiBRLToken(_brlTokenContract);
        baseToken = BaseOfferToken(_tokenAddress);
    }

    /*
     * @dev Initializes the sale
     */
    function initialize() public override {
        require(_msgSender() == address(baseToken), "Only call from token");

        require(!bInitialized, "Sale is initialized");

        bInitialized = true;
    }

    function cashoutBRLT() public {
        // no unsuccessful sale
        require(bSuccess, "Sale is not successful");
        // check the balance of tokens of this contract
        uint256 nBalance = brlToken.balanceOf(address(this));
        // nothing to execute if the balance is 0
        require(nBalance != 0, "Balance to cashout is 0");
        // transfer all tokens to the emitter account
        brlToken.transfer(aEmitter, nBalance);
    }

    function getTokenAddress() public view returns (address) {
        return address(brlToken);
    }

    function getToken() public view returns (address token) {
        return address(baseToken);
    }

    /*
     * @dev Declare an investment for an address
     */
    function invest(address _investor, uint256 _amount) public onlyOwner {
        // make sure the investor is not an empty address
        require(_investor != address(0), "Investor is empty");
        // make sure the amount is not zero
        require(_amount != 0, "Amount is zero");
        // do not sell if sale is finished
        require(!bFinished, "Sale is finished");
        // do not sell if not initialized
        require(bInitialized, "Sale is not initialized");

        // process input data
        // call with same args
        brlToken.invest(_investor, _amount);
        // convert input currency to output
        // - get rate from module
        uint256 nRate = getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nRate);

        // pass to module to handling outputs
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

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // and check if the sale is sucessful after this sale
        if (!bSuccess) {
            if (nTotalSold >= MIN_TOTAL_TOKEN_SOLD) {
                // we have sold more than minimum, success
                bSuccess = true;
            }
        }
    }

    /*
     * @dev Marks the offer as finished
     */
    function finishSale() public onlyOwner {
        require(!bFinished, "Sale is finished");
        bFinished = true;

        if (!getSuccess()) {
            // notify the BRLT
            brlToken.failedSale();
        }
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

    /*
     * @dev Cashouts tokens for a specified user
     */
    function cashoutTokens(address _investor)
        external
        virtual
        override
        returns (bool)
    {
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

    /*
     * @dev Returns the current rate for the token
     */
    function getRate() public view virtual returns (uint256 rate) {
        if (nTotalSold >= RATE_AMOUNT_PHASE_3) {
            return RATE_PHASE_4;
        } else if (nTotalSold >= RATE_AMOUNT_PHASE_2) {
            return RATE_PHASE_3;
        } else if (nTotalSold >= RATE_AMOUNT_PHASE_1) {
            return RATE_PHASE_2;
        } else {
            return RATE_PHASE_1;
        }
    }

    /*
     * @dev Gets how much the specified user has bought from this offer
     */
    function getTotalBought(address _investor)
        public
        view
        override
        returns (uint256 nTotalBought)
    {
        return mapPayments[_investor].totalAmount;
    }

    /*
     * @dev Get total amount the user has cashed out from this offer
     */
    function getTotalCashedOut(address _investor)
        public
        view
        override
        returns (uint256 nTotalCashedOut)
    {
        return mapPayments[_investor].totalPaid;
    }

    /*
     * @dev Returns true if the sale is initialized
     */
    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    /*
     * @dev Returns true if the sale is finished
     */
    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    /*
     * @dev Returns true if the sale is successful
     */
    function getSuccess() public view override returns (bool) {
        return bSuccess;
    }

    /*
     * @dev Gets the total amount of tokens sold
     */
    function getTotalSold() public view virtual returns (uint256 totalSold) {
        return nTotalSold;
    }

    /*
     * @dev Gets the date the offer finished at
     */
    function getFinishDate() external view override returns (uint256) {
        return nFinishDate;
    }
}