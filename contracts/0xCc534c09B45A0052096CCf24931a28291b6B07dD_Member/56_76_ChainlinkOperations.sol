//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract ChainlinkOperations is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ChainlinkClient
{
    /// @dev ProtocolDirectory location
    address public directoryContract;

    /// @dev allows us to use Chainlink methods for requesting data
    using Chainlink for Chainlink.Request;

    /// @dev job ID that the node provider sets up
    bytes32 private jobId;

    /// @dev amount in link to pay oracle for data
    uint256 private constant ORACLE_PAYMENT = 0;

    /// @dev URL of our API that will be requested
    string private WEBACY_API_URL;

    /// @dev What field(s) in the JSON response we want
    string private PATH;

    /// @dev LINK token
    IERC20 public LINK_TOKEN;

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
        bytes32 _jobId
    ) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        directoryContract = _directoryContract;
        WEBACY_API_URL = _webacyUrl;
        PATH = _path;
        setChainlinkToken(_linkToken);
        LINK_TOKEN = IERC20(_linkToken);
        setChainlinkOracle(_oracle);
        jobId = _jobId;
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
     * @dev requestBytes - this is the "main" function that calls our API
     */
    function requestBytes() public {
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