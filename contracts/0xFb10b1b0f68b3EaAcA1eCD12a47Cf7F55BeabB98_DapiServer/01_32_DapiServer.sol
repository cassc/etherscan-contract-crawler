// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../utils/ExtendedMulticall.sol";
import "../whitelist/WhitelistWithManager.sol";
import "../protocol/AirnodeRequester.sol";
import "./Median.sol";
import "./interfaces/IDapiServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Contract that serves Beacons, Beacon sets and dAPIs based on the
/// Airnode protocol
/// @notice A Beacon is a live data feed addressed by an ID, which is derived
/// from an Airnode address and a template ID. This is suitable where the more
/// recent data point is always more favorable, e.g., in the context of an
/// asset price data feed. Beacons can also be seen as one-Airnode data feeds
/// that can be used individually or combined to build Beacon sets. dAPIs are
/// an abstraction layer over Beacons and Beacon sets.
/// @dev DapiServer is a PSP requester contract. Unlike RRP, which is
/// implemented as a central contract, PSP implementation is built into the
/// requester for optimization. Accordingly, the checks that are not required
/// are omitted. Some examples:
/// - While executing a PSP Beacon update, the condition is not verified
/// because Beacon updates where the condition returns `false` (i.e., the
/// on-chain value is already close to the actual value) are not harmful, and
/// are even desirable.
/// - PSP Beacon set update subscription IDs are not verified, as the
/// Airnode/relayer cannot be made to "misreport a Beacon set update" by
/// spoofing a subscription ID.
/// - While executing a PSP Beacon set update, even the signature is not
/// checked because this is a purely keeper job that does not require off-chain
/// data. Similar to Beacon updates, any Beacon set update is welcome.
contract DapiServer is
    ExtendedMulticall,
    WhitelistWithManager,
    AirnodeRequester,
    Median,
    IDapiServer
{
    using ECDSA for bytes32;

    // Airnodes serve their fulfillment data along with timestamps. This
    // contract casts the reported data to `int224` and the timestamp to
    // `uint32`, which works until year 2106.
    struct DataFeed {
        int224 value;
        uint32 timestamp;
    }

    /// @notice dAPI name setter role description
    string public constant override DAPI_NAME_SETTER_ROLE_DESCRIPTION =
        "dAPI name setter";

    /// @notice Number that represents 100%
    /// @dev 10^8 (and not a larger number) is chosen to avoid overflows in
    /// `calculateUpdateInPercentage()`. Since the reported data needs to fit
    /// into 224 bits, its multiplication by 10^8 is guaranteed not to
    /// overflow.
    uint256 public constant override HUNDRED_PERCENT = 1e8;

    /// @notice dAPI name setter role
    bytes32 public immutable override dapiNameSetterRole;

    /// @notice If an account is an unlimited reader
    mapping(address => bool) public unlimitedReaderStatus;

    /// @notice If a sponsor has permitted an account to request RRP-based
    /// updates at this contract
    mapping(address => mapping(address => bool))
        public
        override sponsorToRrpBeaconUpdateRequesterToPermissionStatus;

    /// @notice ID of the Beacon that the subscription is registered to update
    mapping(bytes32 => bytes32) public override subscriptionIdToBeaconId;

    mapping(bytes32 => DataFeed) private dataFeeds;

    mapping(bytes32 => bytes32) private requestIdToBeaconId;

    mapping(bytes32 => bytes32) private subscriptionIdToHash;

    mapping(bytes32 => bytes32) private dapiNameHashToDataFeedId;

    /// @dev Reverts if the sender is not permitted to request an RRP-based
    /// update with the sponsor and is not the sponsor
    /// @param sponsor Sponsor address
    modifier onlyPermittedUpdateRequester(address sponsor) {
        require(
            sponsor == msg.sender ||
                sponsorToRrpBeaconUpdateRequesterToPermissionStatus[sponsor][
                    msg.sender
                ],
            "Sender not permitted"
        );
        _;
    }

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    /// @param _manager Manager address
    /// @param _airnodeProtocol AirnodeProtocol contract address
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _airnodeProtocol
    )
        WhitelistWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
        AirnodeRequester(_airnodeProtocol)
    {
        dapiNameSetterRole = _deriveRole(
            _deriveAdminRole(manager),
            keccak256(abi.encodePacked(DAPI_NAME_SETTER_ROLE_DESCRIPTION))
        );
    }

    ///                     ~~~RRP Beacon updates~~~

    /// @notice Called by the sponsor to set the update request permission
    /// status of an account
    /// @param rrpBeaconUpdateRequester RRP-based Beacon update requester
    /// address
    /// @param status Permission status
    function setRrpBeaconUpdatePermissionStatus(
        address rrpBeaconUpdateRequester,
        bool status
    ) external override {
        require(
            rrpBeaconUpdateRequester != address(0),
            "Update requester zero"
        );
        sponsorToRrpBeaconUpdateRequesterToPermissionStatus[msg.sender][
            rrpBeaconUpdateRequester
        ] = status;
        emit SetRrpBeaconUpdatePermissionStatus(
            msg.sender,
            rrpBeaconUpdateRequester,
            status
        );
    }

    /// @notice Creates an RRP requests for the Beacon to be updated
    /// @dev In addition to the sponsor sponsoring this contract (by calling
    /// `setRrpSponsorshipStatus()`), the sponsor must also give update request
    /// permission to the sender (by calling
    /// `setRrpBeaconUpdatePermissionStatus()`) before this method is called.
    /// The template must specify a single point of data of type `int256` to be
    /// returned and for it to be small enough to be castable to `int224`
    /// because this is what `fulfillRrpBeaconUpdate()` expects.
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param sponsor Sponsor address
    /// @return requestId Request ID
    function requestRrpBeaconUpdate(
        address airnode,
        bytes32 templateId,
        address sponsor
    )
        external
        override
        onlyPermittedUpdateRequester(sponsor)
        returns (bytes32 requestId)
    {
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        requestId = IAirnodeProtocol(airnodeProtocol).makeRequest(
            airnode,
            templateId,
            "",
            sponsor,
            this.fulfillRrpBeaconUpdate.selector
        );
        requestIdToBeaconId[requestId] = beaconId;
        emit RequestedRrpBeaconUpdate(
            beaconId,
            sponsor,
            msg.sender,
            requestId,
            airnode,
            templateId
        );
    }

    /// @notice Creates an RRP requests for the Beacon to be updated by the relayer
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @return requestId Request ID
    function requestRrpBeaconUpdateRelayed(
        address airnode,
        bytes32 templateId,
        address relayer,
        address sponsor
    )
        external
        override
        onlyPermittedUpdateRequester(sponsor)
        returns (bytes32 requestId)
    {
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        requestId = IAirnodeProtocol(airnodeProtocol).makeRequestRelayed(
            airnode,
            templateId,
            "",
            relayer,
            sponsor,
            this.fulfillRrpBeaconUpdate.selector
        );
        requestIdToBeaconId[requestId] = beaconId;
        emit RequestedRrpBeaconUpdateRelayed(
            beaconId,
            sponsor,
            msg.sender,
            requestId,
            airnode,
            relayer,
            templateId
        );
    }

    /// @notice Called by the Airnode/relayer using the sponsor wallet through
    /// AirnodeProtocol to fulfill the request
    /// @param requestId Request ID
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    function fulfillRrpBeaconUpdate(
        bytes32 requestId,
        uint256 timestamp,
        bytes calldata data
    ) external override onlyAirnodeProtocol onlyValidTimestamp(timestamp) {
        bytes32 beaconId = requestIdToBeaconId[requestId];
        delete requestIdToBeaconId[requestId];
        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithRrp(beaconId, requestId, decodedData, timestamp);
    }

    ///                     ~~~PSP Beacon updates~~~

    /// @notice Registers the Beacon update subscription
    /// @dev Similar to how one needs to call `requestRrpBeaconUpdate()` for
    /// this contract to recognize the incoming RRP fulfillment, this needs to
    /// be called before the subscription fulfillments.
    /// In addition to the subscription being registered, the sponsor must use
    /// `setPspSponsorshipStatus()` to give permission for its sponsor wallet
    /// to be used for the specific subscription.
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param conditions Conditions under which the subscription is requested
    /// to be fulfilled
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @return subscriptionId Subscription ID
    function registerBeaconUpdateSubscription(
        address airnode,
        bytes32 templateId,
        bytes memory conditions,
        address relayer,
        address sponsor
    ) external override returns (bytes32 subscriptionId) {
        require(relayer != address(0), "Relayer address zero");
        require(sponsor != address(0), "Sponsor address zero");
        subscriptionId = keccak256(
            abi.encode(
                block.chainid,
                airnode,
                templateId,
                "",
                conditions,
                relayer,
                sponsor,
                address(this),
                this.fulfillPspBeaconUpdate.selector
            )
        );
        subscriptionIdToHash[subscriptionId] = keccak256(
            abi.encodePacked(airnode, relayer, sponsor)
        );
        subscriptionIdToBeaconId[subscriptionId] = deriveBeaconId(
            airnode,
            templateId
        );
        emit RegisteredBeaconUpdateSubscription(
            subscriptionId,
            airnode,
            templateId,
            "",
            conditions,
            relayer,
            sponsor,
            address(this),
            this.fulfillPspBeaconUpdate.selector
        );
    }

    /// @notice Returns if the respective Beacon needs to be updated based on
    /// the fulfillment data and the condition parameters
    /// @dev Reverts if not called by a void signer with zero address because
    /// this method can be used to indirectly read a Beacon.
    /// `conditionParameters` are specified within the `conditions` field of a
    /// Subscription.
    /// @param subscriptionId Subscription ID
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @param conditionParameters Subscription condition parameters (a
    /// `uint256` encoded in contract ABI)
    /// @return If the Beacon update subscription should be fulfilled
    function conditionPspBeaconUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external view override returns (bool) {
        require(msg.sender == address(0), "Sender not zero address");
        bytes32 beaconId = subscriptionIdToBeaconId[subscriptionId];
        require(beaconId != bytes32(0), "Subscription not registered");
        DataFeed storage beacon = dataFeeds[beaconId];
        return
            calculateUpdateInPercentage(
                beacon.value,
                decodeFulfillmentData(data)
            ) >=
            decodeConditionParameters(conditionParameters) ||
            beacon.timestamp == 0;
    }

    /// @notice Called by the Airnode/relayer using the sponsor wallet to
    /// fulfill the Beacon update subscription
    /// @dev There is no need to verify that `conditionPspBeaconUpdate()`
    /// returns `true` because any Beacon update is a good Beacon update
    /// @param subscriptionId Subscription ID
    /// @param airnode Airnode address
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (a single `int256` encoded in contract
    /// ABI)
    /// @param signature Subscription ID, timestamp, sponsor wallet address
    /// (and fulfillment data if the relayer is not the Airnode) signed by the
    /// Airnode wallet
    function fulfillPspBeaconUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override onlyValidTimestamp(timestamp) {
        require(
            subscriptionIdToHash[subscriptionId] ==
                keccak256(abi.encodePacked(airnode, relayer, sponsor)),
            "Subscription not registered"
        );
        if (airnode == relayer) {
            require(
                (
                    keccak256(
                        abi.encodePacked(subscriptionId, timestamp, msg.sender)
                    ).toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
        } else {
            require(
                (
                    keccak256(
                        abi.encodePacked(
                            subscriptionId,
                            timestamp,
                            msg.sender,
                            data
                        )
                    ).toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
        }
        bytes32 beaconId = subscriptionIdToBeaconId[subscriptionId];
        // Beacon ID is guaranteed to not be zero because the subscription is
        // registered
        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithPsp(
            beaconId,
            subscriptionId,
            int224(decodedData),
            uint32(timestamp)
        );
    }

    ///                     ~~~Signed data Beacon updates~~~

    /// @notice Updates a Beacon using data signed by the respective Airnode,
    /// without requiring a request or subscription
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @param timestamp Timestamp used in the signature
    /// @param data Response data (an `int256` encoded in contract ABI)
    /// @param signature Template ID, a timestamp and the response data signed
    /// by the Airnode address
    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override onlyValidTimestamp(timestamp) {
        require(
            (
                keccak256(abi.encodePacked(templateId, timestamp, data))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithSignedData(beaconId, decodedData, timestamp);
    }

    ///                     ~~~PSP Beacon set updates~~~

    /// @notice Updates the Beacon set using the current values of its Beacons
    /// @dev This function still works if some of the IDs in `beaconIds` belong
    /// to Beacon sets rather than Beacons. However, this is not the intended
    /// use.
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function updateBeaconSetWithBeacons(bytes32[] memory beaconIds)
        public
        override
        returns (bytes32 beaconSetId)
    {
        uint256 beaconCount = beaconIds.length;
        require(beaconCount > 1, "Specified less than two Beacons");
        int256[] memory values = new int256[](beaconCount);
        uint256 accumulatedTimestamp = 0;
        for (uint256 ind = 0; ind < beaconCount; ind++) {
            DataFeed storage dataFeed = dataFeeds[beaconIds[ind]];
            values[ind] = dataFeed.value;
            accumulatedTimestamp += dataFeed.timestamp;
        }
        uint32 updatedTimestamp = uint32(accumulatedTimestamp / beaconCount);
        beaconSetId = deriveBeaconSetId(beaconIds);
        require(
            updatedTimestamp >= dataFeeds[beaconSetId].timestamp,
            "Updated value outdated"
        );
        int224 updatedValue = int224(median(values));
        dataFeeds[beaconSetId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedBeaconSetWithBeacons(
            beaconSetId,
            updatedValue,
            updatedTimestamp
        );
    }

    /// @notice Updates the Beacon set using the current values of the Beacons
    /// and returns if this update was justified according to the deviation
    /// threshold
    /// @dev This method does not allow the caller to indirectly read a Beacon
    /// set, which is why it does not require the sender to be a void signer
    /// with zero address. This allows the implementation of incentive
    /// mechanisms that rewards keepers that trigger valid dAPI updates.
    /// @param beaconIds Beacon IDs
    /// @param deviationThresholdInPercentage Deviation threshold in percentage
    /// where 100% is represented as `HUNDRED_PERCENT`
    function updateBeaconSetWithBeaconsAndReturnCondition(
        bytes32[] memory beaconIds,
        uint256 deviationThresholdInPercentage
    ) public override returns (bool) {
        bytes32 beaconSetId = deriveBeaconSetId(beaconIds);
        DataFeed memory initialBeaconSet = dataFeeds[beaconSetId];
        updateBeaconSetWithBeacons(beaconIds);
        DataFeed storage updatedBeaconSet = dataFeeds[beaconSetId];
        return
            calculateUpdateInPercentage(
                initialBeaconSet.value,
                updatedBeaconSet.value
            ) >=
            deviationThresholdInPercentage ||
            (initialBeaconSet.timestamp == 0 && updatedBeaconSet.timestamp > 0);
    }

    /// @notice Returns if the respective Beacon set needs to be updated based
    /// on the condition parameters
    /// @dev The template ID used in the respective Subscription is expected to
    /// be zero, which means the `parameters` field of the Subscription will be
    /// forwarded to this function as `data`. This field should be the Beacon
    /// ID array encoded in contract ABI.
    /// @param subscriptionId Subscription ID
    /// @param data Fulfillment data (array of Beacon IDs, i.e., `bytes32[]`
    /// encoded in contract ABI)
    /// @param conditionParameters Subscription condition parameters (a
    /// `uint256` encoded in contract ABI)
    /// @return If the Beacon set update subscription should be fulfilled
    function conditionPspBeaconSetUpdate(
        bytes32 subscriptionId, // solhint-disable-line no-unused-vars
        bytes calldata data,
        bytes calldata conditionParameters
    ) external override returns (bool) {
        require(msg.sender == address(0), "Sender not zero address");
        bytes32[] memory beaconIds = abi.decode(data, (bytes32[]));
        require(
            keccak256(abi.encode(beaconIds)) == keccak256(data),
            "Data length not correct"
        );
        return
            updateBeaconSetWithBeaconsAndReturnCondition(
                beaconIds,
                decodeConditionParameters(conditionParameters)
            );
    }

    /// @notice Called by the Airnode/relayer using the sponsor wallet to
    /// fulfill the Beacon set update subscription
    /// @dev Similar to `conditionPspBeaconSetUpdate()`, if `templateId` of the
    /// Subscription is zero, its `parameters` field will be forwarded to
    /// `data` here, which is expect to be contract ABI-encoded array of Beacon
    /// IDs.
    /// It does not make sense for this subscription to be relayed, as there is
    /// no external data being delivered. Nevertheless, this is allowed for the
    /// lack of a reason to prevent it.
    /// Even though the consistency of the arguments are not being checked, if
    /// a standard implementation of Airnode is being used, these can be
    /// expected to be correct. Either way, the assumption is that it does not
    /// matter for the purposes of a Beacon set update subscription.
    /// @param subscriptionId Subscription ID
    /// @param airnode Airnode address
    /// @param relayer Relayer address
    /// @param sponsor Sponsor address
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @param signature Subscription ID, timestamp, sponsor wallet address
    /// (and fulfillment data if the relayer is not the Airnode) signed by the
    /// Airnode wallet
    function fulfillPspBeaconSetUpdate(
        bytes32 subscriptionId, // solhint-disable-line no-unused-vars
        address airnode, // solhint-disable-line no-unused-vars
        address relayer, // solhint-disable-line no-unused-vars
        address sponsor, // solhint-disable-line no-unused-vars
        uint256 timestamp, // solhint-disable-line no-unused-vars
        bytes calldata data,
        bytes calldata signature // solhint-disable-line no-unused-vars
    ) external override {
        require(
            keccak256(data) ==
                updateBeaconSetWithBeacons(abi.decode(data, (bytes32[]))),
            "Data length not correct"
        );
    }

    ///                     ~~~Signed data Beacon set updates~~~

    /// @notice Updates a Beacon set using data signed by the respective
    /// Airnodes without requiring a request or subscription. The Beacons for
    /// which the signature is omitted will be read from the storage.
    /// @param airnodes Airnode addresses
    /// @param templateIds Template IDs
    /// @param timestamps Timestamps used in the signatures
    /// @param data Response data (an `int256` encoded in contract ABI per
    /// Beacon)
    /// @param signatures Template ID, a timestamp and the response data signed
    /// by the respective Airnode address per Beacon
    /// @return beaconSetId Beacon set ID
    function updateBeaconSetWithSignedData(
        address[] memory airnodes,
        bytes32[] memory templateIds,
        uint256[] memory timestamps,
        bytes[] memory data,
        bytes[] memory signatures
    ) external override returns (bytes32 beaconSetId) {
        uint256 beaconCount = airnodes.length;
        require(
            beaconCount == templateIds.length &&
                beaconCount == timestamps.length &&
                beaconCount == data.length &&
                beaconCount == signatures.length,
            "Parameter length mismatch"
        );
        require(beaconCount > 1, "Specified less than two Beacons");
        bytes32[] memory beaconIds = new bytes32[](beaconCount);
        int256[] memory values = new int256[](beaconCount);
        uint256 accumulatedTimestamp = 0;
        for (uint256 ind = 0; ind < beaconCount; ind++) {
            if (signatures[ind].length != 0) {
                address airnode = airnodes[ind];
                uint256 timestamp = timestamps[ind];
                require(timestampIsValid(timestamp), "Timestamp not valid");
                require(
                    (
                        keccak256(
                            abi.encodePacked(
                                templateIds[ind],
                                timestamp,
                                data[ind]
                            )
                        ).toEthSignedMessageHash()
                    ).recover(signatures[ind]) == airnode,
                    "Signature mismatch"
                );
                values[ind] = decodeFulfillmentData(data[ind]);
                // Timestamp validity is already checked, which means it will
                // be small enough to be typecast into `uint32`
                accumulatedTimestamp += timestamp;
                beaconIds[ind] = deriveBeaconId(airnode, templateIds[ind]);
            } else {
                bytes32 beaconId = deriveBeaconId(
                    airnodes[ind],
                    templateIds[ind]
                );
                DataFeed storage dataFeed = dataFeeds[beaconId];
                values[ind] = dataFeed.value;
                accumulatedTimestamp += dataFeed.timestamp;
                beaconIds[ind] = beaconId;
            }
        }
        beaconSetId = deriveBeaconSetId(beaconIds);
        uint32 updatedTimestamp = uint32(accumulatedTimestamp / beaconCount);
        require(
            updatedTimestamp >= dataFeeds[beaconSetId].timestamp,
            "Updated value outdated"
        );
        int224 updatedValue = int224(median(values));
        dataFeeds[beaconSetId] = DataFeed({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedBeaconSetWithSignedData(
            beaconSetId,
            updatedValue,
            updatedTimestamp
        );
    }

    /// @notice Called by the manager to add the unlimited reader indefinitely
    /// @dev Since the unlimited reader status cannot be revoked, only
    /// contracts that are adequately restricted should be given this status
    /// @param unlimitedReader Unlimited reader address
    function addUnlimitedReader(address unlimitedReader) external override {
        require(msg.sender == manager, "Sender not manager");
        unlimitedReaderStatus[unlimitedReader] = true;
        emit AddedUnlimitedReader(unlimitedReader);
    }

    /// @notice Sets the data feed ID the dAPI name points to
    /// @dev While a data feed ID refers to a specific Beacon or Beacon set,
    /// dAPI names provide a more abstract interface for convenience. This
    /// means a dAPI name that was pointing to a Beacon can be pointed to a
    /// Beacon set, then another Beacon set, etc.
    /// @param dapiName Human-readable dAPI name
    /// @param dataFeedId Data feed ID the dAPI name will point to
    function setDapiName(bytes32 dapiName, bytes32 dataFeedId)
        external
        override
    {
        require(dapiName != bytes32(0), "dAPI name zero");
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    dapiNameSetterRole,
                    msg.sender
                ),
            "Sender cannot set dAPI name"
        );
        dapiNameHashToDataFeedId[
            keccak256(abi.encodePacked(dapiName))
        ] = dataFeedId;
        emit SetDapiName(dapiName, dataFeedId, msg.sender);
    }

    /// @notice Returns the data feed ID the dAPI name is set to
    /// @param dapiName dAPI name
    /// @return Data feed ID
    function dapiNameToDataFeedId(bytes32 dapiName)
        external
        view
        override
        returns (bytes32)
    {
        return dapiNameHashToDataFeedId[keccak256(abi.encodePacked(dapiName))];
    }

    /// @notice Reads the data feed with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithId(bytes32 dataFeedId)
        external
        view
        override
        returns (int224 value, uint32 timestamp)
    {
        require(
            readerCanReadDataFeed(dataFeedId, msg.sender),
            "Sender cannot read"
        );
        DataFeed storage dataFeed = dataFeeds[dataFeedId];
        return (dataFeed.value, dataFeed.timestamp);
    }

    /// @notice Reads the data feed value with ID
    /// @param dataFeedId Data feed ID
    /// @return value Data feed value
    function readDataFeedValueWithId(bytes32 dataFeedId)
        external
        view
        override
        returns (int224 value)
    {
        require(
            readerCanReadDataFeed(dataFeedId, msg.sender),
            "Sender cannot read"
        );
        DataFeed storage dataFeed = dataFeeds[dataFeedId];
        require(dataFeed.timestamp != 0, "Data feed does not exist");
        return dataFeed.value;
    }

    /// @notice Reads the data feed with dAPI name
    /// @dev The read data feed may belong to a Beacon or dAPI. The reader
    /// must be whitelisted for the hash of the dAPI name.
    /// @param dapiName dAPI name
    /// @return value Data feed value
    /// @return timestamp Data feed timestamp
    function readDataFeedWithDapiName(bytes32 dapiName)
        external
        view
        override
        returns (int224 value, uint32 timestamp)
    {
        bytes32 dapiNameHash = keccak256(abi.encodePacked(dapiName));
        require(
            readerCanReadDataFeed(dapiNameHash, msg.sender),
            "Sender cannot read"
        );
        bytes32 dataFeedId = dapiNameHashToDataFeedId[dapiNameHash];
        require(dataFeedId != bytes32(0), "dAPI name not set");
        DataFeed storage dataFeed = dataFeeds[dataFeedId];
        return (dataFeed.value, dataFeed.timestamp);
    }

    /// @notice Reads the data feed value with dAPI name
    /// @param dapiName dAPI name
    /// @return value Data feed value
    function readDataFeedValueWithDapiName(bytes32 dapiName)
        external
        view
        override
        returns (int224 value)
    {
        bytes32 dapiNameHash = keccak256(abi.encodePacked(dapiName));
        require(
            readerCanReadDataFeed(dapiNameHash, msg.sender),
            "Sender cannot read"
        );
        DataFeed storage dataFeed = dataFeeds[
            dapiNameHashToDataFeedId[dapiNameHash]
        ];
        require(dataFeed.timestamp != 0, "Data feed does not exist");
        return dataFeed.value;
    }

    /// @notice Returns if a reader can read the data feed
    /// @param dataFeedId Data feed ID (or dAPI name hash)
    /// @param reader Reader address
    /// @return If the reader can read the data feed
    function readerCanReadDataFeed(bytes32 dataFeedId, address reader)
        public
        view
        override
        returns (bool)
    {
        return
            reader == address(0) ||
            userIsWhitelisted(dataFeedId, reader) ||
            unlimitedReaderStatus[reader];
    }

    /// @notice Returns the detailed whitelist status of the reader for the
    /// data feed
    /// @param dataFeedId Data feed ID (or dAPI name hash)
    /// @param reader Reader address
    /// @return expirationTimestamp Timestamp at which the whitelisting of the
    /// reader will expire
    /// @return indefiniteWhitelistCount Number of times `reader` was
    /// whitelisted indefinitely for `dataFeedId`
    function dataFeedIdToReaderToWhitelistStatus(
        bytes32 dataFeedId,
        address reader
    )
        external
        view
        override
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount)
    {
        WhitelistStatus
            storage whitelistStatus = serviceIdToUserToWhitelistStatus[
                dataFeedId
            ][reader];
        expirationTimestamp = whitelistStatus.expirationTimestamp;
        indefiniteWhitelistCount = whitelistStatus.indefiniteWhitelistCount;
    }

    /// @notice Returns if an account has indefinitely whitelisted the reader
    /// for the data feed
    /// @param dataFeedId Data feed ID (or dAPI name hash)
    /// @param reader Reader address
    /// @param setter Address of the account that has potentially whitelisted
    /// the reader for the data feed indefinitely
    /// @return indefiniteWhitelistStatus If `setter` has indefinitely
    /// whitelisted reader for the data feed
    function dataFeedIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 dataFeedId,
        address reader,
        address setter
    ) external view override returns (bool indefiniteWhitelistStatus) {
        indefiniteWhitelistStatus = serviceIdToUserToSetterToIndefiniteWhitelistStatus[
            dataFeedId
        ][reader][setter];
    }

    /// @notice Derives the Beacon ID from the Airnode address and template ID
    /// @param airnode Airnode address
    /// @param templateId Template ID
    /// @return beaconId Beacon ID
    function deriveBeaconId(address airnode, bytes32 templateId)
        public
        pure
        override
        returns (bytes32 beaconId)
    {
        require(airnode != address(0), "Airnode address zero");
        require(templateId != bytes32(0), "Template ID zero");
        beaconId = keccak256(abi.encodePacked(airnode, templateId));
    }

    /// @notice Derives the Beacon set ID from the Beacon IDs
    /// @dev Notice that `abi.encode()` is used over `abi.encodePacked()`
    /// @param beaconIds Beacon IDs
    /// @return beaconSetId Beacon set ID
    function deriveBeaconSetId(bytes32[] memory beaconIds)
        public
        pure
        override
        returns (bytes32 beaconSetId)
    {
        beaconSetId = keccak256(abi.encode(beaconIds));
    }

    /// @notice Called privately to process the Beacon update
    /// @param beaconId Beacon ID
    /// @param timestamp Timestamp used in the signature
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return updatedBeaconValue Updated Beacon value
    function processBeaconUpdate(
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data
    ) private returns (int256 updatedBeaconValue) {
        updatedBeaconValue = decodeFulfillmentData(data);
        require(
            timestamp > dataFeeds[beaconId].timestamp,
            "Fulfillment older than Beacon"
        );
        // Timestamp validity is already checked by `onlyValidTimestamp`, which
        // means it will be small enough to be typecast into `uint32`
        dataFeeds[beaconId] = DataFeed({
            value: int224(updatedBeaconValue),
            timestamp: uint32(timestamp)
        });
    }

    /// @notice Called privately to decode the fulfillment data
    /// @param data Fulfillment data (an `int256` encoded in contract ABI)
    /// @return decodedData Decoded fulfillment data
    function decodeFulfillmentData(bytes memory data)
        private
        pure
        returns (int224)
    {
        require(data.length == 32, "Data length not correct");
        int256 decodedData = abi.decode(data, (int256));
        require(
            decodedData >= type(int224).min && decodedData <= type(int224).max,
            "Value typecasting error"
        );
        return int224(decodedData);
    }

    /// @notice Called privately to decode the condition parameters
    /// @param conditionParameters Condition parameters (a `uint256` encoded in
    /// contract ABI)
    /// @return deviationThresholdInPercentage Deviation threshold in
    /// percentage where 100% is represented as `HUNDRED_PERCENT`
    function decodeConditionParameters(bytes calldata conditionParameters)
        private
        pure
        returns (uint256 deviationThresholdInPercentage)
    {
        require(conditionParameters.length == 32, "Incorrect parameter length");
        deviationThresholdInPercentage = abi.decode(
            conditionParameters,
            (uint256)
        );
    }

    /// @notice Called privately to calculate the update magnitude in
    /// percentages where 100% is represented as `HUNDRED_PERCENT`
    /// @dev The percentage changes will be more pronounced when the first
    /// value is almost zero, which may trigger updates more frequently than
    /// wanted. To avoid this, Beacons should be defined in a way that the
    /// expected values are not small numbers floating around zero, i.e.,
    /// offset and scale.
    /// @param initialValue Initial value
    /// @param updatedValue Updated value
    /// @return updateInPercentage Update in percentage
    function calculateUpdateInPercentage(
        int224 initialValue,
        int224 updatedValue
    ) private pure returns (uint256 updateInPercentage) {
        int256 delta = int256(updatedValue) - int256(initialValue);
        uint256 absoluteDelta = delta > 0 ? uint256(delta) : uint256(-delta);
        uint256 absoluteInitialValue = initialValue > 0
            ? uint256(int256(initialValue))
            : uint256(-int256(initialValue));
        // Avoid division by 0
        if (absoluteInitialValue == 0) {
            absoluteInitialValue = 1;
        }
        updateInPercentage =
            (absoluteDelta * HUNDRED_PERCENT) /
            absoluteInitialValue;
    }
}