// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;
import {ERC20} from "ERC20.sol";
import {IStrategy} from "IStrategy.sol";

/// GVault interface
interface IGVault {
    function asset() external view returns (ERC20);

    function excessDebt(address _strategy)
        external
        view
        returns (uint256, uint256);

    function getStrategyDebt() external view returns (uint256);

    function creditAvailable() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtRepayment,
        bool _emergency
    ) external returns (uint256);

    function getStrategyData()
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );
}