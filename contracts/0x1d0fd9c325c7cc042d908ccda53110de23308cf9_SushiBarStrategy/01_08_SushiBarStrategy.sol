// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "../BaseStrategy.sol";
import "../interfaces/xsushi/ISushiBar.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

/// @title Sushi Bar Strategy
/// @dev Stake Sushi to get xSushi
contract SushiBarStrategy is BaseStrategy {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    ISushiBar public immutable sushiBar;

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
    /// @param _sushiBar address of sushi bar contract
    constructor(
        address _bentoBox,
        address _strategyToken,
        address _strategyExecutor,
        address _feeTo,
        address _owner,
        uint256 _fee,
        address _sushiBar
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
        sushiBar = ISushiBar(_sushiBar);
    }

    function _skim(uint256 amount) internal override {
        strategyToken.safeApprove(address(sushiBar), amount);
        sushiBar.enter(amount);
    }

    function _harvest(uint256 balance) internal override returns (int256) {
        uint256 keep = toShare(balance);
        uint256 total = ERC20(address(sushiBar)).balanceOf(address(this));
        if (total > keep) sushiBar.leave(total - keep);
        // xSUSHI can't report a loss so no need to check for keep < total case
        // we can return 0 when reporting profits (BaseContract checks balanceOf)
        return int256(0);
    }

    function _withdraw(uint256 amount) internal override {
        uint256 requested = toShare(amount);
        uint256 actual = ERC20(address(sushiBar)).balanceOf(address(this));
        sushiBar.leave(requested > actual ? actual : requested);
    }

    function _exit() internal override {
        sushiBar.leave(ERC20(address(sushiBar)).balanceOf(address(this)));
    }

    function toShare(uint256 amount) internal view returns (uint256) {
        uint256 totalShares = ERC20(address(sushiBar)).totalSupply();
        uint256 totalSushi = strategyToken.balanceOf(address(sushiBar));
        return (amount * totalShares) / totalSushi;
    }
}