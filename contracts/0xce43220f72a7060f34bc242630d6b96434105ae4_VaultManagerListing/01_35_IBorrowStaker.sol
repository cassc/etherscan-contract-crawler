// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBorrowStakerCheckpoint {
    function checkpointFromVaultManager(
        address from,
        uint256 amount,
        bool add
    ) external;
}

interface IBorrowStaker is IBorrowStakerCheckpoint, IERC20 {
    function asset() external returns (IERC20 stakingToken);

    function deposit(uint256 amount, address to) external;

    function withdraw(
        uint256 amount,
        address from,
        address to
    ) external;

    //solhint-disable-next-line
    function claim_rewards(address user) external returns (uint256[] memory);
}