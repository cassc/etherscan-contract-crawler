// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";

contract OneInchAdapter is AdapterBase {
    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "1InchAdapter")
    {}

    address public constant oneInchRouter =
        0x1111111254fb6c44bAC0beD2854e76F90643097d;

    /// @dev Swap.
    /// @param callArgs The args needed for swapping.
    /// @param amountETH ETH amount. If swap ETH for other token, amountETH is the amount to swap.
    /// Else amountETH is 0.
    function swap(bytes memory callArgs, uint256 amountETH)
        external
        onlyDelegation
    {
        (bool success, bytes memory returnData) = oneInchRouter.call{
            value: amountETH
        }(callArgs);
        require(success, string(returnData));
    }
}