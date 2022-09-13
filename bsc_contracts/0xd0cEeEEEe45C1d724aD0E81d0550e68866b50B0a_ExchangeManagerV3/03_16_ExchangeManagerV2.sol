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

import "./ExchangeManager.sol";

contract ExchangeManagerV2 is ExchangeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) public authorizedUsers;

    function swap(
        address[][] calldata _paths,
        address _router,
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

            _swap(
                _router,
                _to,
                path,
                balance
            );
        }
    }

    function collect(address _token) public {
        require(authorizedUsers[msg.sender], "UNAUTHORIZED");

        IERC20Upgradeable(_token).safeTransfer(
            owner(),
            IERC20Upgradeable(_token).balanceOf(address(this))
        );
    }

    function setAuthorization(address _user, bool _value) public onlyOwner {
        authorizedUsers[_user] = _value;
    }
}