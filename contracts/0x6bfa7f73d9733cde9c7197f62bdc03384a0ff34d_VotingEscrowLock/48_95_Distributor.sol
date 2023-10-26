//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../../core/dividend/interfaces/IDividendPool.sol";

contract Distributor {
    using SafeERC20 for IERC20;

    IDividendPool public dividendPool;

    function _setup(address _dividendPool) internal {
        dividendPool = IDividendPool(_dividendPool);
    }

    function _distribute(address currency, uint256 amount) internal virtual {
        IERC20(currency).safeApprove(address(dividendPool), amount);
        dividendPool.distribute(currency, amount);
    }
}