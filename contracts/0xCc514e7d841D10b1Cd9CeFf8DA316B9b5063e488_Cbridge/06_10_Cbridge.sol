// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {DefiOp} from "../DefiOp.sol";
import {Bridge} from "./Bridge.sol";
import {ICbridge} from "../interfaces/external/ICbridge.sol";

contract Cbridge is Bridge, DefiOp {
    using SafeERC20 for IERC20;

    ICbridge public immutable cbridge;

    constructor(ICbridge cbridge_) {
        cbridge = cbridge_;
    }

    /**
     * @notice Bridge ERC20 token to another chain
     * @dev This function bridge all token on balance to owner address
     * @param token ERC20 token address
     * @param slippage Max slippage, * 1M, eg. 0.5% -> 5000
     * @param chainId Destination chain id.
     */
    function useCbridge(
        IERC20 token,
        uint32 slippage,
        uint64 chainId
    ) external checkChainId(chainId) onlyOwner {
        uint256 tokenAmount = token.balanceOf(address(this));

        token.safeApprove(address(cbridge), tokenAmount);
        cbridge.send(
            owner,
            address(token),
            tokenAmount,
            chainId,
            uint64(block.timestamp * 1000),
            slippage
        );
    }
}