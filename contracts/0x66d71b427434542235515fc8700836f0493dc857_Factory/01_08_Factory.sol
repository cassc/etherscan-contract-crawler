// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../controller/ControllerInterface.sol";
import "./FactoryInterface.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title AMKT Factory
/// @author Alongside Finance
/// @notice Allows Merchants to initiate burn/mint requests and allows custodians to approve or deny them
contract Factory is FactoryInterface, OwnableUpgradeable, PausableUpgradeable {
    
    ///=============================================================================================
    /// Data Structres
    ///=============================================================================================

    enum RequestStatus {
        PENDING,
        CANCELED,
        APPROVED,
        REJECTED
    }

    struct Request {
        address requester; // sender of the request.
        uint256 amount; // amount of token to mint/burn.
        string depositAddress; // custodian's asset address in mint, merchant's asset address in burn.
        string txid; // asset txid for sending/redeeming asset in the mint/burn process.
        uint256 nonce; // serial number allocated for each request.
        uint256 timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    ///=============================================================================================
    /// State Variables
    ///=============================================================================================

    ControllerInterface public controller;

    // mapping between merchant to its per-mint limit.
    mapping(address => uint256) public merchantMintLimit;

    // mapping between merchant to its per-burn limit.
    mapping(address => uint256) public merchantBurnLimit;

    // mapping between merchant to the corresponding custodian deposit address, used in the minting process.
    // by using a different deposit address per merchant the custodian can identify which merchant deposited.
    mapping(address => string) public custodianDepositAddress;

    // mapping between merchant to the its deposit address where the asset should be moved to, used in the burning process.
    mapping(address => string) public merchantDepositAddress;

    // mapping between a mint request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    ///=============================================================================================
    /// Initializer
    ///=============================================================================================

    function initialize(address _controller) external initializer {
        controller = ControllerInterface(_controller);

        __Ownable_init();
        __Pausable_init();

        transferOwnership(_controller);
    }

    ///=============================================================================================
    /// Modifiers
    ///=============================================================================================

    modifier onlyMerchant() {
        require(controller.isMerchant(msg.sender), "sender not a merchant.");
        _;
    }

    modifier onlyCustodian() {
        require(controller.isCustodian(msg.sender), "sender not a custodian.");
        _;
    }

    modifier onlyFactoryAdmin() {
        require(
            controller.isFactoryAdmin(msg.sender),
            "sender not a factory admin."
        );
        _;
    }

    modifier onlyFactoryAdminOrCustodian() {
        require(
            controller.isFactoryAdmin(msg.sender) ||
                controller.isCustodian(msg.sender),
            "sender not a factory admin."
        );
        _;
    }

    ///=============================================================================================
    /// Setters
    ///=============================================================================================

    /// @notice sets the address for the merchant to deposit thier assets
    /// @param merchant address
    /// @param depositAddress string
    /// @return bool
    function setCustodianDepositAddress(
        address merchant,
        string memory depositAddress
    ) external override onlyFactoryAdmin returns (bool) {
        require(merchant != address(0), "invalid merchant address");
        require(
            controller.isMerchant(merchant),
            "merchant address is not a real merchant."
        );
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );

        custodianDepositAddress[merchant] = depositAddress;
        emit CustodianDepositAddressSet(merchant, msg.sender, depositAddress);
        return true;
    }

    /// @notice Allows a merchant to relay what address they will be sending assets from
    /// @param depositAddress string
    /// @return bool
    function setMerchantDepositAddress(string memory depositAddress)
        external
        override
        onlyMerchant
        returns (bool)
    {
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );

        merchantDepositAddress[msg.sender] = depositAddress;
        emit MerchantDepositAddressSet(msg.sender, depositAddress);
        return true;
    }

    /// @notice Sets the maximum mint limit allowed per merchant
    /// @param merchant address
    /// @param amount uint256
    /// @return bool
    function setMerchantMintLimit(address merchant, uint256 amount)
        external
        override
        onlyFactoryAdmin
        returns (bool)
    {
        merchantMintLimit[merchant] = amount;
        return true;
    }

    /// @notice Sets the maximum burn limit allowed per merchant
    /// @param merchant address
    /// @param amount uint256
    /// @return bool
    function setMerchantBurnLimit(address merchant, uint256 amount)
        external
        override
        onlyFactoryAdmin
        returns (bool)
    {
        merchantBurnLimit[merchant] = amount;
        return true;
    }

    ///=============================================================================================
    /// Merchant Mint Logic
    ///=============================================================================================

    /// @notice Allows a merchnat to initiate a mint request
    /// @param amount uint256
    /// @param txid string
    /// @param depositAddress string
    /// @return bool
    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) external override onlyMerchant whenNotPaused returns (uint256) {
        require(
            !isEmptyString(depositAddress),
            "invalid asset deposit address"
        );
        require(
            compareStrings(depositAddress, custodianDepositAddress[msg.sender]),
            "wrong asset deposit address"
        );
        require(amount <= merchantMintLimit[msg.sender], "exceeds mint limit");
        uint256 nonce = mintRequests.length;
        uint256 timestamp = getTimestamp();

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            depositAddress: depositAddress,
            txid: txid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestNonce[requestHash] = nonce;
        mintRequests.push(request);

        emit MintRequestAdd(
            nonce,
            msg.sender,
            amount,
            depositAddress,
            txid,
            timestamp,
            requestHash
        );
        return nonce;
    }

    /// @notice Allows a merchnat to cancel a mint request
    /// @param requestHash bytes32
    /// @return bool
    function cancelMintRequest(bytes32 requestHash)
        external
        override
        onlyMerchant
        whenNotPaused
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        require(
            msg.sender == request.requester,
            "cancel sender is different than pending request initiator"
        );
        mintRequests[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
        return true;
    }

    ///=============================================================================================
    /// Custodian Mint Logic
    ///=============================================================================================

    /// @notice Allows a custodian to confirm a mint request
    /// @param requestHash bytes32
    /// @return bool
    function confirmMintRequest(bytes32 requestHash)
        external
        override
        onlyFactoryAdminOrCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.APPROVED;
        require(
            controller.mint(request.requester, request.amount),
            "mint failed"
        );

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    /// @notice Allows a custodian to reject a mint request
    /// @param requestHash bytes32
    /// @return bool
    function rejectMintRequest(bytes32 requestHash)
        external
        override
        onlyFactoryAdminOrCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    ///=============================================================================================
    /// Merchant Burn Logic
    ///=============================================================================================

    /// @notice Allows a merchnat to initiate a burn request
    /// @param amount uint256
    /// @return bool
    function burn(uint256 amount, string memory txid)
        external
        override
        onlyMerchant
        whenNotPaused
        returns (uint256)
    {
        require(amount <= merchantBurnLimit[msg.sender], "exceeds burn limit");
        string memory depositAddress = merchantDepositAddress[msg.sender];
        require(
            !isEmptyString(depositAddress),
            "merchant asset deposit address was not set"
        );

        uint256 nonce = burnRequests.length;
        uint256 timestamp = getTimestamp();

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            depositAddress: depositAddress,
            txid: txid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce;
        burnRequests.push(request);

        require(controller.burn(msg.sender, amount), "burn failed");

        emit Burned(
            nonce,
            msg.sender,
            amount,
            depositAddress,
            timestamp,
            requestHash
        );
        return nonce;
    }

    ///=============================================================================================
    /// Custodian Burn Logic
    ///=============================================================================================

    /// @notice Allows a custodian to confirm a burn request
    /// @param requestHash bytes32
    /// @return bool
    function confirmBurnRequest(bytes32 requestHash)
        external
        override
        onlyFactoryAdminOrCustodian
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].status = RequestStatus.APPROVED;
        burnRequestNonce[calcRequestHash(burnRequests[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    ///=============================================================================================
    /// Pause Logic
    ///=============================================================================================

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    ///=============================================================================================
    /// Non Mutable
    ///=============================================================================================

    function getBurnRequestsLength()
        external
        view
        override
        returns (uint256 length)
    {
        return burnRequests.length;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param nonce uint256
    function getBurnRequest(uint256 nonce)
        external
        view
        override
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    /// @notice Explain to an end user what this does
    /// @dev External function, calculate the request hash and returns it
    /// @param nonce uint256
    function getMintRequest(uint256 nonce)
        external
        view
        override
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request memory request = mintRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getTimestamp() internal view returns (uint256) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function getPendingMintRequest(bytes32 requestHash)
        internal
        view
        returns (uint256 nonce, Request memory request)
    {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash)
        internal
        view
        returns (uint256 nonce, Request memory request)
    {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getMintRequestsLength()
        external
        view
        override
        returns (uint256 length)
    {
        return mintRequests.length;
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash)
        internal
        pure
    {
        require(
            request.status == RequestStatus.PENDING,
            "request is not pending"
        );
        require(
            requestHash == calcRequestHash(request),
            "given request hash does not match a pending request"
        );
    }

    function calcRequestHash(Request memory request)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    request.requester,
                    request.amount,
                    request.depositAddress,
                    request.txid,
                    request.nonce,
                    request.timestamp
                )
            );
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(a)) ==
            keccak256(abi.encodePacked(b)));
    }

    function isEmptyString(string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status)
        internal
        pure
        returns (string memory)
    {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
            // this fallback can never be reached.
            return "unknown";
        }
    }
}