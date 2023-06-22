// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../WHAssetv2.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract (WHETH)
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
contract WHETHv2 is WHAssetv2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address public WETH;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer
    ) public WHAssetv2(_swapRouter, _stablecoin, IToken(_swapRouter.WETH()), _priceProvider, _pool, _whiteOptionsPricer, "Whiteheart Hedged ETH", "WHETH") {
      connectRouter(_swapRouter);
      IERC20(_stablecoin).safeApprove(address(_pool), type(uint256).max);
    }

    receive() payable external {}

    function connectRouter(IUniswapV2Router02 _swapRouter) public onlyOwner {
      WETH = _swapRouter.WETH();
      IERC20(WETH).safeApprove(address(_swapRouter), type(uint256).max);
    }

    /**
     * @notice function to be called by the router after a swap has been completed
     * @param total principal + hedge cost added amount
     * @param protectionPeriod seconds of protection
     * @param to recipient of Hedge Contract (onBehalfOf)
     * @param mintToken whether to mintToken or not
     * @return newTokenId new hedge contract id
     */
    function wrapAfterSwap(uint total, uint protectionPeriod, address to, bool mintToken, uint minUSDCPremium) external onlyRouter override returns (uint newTokenId) {
        uint amountToWrap = whiteOptionsPricer.getAmountToWrapFromTotal(total, protectionPeriod);
        newTokenId = _wrap(amountToWrap, protectionPeriod, to, false, mintToken, minUSDCPremium);
    }

    /**
     * @notice internal function that supports the receival of principal+hedge cost to be sent
     * @param from address sender
     * @param amount principal to receive
     * @param toUsdc hedgeCost
     */
    function _receiveAsset(address from, uint amount, uint toUsdc) internal override {
        uint received = msg.value;
        require(received >= amount.add(toUsdc), "!wrong value");
        if(received > amount.add(toUsdc)) payable(from).transfer(received.sub(amount.add(toUsdc)));
        IWETH(WETH).deposit{value:amount.add(toUsdc)}();
    }

    /**
     * @notice internal function of support that sends the principal that was protected
     * @param to receiver of principal
     * @param amount principal that has been protected
     */
    function _sendTotal(address payable to, uint amount) internal override {
        IWETH(WETH).withdraw(amount);
        to.transfer(amount);
    }
}