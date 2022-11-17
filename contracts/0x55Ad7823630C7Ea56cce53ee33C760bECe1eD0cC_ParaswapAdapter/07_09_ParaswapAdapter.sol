// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";

contract ParaswapAdapter is AdapterBase {
    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "ParaswapAdapter")
    {}

    address public constant AugustusSwapper =
        0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    function swap(bytes memory callArgs, uint256 amountETH)
        external
        onlyDelegation
    {
        (bool success, bytes memory returnData) = AugustusSwapper.call{
            value: amountETH
        }(callArgs);
        require(success, string(returnData));
    }
}