//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import './IERC3156FlashBorrower.sol';

interface IFlashLoan {
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}