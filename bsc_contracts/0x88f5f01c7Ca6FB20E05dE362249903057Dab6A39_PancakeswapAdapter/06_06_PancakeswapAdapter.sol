// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdapterBase.sol";

/**
// @title Adapter Contract for Pancakeswap DEX.
// @notice Follows AdapterBase interface.
*/
contract PancakeswapAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public pancakeRouter;

    constructor(address _dispatcher, address _pancakeRouter) AdapterBase(_dispatcher) {
        pancakeRouter = _pancakeRouter;
    }

    function setPancakeRouter(address _pancakeRouter) public onlyDispatcher {
        require(_pancakeRouter != address(0), "ZERO_ADDRESS_FORBIDDEN");
        pancakeRouter = _pancakeRouter;
    }

    /**
    // @dev generic function to call pancake swap function
    // @param fromUser wallet address requesting the swap
    // @param _fromToken input token address
    // @param _fromAmount input token amount
    // @param _toToken output token address
    // @param _swapCallData swap callData (intended for pancake router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    */
    function callAction(
        address fromUser,
        address _fromToken,
        uint256 _fromAmount,
        address _toToken,
        bytes memory _swapCallData
    ) public payable override onlyDispatcher returns (uint256 toAmount){
        require(_fromToken != address(0) && _toToken != address(0), "INVALID_ASSET_ADDRESS");
        bool success;
        bytes memory result;
        
        if (_fromToken != NATIVE) {
            require(IERC20(_fromToken).balanceOf(address(this)) >= _fromAmount, "UNAVAILABLE_FUNDS");
            IERC20(_fromToken).safeIncreaseAllowance(pancakeRouter, _fromAmount);
            // solhint-disable-next-line
            (success, result) = pancakeRouter.call(_swapCallData);
            IERC20(_fromToken).safeApprove(pancakeRouter, 0);
        } else {
            require(msg.value >= _fromAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = pancakeRouter.call{value: _fromAmount}(_swapCallData);
        }
        require(success, "PANCAKESWAP_SWAP_FAIL");

        (uint[] memory returnAmounts) = abi.decode(result, (uint[]));
        toAmount = returnAmounts[returnAmounts.length - 1];

        if (_toToken != NATIVE) {
            IERC20(_toToken).safeTransfer(fromUser, toAmount);
        } else {
            payable(fromUser).transfer(toAmount);
        }
    }
}