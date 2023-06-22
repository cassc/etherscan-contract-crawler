// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "../WHAssetv2.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @author jmonteer
 * @title Whiteheart's Hedge Contract (Any ERC20)
 * @notice WHAsset implementation. Hedge contract: Wraps an amount of the underlying asset with an ATM put option (or other protection instrument)
 */
contract WHERC20v2 is WHAssetv2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable token;

    constructor(
            IUniswapV2Router02 _swapRouter,
            IToken _stablecoin,
            IToken _token,
            AggregatorV3Interface _priceProvider,
            IWhiteUSDCPool _pool,
            IWhiteOptionsPricer _whiteOptionsPricer,
            string memory _name,
            string memory _symbol
    ) public WHAssetv2(_swapRouter, _stablecoin, _token, _priceProvider, _pool, _whiteOptionsPricer, _name, _symbol) {
        token = _token;

        IERC20(_stablecoin).safeApprove(address(_pool), type(uint256).max);
        IERC20(_token).safeApprove(address(_swapRouter), type(uint256).max);
    }

    function wrap(uint128 amount, uint period, address to, bool _mintToken, uint minPremiumUSDC) payable public override returns (uint newTokenId) {
        require(msg.value == 0, "!eth not accepted");
        newTokenId = super.wrap(amount, period, to, _mintToken, minPremiumUSDC);
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
        token.safeTransferFrom(from, address(this), amount.add(toUsdc));
    }

    /**
     * @notice internal function of support that sends the principal that was protected
     * @param to receiver of principal
     * @param amount principal that has been protected
     */
    function _sendTotal(address payable to, uint amount) internal override {
        token.safeTransfer(to, amount);
    }
}