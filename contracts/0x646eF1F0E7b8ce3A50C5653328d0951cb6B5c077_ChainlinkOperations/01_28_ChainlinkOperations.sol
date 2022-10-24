//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./chainlink/ChainlinkClientUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title ChainlinkOperations Contract
 *
 * Relays heartbeat info on-chain via Chainlink Keepers and AnyAPI
 *
 */

contract ChainlinkOperations is
    Initializable,
    OwnableUpgradeable,
    ChainlinkClientUpgradeable,
    AutomationCompatibleInterface
{
    /// @dev ProtocolDirectory location
    address public directoryContract;

    /// @dev allows us to use Chainlink methods for requesting data
    using Chainlink for Chainlink.Request;

    /// @dev job ID that the node provider sets up
    bytes32 public jobId;

    /// @dev amount in link to pay oracle for data
    uint256 public ORACLE_PAYMENT;

    /// @dev URL of our API that will be requested
    string public WEBACY_API_URL;

    /// @dev What field(s) in the JSON response we want
    string public PATH;

    /// @dev LINK token
    IERC20 public LINK_TOKEN;

    /// @dev timestamp of last request
    uint256 public lastRequestTime;

    /// @dev interval for requests
    uint256 public requestInterval;

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract - address of the ProtocolDirectory contract
     * @param _webacyUrl - URL of our API that will be requested
     * @param _linkToken - address of the LINK token
     * @param _oracle - address of the oracle
     * @param _jobId - job ID that the node provider sets up
     */
    function initialize(
        address _directoryContract,
        string calldata _webacyUrl,
        string calldata _path,
        address _linkToken,
        address _oracle,
        bytes32 _jobId,
        uint256 _oraclePayment
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ChainlinkClientUpgradeable_init();
        directoryContract = _directoryContract;
        WEBACY_API_URL = _webacyUrl;
        PATH = _path;
        setChainlinkToken(_linkToken);
        LINK_TOKEN = IERC20(_linkToken);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        ORACLE_PAYMENT = _oraclePayment;
        requestInterval = 1 days;
    }

    /**
     * @dev setWebacyUrl updates the API URL we're requesting
     * @param _webacyUrl - new url
     */
    function setWebacyUrl(string calldata _webacyUrl) external onlyOwner {
        WEBACY_API_URL = _webacyUrl;
    }

    /**
     * @dev setPath updates the path to fetch from response. If an empty string then the entire response is returned
     * @param _path - new path
     */
    function setPath(string calldata _path) external onlyOwner {
        PATH = _path;
    }

    /**
     * @dev setOracle updates oracle address in the event we're changing node providers
     * @param _addr - new oracle address
     */
    function setOracle(address _addr) external onlyOwner {
        setChainlinkOracle(_addr);
    }

    /**
     * @dev setOraclePayment updates LINK amount we pay per request
     * @param _amount - new amount
     */
    function setOraclePayment(uint _amount) external onlyOwner {
        ORACLE_PAYMENT = _amount;
    }

    /**
     * @dev setRequestInterval updates LINK amount we pay per request
     * @param _time - new time in seconds
     */
    function setRequestInterval(uint _time) external onlyOwner {
        requestInterval = _time;
    }

    /**
     * @dev setLinkToken updates linkTokenAddress
     * @param _addr - new token address
     */
    function setLinkToken(address _addr) external onlyOwner {
        setChainlinkToken(_addr);
        LINK_TOKEN = IERC20(_addr);
    }

    /**
     * @dev setJobId
     * @param _id - id of the job
     */
    function setJobId(bytes32 _id) external onlyOwner {
        jobId = _id;
    }

    /**
     * @dev withdrawLInk - withdraws LINK from the contract
     */
    function withdrawLink() external onlyOwner {
        bool sent = LINK_TOKEN.transfer(
            msg.sender,
            LINK_TOKEN.balanceOf(address(this))
        );
        require(sent, "Transfer Failed");
    }

    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. Here they aren't used so it doesn't matter and will just be '0x'
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not. This is based off whether it has been at least the requestInterval from the last call
     * @return performData bytes. Here they aren't used so it doesn't matter and will just be '0x'
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = block.timestamp - lastRequestTime >= requestInterval;
        performData = checkData;
    }

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external {
        if (block.timestamp - lastRequestTime < requestInterval) {
            revert("Request interval not met");
        }
        _requestBytes();
    }

    /**
     * @dev requestBytes - this is the "main" function that calls our API
     */
    function _requestBytes() internal {
        lastRequestTime = block.timestamp;
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillArray.selector
        );
        req.add("get", WEBACY_API_URL);
        // if PATH is not an empty string add it to the request
        if (bytes(PATH).length > 0) {
            req.add("path", PATH);
        }
        sendOperatorRequest(req, ORACLE_PAYMENT);
    }

    /// @dev this event indicated the API request has been relayed successfully
    event RequestFulfilled(bytes32 indexed requestId);

    /**
     * @dev fulfillArray is our callback function - i.e., what to do with the data when it is recieved by our conract
     * @dev we're turning the bytes into an address and then setting the approvals active for that address
     * @param requestId - id of the request
     * @param _arrayOfBytes - data returned from the API
     */
    function fulfillArray(bytes32 requestId, bytes[] memory _arrayOfBytes)
        public
        recordChainlinkFulfillment(requestId)
    {
        for (uint8 i = 0; i < _arrayOfBytes.length; i++) {
            _setApprovalActiveForUID(string(_arrayOfBytes[i]));
        }

        emit RequestFulfilled(requestId);
    }

    /**
     * @dev setApprovalActiveForUID - allows beneficiaries to claim on behalf of a given uid
     * @param _uid - uid to activate
     */
    function setApprovalActiveForUID(string memory _uid) external onlyOwner {
        _setApprovalActiveForUID(_uid);
    }

    /**
     * @dev _setApprovalActiveForUID - internal version called by fulfillArray
     * @param _uid - uid to activate
     */
    function _setApprovalActiveForUID(string memory _uid) internal {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }
}