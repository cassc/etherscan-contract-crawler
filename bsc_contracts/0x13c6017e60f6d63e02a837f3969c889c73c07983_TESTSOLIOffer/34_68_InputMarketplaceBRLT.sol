/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../LiqiBRLToken.sol";

/**
 * @dev InputMarketplaceBRLT handles investments using Liqi's BRLT tokens inside the marketplace
 * @notice InputMarketplaceBRLT administra tokens num ambiente de mercado.
 * Esse contrato não está pronto para produção.
 */
contract InputMarketplaceBRLT is BaseOfferSale {
    // SafeMath for all math operations
    using SafeMath for uint256;

    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;

    // A reference to the issuer of the offer
    address private aIssuer;

    // Total amount of BRLT tokens collected during sale
    uint256 internal nTotalCollected;

    // A map for the returnal of tokens, if the sale fails
    mapping(address => bool) internal mapReturnals;

    /**
     * @dev Investment with Liqi's BRLT token
     */
    constructor(address _issuer, address _brlTokenContract)
        public
        BaseOfferSale()
    {
        // save the issuer's address
        aIssuer = _issuer;

        // convert the BRLT's address to our interface
        brlToken = LiqiBRLToken(_brlTokenContract);
    }

    function cashoutBRLT() public {
        // cache the sender
        address aSender = _msgSender();

        cashoutAnyBRLT(aSender);
    }

    /**
     * @dev In case of failure, cashout BRLTs invested in the offer
     */
    function cashoutAnyBRLT(address _investor) public {
        // make sure the offer is finished
        require(bFinished, "Offer is not finished");

        // only cashout if finished and failure
        require(!bSuccess, "Offer is successfull");

        // make sure the user has not cashed out
        require(!mapReturnals[_investor], "Already cashed out");

        // check the balance of tokens of this contract
        Payment storage payment = mapPayments[_investor];

        // return the tokens
        brlToken.transfer(_investor, payment.totalInputAmount);

        // save that we returned his tokens
        mapReturnals[_investor] = true;
    }

    /**
     * @dev Cashouts BRLTs paid to the offer to the issuer
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

    function _finishOffer() internal virtual override {
        if (!getSuccess()) {
            // notify the BRLT token that we failed, so tokens are burned
            //brlToken.failedSale();
        }
    }

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
        override
    {
        // call with same arguments
        //brlToken.investMkt(_investor, _amount);

        // add the amount to the total
        nTotalCollected = nTotalCollected.add(_amount);
    }

    /**
     * @dev Returns the address of the input token
     */
    function getInputToken() public view returns (address) {
        return address(brlToken);
    }

    /**
     * @dev Returns the total amount of tokens invested
     */
    function getTotalCollected() public view returns (uint256) {
        return nTotalCollected;
    }
}