// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://etherscan.io/address/0xd8b712d29381748dB89c36BCa0138d7c75866ddF#code
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */
interface ILiquidityGauge {
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external returns (uint256);
    function balanceOf(address owner) external returns (uint256);

    // Get claimable CRV
    function claimable_tokens(address addr) external returns (uint256);
    function claim_rewards() external;

    // NOTE: The below only applies to non-CRV rewards
    // claimable_reward - claimed_reward = pending rewards
    // Total rewards, claimed and unclaimed
    function claimable_reward(address addr, address token) external view returns (uint256);
    // unclaimed
    function claimed_reward(address addr, address token) external view returns (uint256);
}

/*  solhint-disable func-name-mixedcase, var-name-mixedcase */