// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./BitClusterNordToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BitClusterNordCrowdsale is Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for BitClusterNordToken;

    // token being sold
    BitClusterNordToken public immutable token;

    // investments are only allowed before endTime timestamp
    uint public immutable endTime;

    // how many tokens a buyer gets per USD
    uint public immutable rate;

    /**
     * Token purchase event.
     * @param purchaser - who paid for the tokens
     * @param amount - amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 amount);

    // funds collected from the crowdsale are transferred to this wallet
    address payable private outputWallet;
    // ETH/USD exchange rate feed address
    AggregatorV3Interface private immutable ethUsdExchangeRateFeed;
    // USDT token address (or alternative test token on testnets)
    IERC20Metadata private immutable usdt;

    constructor(
        BitClusterNordToken _token,
        uint _endTime,
        uint _rate,
        address payable _outputWallet,
        address _ethUsdExchangeRateFeedAddress,
        address _usdtContractAddress
    ) {
        token = _token;
        endTime = _endTime;
        rate = _rate;
        outputWallet = _outputWallet;
        ethUsdExchangeRateFeed = AggregatorV3Interface(_ethUsdExchangeRateFeedAddress);
        usdt = IERC20Metadata(_usdtContractAddress);
    }

    /**
     * Amount of tokens remaining to be sold.
     */
    function remainingSupply() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    receive() external payable {
        buyTokensWithETH();
    }

    /**
     * Pay ETH to buy tokens.
     */
    function buyTokensWithETH() public whenNotPaused nonReentrant payable {
        // get latest ETH/USD rate
        (
            , // roundID,
            int ethUsdExchangeRate,
            , // startedAt,
            , // timeStamp,
            // answeredInRound
        ) = ethUsdExchangeRateFeed.latestRoundData();

        // calculate purchased token amount
        uint tokenAmount = msg.value * uint(ethUsdExchangeRate) * rate / (10**ethUsdExchangeRateFeed.decimals());

        validatePurchase(tokenAmount);

        deliverTokens(msg.sender, tokenAmount);

        (bool sent,) = outputWallet.call { value: msg.value }("");
        require(sent, "BCND: failed to send ETH");
    }

    /**
     * Pay USDT to buy tokens.
     * Purchaser must first approve USDT withdrawal to the crowdsale address.
     * @param usdtAmount - amount of USDT tokens
     */
    function buyTokensWithUSDT(uint usdtAmount) external whenNotPaused nonReentrant {
        // withdraw usdt and send it to outputWallet
        usdt.safeTransferFrom(msg.sender, outputWallet, usdtAmount);

        // calculate purchased token amount
        uint tokenAmount = usdtAmount * 10**(18-usdt.decimals()) * rate;

        validatePurchase(tokenAmount);

        deliverTokens(msg.sender, tokenAmount);
    }

    /**
     * Validate the incoming purchase request.
     */
    function validatePurchase(uint tokenAmount) internal view {
        require(!paused(), "BCND: sale is paused");
        require(block.timestamp <= endTime, "BCND: sale has ended");
        require(tokenAmount > 0, "BCND: amount must be > 0");
        require(token.balanceOf(address(this)) >= tokenAmount, "BCND: sale limit exceeded");
    }

    /**
     * Deliver tokens to the purchaser.
     */
    function deliverTokens(address purchaser, uint tokenAmount) internal {
        token.safeTransfer(purchaser, tokenAmount);
        emit TokenPurchase(purchaser, tokenAmount);
    }

    /**
     * Output wallet update event
     * @param outputWallet - new output wallet
     */
    event OutputWalletUpdate(address indexed outputWallet);
    function setOutputWallet(address payable _outputWallet) external onlyOwner {
        outputWallet = _outputWallet;
        emit OutputWalletUpdate(_outputWallet);
    }

    /**
     * Pauses all token purchases.
     * See {ERC20Pausable} and {Pausable-_pause}.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * Unpauses all token purchases.
     * See {ERC20Pausable} and {Pausable-_unpause}.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
     * This function is needed to allow withdrawal of ERC20 funds that may be accidentally sent to this contract.
     */
    function withdrawAnyERC20Token(address tokenAddress, address to, uint amount) external onlyOwner nonReentrant {
        IERC20Metadata(tokenAddress).safeTransfer(to, amount);
    }

}