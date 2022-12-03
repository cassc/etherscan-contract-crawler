/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../base/IOffer.sol";

contract CRZ0Token is ERC20Snapshot, Ownable {
    // Name of the token
    string public constant TOKEN_NAME = "Cruzeiro Token - Talentos da Toca";
    // Symbol of the token
    string public constant TOKEN_SYMBOL = "CRZ0";
    // Total amount of tokens
    uint256 public constant TOTAL_TOKENS = 792000 * 1 ether;
    // Date the token should expire
    uint256 public constant EXPIRATION_DATE_AFTER = 1811865600;
    // Date the token should unlock for the emitter
    uint256 public constant LOCKUP_EMITTER_DATE_AFTER = 1811865600;
    // Total amount the emitter has to hold
    uint256 public constant LOCKUP_EMITTER_AMOUNT = 475200 * 1 ether;

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;
    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;
    // address of the receiver
    address internal aReceiver;
    // Index of the last token snapshot
    uint256 private nSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend total amount
    mapping(uint256 => uint256) private mapERCPayment;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;
    // A reference to the emitter of the offer
    address internal aEmitter;

    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    constructor(
        address _receiver,
        address _dividendsToken,
        address _emitter
    ) public ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        // make sure the receiver is not empty
        require(_receiver != address(0));
        // save address of the receiver
        aReceiver = _receiver;
        // mints all tokens to receiver
        _mint(_receiver, TOTAL_TOKENS);
        // make sure the dividends token isnt empty
        require(_dividendsToken != address(0), "Dividends token cant be zero");
        // convert the address to an interface
        dividendsToken = IERC20(_dividendsToken);
        // get the balance of this contract to check if the interface works
        uint256 nBalance = dividendsToken.balanceOf(address(this));
        // this is never false, it's just a failsafe so that we execute balanceOf
        require(nBalance == 0, "Contract must have no balance");
        require(_emitter != address(0), "Emitter is empty");
        // save the address of the emitter
        aEmitter = _emitter;
    }

    /*
     * @dev Get the date the offer of the _index started
     */
    function getOfferDate(uint256 _index) public view returns (uint256) {
        return mapOfferStartDate[_index];
    }

    /*
     * @dev Get the address of the _index offer
     */
    function getOfferAddress(uint256 _index) public view returns (address) {
        return address(mapOffers[_index]);
    }

    /*
     * @dev Get the index of the last cashout for the _account
     */
    function getLastCashout(address _account) public view returns (uint256) {
        return mapLastCashout[_account];
    }

    /*
     * @dev Get the total amount of offers registered
     */
    function getTotalOffers() public view returns (uint256) {
        return counterTotalOffers.current();
    }

    /*
     * @dev Registers a sale on the token
     */
    function startSale(address _aTokenSale) public onlyOwner returns (uint256) {
        // make sure the address isn't empty
        require(_aTokenSale != address(0), "Sale cant be empty");
        // convert the sale to a interface
        IOffer objSale = IOffer(_aTokenSale);
        // make sure the sale is intiialized
        require(!objSale.getInitialized(), "Sale should not be initialized");
        // increment the total of offers
        counterTotalOffers.increment();
        // gets the current offer index
        uint256 nCurrentId = counterTotalOffers.current();
        // save the address of the sale
        mapOffers[nCurrentId] = objSale;
        // save the date the offer should be considered for dividends
        mapOfferStartDate[nCurrentId] = block.timestamp;
        // initialize the sale
        objSale.initialize();
        return nCurrentId;
    }

    /*
     * @dev Try to cashout up to 15 times
     */
    function tryCashouts(address aSender) private {
        for (uint256 i = 0; i < 15; i++) {
            if (!cashoutFrozenAny(aSender)) {
                return;
            }
        }
    }

    /*
     * @dev Main cashout function, cashouts up to 16 times
     */
    function cashoutFrozen() public {
        // cache the sender
        address aSender = _msgSender();
        bool bHasCashout = cashoutFrozenAny(aSender);
        require(bHasCashout, "No cashouts available");
        // try to do 10 cashouts
        tryCashouts(aSender);
    }

    /**
     * @return true if it changed the state
     */
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
        // get the latest token sale that was cashed out
        uint256 nCurrentSnapshotId = counterTotalOffers.current();
        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_account];
        // return if its the latest offer
        if (nCurrentSnapshotId <= nLastCashout) {
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

     /*
     * @dev Returns the total amount of tokens the
     * caller has in offers, up to _nPaymentDate
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

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_aInvestor];

        for (uint256 i = nLastCashout + 1; i <= nCurrent; i++) {
            // get offer start date
            uint256 nOfferDate = getOfferDate(i);

            // break if the offer started after the payment date
            if (nOfferDate > _nPaymentDate) {
                break;
            }

            // grab the offer from the map
            IOffer objOffer = mapOffers[i];

            // get the total amount the user bought at the offer
            uint256 nAddBalance = objOffer.getTotalBought(_aInvestor);

            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOut(_aInvestor);

            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }

        return nBalance;
    }

    /*
     * @dev Gets the address of the token used for dividends
     */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /*
     * @dev Gets the total count of payments
     */
    function getTotalDividendPayments() public view returns (uint256) {
        return nSnapshotId;
    }

    function getPayment(uint256 _nIndex)
        public
        view
        returns (uint256 nERCPayment, uint256 nDate)
    {
        nERCPayment = mapERCPayment[_nIndex];
        nDate = mapPaymentDate[_nIndex];
    }

    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /*
     * @dev Function made for owner to transfer tokens to contract for dividend payment
     */
    function payDividends(uint256 _amount) public onlyOwner {
        // make sure the amount is not zero
        require(_amount > 0, "Amount cant be zero");
        // grab our current allowance
        uint256 nAllowance =
            dividendsToken.allowance(_msgSender(), address(this));
        // make sure we at least have the balance added
        require(_amount <= nAllowance, "Not enough balance to pay dividends");
        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), _amount);
        // snapshot the tokens at the moment the ether enters
        nSnapshotId = _snapshot();
        // register the balance in ether that entered
        mapERCPayment[nSnapshotId] = _amount;
        // save the date
        mapPaymentDate[nSnapshotId] = block.timestamp;
    }

    /*
     * @dev Withdraws dividends up to 16 times
     */
    function withdrawDividends() public {
        require(_withdrawDividends(), "No new withdrawal");
        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends()) {
                return;
            }
        }
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
            uint256 nTokenSuppy = totalSupplyAt(_nPaymentIndex);

            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[_nPaymentIndex];

            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);

            return nToReceive;
        }
    }

    /**
     * @dev Gets the total amount of dividends for an investor
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
        uint256 nEndPayment = nLastPayment.add(16);

        // loop
        for (uint256 i = nLastPayment + 1; i < nEndPayment; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(_recursiveGetTotalDividends(_investor, i));

            // if bigger than all total snapshots, end the loop
            if (i >= nSnapshotId) {
                break;
            }
        }

        return nBalance;
    }

    /*
     * @dev Based on how many tokens the user had at the snapshot,
     * pay dividends of the erc20 token
     * (also pays for tokens inside offer)
     */
    function _withdrawDividends() private returns (bool) {
        // cache the sender
        address aSender = _msgSender();
        // read the last payment
        uint256 nLastPayment = mapLastPaymentSnapshot[aSender];
        // make sure we have a next payment
        if (nLastPayment >= nSnapshotId) {
            return false;
        }
        // add 1 to get the next payment
        uint256 nNextPayment = nLastPayment.add(1);
        // save back that we have paid this user
        mapLastPaymentSnapshot[aSender] = nNextPayment;
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(aSender, nNextPayment);
        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextPayment];
        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, aSender);
        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);
        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(nNextPayment);
            // get the total token amount for this payment
            uint256 nTotalTokens = mapERCPayment[nNextPayment];
            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive =
                mulDiv(nTokenBalance, nTotalTokens, nTokenSuppy);
            // send the ERC20 value to the user
            dividendsToken.transfer(aSender, nToReceive);
        }
        return true;
    }

    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;
        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

    /**
     * @dev Very cheap x*y/z
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address aSender = _msgSender();
        // try to cashout all possible offers before transfering
        tryCashouts(aSender);
        // check if were allowed to continue
        if (block.timestamp > EXPIRATION_DATE_AFTER) {
            revert("Date is after token lockup date");
        }
        if (_msgSender() == aEmitter) {
            // rule only applies before
            if (block.timestamp < LOCKUP_EMITTER_DATE_AFTER) {
                // check if the balance is enough
                uint256 nBalance = balanceOf(aEmitter);
                // remove the transfer from the balance
                uint256 nFinalBalance = nBalance.sub(amount);
                // make sure the remaining tokens are more than the needed by the rule
                require(
                    nFinalBalance >= LOCKUP_EMITTER_AMOUNT,
                    "Transfering more than account allows"
                );
                super._beforeTokenTransfer(from, to, amount);
            }
        }
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
}