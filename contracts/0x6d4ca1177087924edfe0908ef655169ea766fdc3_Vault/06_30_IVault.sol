// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

import {IFaucet} from "../libraries/Faucet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault is IFaucet, IERC20 {
    function deposit(
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        uint256
    ) external returns (uint256);

    function withdraw(
        uint256,
        uint256,
        uint256,
        uint256
    ) external;

    function calcSharesAndAmounts(
        uint256 _amountEth,
        uint256 _amountUsdc,
        uint256 _amountOsqth,
        uint256 _totalSupply,
        bool _isFlash
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}