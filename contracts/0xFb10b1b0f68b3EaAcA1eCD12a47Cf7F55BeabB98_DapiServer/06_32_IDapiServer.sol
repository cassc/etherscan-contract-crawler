// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../protocol/interfaces/IAirnodeRequester.sol";

interface IDapiServer is IAirnodeRequester {
    event SetRrpBeaconUpdatePermissionStatus(
        address indexed sponsor,
        address indexed rrpBeaconUpdateRequester,
        bool status
    );

    event RequestedRrpBeaconUpdate(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        address airnode,
        bytes32 templateId
    );

    event RequestedRrpBeaconUpdateRelayed(
        bytes32 indexed beaconId,
        address indexed sponsor,
        address indexed requester,
        bytes32 requestId,
        address airnode,
        address relayer,
        bytes32 templateId
    );

    event UpdatedBeaconWithRrp(
        bytes32 indexed beaconId,
        bytes32 requestId,
        int256 value,
        uint256 timestamp
    );

    event RegisteredBeaconUpdateSubscription(
        bytes32 indexed subscriptionId,
        address airnode,
        bytes32 templateId,
        bytes parameters,
        bytes conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    );

    event UpdatedBeaconWithPsp(
        bytes32 indexed beaconId,
        bytes32 subscriptionId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconWithSignedData(
        bytes32 indexed beaconId,
        int256 value,
        uint256 timestamp
    );

    event UpdatedBeaconSetWithBeacons(
        bytes32 indexed beaconSetId,
        int224 value,
        uint32 timestamp
    );

    event UpdatedBeaconSetWithSignedData(
        bytes32 indexed dapiId,
        int224 value,
        uint32 timestamp
    );

    event AddedUnlimitedReader(address indexed unlimitedReader);

    event SetDapiName(
        bytes32 indexed dapiName,
        bytes32 dataFeedId,
        address indexed sender
    );

    function setRrpBeaconUpdatePermissionStatus(
        address rrpBeaconUpdateRequester,
        bool status
    ) external;

    function requestRrpBeaconUpdate(
        address airnode,
        bytes32 templateId,
        address sponsor
    ) external returns (bytes32 requestId);

    function requestRrpBeaconUpdateRelayed(
        address airnode,
        bytes32 templateId,
        address relayer,
        address sponsor
    ) external returns (bytes32 requestId);

    function fulfillRrpBeaconUpdate(
        bytes32 requestId,
        uint256 timestamp,
        bytes calldata data
    ) external;

    function registerBeaconUpdateSubscription(
        address airnode,
        bytes32 templateId,
        bytes memory conditions,
        address relayer,
        address sponsor
    ) external returns (bytes32 subscriptionId);

    function conditionPspBeaconUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external view returns (bool);

    function fulfillPspBeaconUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconWithSignedData(
        address airnode,
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconSetWithBeacons(bytes32[] memory beaconIds)
        external
        returns (bytes32 beaconSetId);

    function updateBeaconSetWithBeaconsAndReturnCondition(
        bytes32[] memory beaconIds,
        uint256 updateThresholdInPercentage
    ) external returns (bool);

    function conditionPspBeaconSetUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external returns (bool);

    function fulfillPspBeaconSetUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external;

    function updateBeaconSetWithSignedData(
        address[] memory airnodes,
        bytes32[] memory templateIds,
        uint256[] memory timestamps,
        bytes[] memory data,
        bytes[] memory signatures
    ) external returns (bytes32 beaconSetId);

    function addUnlimitedReader(address unlimitedReader) external;

    function setDapiName(bytes32 dapiName, bytes32 dataFeedId) external;

    function dapiNameToDataFeedId(bytes32 dapiName)
        external
        view
        returns (bytes32);

    function readDataFeedWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedValueWithId(bytes32 dataFeedId)
        external
        view
        returns (int224 value);

    function readDataFeedWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value, uint32 timestamp);

    function readDataFeedValueWithDapiName(bytes32 dapiName)
        external
        view
        returns (int224 value);

    function readerCanReadDataFeed(bytes32 dataFeedId, address reader)
        external
        view
        returns (bool);

    function dataFeedIdToReaderToWhitelistStatus(
        bytes32 dataFeedId,
        address reader
    )
        external
        view
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount);

    function dataFeedIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 dataFeedId,
        address reader,
        address setter
    ) external view returns (bool indefiniteWhitelistStatus);

    function deriveBeaconId(address airnode, bytes32 templateId)
        external
        pure
        returns (bytes32 beaconId);

    function deriveBeaconSetId(bytes32[] memory beaconIds)
        external
        pure
        returns (bytes32 beaconSetId);

    // solhint-disable-next-line func-name-mixedcase
    function DAPI_NAME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function HUNDRED_PERCENT() external view returns (uint256);

    function dapiNameSetterRole() external view returns (bytes32);

    function sponsorToRrpBeaconUpdateRequesterToPermissionStatus(
        address sponsor,
        address updateRequester
    ) external view returns (bool);

    function subscriptionIdToBeaconId(bytes32 subscriptionId)
        external
        view
        returns (bytes32);
}