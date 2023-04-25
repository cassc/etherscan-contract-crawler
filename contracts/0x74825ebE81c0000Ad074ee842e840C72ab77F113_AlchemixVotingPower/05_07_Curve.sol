//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ICurvePool {
    function fee() external view returns (uint256);
    function balances(uint256 i) external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, bool use_eth, address receiver)
        external
        returns (uint256);
}

interface ICurveGauge {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;
}

interface IConvexBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
}

interface IConvexRewardPool {
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 _amount) external returns (bool);
}

interface IConvexStakingWrapperFrax {
    function balanceOf(address account) external view returns (uint256);
    function totalBalanceOf(address account) external view returns (uint256);
    function deposit(uint256 _amount, address _to) external;
}

interface IFraxPoolRegistry {
    function vaultMap(uint256 _pid, address account) external view returns (address);
}

interface IFraxBooster {
    function createVault(uint256 _pid) external returns (address);
}

interface IFraxStakingProxy {
    function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);
}