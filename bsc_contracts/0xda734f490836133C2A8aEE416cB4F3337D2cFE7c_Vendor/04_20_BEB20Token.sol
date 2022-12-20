// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../helpers/PriceConsumerV3.sol";
import "../helpers/TransactionFee.sol";
import "../helpers/TransferHistory.sol";
import "../security/ReEntrancyGuard.sol";

contract BEB20Token is
    Context,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private beb20Token;

    constructor(address _tokenAddress) {
        beb20Token = IERC20(_tokenAddress);
    }

    /// @dev   Allow users to buy tokens for MATIC
    function buy() external payable limitBuy(SentBuy(msg.value)) noReentrant {
        require(msg.value > 0, "Send MATIC to buy some tokens");

        /// @dev  send fee
        uint256 _amountfee = calculateFee(msg.value);
        require(
            payable(_walletFee).send(_amountfee),
            "Failed to transfer token to fee contract Owner"
        );

        uint256 _amountOfTokens = msg.value - _amountfee;

        /// @dev  token  para enviar al sender
        uint256 amountToBuy = SentBuy(_amountOfTokens);

        /// @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = beb20Token.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        /// @dev  Transfer token to the msg.sender
        bool sent = beb20Token.transfer(_msgSender(), amountToBuy);
        require(sent, "Failed to transfer token to user");
    }

    // @dev calculate the tokens to send to the sender
    function SentBuy(uint256 amountOfTokens) internal view returns (uint256) {
        (address _addr, uint256 _decimal) = getOracle(0);

        // Get the amount of tokens that the user will receive
        // convert cop to usd
        uint256 valueBNBinUSD = amountOfTokens *
            getLatestPrice(_addr, _decimal);

        // token para enviar al sender
        uint256 amountToBuy = valueBNBinUSD / getPriceToken();

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell  by MATIC
    function sell(uint256 tokenAmountToSell)
        external
        limitSell(tokenAmountToSell)
        noReentrant
    {
        /// @dev Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "sell: Specify an amount of token greater than zero"
        );

        /// @dev Check that the user's token balance is enough to do the swap
        uint256 userBalance = beb20Token.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "sell: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev  get price token
        (address _addr, uint256 _decimal) = getOracle(0);

        /// @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToSell);
        require(
            beb20Token.transfer(_walletFee, _amountfee),
            "sell: Failed to transfer token"
        );

        /// @dev  liquids of the contract in matic
        uint256 ownerMATICBalance = address(this).balance;

        /// @dev   token available to send to user
        uint256 tokenSend = tokenAmountToSell - _amountfee;

        /// @dev  Token To Usd
        uint256 tokenToUsd = tokenSend * getPriceToken();

        /// dev get value token
        uint256 lastPriceToken = getLatestPrice(_addr, _decimal);

        /// @dev  token To MAtic
        uint256 amountToTransfer = tokenToUsd / lastPriceToken;


        /// @dev  Check that the Vendor's balance is enough to do the swap
        require(
            ownerMATICBalance >= amountToTransfer,
            "sell: Vendor has not enough funds to accept the sell request"
        );

        /// @dev  Transfer token to the msg.sender
        require(
            beb20Token.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToSell
            ),
            "sell: Failed to transfer tokens from user to vendor"
        );

        /// @dev   we send matic to the sender
        (bool success, ) = _msgSender().call{value: amountToTransfer}("");
        require(success, "receiver rejected BNB transfer");
    }
}