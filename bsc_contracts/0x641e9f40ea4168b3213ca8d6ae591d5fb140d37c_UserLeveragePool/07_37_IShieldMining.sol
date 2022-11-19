// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShieldMining {
    struct ShieldMiningInfo {
        IERC20 rewardsToken;
        uint8 decimals;
        uint256 firstBlockWithReward;
        uint256 lastBlockWithReward;
        uint256 lastUpdateBlock;
        uint256 rewardTokensLocked;
        uint256 rewardPerTokenStored;
        uint256 totalSupply;
        uint256[] endsOfDistribution;
        // new state post v2
        uint256 nearestLastBlocksWithReward;
        // lastBlockWithReward => rewardPerBlock
        mapping(uint256 => uint256) rewardPerBlock;
    }

    struct ShieldMiningDeposit {
        address policyBook;
        uint256 amount;
        uint256 duration;
        uint256 depositRewardPerBlock;
        uint256 startBlock;
        uint256 endBlock;
    }

    /// TODO document SM functions
    function blocksWithRewardsPassed(address _policyBook) external view returns (uint256);

    function rewardPerToken(address _policyBook) external view returns (uint256);

    function earned(
        address _policyBook,
        address _userLeveragePool,
        address _account
    ) external view returns (uint256);

    function updateTotalSupply(
        address _policyBook,
        address _userLeveragePool,
        address liquidityProvider
    ) external;

    function associateShieldMining(address _policyBook, address _shieldMiningToken) external;

    function fillShieldMining(
        address _policyBook,
        uint256 _amount,
        uint256 _duration
    ) external;

    function getRewardFor(
        address _userAddress,
        address _policyBook,
        address _userLeveragePool
    ) external;

    function getRewardFor(address _userAddress, address _userLeveragePoolAddress) external;

    function getReward(address _policyBook, address _userLeveragePool) external;

    function getReward(address _userLeveragePoolAddress) external;

    function getShieldTokenAddress(address _policyBook) external view returns (address);

    function getShieldMiningInfo(address _policyBook)
        external
        view
        returns (
            address _rewardsToken,
            uint256 _decimals,
            uint256 _firstBlockWithReward,
            uint256 _lastBlockWithReward,
            uint256 _lastUpdateBlock,
            uint256 _nearestLastBlocksWithReward,
            uint256 _rewardTokensLocked,
            uint256 _rewardPerTokenStored,
            uint256 _rewardPerBlock,
            uint256 _tokenPerDay,
            uint256 _totalSupply
        );

    function getDepositList(
        address _account,
        uint256 _offset,
        uint256 _limit
    ) external view returns (ShieldMiningDeposit[] memory _depositsList);

    function countUsersDeposits(address _account) external view returns (uint256);
}