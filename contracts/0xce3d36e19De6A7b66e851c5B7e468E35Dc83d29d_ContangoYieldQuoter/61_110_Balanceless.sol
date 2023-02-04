//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/TransferLib.sol";

abstract contract Balanceless {
    using SafeTransferLib for address payable;
    using TransferLib for ERC20;

    event BalanceCollected(address indexed token, address indexed to, uint256 amount);

    /// @dev Contango contracts are never meant to hold a balance.
    function _collectBalance(address token, address payable to, uint256 amount) internal {
        if (token == address(0)) {
            to.safeTransferETH(amount);
        } else {
            ERC20(token).transferOut(address(this), to, amount);
        }
        emit BalanceCollected(token, to, amount);
    }
}