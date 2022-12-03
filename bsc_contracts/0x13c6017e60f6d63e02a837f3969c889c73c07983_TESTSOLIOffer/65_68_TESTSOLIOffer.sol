// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../base/IOffer_v2.sol";
import "../../LiqiBRLToken.sol";
import "../../base/BaseOfferToken.sol";

/**
 * @dev TESTSOLIOffer
 */
contract TESTSOLIOffer is Ownable, IOffer {
    uint256 public constant TOKEN_BASE_RATE = 100;
    uint256 public constant MIN_TOTAL_TOKEN_SOLD = 1 * 1 ether;
    uint256 public constant TOTAL_TOKENS = 5 * 1 ether;
    address public constant OWNER = 0xe7463F674837F3035a4fBE15Da5D50F5cAC982f4;

    // If the offer has been initialized by the owner
    bool private bInitialized;
    // If the success condition has been met
    bool private bSuccess;
    // If the offer has finished the sale of tokens
    bool private bFinished;

    // A counter of the total amount of tokens sold
    uint256 internal nTotalSold;

    // The date the offer finishOffer function was called
    uint256 internal nFinishDate;

    // To save cashout date/amount so we can filter by date
    struct SubPayment {
        // The amount of tokens the user cashed out
        uint256 amount;
        // The date the user performed this cash out
        uint256 date;
    }

    // Create a structure to save our payments
    struct Payment {
        // The total amount the user bought
        uint256 totalInputAmount;
        // The total amount the user bought in tokens
        uint256 totalAmount;
        // The total amount the user has received in tokens
        uint256 totalPaid;
        // Dates the user cashed out from the offer
        SubPayment[] cashouts;
        // Payments
        SubPayment[] payments;
    }

    // A map of address to payment
    mapping(address => Payment) internal mapPayments;

    event OnInvest(address _investor, uint256 _amount);

    // SafeMath for all math operations
    using SafeMath for uint256;
    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;
    // A reference to the issuer of the offer
    address private aIssuer;
    // Total amount of BRLT tokens collected during sale
    uint256 internal nTotalCollected;
    // A reference to the token were selling
    BaseOfferToken private baseToken;
    // A counter for the total amount users have cashed out
    uint256 private nTotalCashedOut;

    constructor(
        address _issuer, 
        address _brlTokenContract, 
        address _tokenAddress
        )
        public
    {
        // save the issuer's address
        aIssuer = _issuer;
        // convert the BRLT's address to our interface
        brlToken = LiqiBRLToken(_brlTokenContract);
        // convert the token's address to our interface
        baseToken = BaseOfferToken(_tokenAddress);
    }

    /*
    * @dev Initializes the sale
    */
    function initialize() public override {
        require(!bInitialized, "Offer is already initialized");
        
        // for OutputOnDemand, only the token can call initialize
        require(_msgSender() == address(baseToken), "Only call from token");

        bInitialized = true;
    }   

    /**
* @dev Cashouts BRLTs paid to the offer to the issuer
* @notice Faz o cashout de todos os BRLTs que estão nesta oferta para o issuer, se a oferta já tiver sucesso.
*/
    function cashoutIssuerBRLT() public {
    	// no cashout if offer is not successful
    	require(bSuccess, "Offer is not successful");
    	// check the balance of tokens of this contract
    	uint256 nBalance = brlToken.balanceOf(address(this));
    	// nothing to execute if the balance is 0
    	require(nBalance != 0, "Balance to cashout is 0");
    	// transfer all tokens to the issuer account
    	brlToken.transfer(aIssuer, nBalance);
    }
    
    /**
* @dev Returns the address of the input token
* @notice Retorna o endereço do token de input (BRLT)
*/
    function getInputToken() public view returns (address) {
    	return address(brlToken);
    }
    
    /**
* @dev Returns the total amount of tokens invested
* @notice Retorna quanto total do token de input (BRLT) foi coletado
*/
    function getTotalCollected() public view returns (uint256) {
    	return nTotalCollected;
    }
    
    /**
* @dev Returns the total amount of tokens the specified
* investor has bought from this contract, up to the specified date
* @notice Retorna quanto o investidor comprou até a data especificada
*/
    function getTotalBoughtDate(address _investor, uint256 _date)
    	public
    	view
    	override
    	returns (uint256)
    {
    	Payment memory payment = mapPayments[_investor];
    	uint256 nTotal = 0;
    	for (uint256 i = 0; i < payment.payments.length; i++) {
    		SubPayment memory subPayment = payment.payments[i];
    		if (subPayment.date >= _date) {
    			break;
    		}
    		nTotal = nTotal.add(subPayment.amount);
    	}
    	return nTotal;
    }
    
    /**
* @dev Returns the total amount of tokens the specified investor
* has cashed out from this contract, up to the specified date
* @notice Retorna quanto o investidor sacou até a data especificada
*/
    function getTotalCashedOutDate(address _investor, uint256 _date)
    	external
    	view
    	virtual
    	override
    	returns (uint256)
    {
    	Payment memory payment = mapPayments[_investor];
    	uint256 nTotal = 0;
    	for (uint256 i = 0; i < payment.cashouts.length; i++) {
    		SubPayment memory cashout = payment.cashouts[i];
    		if (cashout.date >= _date) {
    			break;
    		}
    		nTotal = nTotal.add(cashout.amount);
    	}
    	return nTotal;
    }
    
    /**
* @dev Returns the address of the token being sold
* @notice Retorna o endereço do token sendo vendido
*/
    function getToken() public view returns (address token) {
    	return address(baseToken);
    }
    

    /**
    * @dev Declare an investment for an address
    */
    function invest(address _investor, uint256 _amount) public onlyOwner {
        // make sure the investor is not an empty address
        require(_investor != address(0), "Investor is empty");
        // make sure the amount is not zero
        require(_amount != 0, "Amount is zero");
        // do not sell if offer is finished
        require(!bFinished, "Offer is already finished");
        // do not sell if not initialized
        require(bInitialized, "Offer is not initialized");

        // read the payment data from our map
        Payment storage payment = mapPayments[_investor];

        // increase the amount of tokens this investor has invested
        payment.totalInputAmount = payment.totalInputAmount.add(_amount);

        // process input data
        // call with same arguments
        brlToken.invest(_investor, _amount);
        // add the amount to the total
        nTotalCollected = nTotalCollected.add(_amount);
        
        // convert input currency to output
        // - get rate from module
        uint256 nRate = getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nRate);

        // increase the amount of tokens this investor has purchased
        payment.totalAmount = payment.totalAmount.add(nOutputAmount);

        // pass to module to handling outputs
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));
        // dont sell tokens that are already cashed out
        uint256 nRemainingToCashOut = nTotalSold.sub(nTotalCashedOut);
        // calculate how many tokens we can sell
        uint256 nRemainingBalance = nBalance.sub(nRemainingToCashOut);
        // make sure we're not selling more than we have
        require(
        nOutputAmount <= nRemainingBalance,
        "Offer does not have enough tokens to sell"
        );
        // log the payment
        SubPayment memory subPayment;
        subPayment.amount = nOutputAmount;
        subPayment.date = block.timestamp;
        payment.payments.push(subPayment);

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // and check if the offer is sucessful after this sale
        if (!bSuccess) {
            if (nTotalSold >= MIN_TOTAL_TOKEN_SOLD) {
            	// we have sold more than minimum, success
            	bSuccess = true;
            }
        }

        emit OnInvest(_investor, _amount);
    }

    /*
    * @dev Marks the offer as finished
    */
    function finishOffer() public onlyOwner {
        require(!bFinished, "Offer is already finished");
        bFinished = true;
        
        // save the date the offer finished
        nFinishDate = block.timestamp;
        
        if (!getSuccess()) {
        	// notify the BRLT token that we failed, so tokens are burned
        	brlToken.failedSale();
        }
        // get the current contract's balance
        uint256 nBalance = baseToken.balanceOf(address(this));
        if (getSuccess()) {
        	uint256 nRemainingToCashOut = nTotalSold.sub(nTotalCashedOut);
        	// calculate how many tokens we have not sold
        	uint256 nRemainingBalance = nBalance.sub(nRemainingToCashOut);
        	if (nRemainingBalance != 0) {
        		// return remaining tokens to issuer
        		baseToken.transfer(aIssuer, nRemainingBalance);
        	}
        } else {
        	// return all tokens to issuer
        	baseToken.transfer(aIssuer, nBalance);
        }
    }

    /*
    * @dev Cashouts tokens for a specified user
    */
    function cashoutTokens(address _investor) external virtual override returns (bool) {
        // cashout is automatic, and done ONLY by the token
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
        // increase the total cashed out
        nTotalCashedOut = nTotalCashedOut.add(nRemaining);
        // log the cashout
        SubPayment memory cashout;
        cashout.amount = nRemaining;
        cashout.date = block.timestamp;
        payment.cashouts.push(cashout);
        return true;
        
    }

    /*
    * @dev Returns the current rate for the token
    */
    function getRate() public view virtual returns (uint256 rate) {
        return TOKEN_BASE_RATE;
    }

    /*
    * @dev Gets how much the specified user has bought from this offer
    */
    function getTotalBought(address _investor) public view override returns (uint256 nTotalBought) {
        return mapPayments[_investor].totalAmount;
    }

    /*
    * @dev Get total amount the user has cashed out from this offer
    */
    function getTotalCashedOut(address _investor) public view override returns (uint256 nTotalCashedOut) {
        return mapPayments[_investor].totalPaid;
    }

    /*
    * @dev Returns true if the offer is initialized
    */
    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    /*
    * @dev Returns true if the offer is finished
    */
    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    /*
    * @dev Returns true if the offer is successful
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