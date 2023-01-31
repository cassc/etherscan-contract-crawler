// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IExchangeConfig} from "../interfaces/IExchangeConfig.sol";

abstract contract ExchangeConfig is
    IExchangeConfig,
    AccessControl,
    ERC721Holder
{
    using SafeERC20 for IERC20;

    error ZeroAddress();

    address public target;
    address public delegate;
    modifier nonZeroAddress(address token) {
        if (token == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    constructor(address admin_, address target_, address delegate_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        target = target_;
        if (delegate_ == address(0)) {
            revert ZeroAddress();
        }
        delegate = delegate_;
    }

    function updateTarget(
        address _target
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) nonZeroAddress(_target) {
        if (_target != target) {
            target = _target;
            emit UpdateTarget(_target);
        }
    }

    function updateDelegate(
        address _delegate
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) nonZeroAddress(_delegate) {
        if (_delegate != delegate) {
            delegate = _delegate;
            emit UpdateDelegate(_delegate);
        }
    }

    function _approve(address spender, address asset, uint256 amount) internal {
        uint256 allowance = IERC20(asset).allowance(address(this), spender);
        if(amount > allowance) {
            IERC20(asset).safeIncreaseAllowance(spender, amount - allowance);
        }
    }
}