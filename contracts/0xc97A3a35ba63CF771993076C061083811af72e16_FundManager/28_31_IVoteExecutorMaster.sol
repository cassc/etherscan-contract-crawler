// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVoteExecutorMaster {
    struct Message {
        uint256 commandIndex;
        bytes commandData;
    }

    event AdminChanged(address previousAdmin, address newAdmin);
    event BeaconUpgraded(address indexed beacon);
    event Initialized(uint8 version);
    event Paused(address account);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event Unpaused(address account);
    event Upgraded(address indexed implementation);

    function ALLUO() external view returns (address);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function UPGRADER_ROLE() external view returns (bytes32);

    function approveSubmittedData(
        uint256 _dataId,
        bytes[] memory _signs
    ) external;

    function bridgingInfo()
        external
        view
        returns (
            address anyCallAddress,
            address multichainRouter,
            address nextChainExecutor,
            uint256 currentChain,
            uint256 nextChain
        );

    function changeTimeLock(uint256 _newTimeLock) external;

    function changeUpgradeStatus(bool _status) external;

    function decodeApyCommand(
        bytes memory _data
    ) external pure returns (string memory, uint256, uint256);

    function decodeData(
        bytes memory _data
    ) external pure returns (bytes32, Message[] memory);

    function decodeMintCommand(
        bytes memory _data
    ) external pure returns (uint256, uint256);

    function encodeAllMessages(
        uint256[] memory _commandIndexes,
        bytes[] memory _commands
    )
        external
        pure
        returns (
            bytes32 messagesHash,
            Message[] memory messages,
            bytes memory inputData
        );

    function encodeApyCommand(
        string memory _ibAlluoName,
        uint256 _newAnnualInterest,
        uint256 _newInterestPerSecond
    ) external pure returns (uint256, bytes memory);

    function encodeMintCommand(
        uint256 _newMintAmount,
        uint256 _period
    ) external pure returns (uint256, bytes memory);

    function executeSpecificData(uint256 index) external;

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getSubmittedData(
        uint256 _dataId
    ) external view returns (bytes memory, uint256, bytes[] memory);

    function gnosis() external view returns (address);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function hashExecutionTime(bytes32) external view returns (uint256);

    function initialize(
        address _multiSigWallet,
        address _locker,
        address _anyCall,
        uint256 _timeLock
    ) external;

    function locker() external view returns (address);

    function minSigns() external view returns (uint256);

    function paused() external view returns (bool);

    function proxiableUUID() external view returns (bytes32);

    function renounceRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setAnyCallAddresses(address _newAnyCallAddress) external;

    function setGnosis(address _gnosisAddress) external;

    function setLocker(address _lockerAddress) external;

    function setMinSigns(uint256 _minSigns) external;

    function setNextChainExecutor(
        address _newAddress,
        uint256 chainNumber
    ) external;

    function submitData(bytes memory data) external;

    function submittedData(
        uint256
    ) external view returns (bytes memory data, uint256 time);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function timeLock() external view returns (uint256);

    function upgradeStatus() external view returns (bool);

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable;

    function getAssetIdToDepositPercentages(
        uint256 assetId
    ) external view returns (Deposit[] memory);

    struct Deposit {
        uint256 directionId;
        uint256 amount;
    }
}