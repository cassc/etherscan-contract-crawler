// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "../BaseStrategy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title Abra stkcvxcrvRenWBTC Strategy
/// @dev Sends stkcvxcrvRenWBTC to Abra Multisig
contract AbraStkcvxcrvRenWBTCStrategy is BaseStrategy {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    address public abraMultiSig;

    int256 public lossValue;

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
    /// @param _abraMultiSig address of abra multi sig
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee,
        address _abraMultiSig
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
        abraMultiSig = _abraMultiSig;
    }

    function _skim(uint256 amount) internal override {
        strategyToken.safeTransfer(abraMultiSig, amount);
    }

    function _harvest(uint256 balance) internal override returns (int256) {
        return int256(lossValue);
    }

    function _withdraw(uint256 amount) internal override {
        revert();
    }

    function _exit() internal override {}

    function setLossValue(int256 _val) public onlyExecutor {
        lossValue = _val;
    }
}