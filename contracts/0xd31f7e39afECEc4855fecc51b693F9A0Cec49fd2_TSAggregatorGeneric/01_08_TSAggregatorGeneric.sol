// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { SafeTransferLib } from "../lib/SafeTransferLib.sol";
import { TSAggregator } from "./TSAggregator.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IThorchainRouter } from "./interfaces/IThorchainRouter.sol";
import { TSAggregatorTokenTransferProxy } from './TSAggregatorTokenTransferProxy.sol';

contract TSAggregatorGeneric is TSAggregator {
    using SafeTransferLib for address;

    constructor(address _ttp) TSAggregator(_ttp) {
    }

    // Use 1inch's swap API endpoint to get data to send
    // e.g. https://api.1inch.io/v4.0/1/swap?toTokenAddress=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&fromTokenAddress=0x111111111117dc0aa78b770fa6a738034120c302&amount=10000000000000000&fromAddress=0x2f8aedd149afbdb5206ecaf8b1a3abb9186c8053&slippage=1&disableEstimate=true
    // toTokenAddress needs to be 0xeeee so ETH is sent back to swapIn
    // fromAddress needs to be the address of this contract
    // disableEstimate makes the API return a result even if there's no token balance in the contract
    function swapIn(
        address tcRouter,
        address tcVault,
        string calldata tcMemo,
        address token,
        uint amount,
        address router,
        bytes calldata data,
        uint deadline
    ) public nonReentrant {
        require(router != address(tokenTransferProxy), "no calling ttp");
        tokenTransferProxy.transferTokens(token, msg.sender, address(this), amount);
        token.safeApprove(address(router), 0); // USDT quirk
        token.safeApprove(address(router), amount);

        (bool success,) = router.call(data);
        require(success, "failed to swap");

        uint256 amountOut = address(this).balance;
        amountOut = skimFee(amountOut);
        IThorchainRouter(tcRouter).depositWithExpiry{value: amountOut}(
            payable(tcVault),
            address(0), // ETH
            amountOut,
            tcMemo,
            deadline
        );
    }
}