// SPDX-License-Identifier: Apache-2.0
// Author: D3Serve Labs Inc. <[email protected]>
// Source Code Repo: https://github.com/d3servelabs/d3caf

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@ercref/contracts/drafts/IERC5732.sol";

enum RewardType {
    ETH,
    ERC20
}

/**
 * @title D3CAFRequest
 * @dev Represents a D3CAF request.
 */
struct D3CAFRequest {
    address factory;        // The address of the factory.
    bytes32 bytecodeHash;   // The hash of the bytecode.
    uint256 expireAt;       // After this block, the request is considered expired and reward can be claimed.
    bytes32 initSalt;       // Initial salt
    RewardType rewardType;  // The type of reward.
    uint256 rewardAmount;   // The reward amount for the request. For Ethers the unit will be `wei`.
    address rewardToken;    // The reward token address. For ETH, this is Zero. Non-Zeros are reserved for ERC20 and future extensions.
    address payable refundReceiver;  // The address of the refund receiver.
}

/**
 * @title D3CAFImplV1
 * @notice This contract implements the D3CAF mechanism.
 * @dev Economic Mechanism:
 * - Criteria: any GeneratedAddress **lower than** the Bar is eligible for reward.
 *   - The commission rate is a parameter, currently 0%.
 *   - The commission is paid to the commissionRecipient.
 *   - Currently supports ETH and hopes to support ERC20 in the future by extending the type.
 * - When there is no submission that meets the criteria before the deadline,
 *   the reward is returned to the submitter.
 * - When there are multiple submissions before the deadline that meet the criteria,
 *   the submitter who submitted the lowest address is considered "the winner"
 *   and can claim the reward.
 */
contract D3CAFImplV1 is Initializable, ContextUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 private comissionRateBasisPoints;    // The commission basis points (0-10000).
    address payable private commissionReceiver;  // The address of the commission receiver.
    uint256 private maxDeadlineBlockDuration;  // The maximum duration in blocks for a request deadline.

    mapping(bytes32 /* RequestId */ => D3CAFRequest) private create2Requests;  // Mapping to store D3CAF requests.
    mapping(bytes32 /* RequestId */ => bytes32) private currentBestSalt;      // Mapping to store the current best salt for each request.

    event OnRegisterD3CAFRequest(
        bytes32 indexed requestId
    );

    event OnClearD3CAFRequest(bytes32 indexed requestId);
    event OnNewSalt(
        bytes32 indexed requestId, 
        bytes32 indexed salt,
        address indexed calculatedAddress
    );

    event OnClaimD3CAFReward(
        bytes32 indexed requestId,
        address indexed winner,
        bytes32 indexed salt,
        address calculatedAddress,
        uint256 rewardAmount,
        address rewardToken
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        maxDeadlineBlockDuration = 604800 / 12; // 2 weeks 
        commissionReceiver = payable(owner());
        comissionRateBasisPoints = 500; // 5%
    }

    /**
     * @dev Calculates the input salt for Create2 a given reward receiver address and raw salt.
     *      The purpose is to prevent front-running.
     * @param rewardReceiver The address of the reward receiver.
     * @param sourceSalt The source salt for the input of compositeSalt.
     * @return The calculated salt.
     */
    function _computeSalt(
        address rewardReceiver,
        bytes32 sourceSalt
    ) internal pure returns (bytes32) {
        // Add "V1" to the pack to prevent collision with future versions.
        return keccak256(abi.encodePacked(rewardReceiver, sourceSalt));
    }

    /**
     * @dev Computes the Create2 address based on the request ID and salt.
     * @param requestId The ID of the request.
     * @param salt The salt value.
     * @return The computed Create2 address.
     */
    function _computeAddress(bytes32 requestId, bytes32 salt) internal view returns (address) {
        D3CAFRequest memory _request = create2Requests[requestId];
        return Create2.computeAddress(
            salt,
            _request.bytecodeHash,
            _request.factory
        );
    }

    /**
     * @dev Computes the Create2 address based on the request ID and salt.
     * @param requestId The ID of the request.
     * @param salt The salt value.
     * @return The computed Create2 address.
     */
    function computeAddress(bytes32 requestId, bytes32 salt) public view returns (address) {
        return _computeAddress(requestId, salt);
    }

    /**
     * @dev Computes the salt based on the reward receiver and raw salt.
     * @param sender The address of the sender.
     * @param rawSalt The raw salt value.
     * @return The computed salt.
     */
    function computeSalt(address sender, bytes32 rawSalt) public pure returns (bytes32) {
        return _computeSalt(sender, rawSalt);
    }

    /**
     * @dev Clears the request from the storage.
     * @param requestId The requestId of the request.
     */
    function _clearRequest(bytes32 requestId) internal {
        delete create2Requests[requestId];
        delete currentBestSalt[requestId];
        emit OnClearD3CAFRequest(requestId);
    }

    /**
     * @dev Computes the request ID based on the request information.
     * @param _request The request information.
     * @return requestId The computed request ID.
     */
    function _computeRequestId(
        D3CAFRequest memory _request
    ) internal pure returns (bytes32 requestId) {
        return
            keccak256(
                abi.encodePacked(
                    _request.factory,
                    _request.bytecodeHash,
                    _request.expireAt,
                    _request.refundReceiver
                )
            );
    }

    /**
     * @dev Computes the request ID based on the request information.
     * @param _request The request information.
     * @return requestId The computed request ID.
     */
    function computeRequestId(
        D3CAFRequest memory _request
    ) public pure returns (bytes32 requestId) {
        return _computeRequestId(_request);
    }

    /**
     * @dev Gets the factory address for a request.
     * @param requestId The request ID.
     * @return The factory address.
     */
    function getFactory(bytes32 requestId) external view returns (address) {
        return create2Requests[requestId].factory;
    }

    /**
     * @dev Gets the bytecode hash for a request.
     * @param requestId The request ID.
     * @return The bytecode hash.
     */
    function getBytecodeHash(bytes32 requestId) external view returns (bytes32) {
        return create2Requests[requestId].bytecodeHash;
    }

    /**
     * @dev Gets the current best salt for a request.
     * @param requestId The request ID.
     * @return The current best salt value.
     */
    function getCurrentBestSalt(bytes32 requestId) external view returns (bytes32) {
        return currentBestSalt[requestId];
    }

    /**
     * @dev Gets the request information for a given request ID.
     * @param requestId The request ID.
     * @return The request information.
     */
    function getCreate2Request(bytes32 requestId) external view returns (D3CAFRequest memory) {
        return create2Requests[requestId];
    }

    /**
     * @dev Sets the commission receiver address.
     * @param _commissionReceiver The address of the commission receiver.
     */
    function setCommissionReceiver(address payable _commissionReceiver) external onlyOwner {
        commissionReceiver = _commissionReceiver;
    }

    /**
     * @dev Gets the commission receiver address.
     * @return The address of the commission receiver.
     */
    function getCommissionReceiver() external view returns (address payable) {
        return commissionReceiver;
    }

    /**
     * @dev Sets the commission rate basis points.
     * @param _comissionRateBasisPoints The commission basis points.
     */
    function setComissionRateBasisPoints(uint256 _comissionRateBasisPoints) external onlyOwner {
        require(_comissionRateBasisPoints <= 10000, "D3CAF: comission invalid");
        comissionRateBasisPoints = _comissionRateBasisPoints;
    }

    /**
     * @dev Gets the commission basis points.
     * @return The commission basis points.
     */
    function getComissionRateBasisPoints() external view returns (uint256) {
        return comissionRateBasisPoints;
    }

    /**
     * @dev Sets the maximum deadline block duration.
     * @param _maxDeadlineBlockDuration The maximum deadline block duration.
     */
    function setMaxDeadlineBlockDuration(uint256 _maxDeadlineBlockDuration) external onlyOwner {
        maxDeadlineBlockDuration = _maxDeadlineBlockDuration;
    }

    /**
     * @dev Gets the maximum deadline block duration.
     * @return The maximum deadline block duration.
     */
    function getMaxDeadlineBlockDuration() external view returns (uint256) {
        return maxDeadlineBlockDuration;
    }

    /**
     * @dev Registers a new D3CAF request.
     * @param _request The request information.
     * @return The request ID.
     */
    function registerCreate2Request(
        D3CAFRequest memory _request
    ) external payable returns (bytes32) {
        require(_request.expireAt > block.number, "D3CAF: request expired");
        require(
            _request.expireAt <= block.number + maxDeadlineBlockDuration,
            "D3CAF: deadline too far"
        );
        require(_request.refundReceiver != address(0), "D3CAF: refundReceiver not set");
        require(_request.factory != address(0), "D3CAF: factory not set");

        require(_request.rewardType == RewardType.ETH, "D3CAF: only $ETH supported");
        require(_request.rewardToken == address(0), "D3CAF: only $ETH supported");
        
        require(msg.value == _request.rewardAmount, "D3CAF: reward amount does not match");

        bytes32 requestId = _computeRequestId(_request);
        require(create2Requests[requestId].expireAt == 0, "D3CAF: requestId already exists");
        create2Requests[_computeRequestId(_request)] = _request;
        currentBestSalt[requestId] = _request.initSalt;
        
        address calculatedAddress = Create2.computeAddress(
            _request.initSalt,
            _request.bytecodeHash,
            _request.factory
        );

        emit OnNewSalt(requestId, _request.initSalt, calculatedAddress);
        emit OnRegisterD3CAFRequest(
            requestId
        );

        return requestId;
    }

    /**
     * @dev Registers a response for a request.
     * @param requestId The request ID.
     * @param salt The salt value.
     */
    function registerResponse(bytes32 requestId, bytes32 salt) external payable {
        D3CAFRequest memory request = create2Requests[requestId];
        require(request.expireAt > block.number, "D3CAF: expired");
        address lastBestAddress = _computeAddress(requestId, currentBestSalt[requestId]);
        address newAddress = _computeAddress(requestId, salt);

        require(newAddress <= address(uint160(lastBestAddress) / (2 ** 4)), 
            "D3CAF: At least one more zero");
        currentBestSalt[requestId] = salt;
        emit OnNewSalt(
            requestId, 
            salt, 
            newAddress);
    }

    /**
     * @dev Claims the reward for a request.
     * @param requestId The request ID.
     * @param winner The address of the winner.
     * @param sourceSalt The source salt value.
     */
    function claimReward(
        bytes32 requestId, 
        address payable winner, 
        bytes32 sourceSalt
    ) external {
        D3CAFRequest memory request = create2Requests[requestId];
        require(request.expireAt <= block.number, "D3CAF: request is not expired");

        bytes32 salt = _computeSalt(winner, sourceSalt);
        require(currentBestSalt[requestId] == salt, "D3CAF: salt not matched");

        address computedAddress = Create2.computeAddress(
            salt,
            request.bytecodeHash,
            request.factory
        );
        emit OnClaimD3CAFReward(
            requestId,
            winner,
            salt,
            computedAddress,
            request.rewardAmount,
            request.rewardToken
        );

        _clearRequest(requestId);

        require(request.rewardType == RewardType.ETH, "D3CAF: unknown reward type");
        require(request.rewardToken == address(0), "D3CAF: unknown reward token");
        
        uint256 commission = request.rewardAmount.mul(comissionRateBasisPoints).div(10000);

        commissionReceiver.transfer(commission);
        uint256 remainder = request.rewardAmount.sub(commission);
        winner.transfer(remainder);
    }

    /**
     * @dev Allows the requester to claim back the reward if no submission meets the bar yet.
     * @param requestId The request ID.
     */
    function requesterWithdraw(bytes32 requestId) external {
        D3CAFRequest memory request = create2Requests[requestId];

        require(request.expireAt <= block.number, "D3CAF: too soon");
        require(currentBestSalt[requestId] == 
            create2Requests[requestId].initSalt, "D3CAF: must have no submission");
        _clearRequest(requestId);

        request.refundReceiver.transfer(request.rewardAmount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}