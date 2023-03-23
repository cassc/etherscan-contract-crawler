// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../AdapterBase.sol";

/**
// @title Adapter Contract for Paraswap DEX Aggregator.
// @notice Follows AdapterBase interface.
*/
contract ParaswapAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public paraswapTokenTransferProxy;
    address public augustusSwapper;

    /**
    // @dev _paraswapTokenTransferProxy is the adddress that must be approved before calling the swap function
    // @dev _augustusSwapper is the address to which transfer the callData
    */
    constructor(address _dispatcher, address _paraswapTokenTransferProxy, address _augustusSwapper) AdapterBase(_dispatcher) {
        paraswapTokenTransferProxy = _paraswapTokenTransferProxy;
        augustusSwapper = _augustusSwapper;
    }

    function setParaswapAddresses(address _paraswapProxy, address _augustusSwapper) public onlyDispatcher {
        require(_paraswapProxy != address(0) && _augustusSwapper != address(0), "ZERO_ADDRESS_FORBIDDEN");
        paraswapTokenTransferProxy = _paraswapProxy;
        augustusSwapper = _augustusSwapper;
    }

    /**
    // @dev Generic function to call Paraswap swap function
    // @param _fromToken input token address
    // @param _fromAmount input token amount
    // @param _toToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    */
    function callAction(
        address /*_fromUser*/,
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
            IERC20(_fromToken).safeIncreaseAllowance(paraswapTokenTransferProxy, _fromAmount);
            // solhint-disable-next-line
            (success, result) = augustusSwapper.call(_swapCallData);
            IERC20(_fromToken).safeApprove(paraswapTokenTransferProxy, 0);
        } else {
            require(msg.value >= _fromAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = augustusSwapper.call{value: _fromAmount}(_swapCallData);
        }
        require(success, "PARASWAP_SWAP_FAIL");

        (toAmount) = abi.decode(result, (uint256));
    }
}