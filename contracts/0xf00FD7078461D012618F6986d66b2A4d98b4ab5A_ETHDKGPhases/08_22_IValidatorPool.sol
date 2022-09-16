// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/CustomEnumerableMaps.sol";

interface IValidatorPool {
    event ValidatorJoined(address indexed account, uint256 validatorStakingTokenID);
    event ValidatorLeft(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMinorSlashed(address indexed account, uint256 publicStakingTokenID);
    event ValidatorMajorSlashed(address indexed account);
    event MaintenanceScheduled();

    function setStakeAmount(uint256 stakeAmount_) external;

    function setMaxIntervalWithoutSnapshots(uint256 maxIntervalWithoutSnapshots) external;

    function setMaxNumValidators(uint256 maxNumValidators_) external;

    function setDisputerReward(uint256 disputerReward_) external;

    function setLocation(string calldata ip) external;

    function scheduleMaintenance() external;

    function initializeETHDKG() external;

    function completeETHDKG() external;

    function pauseConsensus() external;

    function pauseConsensusOnArbitraryHeight(uint256 aliceNetHeight) external;

    function registerValidators(
        address[] calldata validators,
        uint256[] calldata publicStakingTokenIDs
    ) external;

    function unregisterValidators(address[] calldata validators) external;

    function unregisterAllValidators() external;

    function collectProfits() external returns (uint256 payoutEth, uint256 payoutToken);

    function claimExitingNFTPosition() external returns (uint256);

    function majorSlash(address dishonestValidator_, address disputer_) external;

    function minorSlash(address dishonestValidator_, address disputer_) external;

    function getMaxIntervalWithoutSnapshots()
        external
        view
        returns (uint256 maxIntervalWithoutSnapshots);

    function getValidatorsCount() external view returns (uint256);

    function getValidatorsAddresses() external view returns (address[] memory);

    function getValidator(uint256 index) external view returns (address);

    function getValidatorData(uint256 index) external view returns (ValidatorData memory);

    function getLocation(address validator) external view returns (string memory);

    function getLocations(address[] calldata validators_) external view returns (string[] memory);

    function getStakeAmount() external view returns (uint256);

    function getMaxNumValidators() external view returns (uint256);

    function getDisputerReward() external view returns (uint256);

    function tryGetTokenID(address account_)
        external
        view
        returns (
            bool,
            address,
            uint256
        );

    function isValidator(address participant) external view returns (bool);

    function isInExitingQueue(address participant) external view returns (bool);

    function isAccusable(address participant) external view returns (bool);

    function isMaintenanceScheduled() external view returns (bool);

    function isConsensusRunning() external view returns (bool);
}