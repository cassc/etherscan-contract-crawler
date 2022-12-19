// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdapterBase.sol";

/**
// @title Adapter Contract for 1inch DEX Aggregator.
// @notice Follows AdapterBase interface.
*/
contract OneInchAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public oneInchRouter;

    constructor(address _dispatcher, address _oneInchRouter) AdapterBase(_dispatcher) {
        oneInchRouter = _oneInchRouter;
    }

    function setOneInchRouter(address _oneInchRouter) public onlyDispatcher {
        require(_oneInchRouter != address(0), "ZERO_ADDRESS_FORBIDDEN");
        oneInchRouter = _oneInchRouter;
    }

    /**
    // @dev Generic function to call 1inch swap function
    // @param fromUser wallet address requesting the swap
    // @param _inputToken input token address
    // @param _inputTokenAmount input token amount
    // @param _outputToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    // @dev 1inch API parameter "destReceiver" must be set to the wallet address requesting the swap
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
            IERC20(_inputToken).safeIncreaseAllowance(oneInchRouter, _inputTokenAmount);
            // solhint-disable-next-line
            (success, result) = oneInchRouter.call(_swapCallData);
            IERC20(_inputToken).safeApprove(oneInchRouter, 0);
        } else {
            require(msg.value >= _inputTokenAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = oneInchRouter.call{value: _inputTokenAmount}(_swapCallData);
        }
        require(success, "ONE_INCH_SWAP_FAIL");

        (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
        
        emit Swap(fromUser, _inputToken, _inputTokenAmount, _outputToken, returnAmount);
    }
}