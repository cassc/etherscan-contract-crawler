/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "../../../base/BaseOfferSale.sol";
import "../../../LiqiBRLToken.sol";

/**
 * @dev InputBRLT handles investments using Liqi's BRLT tokens
 * @notice InputBRLT administra investimentos na oferta usando LiqiBRLTs.
 * A cada investimento, há uma chamada ao invest() do BRLToken, que minta os tokens na conta do investidor e automaticamente os transfere à este contrato.
 * Se a oferta for finalizada sem sucesso, todos os tokens são queimados utilizando a função failedSale() do BRLToken.
 */
contract InputBRLT is BaseOfferSale {
    // SafeMath for all math operations
    using SafeMath for uint256;

    // A reference to the BRLToken contract
    LiqiBRLToken private brlToken;

    // A reference to the issuer of the offer
    address private aIssuer;

    // Total amount of BRLT tokens collected during sale
    uint256 internal nTotalCollected;

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

    function _finishOffer() internal virtual override {
        if (!getSuccess()) {
            // notify the BRLT token that we failed, so tokens are burned
            brlToken.failedSale();
        }
    }

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
        override
    {
        // call with same arguments
        brlToken.invest(_investor, _amount);

        // add the amount to the total
        nTotalCollected = nTotalCollected.add(_amount);
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
}