// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IBuyETHCallback } from './IBuyETHCallback.sol';

contract ArbitrageBot is IBuyETHCallback {
    uint256 private constant WAD = 1e18;

    /// @notice Called on the {to} in TokenBuyer#buyETH, with `msg.value` ETH payment in exchange for {amount} TokenBuyer#paymentToken.
    /// @param sender the `msg.sender` in TokenBuyer#buyETH
    /// @param data arbitrary data passed through by the caller via the TokenBuyer#buyETH call
    /// @dev No ETH should be left in this contract following execution. Anyone can steal it.
    function buyETHCallback(
        address sender,
        uint256,
        bytes calldata data
    ) external payable {
        (address to, bytes memory cdata, uint256 minProfit, uint256 minerCutRate) = abi.decode(
            data,
            (address, bytes, uint256, uint256)
        );
        assembly {
            // Trade ETH for tokens. Revert on failure.
            // This call assumes leftover ETH will be returned to this contract.
            if iszero(call(gas(), to, selfbalance(), add(cdata, 0x20), mload(cdata), 0, 0)) {
                let free_mem_ptr := mload(64)
                let size := returndatasize()
                returndatacopy(free_mem_ptr, 0, size)
                revert(free_mem_ptr, size)
            }

            // Bribe miner if the miner cut rate is greater than 0.
            if gt(minerCutRate, 0) {
                pop(call(gas(), coinbase(), div(mul(selfbalance(), minerCutRate), WAD), 0, 0, 0, 0))
            }

            // Revert if the remaining ETH is below the min profit threshold.
            if lt(selfbalance(), minProfit) {
                let free_mem_ptr := mload(64)
                // BelowProfitThreshold()
                mstore(free_mem_ptr, 0x211e44fd00000000000000000000000000000000000000000000000000000000)
                revert(free_mem_ptr, 4)
            }

            // Transfer ETH profit to `TokenBuyer#buyETH` caller.
            pop(call(gas(), sender, selfbalance(), 0, 0, 0, 0))
        }
    }

    // Receive leftover ETH from the arb.
    receive() external payable {}
}
