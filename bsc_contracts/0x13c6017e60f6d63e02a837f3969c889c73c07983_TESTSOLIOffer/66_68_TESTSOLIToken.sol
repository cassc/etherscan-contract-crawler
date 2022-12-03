/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../library/LiqiMathLib.sol";
import "../../base/IOffer_v2.sol";

contract TESTSOLIToken is ERC20Snapshot, Ownable {
    uint256 public constant DATE_INTEREST_START = 1669086000;
    uint256 public constant INTEREST_RATE = 1.2 * 1 ether;
    uint256 public constant TOTAL_TOKENS = 5 * 1 ether;
    uint256 public constant TOKEN_BASE_RATE = 100;
    address public constant OWNER = 0xe7463F674837F3035a4fBE15Da5D50F5cAC982f4;
    // Name of the token
    string public constant TOKEN_NAME = "TESTSOLIToken";
    // Symbol of the token
    string public constant TOKEN_SYMBOL = "TESTSOLI";

    using SafeMath for uint256;
    // Index of the current token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;
    using Counters for Counters.Counter;
    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;
    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;
    // Address of the issuer
    address internal aIssuer;
    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    constructor(
        address _issuer, 
        address _dividendsToken
    ) public
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
    {        
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");
        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);
        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));
        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
        // make sure the issuer is not empty
        require(_issuer != address(0));
        // save address of the issuer
        aIssuer = _issuer;
        // call onCreate so inheriting contracts can override base mint functionality
        onCreate();
    }

        function onCreate() private {
    // make sure were not starting with 0 tokens
    require(TOTAL_TOKENS != 0, "Tokens to be minted is 0");
    // mints all tokens to issuer
    _mint(aIssuer, TOTAL_TOKENS);
        }

    /**
* @dev Gets the address of the token used for dividends
* @notice Retorna o endereço do token de pagamento de dividendos
*/
    function getDividendsToken() public view returns (address) {
    	return address(dividendsToken);
    }
    
    /**
* @dev Gets the total count of payments
* @notice Retorna o total de pagamentos de dividendos feitos à este contrato
*/
    function getTotalDividendPayments() public view returns (uint256) {
    	return nCurrentSnapshotId;
    }
    
    /**
* @dev Gets payment data for the specified index
* @notice Retorna dados sobre o pagamento no índice especificado.
* nERCPayment: Valor pago no token ERC20 de dividendos.
* nDate: Data em formato unix do pagamento desse dividendo
*/
    function getPayment(uint256 _nIndex)
    	public
    	view
    	returns (uint256 nERCPayment, uint256 nDate)
    {
    	nERCPayment = mapERCPayment[_nIndex];
    	nDate = mapPaymentDate[_nIndex];
    }
    
    /**
* @dev Gets the last payment cashed out by the specified _investor
* @notice Retorna o ID do último saque feito para essa carteira
*/
    function getLastPayment(address _aInvestor) public view returns (uint256) {
    	return mapLastPaymentSnapshot[_aInvestor];
    }
    
    /**
* @dev Function made for owner to transfer tokens to contract for dividend payment
* @notice Faz um pagamento de dividendos ao contrato, no valor especificado
*/
    function payDividends(uint256 _amount) public onlyOwner {
    	// make sure the amount is not zero
    	require(_amount > 0, "Amount cant be zero");
    	// grab our current allowance
    	uint256 nAllowance = dividendsToken.allowance(
    	_msgSender(),
    	address(this)
    	);
    	// make sure we at least have the balance added
    	require(_amount <= nAllowance, "Not enough balance to pay dividends");
    	// transfer the tokens from the sender to the contract
    	dividendsToken.transferFrom(_msgSender(), address(this), _amount);
    	// snapshot the tokens at the moment the ether enters
    	nCurrentSnapshotId = _snapshot();
    	// register the balance in ether that entered
    	mapERCPayment[nCurrentSnapshotId] = _amount;
    	// save the date
    	mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }
    
    /**
* @dev Withdraws dividends (up to 16 times in the same call, if available)
* @notice Faz o saque de até 16 dividendos para a carteira que chama essa função
*/
    function withdrawDividends() public {
    	address aSender = _msgSender();
    	require(_withdrawDividends(aSender), "No new withdrawal");
    	for (uint256 i = 0; i < 15; i++) {
    		if (!_withdrawDividends(aSender)) {
    			return;
    		}
    	}
    }
    
    /**
* @dev Withdraws one single dividend, if available
* @notice Faz o saque de apenas 1 dividendo para a carteira que chama essa função
* (se tiver disponivel)
*/
    function withdrawDividend() public {
    	address aSender = _msgSender();
    	require(_withdrawDividends(aSender), "No new withdrawal");
    }
    
    /**
* @dev Withdraws dividends up to 16 times for the specified user
* @notice Saca até 16 dividendos para o endereço especificado
*/
    function withdrawDividendsAny(address _investor) public {
    	require(_withdrawDividends(_investor), "No new withdrawal");
    	for (uint256 i = 0; i < 15; i++) {
    		if (!_withdrawDividends(_investor)) {
    			return;
    		}
    	}
    }
    
    /**
* @dev Withdraws only 1 dividend for the specified user
* @notice Saca apenas 1 dividendo para o endereço especificado
*/
    function withdrawDividendAny(address _investor) public {
    	require(_withdrawDividends(_investor), "No new withdrawal");
    }
    
    function _recursiveGetTotalDividends(
    	address _aInvestor,
    	uint256 _nPaymentIndex
    ) internal view returns (uint256) {
    	// get the balance of the user at this snapshot
    	uint256 nTokenBalance = balanceOfAt(_aInvestor, _nPaymentIndex);
    	// get the date the payment entered the system
    	uint256 nPaymentDate = mapPaymentDate[_nPaymentIndex];
    	// get the total amount of balance this user has in offers
    	uint256 nTotalOffers = getTotalInOffers(nPaymentDate, _aInvestor);
    	// add the total amount the user has in offers
    	nTokenBalance = nTokenBalance.add(nTotalOffers);
    	if (nTokenBalance == 0) {
    		return 0;
    	} else {
    		// get the total supply at this snapshot
    		uint256 nTokenSupply = totalSupplyAt(_nPaymentIndex);
    		// get the total token amount for this payment
    		uint256 nTotalTokens = mapERCPayment[_nPaymentIndex];
    		// calculate how much he'll receive from this lot,
    		// based on the amount of tokens he was holding
    		uint256 nToReceive = LiqiMathLib.mulDiv(
    		nTokenBalance,
    		nTotalTokens,
    		nTokenSupply
    		);
    		return nToReceive;
    	}
    }
    
    /**
* @dev Gets the total amount of available dividends
* to be cashed out for the specified _investor
* @notice Retorna o total de dividendos que esse endereço pode sacar
*/
    function getTotalDividends(address _investor)
    	public
    	view
    	returns (uint256)
    {
    	// start total balance 0
    	uint256 nBalance = 0;
    	// get the last payment index for the investor
    	uint256 nLastPayment = mapLastPaymentSnapshot[_investor];
    	// add 16 as the limit
    	uint256 nEndPayment = Math.min(
    	nLastPayment.add(16),
    	nCurrentSnapshotId.add(1)
    	);
    	// loop
    	for (uint256 i = nLastPayment.add(1); i < nEndPayment; i++) {
    		// add the balance that would be withdrawn if called for this index
    		nBalance = nBalance.add(_recursiveGetTotalDividends(_investor, i));
    	}
    	return nBalance;
    }
    
    /**
* @dev Based on how many tokens the user had at the snapshot,
* pay dividends of the ERC20 token
* Be aware that this function will pay dividends
* even if the tokens are currently in possession of the offer
*/
    function _withdrawDividends(address _sender) private returns (bool) {
    	// read the last payment
    	uint256 nLastPayment = mapLastPaymentSnapshot[_sender];
    	// make sure we have a next payment
    	if (nLastPayment >= nCurrentSnapshotId) {
    		return false;
    	}
    	// add 1 to get the next payment
    	uint256 nNextUserPayment = nLastPayment.add(1);
    	// save back that we have paid this user
    	mapLastPaymentSnapshot[_sender] = nNextUserPayment;
    	// get the balance of the user at this snapshot
    	uint256 nTokenBalance = balanceOfAt(_sender, nNextUserPayment);
    	// get the date the payment entered the system
    	uint256 nPaymentDate = mapPaymentDate[nNextUserPayment];
    	// get the total amount of balance this user has in offers
    	uint256 nBalanceInOffers = getTotalInOffers(nPaymentDate, _sender);
    	// add the total amount the user has in offers
    	nTokenBalance = nTokenBalance.add(nBalanceInOffers);
    	if (nTokenBalance != 0) {
    		// get the total supply at this snapshot
    		uint256 nTokenSupply = totalSupplyAt(nNextUserPayment);
    		// get the total token amount for this payment
    		uint256 nTotalTokens = mapERCPayment[nNextUserPayment];
    		// calculate how much he'll receive from this lot,
    		// based on the amount of tokens he was holding
    		uint256 nToReceive = LiqiMathLib.mulDiv(
    		nTokenBalance,
    		nTotalTokens,
    		nTokenSupply
    		);
    		// send the ERC20 value to the user
    		dividendsToken.transfer(_sender, nToReceive);
    	}
    	return true;
    }
    
    /**
* @dev Registers a offer on the token
* @notice Método para iniciar uma oferta de venda de token Liqi (parte do sistema interno de deployment)
*/
    function startOffer(address _aTokenOffer)
    	public
    	onlyOwner
    	returns (uint256)
    {
    	// make sure the address isn't empty
    	require(_aTokenOffer != address(0), "Offer cant be empty");
    	// convert the offer to a interface
    	IOffer objOffer = IOffer(_aTokenOffer);
    	// make sure the offer is intiialized
    	require(!objOffer.getInitialized(), "Offer should not be initialized");
    	// gets the index of the last offer, if it exists
    	uint256 nLastId = counterTotalOffers.current();
    	// check if its the first offer
    	if (nLastId != 0) {
    		// get a reference to the last offer
    		IOffer objLastOFfer = IOffer(mapOffers[nLastId]);
    		// make sure the last offer is finished
    		require(objLastOFfer.getFinished(), "Offer should be finished");
    	}
    	// increment the total of offers
    	counterTotalOffers.increment();
    	// gets the current offer index
    	uint256 nCurrentId = counterTotalOffers.current();
    	// save the address of the offer
    	mapOffers[nCurrentId] = objOffer;
    	// save the date the offer should be considered for dividends
    	mapOfferStartDate[nCurrentId] = block.timestamp;
    	// initialize the offer
    	objOffer.initialize();
    	return nCurrentId;
    }
    
    /**
* @dev Try to cashout up to 5 times
* @notice Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira especificada
*/
    function cashoutFrozenMultipleAny(address aSender) public {
    	bool bHasCashout = cashoutFrozenAny(aSender);
    	require(bHasCashout, "No cashouts available");
    	for (uint256 i = 0; i < 5; i++) {
    		if (!cashoutFrozenAny(aSender)) {
    			return;
    		}
    	}
    }
    
    /**
* @dev Main cashout function, cashouts up to 16 times
* @notice Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira que chama essa função
*/
    function cashoutFrozen() public {
    	// cache the sender
    	address aSender = _msgSender();
    	// try to do 10 cashouts
    	cashoutFrozenMultipleAny(aSender);
    }
    
    /**
* @return true if it changed the state
* @notice Faz o cashout de apenas 1 compra para o endereço especificado.
* Retorna true se mudar o estado do contrato.
*/
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
    	// get the latest token sale that was cashed out
    	uint256 nCurSnapshotId = counterTotalOffers.current();
    	// get the last token sale that this user cashed out
    	uint256 nLastCashout = mapLastCashout[_account];
    	// return if its the latest offer
    	if (nCurSnapshotId <= nLastCashout) {
    		return false;
    	}
    	// add 1 to get the next payment index
    	uint256 nNextCashoutIndex = nLastCashout.add(1);
    	// get the address of the offer this user is cashing out
    	IOffer offer = mapOffers[nNextCashoutIndex];
    	// cashout the tokens, if the offer allows
    	bool bOfferCashout = offer.cashoutTokens(_account);
    	// check if the sale is finished
    	if (offer.getFinished()) {
    		// save that it was cashed out, if the offer is over
    		mapLastCashout[_account] = nNextCashoutIndex;
    		return true;
    	}
    	return bOfferCashout;
    }
    
    /**
* @dev Returns the total amount of tokens the
* caller has in offers, up to _nPaymentDate
* @notice Calcula quantos tokens o endereço tem dentro de ofertas com sucesso (possíveis de saque) até a data de pagamento especificada
*/
    function getTotalInOffers(uint256 _nPaymentDate, address _aInvestor)
    	public
    	view
    	returns (uint256)
    {
    	// start the final balance as 0
    	uint256 nBalance = 0;
    	// get the latest offer index
    	uint256 nCurrent = counterTotalOffers.current();
    	for (uint256 i = 1; i <= nCurrent; i++) {
    		// get offer start date
    		uint256 nOfferDate = getOfferDate(i);
    		// break if the offer started after the payment date
    		if (nOfferDate >= _nPaymentDate) {
    			break;
    		}
    		// grab the offer from the map
    		IOffer objOffer = mapOffers[i];
    		// only get if offer is finished
    		if (!objOffer.getFinished()) {
    			break;
    		}
    		if (!objOffer.getSuccess()) {
    			continue;
    		}
    		// get the total amount the user bought at the offer
    		uint256 nAddBalance = objOffer.getTotalBoughtDate(
    		_aInvestor,
    		_nPaymentDate
    		);
    		// get the total amount the user cashed out at the offer
    		uint256 nRmvBalance = objOffer.getTotalCashedOutDate(
    		_aInvestor,
    		_nPaymentDate
    		);
    		// add the bought and remove the cashed out
    		nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
    	}
    	return nBalance;
    }
    
    /**
* @dev Get the date the offer of the _index started
* @notice Retorna a data de inicio da oferta especificada
*/
    function getOfferDate(uint256 _index) public view returns (uint256) {
    	return mapOfferStartDate[_index];
    }
    
    /**
* @dev Get the address of the _index offer
* @notice Retorna o endereço da oferta especificada
*/
    function getOfferAddress(uint256 _index) public view returns (address) {
    	return address(mapOffers[_index]);
    }
    
    /**
* @dev Get the index of the last cashout for the _account
* @notice Retorna o índice da ultima oferta que o endereço especificado fez o cashout
*/
    function getLastCashout(address _account) public view returns (uint256) {
    	return mapLastCashout[_account];
    }
    
    /**
* @dev Get the total amount of offers registered
* @notice Retorna o total de ofertas que foram linkadas a esse token
*/
    function getTotalOffers() public view returns (uint256) {
    	return counterTotalOffers.current();
    }
    
    /**
* @dev Gets the address of the issuer
* @notice Retorna o endereço da carteira do emissor
*/
    function getIssuer() public view returns (address) {
    	return aIssuer;
    }
    
    /**
* @dev Disables the exchangeBalance function
*/
    function disableExchangeBalance() public onlyOwner {
    	require(
    	!bDisabledExchangeBalance,
    	"Exchange balance is already disabled"
    	);
    	bDisabledExchangeBalance = true;
    }
    
    /**
* @dev Exchanges the funds of one address to another
*/
    function exchangeBalance(address _from, address _to) public onlyOwner {
    	// check if the function is disabled
    	require(
    	!bDisabledExchangeBalance,
    	"Exchange balance has been disabled"
    	);
    	// simple checks for empty addresses
    	require(_from != address(0), "Transaction from 0x");
    	require(_to != address(0), "Transaction to 0x");
    	// get current balance of _from address
    	uint256 amount = balanceOf(_from);
    	// check if there's balance to transfer
    	require(amount != 0, "Balance is 0");
    	// transfer balance to new address
    	_transfer(_from, _to, amount);
    }
    

    function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
    ) internal virtual override {
    require(to != address(this), "Sending to contract address");
    super._beforeTokenTransfer(from, to, amount);
    }
   
}