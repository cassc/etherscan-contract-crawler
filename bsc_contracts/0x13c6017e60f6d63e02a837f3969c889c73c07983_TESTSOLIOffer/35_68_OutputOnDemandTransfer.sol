// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../../../base/BaseOfferSale.sol";
import "../../../base/BaseOfferToken.sol";

/**
 * @dev OutputOnDemandTransfer sells tokens to investors on demand
 * (i.e. tokens are pre-emitted and held by the offer contract)
 * @notice OutputOnDemandTransfer vende tokens para investidores sob-demanda
 * (tokens são pré-emitidos e segurados pelo contrato da oferta).
 * Se a oferta falha, retorna todos os tokens para o issuer.
 */
contract OutputOnDemandTransfer is BaseOfferSale {
    // SafeMath for all math operations
    using SafeMath for uint256;

    // A reference to the token were selling
    BaseOfferToken private baseToken;

    // A reference to the issuer of the offer
    address private aIssuer;

    // A counter for the total amount users have cashed out
    uint256 private nTotalCashedOut;

    /**
     * @dev Investment with ERC20 token
     */
    constructor(address _issuer, address _tokenAddress) public BaseOfferSale() {
        // save the issuer's address
        aIssuer = _issuer;

        // convert the token's address to our interface
        baseToken = BaseOfferToken(_tokenAddress);
    }

    function _initialize() internal override {
        // for OutputOnDemand, only the token can call initialize
        require(_msgSender() == address(baseToken), "Only call from token");
    }

    function _investOutput(
        address _investor,
        uint256 nOutputAmount,
        Payment storage payment
    ) internal virtual override {
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
    }

    function _finishOffer() internal virtual override {
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

    /**
     * @dev Called directly from the token's contract,
     * cashouts any tokens the investor has that is currently on this contract
     * @notice Função restrita e só pode ser chamada do contrato do token,
     * faz o cashout de todos os tokens que o investidor tem comprados nesse contrato.
     */
    function cashoutTokens(address _investor) external override returns (bool) {
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

    /**
     * @dev Returns the total amount of tokens the specified investor has bought from this contract
     * @notice Retorna quantos tokens o investidor comprou em total no contrato
     */
    function getTotalBought(address _investor)
        public
        view
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalAmount;
    }

    /**
     * @dev Returns the total amount of tokens the specified investor has cashed out from this contract
     * @notice Retorna quantos tokens o investidor sacou em total no contrato
     */
    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return mapPayments[_investor].totalPaid;
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
}