// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

import "@openzeppelin/contracts-upgradeable-v4/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ExchangeManagerV2.sol";

contract ExchangeManagerV3 is ExchangeManagerV2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function swap(
        address _router,
        address[][] calldata _paths,
        uint[] calldata _minOutputs,
        address _to
    ) public {
        require(authorizedUsers[msg.sender], "UNAUTHORIZED");

        for (uint256 index = 0; index < _paths.length; ++index) {
            address[] calldata path = _paths[index];
            address fromToken = path[0];
            uint balance = IERC20Upgradeable(fromToken).balanceOf(address(this));

            _approveTokenIfNeeded(
                fromToken,
                _router,
                balance
            );

            IPancakeRouter02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                _minOutputs[index],
                path,
                _to,
                block.timestamp
            );
        }
    }
}