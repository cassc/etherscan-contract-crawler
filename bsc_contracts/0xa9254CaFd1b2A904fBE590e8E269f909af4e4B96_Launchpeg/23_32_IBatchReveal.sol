// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBatchReveal
/// @author Trader Joe
/// @notice Defines the basic interface of BatchReveal
interface IBatchReveal {
    struct BatchRevealConfig {
        uint256 collectionSize;
        int128 intCollectionSize;
        /// @notice Size of the batch reveal
        /// @dev Must divide collectionSize
        uint256 revealBatchSize;
        /// @notice Timestamp for the start of the reveal process
        /// @dev Can be set to zero for immediate reveal after token mint
        uint256 revealStartTime;
        /// @notice Time interval for gradual reveal
        /// @dev Can be set to zero in order to reveal the collection all at once
        uint256 revealInterval;
    }

    function initialize() external;

    function configure(
        address _baseLaunchpeg,
        uint256 _revealBatchSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external;

    function setRevealBatchSize(
        address _baseLaunchpeg,
        uint256 _revealBatchSize
    ) external;

    function setRevealStartTime(
        address _baseLaunchpeg,
        uint256 _revealStartTime
    ) external;

    function setRevealInterval(address _baseLaunchpeg, uint256 _revealInterval)
        external;

    function setVRF(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) external;

    function launchpegToConfig(address)
        external
        view
        returns (
            uint256,
            int128,
            uint256,
            uint256,
            uint256
        );

    function launchpegToBatchToSeed(address, uint256)
        external
        view
        returns (uint256);

    function launchpegToLastTokenReveal(address)
        external
        view
        returns (uint256);

    function useVRF() external view returns (bool);

    function subscriptionId() external view returns (uint64);

    function keyHash() external view returns (bytes32);

    function callbackGasLimit() external view returns (uint32);

    function requestConfirmations() external view returns (uint16);

    function launchpegToNextBatchToReveal(address)
        external
        view
        returns (uint256);

    function launchpegToHasBeenForceRevealed(address)
        external
        view
        returns (bool);

    function launchpegToVrfRequestedForBatch(address, uint256)
        external
        view
        returns (bool);

    function getShuffledTokenId(address _baseLaunchpeg, uint256 _startId)
        external
        view
        returns (uint256);

    function isBatchRevealInitialized(address _baseLaunchpeg)
        external
        view
        returns (bool);

    function revealNextBatch(address _baseLaunchpeg, uint256 _totalSupply)
        external
        returns (bool);

    function hasBatchToReveal(address _baseLaunchpeg, uint256 _totalSupply)
        external
        view
        returns (bool, uint256);

    function forceReveal(address _baseLaunchpeg) external;
}