// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract SwapRouterContract {
    /*
    @notice Runs a swap from 1inch Aggregator and then perform a cross-chain swap
    @param _calldata it is provided by the Swap API as an API input from 1inch in the form of bytes
    */
    function swapRouter(address oneInchRouter, bytes memory _calldata) public {
        (bool success, ) = address(oneInchRouter).call(_calldata);

        if (!success) {
            revert("SWAP_FAILED");
        }
    }
}