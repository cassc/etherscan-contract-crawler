// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @notice Generated from Convex's Booster contract on mainnet.
 * https://etherscan.io/address/0xF403C135812408BFbE8713b5A23a04b3D48AAE31
 *
 * mUSD Pool Id (pid) is 14
 * lptoken    : 0x1AEf73d49Dedc4b1778d0706583995958Dc862e6 : Curve LP Token          : Curve.fi MUSD/3Crv (musd3CRV)
 * token      : 0xd34d466233c5195193dF712936049729140DBBd7 : DepositToken            : Curve.fi MUSD/3Crv Convex Deposit (cvxmusd3CRV)
 * gauge      : 0x5f626c30EC1215f4EdCc9982265E8b1F411D1352 : Staking Liquidity Gauge : Curve.fi: MUSD Liquidity Gauge
 * crvRewards : 0xDBFa6187C79f4fE4Cda20609E75760C5AaE88e52 : BaseRewardPool          : Convex staking contract for cvxmusd3CRV for rewards
 * stash      : 0x2eEa402ff31c580630b8545A33EDc00881E6949c : ExtraRewardStashV1      : Convex staking contract for cvxmusd3CRV for extra rewards
 */
interface IConvexBooster {
    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function rewardClaimed(
        uint256 _pid,
        address _address,
        uint256 _amount
    ) external returns (bool);

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteDelegate() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}