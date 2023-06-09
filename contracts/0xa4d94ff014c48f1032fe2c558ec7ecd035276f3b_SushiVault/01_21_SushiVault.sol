pragma solidity ^0.6.0;

import "./base/BaseVaultV2.sol";
import "./base/VaultWithAutoStake.sol";

import "../mocks/StringsConcatenations.sol";

contract SushiVault is BaseVaultV2, VaultWithAutoStake {
    constructor() public BaseVaultV2("XBE Sushi LP", "XBESushi") {}

    function configure(
        address _initialToken,
        address _initialController,
        address _governance,
        uint256 _rewardsDuration,
        address _tokenToAutostake,
        address _votingStakingRewards,
        address[] memory _rewardsTokens,
        string memory _namePostfix,
        string memory _symbolPostfix
    ) public onlyOwner initializer {
        _configureVaultWithAutoStake(_tokenToAutostake, _votingStakingRewards);
        _configure(
            _initialToken,
            _initialController,
            _governance,
            _rewardsDuration,
            _rewardsTokens,
            _namePostfix,
            _symbolPostfix
        );
    }

    function _getReward(
        bool _claimUnderlying,
        address _for,
        address _rewardToken,
        address _stakingToken
    ) internal override {
        _controller.claim(_stakingToken, _rewardToken);

        uint256 reward = rewards[_for][_rewardToken];
        if (reward > 0) {
            rewards[_for][_rewardToken] = 0;
            _autoStakeForOrSendTo(_rewardToken, reward, _for);
            emit RewardPaid(_rewardToken, _for, reward);
        }
    }
}