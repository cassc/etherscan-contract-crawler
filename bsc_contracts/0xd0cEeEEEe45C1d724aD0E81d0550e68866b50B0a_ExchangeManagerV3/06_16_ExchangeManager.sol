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
import "@openzeppelin/contracts-upgradeable-v4/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable-v4/access/OwnableUpgradeable.sol";
import "./interfaces/IPancakeRouter02.sol";

contract ExchangeManager is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
        address _owner
    ) public initializer {
        __Ownable_init();

        transferOwnership(_owner);
    }

    function swap(
        address[] calldata _tokens,
        address _router,
        address _wantToken,
        address _to
    ) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; ++index) {
            address fromToken = _tokens[index];
            uint balance = IERC20Upgradeable(fromToken).balanceOf(address(this));

            _approveTokenIfNeeded(
                fromToken,
                _router,
                balance
            );

            _swap(
                _router,
                _to,
                _getPath(fromToken, _wantToken),
                balance
            );
        }
    }

    function _approveTokenIfNeeded(
        address _token,
        address _router,
        uint _amount
    ) internal virtual {
        if (IERC20Upgradeable(_token).allowance(address(this), _router) < _amount) {
            IERC20Upgradeable(_token).safeApprove(_router, type(uint).max);
        }
    }

    function _swap(
        address _router,
        address _to,
        address[] memory _path,
        uint _amount
    ) internal virtual {
        IPancakeRouter02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            _to,
            block.timestamp
        );
    }

    function _getPath(
        address _from,
        address _to
    ) internal virtual pure returns (address[] memory) {
        address[] memory path = new address[](2);

        path[0] = _from;
        path[1] = _to;

        return path;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}