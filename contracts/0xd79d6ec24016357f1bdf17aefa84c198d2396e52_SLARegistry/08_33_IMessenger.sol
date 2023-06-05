// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title IMessenger
 * @dev Interface to create new Messenger contract to add lo Messenger lists
 */

abstract contract IMessenger is Ownable {
    struct SLIRequest {
        address slaAddress;
        uint256 periodId;
    }

    /**
     * @dev event emitted when created a new chainlink request
     * @param caller 1. Requester's address
     * @param requestsCounter 2. total count of requests
     * @param requestId 3. id of the Chainlink request
     */
    event SLIRequested(
        address indexed caller,
        uint256 requestsCounter,
        bytes32 requestId
    );

    /**
     * @dev event emitted when having a response from Chainlink with the SLI
     * @param slaAddress 1. SLA address to store the SLI
     * @param periodId 2. period id
     * @param requestId 3. id of the Chainlink request
     * @param chainlinkResponse 4. response from Chainlink
     */
    event SLIReceived(
        address indexed slaAddress,
        uint256 periodId,
        bytes32 indexed requestId,
        bytes32 chainlinkResponse
    );

    /**
     * @dev event emitted when updating Chainlink Job ID
     * @param owner 1. Oracle Owner
     * @param jobId 2. Updated job id
     * @param fee 3. Chainlink request fee
     */
    event JobIdModified(address indexed owner, bytes32 jobId, uint256 fee);

    /**
     * @dev sets the SLARegistry contract address and can only be called once
     */
    function setSLARegistry() external virtual;

    /**
     * @dev creates a ChainLink request to get a new SLI value for the
     * given params. Can only be called by the SLARegistry contract or Chainlink Oracle.
     * @param _periodId 1. id of the period to be queried
     * @param _slaAddress 2. address of the receiver SLA
     * @param _slaAddress 2. if approval by owner or msg.sender
     */
    function requestSLI(
        uint256 _periodId,
        address _slaAddress,
        bool _ownerApproval,
        address _callerAddress
    ) external virtual;

    /**
     * @dev callback function for the Chainlink SLI request which stores
     * the SLI in the SLA contract
     * @param _requestId the ID of the ChainLink request
     * @param answer response object from Chainlink Oracles
     */
    function fulfillSLI(bytes32 _requestId, uint256 answer) external virtual;

    /**
     * @dev gets the interfaces precision
     */
    function messengerPrecision() external view virtual returns (uint256);

    /**
     * @dev gets the slaRegistryAddress
     */
    function slaRegistryAddress() external view virtual returns (address);

    /**
     * @dev gets the chainlink oracle contract address
     */
    function oracle() external view virtual returns (address);

    /**
     * @dev gets the chainlink job id
     */
    function jobId() external view virtual returns (bytes32);

    /**
     * @dev gets the fee amount of LINK token
     */
    function fee() external view virtual returns (uint256);

    /**
     * @dev returns the requestsCounter
     */
    function requestsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the fulfillsCounter
     */
    function fulfillsCounter() external view virtual returns (uint256);

    /**
     * @dev returns the name of DSLA-LP token
     */
    function lpName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token
     */
    function lpSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-LP token with slaId
     */
    function lpSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    /**
     * @dev returns the name of DSLA-SP token
     */
    function spName() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token
     */
    function spSymbol() external view virtual returns (string memory);

    /**
     * @dev returns the symbol of DSLA-SP token with slaId
     */
    function spSymbolSlaId(uint128 slaId)
        external
        view
        virtual
        returns (string memory);

    function setChainlinkJobID(bytes32 _newJobId, uint256 _feeMultiplier)
        external
        virtual;

    function retryRequest(address _slaAddress, uint256 _periodId)
        external
        virtual;
}