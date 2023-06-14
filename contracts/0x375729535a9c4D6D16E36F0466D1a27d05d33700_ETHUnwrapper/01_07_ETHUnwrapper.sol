// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {IWETH} from "../interfaces/IWETH.sol";
import {IETHUnwrapper} from "../interfaces/IETHUnwrapper.sol";
import {SafeERC20} from "../../../openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract ETHUnwrapper is IETHUnwrapper {
    using SafeERC20 for IWETH;

    IWETH public immutable weth;

    constructor(address _weth) {
        require(_weth != address(0), "Invalid weth address");
        weth = IWETH(_weth);
    }

    function unwrap(uint256 _amount, address _to) external override{
        weth.safeTransferFrom(msg.sender, address(this), _amount);
        weth.withdraw(_amount);
        // transfer out all ETH, include amount tranfered in by accident. We don't want ETH to stuck here forever
        _safeTransferETH(_to, address(this).balance);
    }

    function _safeTransferETH(address _to, uint256 _amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = _to.call{value: _amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    receive() external payable {}
}