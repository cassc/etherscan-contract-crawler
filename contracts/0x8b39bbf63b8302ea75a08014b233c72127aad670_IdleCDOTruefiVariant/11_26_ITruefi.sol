// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20WithDecimals is IERC20Upgradeable {
    function decimals() external view returns (uint8);

    function mint(address receiver, uint256 amount) external;
}

interface ITrueLender {
    function value(address) external pure returns (uint256);

    function loans(ITruefiPool) external view returns (ILoanToken[] memory);
}

interface ITruefiPool is IERC20WithDecimals {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
    
    function token() external view returns (IERC20WithDecimals);

    function join(uint256 amount) external;

    function liquidExit(uint256 amount) external;

    function poolValue() external view returns (uint256);

    function liquidValue() external view returns (uint256);

    function liquidExitPenalty(uint256 amount) external view returns (uint256);

    function lender() external view returns (ITrueLender);
}

interface ITrueLegacyMultiFarm {
    function rewardToken() external view returns (IERC20WithDecimals);

    function stake(IERC20Upgradeable token, uint256 amount) external;

    function unstake(IERC20Upgradeable token, uint256 amount) external;

    function claim(IERC20Upgradeable[] calldata tokens) external;

    function staked(IERC20Upgradeable token, address staker) external view returns (uint256);
}

interface ILoanToken {
    enum Status {Awaiting, Funded, Withdrawn, Settled, Defaulted, Liquidated}
    function apy() external view returns (uint256);

    function amount() external view returns (uint256);
    // function status() external view returns (uint256);
    function status() external view returns (Status);
    function start() external view returns (uint256);
    function term() external view returns (uint256);
    function enterDefault() external;
}