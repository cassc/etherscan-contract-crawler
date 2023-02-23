// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/utils/SafeTransferLib.sol";

import "./Pair.sol";

/// @title CaviarZapRouter
/// @author out.eth
/// @notice This contract is used to buy and add NFTs on deposit or remove and
///         sell NFTs on withdraw in a single transaction.
contract CaviarZapRouter is ERC721TokenReceiver {
    using SafeTransferLib for address;

    struct BuyParams {
        uint256 outputAmount;
        uint256 maxInputAmount;
        uint256 deadline;
    }

    struct AddParams {
        uint256 baseTokenAmount;
        uint256 fractionalTokenAmount;
        uint256 minLpTokenAmount;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 deadline;
    }

    struct RemoveParams {
        uint256 lpTokenAmount;
        uint256 minBaseTokenOutputAmount;
        uint256 minFractionalTokenOutputAmount;
        uint256 deadline;
    }

    struct SellParams {
        uint256 inputAmount;
        uint256 minOutputAmount;
        uint256 deadline;
    }

    receive() external payable {}

    function buyAndAdd(address pair, BuyParams calldata buyParams, AddParams calldata addParams)
        public
        payable
        returns (uint256 inputAmount, uint256 lpTokenAmount)
    {
        // buy some fractional tokens
        inputAmount = Pair(pair).buy{value: buyParams.maxInputAmount}(
            buyParams.outputAmount, buyParams.maxInputAmount, buyParams.deadline
        );

        // add fractional tokens and eth
        lpTokenAmount = Pair(pair).add{value: address(this).balance}(
            addParams.baseTokenAmount,
            addParams.fractionalTokenAmount,
            addParams.minLpTokenAmount,
            addParams.minPrice,
            addParams.maxPrice,
            addParams.deadline
        );

        // send the LP tokens to the caller
        // transfer the LP tokens to this contract
        LpToken lpToken = LpToken(Pair(pair).lpToken());
        lpToken.transfer(msg.sender, lpTokenAmount);
    }

    function removeAndSell(address pair, RemoveParams calldata removeParams, SellParams calldata sellParams)
        public
        returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount, uint256 outputAmount)
    {
        // transfer the LP tokens to this contract
        LpToken lpToken = LpToken(Pair(pair).lpToken());
        lpToken.transferFrom(msg.sender, address(this), removeParams.lpTokenAmount);

        // remove fractional and base tokens
        (baseTokenOutputAmount, fractionalTokenOutputAmount) = Pair(pair).remove(
            removeParams.lpTokenAmount,
            removeParams.minBaseTokenOutputAmount,
            removeParams.minFractionalTokenOutputAmount,
            removeParams.deadline
        );

        // sell the fractional tokens
        outputAmount = Pair(pair).sell(sellParams.inputAmount, sellParams.minOutputAmount, sellParams.deadline);

        // send the ETH to the caller
        msg.sender.safeTransferETH(address(this).balance);
    }
}