// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPoolFactory {

    event LinerPoolCreated(
        address indexed LinerPoolAddress
    );

    event AllocationPoolCreated(
        address indexed AllocationPoolAddress
    );

    event ChangeLinerImpl(
        address LinerImplAddress
    );

    event ChangeAllocationImpl(
        address LinerImplAddress
    );

    event ChangeSigner(
        address signer
    );

    struct LinerParams {
        address[] stakeToken;
        address[] saleToken;
        uint256[] stakedTokenRate;
        uint256  APR;
        uint256  cap;
        uint256  startTimeJoin;
        uint256  endTimeJoin;
        uint256  lockDuration;
        address  rewardDistributor;
    }

    struct AllocationParams {
        address[] lpToken;
        address[] rewardToken;
        uint256[] stakedTokenRate;
        uint256 bonusMultiplier;
        uint256  startBlock;
        uint256  bonusEndBlock;
        uint256  lockDuration;
        address  rewardDistributor;
        uint256 tokenPerBlock;
    }

    function signerAddress() external view returns(address);

    function getLinerParameters()
        external
        returns (
            address[] memory stakeToken,
            address[] memory saleToken,
            uint256[] memory stakedTokenRate,
            uint256 APR,
            uint256 cap,
            uint256 startTimeJoin,
            uint256 endTimeJoin,
            uint256 lockDuration,
            address rewardDistributor
        );

    function getAllocationParameters()
        external
        returns (
            address[] memory lpToken,
            address[] memory rewardToken,
            uint256[] memory stakedTokenRate,
            uint256 bonusMultiplier,
            uint256  startBlock,
            uint256  bonusEndBlock,
            uint256 lockDuration,
            address rewardDistributor,
            uint256 tokenPerBlock
        );
}