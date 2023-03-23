// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdapterBase.sol";

/**
// @title Adapter Contract for li.fi DEX Aggregator.
// @notice Follows AdapterBase interface.
*/
contract LiFiAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public lifiDiamond;

    constructor(address _dispatcher, address _lifiDiamond) AdapterBase(_dispatcher) {
        lifiDiamond = _lifiDiamond;
    }

    function setLiFiDiamond(address _lifiDiamond) public onlyDispatcher {
        require(_lifiDiamond != address(0), "ZERO_ADDRESS_FORBIDDEN");
        lifiDiamond = _lifiDiamond;
    }

    /**
    // @dev Generic function to call 1inch swap function
    // @param _fromUser wallet address of user requesting the swap
    // @param _fromToken input token address
    // @param _fromAmount input token amount
    // @param _toToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    // @dev LiFi API parameter "toAddress" must be set to the wallet address requesting the swap
    */
    function callAction(
    address _fromUser,
    address _fromToken,
    uint256 _fromAmount,
    address _toToken,
    bytes memory _swapCallData
    ) public payable override onlyDispatcher returns (uint256 returnAmount){
        require(_fromToken != address(0) && _toToken != address(0), "INVALID_ASSET_ADDRESS");
        bool success;

        uint256 balanceBefore;
        if (_toToken != NATIVE) {
            balanceBefore = IERC20(_toToken).balanceOf(address(_fromUser));
        } else {
            balanceBefore = address(_fromUser).balance;
        }

        if (_fromToken != NATIVE) {
            require(IERC20(_fromToken).balanceOf(address(this)) >= _fromAmount, "UNAVAILABLE_FUNDS");
            IERC20(_fromToken).safeIncreaseAllowance(lifiDiamond, _fromAmount);
            // solhint-disable-next-line
            (success, ) = lifiDiamond.call(_swapCallData);
            IERC20(_fromToken).safeApprove(lifiDiamond, 0);
        } else {
            require(msg.value >= _fromAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, ) = lifiDiamond.call{value: _fromAmount}(_swapCallData);
        }
        require(success, "LiFi_SWAP_FAIL");

        uint256 balanceAfter;
        if (_toToken != NATIVE) {
            balanceAfter = IERC20(_toToken).balanceOf(address(_fromUser));
        } else {
            balanceAfter = address(_fromUser).balance;
        }

        returnAmount = balanceAfter - balanceBefore;
    }
}