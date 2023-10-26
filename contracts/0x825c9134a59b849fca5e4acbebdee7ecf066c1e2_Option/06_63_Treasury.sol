// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./GovernanceControl.sol";

/**
 * @title Treasury contract.
 *
 * @dev Treasury contract allows to hold, receive and use ERC20 funds.
 */
contract Treasury is Initializable, GovernanceControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Received(address from, address asset, uint256 amount);
    event Sent(address to, address asset, uint256 amount);
    event IncreasedAllowance(address spender, address asset, uint256 amount);
    event DecreasedAllowance(address spender, address asset, uint256 amount);

    /**
     * @dev Receive ETH fallback payable function.
     */
    receive() external payable virtual {}

    function initialize(address governance_, address executor_) external virtual initializer {
        __Treasury_init(governance_, executor_);
    }

    function increaseAllowance(
        address spender,
        address asset,
        uint256 amount
    ) external virtual onlyGovernance {
        IERC20Upgradeable(asset).safeIncreaseAllowance(spender, amount);
        emit IncreasedAllowance(spender, asset, amount);
    }

    function decreaseAllowance(
        address spender,
        address asset,
        uint256 amount
    ) external virtual onlyGovernance {
        IERC20Upgradeable(asset).safeDecreaseAllowance(spender, amount);
        emit DecreasedAllowance(spender, asset, amount);
    }

    function transfer(
        address to,
        address asset,
        uint256 amount
    ) external virtual onlyGovernance {
        if (asset == address(0)) {
            payable(to).call{value: amount};
        } else {
            IERC20Upgradeable(asset).safeTransfer(to, amount);
        }
        emit Sent(to, asset, amount);
    }

    function __Treasury_init(address governance_, address executor_) internal initializer {
        __GovernanceControl_init(governance_, executor_);
    }
}