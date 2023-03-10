// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {BaseStrategy} from "../BaseStrategy.sol";
import {IEulerEToken} from "../interfaces/euler/IEulerEToken.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title Euler Strategy
/// @dev Lend token on Euler
contract EulerStrategy is BaseStrategy {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public immutable euler;
    IEulerEToken public immutable eToken;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the strategy configurations
    /// @param _bentoBox address of the bentobox
    /// @param _strategyToken address of the token in strategy
    /// @param _strategyExecutor address of the executor
    /// @param _feeTo address of the fee recipient
    /// @param _owner address of the owner of the strategy
    /// @param _fee fee for the strategy
    /// @param _euler address of euler
    /// @param _eToken address of the eToken
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee,
        address _euler,
        address _eToken
    )
        BaseStrategy(
            _bentoBox,
            _strategyToken,
            _strategyExecutor,
            _feeTo,
            _owner,
            _fee
        )
    {
        euler = _euler;
        eToken = IEulerEToken(_eToken);
    }

    function _skim(uint256 amount) internal override {
        strategyToken.safeApprove(euler, amount);
        eToken.deposit(0, amount);
    }

    function _harvest(uint256 balance)
        internal
        override
        returns (int256 amountAdded)
    {
        uint256 currentBalance = eToken.balanceOfUnderlying(address(this));
        amountAdded = int256(currentBalance) - int256(balance);
        if (amountAdded > 0) {
            eToken.withdraw(0, uint256(amountAdded));
        }
    }

    function _withdraw(uint256 amount) internal override {
        eToken.withdraw(0, amount);
    }

    function _exit() internal override {
        uint256 tokenBalance = eToken.balanceOfUnderlying(address(this));
        uint256 available = strategyToken.balanceOf(euler);
        if (tokenBalance <= available) {
            // If there are more tokens available than our full position, take all based on aToken balance (continue if unsuccessful).
            try eToken.withdraw(0, tokenBalance) {} catch {}
        } else {
            // Otherwise redeem all available and take a loss on the missing amount (continue if unsuccessful).
            try eToken.withdraw(0, available) {} catch {}
        }
    }

    function _harvestRewards() internal virtual override {}
}