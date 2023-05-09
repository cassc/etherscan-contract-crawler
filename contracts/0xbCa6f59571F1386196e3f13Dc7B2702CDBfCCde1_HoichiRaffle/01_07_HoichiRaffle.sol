// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract HoichiRaffle is VRFConsumerBaseV2 {
    error UNAUTHORIZED();
    error INVALID_REQUEST();
    error INVALID_CONFIG();

    event RequestSent(uint256 requestId, uint32 numWords);
    event ReturnedRandomness(uint256 requestId, uint256 randomWords);

    IERC20 public immutable erc20;
    IERC721 public immutable erc721;
    LinkTokenInterface public immutable link;
    VRFCoordinatorV2Interface public vrfCoordinator;

    struct Config {
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint64 subscriptionID;
        bytes32 keyHash;
    }

    struct RandomDraw {
        address winnerAddress;
        uint256 drawReward;
        uint256 requestId;
        uint256 randomNumber;
        uint256[] randomWords;
    }

    Config public config;
    mapping(uint => RandomDraw) public rounds;
    uint256 public round;
    address public owner;
    address public manager;
    
    constructor(
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        uint32 _numWords,
        address _linkAddress,
        address _vrfCoordinator,
        address _erc721,
        address _erc20,
        address _multisigWallet,
        address _developmentWallet,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        link = LinkTokenInterface(_linkAddress);
        erc721 = IERC721(_erc721);
        erc20 = IERC20(_erc20);

        owner = _multisigWallet;
        manager = _developmentWallet;

        // create the contract subscription id
        uint64 subId = vrfCoordinator.createSubscription();

        // add subscription id for this contract as a consumer.
        vrfCoordinator.addConsumer(subId, address(this));

        // set raffle config
        config.subscriptionID = subId;
        config.requestConfirmations = _requestConfirmations;
        config.callbackGasLimit = _callbackGasLimit;
        config.numWords = _numWords;
        config.keyHash = _keyHash;

        // set first round
        round = 1;
    }

    /**
     * @dev Assumes this contract owns link token
     */
    function topUpSubscriptionAnyone(uint256 amount) public {
        link.transferAndCall(
            address(vrfCoordinator),
            amount,
            abi.encode(config.subscriptionID)
        );
    }

    /**
     * @dev transfer to contract and make request to get a random number in the same transaction
     * Request random number from the VRF contract and add the reward to the contract
     */
    function requestRandomWords(uint256 rewardAmount) external onlyManager returns (uint256 requestId) {
        (bool success) = erc20.transferFrom(msg.sender, address(this), rewardAmount);
        if(!success) revert INVALID_REQUEST();

        if(erc20.balanceOf(address(this)) == 0) revert INVALID_REQUEST();

        requestId = vrfCoordinator.requestRandomWords(
            config.keyHash,
            config.subscriptionID,
            config.requestConfirmations,
            config.callbackGasLimit,
            config.numWords
        );

        rounds[round].requestId = requestId;

        emit RequestSent(requestId, config.numWords);
        
        return requestId;
    }

    /**
     * Chainlink VRF callback function that is called by the VRF contract once the random number is available
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 winningTokenId = (randomWords[0] % 369) + 1;
        uint256 hoichiPrize = erc20.balanceOf(address(this));
        address winnerAddress = erc721.ownerOf(winningTokenId);
        rounds[round].winnerAddress = winnerAddress;
        rounds[round].randomNumber = winningTokenId;
        rounds[round].randomWords = randomWords;
        rounds[round].drawReward = hoichiPrize;

        (bool success,) = address(erc20).call(abi.encodeWithSignature("transfer(address,uint256)",winnerAddress,hoichiPrize));
        if(!success) revert INVALID_REQUEST();

        emit ReturnedRandomness(requestId, winningTokenId);
        round = round + 1;
    }

    /**
     * Get Chainlink VRF (Verifiable Random Function) provably fair and verifiable random number generator (RNG) in a round
     */
    function getRoundRandomNumber(uint256 roundNr) view external returns (uint256[] memory) {
        return rounds[roundNr].randomWords;
    }

    /**
     * Allow withdrawal of Link tokens from the contract
     */
    function withdrawLink(address _externalWallet) external onlyOwner {
        link.transfer(_externalWallet, link.balanceOf(address(this)));
    }

    /**
     * Allow withdrawal of Hoichi tokens from the contract
     */
    function withdrawHoichi(address _externalWallet) external onlyOwner {
        erc20.transfer(_externalWallet, erc20.balanceOf(address(this)));
    }

    /**
     * Cancel the subscription and send the remaining LINK to a wallet address.
     */
    function cancelSubscription(address receivingWallet) external onlyOwner {
        vrfCoordinator.cancelSubscription(config.subscriptionID, receivingWallet);
        config.subscriptionID = 0;
    }

    /**
     * Set minimum request confirmations for the VRF contract
     */
    function setMinimumRequestConfirmations(uint32 _newRequestConfirmations) external onlyOwner {
        if(_newRequestConfirmations < 3 || _newRequestConfirmations > 200) revert INVALID_CONFIG();
        config.callbackGasLimit = _newRequestConfirmations;
    }

    /**
     * Set callback gas limit for the VRF contract
     */
    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        if(_callbackGasLimit < 175000) revert INVALID_CONFIG();
        config.callbackGasLimit = _callbackGasLimit;
    }

    /**
     * set wrapper address for the VRF contract
     */
    function setVrfCoordinator(address _vrfCoordinator) external onlyOwner {
        if(_vrfCoordinator == address(0)) revert INVALID_CONFIG();
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    /**
     * set KEY_HASH gas lane for the VRF coordinator contract
     */
    function setVrfCoordinatorKeyHash(bytes32 _keyHash) external onlyOwner {
        config.keyHash = _keyHash;
    }

    /**
     * set new owner
     */
    function setNewOwner(address _newOwner) external onlyOwner {
        if(_newOwner == owner || _newOwner == address(0)) revert INVALID_REQUEST();
        owner = _newOwner;
    }

    /**
     * set new manager
     */
    function setNewManager(address _newManager) external onlyOwner {
        if(_newManager == address(0)) revert INVALID_REQUEST();
        manager = _newManager;
    }

    modifier onlyManager() {
        if(msg.sender != manager) revert UNAUTHORIZED();
        _;
    }

    modifier onlyOwner() {
        if(msg.sender != owner) revert UNAUTHORIZED();
        _;
    }
}