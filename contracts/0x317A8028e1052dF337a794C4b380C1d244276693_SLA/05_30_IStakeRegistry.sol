// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

interface IStakeRegistry {
    function registerStakedSla(address _owner) external returns (bool);

    function setSLARegistry() external;

    function lockDSLAValue(
        address slaOwner_,
        address sla_,
        uint256 periodIdsLength_
    ) external;

    function getStakingParameters()
        external
        view
        returns (
            uint256 DSLAburnRate,
            uint256 dslaDepositByPeriod,
            uint256 dslaPlatformReward,
            uint256 dslaMessengerReward,
            uint256 dslaUserReward,
            uint256 dslaBurnedByVerification,
            uint256 maxTokenLength,
            uint64 maxLeverage,
            bool burnDSLA
        );

    function DSLATokenAddress() external view returns (address);

    function isAllowedToken(address tokenAddress_) external view returns (bool);

    function periodIsVerified(address _sla, uint256 _periodId)
        external
        view
        returns (bool);

    function returnLockedValue(address sla_) external;

    function distributeVerificationRewards(
        address _sla,
        address _verificationRewardReceiver,
        uint256 _periodId
    ) external;

    function createDToken(
        string calldata _name,
        string calldata _symbol,
        uint8 decimals
    ) external returns (address);

    function owner() external view returns (address);
}