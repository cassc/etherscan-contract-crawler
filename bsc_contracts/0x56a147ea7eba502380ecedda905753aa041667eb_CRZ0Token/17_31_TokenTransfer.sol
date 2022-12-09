// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../../base/BaseOfferToken.sol";
import "../../base/IOffer.sol";

contract TokenTransfer is BaseOfferToken {
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

    /**
     * @dev Make a Token Transfer
     */
    constructor(
        address _receiver,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public BaseOfferToken(_tokenName, _tokenSymbol) {
        // make sure the receiver is not empty
        require(_receiver != address(0));

        // make sure were not starting with 0 tokens
        require(_totalTokens != 0);

        // save address of the receiver
        aReceiver = _receiver;

        // mints all tokens to receiver
        _mint(_receiver, _totalTokens);
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
    function getTotalInOffers(uint256 _nPaymentDate)
        public
        view
        returns (uint256)
    {
        // start the final balance as 0
        uint256 nBalance = 0;

        // get the latest offer index
        uint256 nCurrent = counterTotalOffers.current();

        // get the address of the sender
        address aSender = _msgSender();

        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[aSender];

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
            uint256 nAddBalance = objOffer.getTotalBought(aSender);

            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOut(aSender);

            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }

        return nBalance;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address aSender = _msgSender();
        // try to cashout all possible offers before transfering
        tryCashouts(aSender);

        super._beforeTokenTransfer(from, to, amount);
    }
}