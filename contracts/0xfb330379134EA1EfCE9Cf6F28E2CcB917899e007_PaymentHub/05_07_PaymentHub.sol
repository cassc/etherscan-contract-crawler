/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2021 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "../utils/Address.sol";
import "../ERC20/IERC20.sol";
import "./IUniswapV3.sol";
import "../utils/Ownable.sol";
import "./IBrokerbot.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * A hub for payments. This allows tokens that do not support ERC 677 to enjoy similar functionality,
 * namely interacting with a token-handling smart contract in one transaction, without having to set an allowance first.
 * Instead, an allowance needs to be set only once, namely for this contract.
 * Further, it supports automatic conversion from Ether to the payment currency through Uniswap or the reception of Ether
 * using the current exchange rate as found in the chainlink oracle.
 */
contract PaymentHub {

    uint24 private constant DEFAULT_FEE = 3000;
    uint256 private constant DENOMINATOR = 1e8;
    address private constant CHF_TOKEN = 0xB4272071eCAdd69d933AdcD19cA99fe80664fc08;

    uint8 private constant KEEP_ETHER = 0x4; // copied from brokerbot
    
    IQuoter private immutable uniswapQuoter;
    ISwapRouter private immutable uniswapRouter;
    AggregatorV3Interface internal immutable priceFeedCHFUSD;
    AggregatorV3Interface internal immutable priceFeedETHUSD;

    constructor(IQuoter _quoter, ISwapRouter swapRouter, AggregatorV3Interface _aggregatorCHFUSD, AggregatorV3Interface _aggregatorETHUSD) {
        uniswapQuoter = _quoter;
        uniswapRouter = swapRouter;
        priceFeedCHFUSD = _aggregatorCHFUSD;
        priceFeedETHUSD = _aggregatorETHUSD;
    }

    /*  
     * Get price in ERC20
     * This is the method that the Brokerbot widget should use to quote the price to the user.
     * @param amountInBase The amount of the base currency for the exact output.
     * @param path The encoded path of the swap from erc20 to base.
     * @return amount quoted to pay
     */
    function getPriceInERC20(uint256 amountInBase, bytes memory path) public returns (uint256) {
        return uniswapQuoter.quoteExactOutput(
            path,
            amountInBase
        );
    }

    /**
     * Get price in Ether depding on brokerbot setting.
     * If keep ETH is set price is from oracle.
     * This is the method that the Brokerbot widget should use to quote the price to the user.
     * @return The price in wei.
     */
    function getPriceInEther(uint256 amountInBase, IBrokerbot brokerBot) public returns (uint256) {
        if ((address(brokerBot) != address(0)) && hasSettingKeepEther(brokerBot)) {
            return getPriceInEtherFromOracle(amountInBase, IBrokerbot(brokerBot).base());
        } else {
            return uniswapQuoter.quoteExactOutputSingle(uniswapQuoter.WETH9(), address(brokerBot.base()), DEFAULT_FEE, amountInBase, 0);
        }
    }

    /**
     * Price in ETH with 18 decimals
     */
    function getPriceInEtherFromOracle(uint256 amountInBase, IERC20 base) public view returns (uint256) {
        if(address(base) == CHF_TOKEN) {
            return getLatestPriceCHFUSD() * amountInBase / getLatestPriceETHUSD();
        } else {
            return amountInBase * DENOMINATOR / getLatestPriceETHUSD();
        }
    }

    /**
     * Returns the latest price of eth/usd pair from chainlink with 8 decimals
     */
    function getLatestPriceETHUSD() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedETHUSD.latestRoundData();
        return uint256(price);
    }

    /**
     * Returns the latest price of chf/usd pair from chainlink with 8 decimals
     */
    function getLatestPriceCHFUSD() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedCHFUSD.latestRoundData();
        return uint256(price);
    }

    /**
     * Convenience method to swap ether into base and pay a target address
     */
    function payFromEther(address recipient, uint256 amountInBase, IERC20 base) public payable {
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            // rely on time stamp is ok, no exact time stamp needed
            // solhint-disable-next-line not-rely-on-time
            uniswapQuoter.WETH9(), address(base), DEFAULT_FEE, recipient, block.timestamp, amountInBase, msg.value, 0);

        ISwapRouter swapRouter = uniswapRouter;
        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        uint256 amountIn = swapRouter.exactOutputSingle{value: msg.value}(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < msg.value) {
            swapRouter.refundETH();
            (bool success, ) = msg.sender.call{value:msg.value - amountIn}(""); // return change
            require(success, "Transfer failed.");
        }
    }

    /// @dev The calling address must approve this contract to spend its ERC20 for this function to succeed. As the amount of input ERC20 is variable,
    /// the calling address will need to approve for a slightly higher or infinit amount, anticipating some variance.
    /// @param amountOut The desired amount of baseCurrency.
    /// @param amountInMaximum The maximum amount of ERC20 willing to be swapped for the specified amountOut of baseCurrency.
    /// @param erc20In The address of the erc20 token to pay with.
    /// @param path The encoded path of the swap from erc20 to base.
    /// @param recipient The reciving address - brokerbot.
    /// @return amountIn The amountIn of ERC20 actually spent to receive the desired amountOut.
    function payFromERC20(uint256 amountOut, uint256 amountInMaximum, address erc20In, bytes memory path, address recipient) public returns (uint256 amountIn) {
        ISwapRouter swapRouter = uniswapRouter;
        // Transfer the specified `amountInMaximum` to this contract.
        IERC20(erc20In).transferFrom(msg.sender, address(this), amountInMaximum);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        ISwapRouter.ExactOutputParams memory params =
            ISwapRouter.ExactOutputParams({
                path: path,
                recipient: recipient,
                // solhint-disable-next-line not-rely-on-time
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            IERC20(erc20In).transfer(msg.sender, amountInMaximum - amountIn);
        }
    }

    ///This function appoves infinite allowance for Uniswap, this is safe as the paymenthub should never hold any token (see also recover() ).
    ///@dev This function needs to be called before using the PaymentHub the first time with a new ERC20 token.
    ///@param erc20In The erc20 addresse to approve.
    function approveERC20(address erc20In) external {
        IERC20(erc20In).approve(address(uniswapRouter), 0x8000000000000000000000000000000000000000000000000000000000000000);
    }

    function multiPay(IERC20 token, address[] calldata recipients, uint256[] calldata amounts) public {
        for (uint i=0; i<recipients.length; i++) {
            require(IERC20(token).transferFrom(msg.sender, recipients[i], amounts[i]));
        }
    }

    /**
     * Can (at least in theory) save some gas as the sender balance only is touched in one transaction.
     */
    function multiPayAndNotify(IERC20 token, address[] calldata recipients, uint256[] calldata amounts, bytes calldata ref) external {
        for (uint i=0; i<recipients.length; i++) {
            payAndNotify(token, recipients[i], amounts[i], ref);
        }
    }

    // Allows to make a payment from the sender to an address given an allowance to this contract
    // Equivalent to xchf.transferAndCall(recipient, amountInBase)
    function payAndNotify(address recipient, uint256 amountInBase, bytes calldata ref) external {
        payAndNotify(IBrokerbot(recipient).base(), recipient, amountInBase, ref);
    }

    function payAndNotify(IERC20 token, address recipient, uint256 amount, bytes calldata ref) public {
        require(IERC20(token).transferFrom(msg.sender, recipient, amount));
        IBrokerbot(recipient).processIncoming(token, msg.sender, amount, ref);
    }

    function payFromEtherAndNotify(IBrokerbot recipient, uint256 amountInBase, bytes calldata ref) external payable {
        IERC20 base = recipient.base();
        // Check if the brokerbot has setting to keep ETH
        if (hasSettingKeepEther(recipient)) {
            uint256 priceInEther = getPriceInEtherFromOracle(amountInBase, base);
            recipient.processIncoming{value: priceInEther}(base, msg.sender, amountInBase, ref);

            // Pay back ETH that was overpaid
            if (priceInEther < msg.value) {
                (bool success, ) = msg.sender.call{value:msg.value - priceInEther}(""); // return change
                require(success, "Transfer failed.");
            }

        } else {
            payFromEther(address(recipient), amountInBase, base);
            recipient.processIncoming(base, msg.sender, amountInBase, ref);
        }
    }

    /***
     * Pay from any ERC20 token (which has Uniswapv3 ERC20-ETH pool) and send swapped base currency to brokerbot.
     * The needed amount needs to be approved at the ERC20 contract beforehand
     */
    function payFromERC20AndNotify(address recipient, uint256 amountBase, address erc20, uint256 amountInMaximum, bytes memory path, bytes calldata ref) external {
        IERC20 base = IBrokerbot(recipient).base();
        uint256 balanceBefore = IERC20(base).balanceOf(recipient);
        payFromERC20(amountBase, amountInMaximum, erc20, path, recipient);
        uint256 balanceAfter = IERC20(base).balanceOf(recipient);
        require(amountBase == (balanceAfter - balanceBefore), "swap error");
        IBrokerbot(recipient).processIncoming(base, msg.sender, balanceAfter - balanceBefore, ref);
    }

    /**
     * Checks if the recipient(brokerbot) has setting enabled to keep ether
     */
    function hasSettingKeepEther(IBrokerbot recipient) public view returns (bool) {
        return recipient.settings() & KEEP_ETHER == KEEP_ETHER;
    }

    /**
     * In case tokens have been accidentally sent directly to this contract.
     * Make sure to be fast as anyone can call this!
     */
    function recover(IERC20 ercAddress, address to, uint256 amount) external {
        require(ercAddress.transfer(to, amount));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Important to receive ETH refund from Uniswap
    }
}