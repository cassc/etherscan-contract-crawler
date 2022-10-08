// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBooster {
    event ArbitratorUpdated(address newArbitrator);
    event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
    event FactoriesUpdated(address rewardFactory, address stashFactory, address tokenFactory);
    event FeeInfoChanged(address feeDistro, bool active);
    event FeeInfoUpdated(address feeDistro, address lockFees, address feeToken);
    event FeeManagerUpdated(address newFeeManager);
    event FeesUpdated(uint256 lockIncentive, uint256 stakerIncentive, uint256 earmarkIncentive, uint256 platformFee);
    event OwnerUpdated(address newOwner);
    event PoolAdded(address lpToken, address gauge, address token, address rewardPool, address stash, uint256 pid);
    event PoolManagerUpdated(address newPoolManager);
    event PoolShutdown(uint256 poolId);
    event RewardContractsUpdated(address lockRewards, address stakerRewards);
    event TreasuryUpdated(address newTreasury);
    event VoteDelegateUpdated(address newVoteDelegate);
    event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

    function FEE_DENOMINATOR() external view returns (uint256);

    function MaxFees() external view returns (uint256);

    function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);

    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function crv() external view returns (address);

    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkFees(address _feeToken) external returns (bool);

    function earmarkIncentive() external view returns (uint256);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function feeManager() external view returns (address);

    function feeTokens(address) external view returns (address distro, address rewards, bool active);

    function gaugeMap(address) external view returns (bool);

    function isShutdown() external view returns (bool);

    function lockIncentive() external view returns (uint256);

    function lockRewards() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function platformFee() external view returns (uint256);

    function poolInfo(uint256)
        external
        view
        returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);

    function poolLength() external view returns (uint256);

    function poolManager() external view returns (address);

    function rewardArbitrator() external view returns (address);

    function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);

    function rewardFactory() external view returns (address);

    function setArbitrator(address _arb) external;

    function setFactories(address _rfactory, address _sfactory, address _tfactory) external;

    function setFeeInfo(address _feeToken, address _feeDistro) external;

    function setFeeManager(address _feeM) external;

    function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;

    function setGaugeRedirect(uint256 _pid) external returns (bool);

    function setOwner(address _owner) external;

    function setPoolManager(address _poolM) external;

    function setRewardContracts(address _rewards, address _stakerRewards) external;

    function setTreasury(address _treasury) external;

    function setVote(bytes32 _hash, bool valid) external returns (bool);

    function setVoteDelegate(address _voteDelegate) external;

    function shutdownPool(uint256 _pid) external returns (bool);

    function shutdownSystem() external;

    function staker() external view returns (address);

    function stakerIncentive() external view returns (uint256);

    function stakerRewards() external view returns (address);

    function stashFactory() external view returns (address);

    function tokenFactory() external view returns (address);

    function treasury() external view returns (address);

    function updateFeeInfo(address _feeToken, bool _active) external;

    function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);

    function voteDelegate() external view returns (address);

    function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);

    function voteOwnership() external view returns (address);

    function voteParameter() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}