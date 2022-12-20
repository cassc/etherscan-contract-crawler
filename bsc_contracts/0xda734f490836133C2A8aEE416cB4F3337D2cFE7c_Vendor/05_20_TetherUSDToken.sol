// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BEB20Token.sol";
import "../security/ReEntrancyGuard.sol";
import "../helpers/PriceConsumerV3.sol";
import "../helpers/TransferHistory.sol";
import "../helpers/TransactionFee.sol";

contract TetherUSDToken is
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private usdtToken;
    IERC20 private BEB20Token2;

    constructor(address usdtTokenAddress, address _tokenAddress) {
        usdtToken = IERC20(usdtTokenAddress);
        BEB20Token2 = IERC20(_tokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt
    function buyUSDT(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(USDTSentBuy(tokenAmountToBuy))
    {
        require(
            tokenAmountToBuy > 0,
            "buyUSDT: Specify an amount of token greater than zero"
        );

        //  @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = usdtToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "buyUSDT: Your balance is lower than the amount of tokens you want to sell"
        );

        //@dev Transfer token to the SENDER USDT =>  SC
        require(
            usdtToken.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToBuy
            ),
            "buyUSDT: Failed to transfer tokens from user to vendor"
        );

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        require(
            usdtToken.transfer(_walletFee, _amountfee),
            "buyUSDT: Failed to transfer token to user"
        );

        // @dev  token available to send to user
        uint256 tokenSend = tokenAmountToBuy - _amountfee;

        //  @dev  Get the amount of tokens that the user will receive
        uint256 amountToBuy = USDTSentBuy(tokenSend);

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = BEB20Token2.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "buyUSDT: Vendor contract has not enough tokens in its balance"
        );

        //  @dev  Transfer token to the msg.sender SC => SENDER
        require(
            BEB20Token2.transfer(_msgSender(), amountToBuy),
            "buyUSDT: Failed to transfer token to user"
        );
    }

    // @dev calculate the tokens to send to the sender
     function USDTSentBuy(uint256 amountOfTokens)
        public
        view
        returns (uint256)
    {
        (address _addr, uint256 _decimal) = getOracle(2);

        // Get the amount of tokens that the user will receive
        uint256 valueUSDTinUSD = amountOfTokens *
            getLatestPrice(_addr, _decimal);

        // token para enviar al sender
        uint256 amountToBuy = valueUSDTinUSD / getPriceToken();

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell  USDT
    function sellUSDT(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "sellUSDT: Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = BEB20Token2.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "sellUSDT: Your balance is lower than the amount of tokens you want to sell"
        );

        // Transfer token to the msg.sender TOKEN =>  SMART CONTRACT
        require(
            BEB20Token2.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToSell
            ),
            "sellUSDT: Failed to transfer tokens from user to vendor"
        );

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToSell);
        require(
            BEB20Token2.transfer(_walletFee, _amountfee),
            "sellUSDT: Failed to transfer token"
        );

        // @dev  token available to send to user
        uint256 tokenSend = tokenAmountToSell - _amountfee;

        /// @dev  Token To Usd
        uint256 tokenToUsd = tokenSend * getPriceToken();

        /// @dev  get price token
        (address _addr, uint256 _decimal) = getOracle(2);
        /// @dev  get value token
        uint256 lastPriceToken = getLatestPrice(_addr, _decimal);

        /// @dev  token To MAtic
        uint256 amountToTransfer = tokenToUsd / lastPriceToken;

        require(
            usdtToken.transfer(_msgSender(), amountToTransfer),
            "Failed to transfer token to user"
        );
    }
}