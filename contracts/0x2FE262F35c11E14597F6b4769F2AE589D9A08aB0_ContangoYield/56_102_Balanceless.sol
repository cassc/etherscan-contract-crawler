//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/TransferLib.sol";

abstract contract Balanceless {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using TransferLib for IERC20;

    event BalanceCollected(address indexed token, address indexed to, uint256 amount);

    /// @dev Contango contracts are never meant to hold a balance (apart from dust for gas optimisations).
    /// Given we interact with third parties, we may get airdrops, rewards or be sent money by mistake, this function can be use to recoup them
    function _collectBalance(address token, address payable to, uint256 amount) internal {
        if (token == address(0)) {
            to.sendValue(amount);
        } else {
            IERC20(token).transferOut(address(this), to, amount);
        }
        emit BalanceCollected(token, to, amount);
    }
}