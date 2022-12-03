/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./IOffer_v2.sol";
import "./ISignatureManager.sol";

/**
 * @dev BaseOfferSale is the base module for all offer modules in the platform
 * It's used primarily for unit testing
 * This contract's code should be the same as genesis Offer.sol
 * @notice Contrato base para todas as ofertas na plataforma
 */
contract BaseOfferSale is Ownable, IOffer {
    // SafeMath for all math operations
    using SafeMath for uint256;

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

    // If the offer has been initialized by the owner
    bool internal bInitialized;
    // If the success condition has been met
    bool internal bSuccess;
    // If the offer has finished the sale of tokens
    bool internal bFinished;

    // A counter of the total amount of tokens sold
    uint256 internal nTotalSold;

    // The date the offer finishOffer function was called
    uint256 internal nFinishDate;

    // A map of address to payment
    mapping(address => Payment) internal mapPayments;

    // TESTING: The current rate the tokens are traded at
    uint256 private nRate = 1;

    event OnInvest(address _investor, uint256 _amount);

    constructor() public {}

    function initialize() public override {
        require(!bInitialized, "Offer is already initialized");

        bInitialized = true;

        _initialize();
    }

    /**
     * @dev TESTING PURPOSES: changes the initialized state of the contract
     */
    function setInitialized() public onlyOwner {
        require(!bInitialized, "Offer is already successful");

        bInitialized = true;
    }

    /**
     * @dev Base function for all investments in the offer
     * @notice Função base para investimento,
     * grava a quantidade de tokens que o usuário investiu, converte de acordo com a rate e passa pelas regras e módulos setados pelo gerador.
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

        // pass the function to one of our modules
        _investInput(_investor, _amount);

        // convert input currency to output
        // - get rate from module
        uint256 nTokenRate = _getRate();

        // - total amount from the rate obtained
        uint256 nOutputAmount = _amount.div(nTokenRate);

        // pass to module to handling outputs
        _investOutput(_investor, nOutputAmount, payment);

        // increase the amount of tokens this investor has purchased
        payment.totalAmount = payment.totalAmount.add(nOutputAmount);

        // after everything, add the bought tokens to the total
        nTotalSold = nTotalSold.add(nOutputAmount);

        // now make sure everything we've done is okay
        _rule();

        // and check if the offer is sucessful after this sale
        if (!bSuccess) {
            _investNoSuccess();
        }

        emit OnInvest(_investor, _amount);
    }

    /**
     * @dev Finishes the offer of tokens, restricting sale and executing the modules for ending
     * @notice Finaliza a oferta de tokens, restringindo a venda e executando os módulos de término
     */
    function finishOffer() public onlyOwner {
        // only if not finished
        require(!bFinished, "Offer is already finished");
        bFinished = true;

        // save the date the offer finished
        nFinishDate = block.timestamp;

        // call module
        _finishOffer();
    }

    function cashoutTokens(address _investor)
        external
        virtual
        override
        returns (bool)
    {
        return bFinished;
    }

    function _initialize() internal virtual {}

    function getRate() public view virtual returns (uint256 rate) {
        return _getRate();
    }

    function _getRate() internal view virtual returns (uint256 rate) {
        return nRate;
    }

    function _investInput(address _investor, uint256 _amount)
        internal
        virtual
    {}

    function _investOutput(
        address _investor,
        uint256 _outputAmount,
        Payment storage payment
    ) internal virtual {}

    function _finishOffer() internal virtual {}

    function _rule() internal virtual {}

    function _investNoSuccess() internal virtual {}

    /**
     * @dev TESTING PURPOSES: changes the rate the token is traded at
     */
    function setRate(uint256 _rate) public {
        nRate = _rate;
    }

    /**
     * @dev TESTING PURPOSES: changes the success state of the contract
     */
    function setSuccess() public onlyOwner {
        require(bInitialized, "Offer is not initialized");

        require(!bSuccess, "Offer is already successful");

        bSuccess = true;
    }

    function getFinishDate() external view override returns (uint256) {
        return nFinishDate;
    }

    function getInitialized() public view override returns (bool) {
        return bInitialized;
    }

    function getFinished() public view override returns (bool) {
        return bFinished;
    }

    function getSuccess() public view override returns (bool) {
        return bSuccess;
    }

    function getTotalBought(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalCashedOut(address _investor)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalBoughtDate(address _investor, uint256 _date)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalCashedOutDate(address _investor, uint256 _date)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return 0;
    }

    function getTotalSold() public view virtual returns (uint256 totalSold) {
        return nTotalSold;
    }
}