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
    // @param fromUser wallet address requesting the swap
    // @param _inputToken input token address
    // @param _inputTokenAmount input token amount
    // @param _outputToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    */
    function callAction(
        address fromUser,
        address _inputToken,
        uint256 _inputTokenAmount,
        address _outputToken,
        bytes memory _swapCallData
    ) public payable override onlyDispatcher {
        require(_inputToken != address(0) && _outputToken != address(0), "INVALID_ASSET_ADDRESS");
        bool success;
        bytes memory result;

        if (_inputToken != NATIVE) {
            require(IERC20(_inputToken).balanceOf(address(this)) >= _inputTokenAmount, "UNAVAILABLE_FUNDS");
            IERC20(_inputToken).safeIncreaseAllowance(zeroXRouter, _inputTokenAmount);
            // solhint-disable-next-line
            (success, result) = zeroXRouter.call(_swapCallData);
            IERC20(_inputToken).safeApprove(zeroXRouter, 0);
        } else {
            require(msg.value >= _inputTokenAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = zeroXRouter.call{value: _inputTokenAmount}(_swapCallData);
        }
        require(success, "ZERO_X_SWAP_FAIL");

        (uint256 returnAmount) = abi.decode(result, (uint256));
        
        if (_outputToken != NATIVE) {
            IERC20(_outputToken).safeTransfer(fromUser, returnAmount);
        } else {
            payable(fromUser).transfer(returnAmount);
        }
        
        emit Swap(fromUser, _inputToken, _inputTokenAmount, _outputToken, returnAmount);
    }
}