// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ILaunchpegFactory
/// @author Trader Joe
/// @notice Defines the basic interface of LaunchpegFactory
interface ILaunchpegFactory {
    function LAUNCHPEG_PAUSER_ROLE() external pure returns (bytes32);

    function launchpegImplementation() external view returns (address);

    function flatLaunchpegImplementation() external view returns (address);

    function batchReveal() external view returns (address);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function isLaunchpeg(uint256 _type, address _contract)
        external
        view
        returns (bool);

    function allLaunchpegs(uint256 _launchpegType, uint256 _launchpegID)
        external
        view
        returns (address);

    function numLaunchpegs(uint256 _launchpegType)
        external
        view
        returns (uint256);

    function createLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForAuction,
        uint256 _amountForAllowlist,
        uint256 _amountForDevs,
        bool _enableBatchReveal
    ) external returns (address);

    function createFlatLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        bool _enableBatchReveal
    ) external returns (address);

    function setLaunchpegImplementation(address _launchpegImplementation)
        external;

    function setFlatLaunchpegImplementation(
        address _flatLaunchpegImplementation
    ) external;

    function setBatchReveal(address _batchReveal) external;

    function setDefaultJoeFeePercent(uint256 _joeFeePercent) external;

    function setDefaultJoeFeeCollector(address _joeFeeCollector) external;

    function addLaunchpegPauser(address _pauser) external;

    function removeLaunchpegPauser(address _pauser) external;

    function pauseLaunchpeg(address _launchpeg) external;
}