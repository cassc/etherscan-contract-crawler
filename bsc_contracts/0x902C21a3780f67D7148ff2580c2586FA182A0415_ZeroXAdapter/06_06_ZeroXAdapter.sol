// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdapterBase.sol";

/**
// @title Adapter Contract for 0x DEX Aggregator.
// @notice Follows AdapterBase interface.
*/
contract ZeroXAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public zeroXRouter;

    constructor(address _dispatcher, address _zeroXRouter) AdapterBase(_dispatcher) {
        zeroXRouter = _zeroXRouter;
    }

    function setZeroXRouter(address _zeroXRouter) public onlyDispatcher {
        require(_zeroXRouter != address(0), "ZERO_ADDRESS_FORBIDDEN");
        zeroXRouter = _zeroXRouter;
    }

    /**
    // @dev Generic function to call 0x swap function
    // @param _fromUser wallet address of user requesting the swap
    // @param _fromToken input token address
    // @param _fromAmount input token amount
    // @param _toToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    */
    function callAction(
        address _fromUser,
        address _fromToken,
        uint256 _fromAmount,
        address _toToken,
        bytes memory _swapCallData
    ) public payable override onlyDispatcher returns (uint256 toAmount) {
        require(_fromToken != address(0) && _toToken != address(0), "INVALID_ASSET_ADDRESS");
        bool success;
        bytes memory result;

        if (_fromToken != NATIVE) {
            require(IERC20(_fromToken).balanceOf(address(this)) >= _fromAmount, "UNAVAILABLE_FUNDS");
            IERC20(_fromToken).safeIncreaseAllowance(zeroXRouter, _fromAmount);
            // solhint-disable-next-line
            (success, result) = zeroXRouter.call(_swapCallData);
            IERC20(_fromToken).safeApprove(zeroXRouter, 0);
        } else {
            require(msg.value >= _fromAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = zeroXRouter.call{value: _fromAmount}(_swapCallData);
        }
        require(success, "ZERO_X_SWAP_FAIL");

        (toAmount) = abi.decode(result, (uint256));
        
        if (_toToken != NATIVE) {
            IERC20(_toToken).safeTransfer(_fromUser, toAmount);
        } else {
            payable(_fromUser).transfer(toAmount);
        }
    }
}