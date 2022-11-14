// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./interfaces/IMintpassVault.sol";
import "./libs/UniformRandomNumber.sol";
import "./utils/Recoverable.sol";

/**
 * @title MintpassVault handles the randomized claiming process of 
 * Gooodfellas mintpass mintable NFTs using Chainlink VRFv2.
 */
contract MintpassVault is ERC721Holder, VRFConsumerBaseV2, Recoverable, IMintpassVault {
    event VRFRequested(
        address indexed user,
        uint256 amount,
        uint256 indexed vrfRequestId
    );

    event RandomNumberCompleted(
        uint256 indexed requestId,
        uint256[] randomWords
    );

    event RandomNumberCompletedFallback(
        uint256 indexed requestId,
        uint256[] randomWords
    );

    struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    VRFConfig private vrfConfig;

    IERC721Enumerable public mintable;
    mapping(uint256 => address) public vrfRequestTargets;

    constructor(
        address _mintable,
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        require(_mintable != address(0), "Invalid mintable");
        mintable = IERC721Enumerable(_mintable);

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _vrfSubscriptionId,
            keyHash: _vrfKeyHash,
            callbackGasLimit: _vrfCallbackGasLimit,
            requestConfirmations: _vrfRequestConfirmations
        });
    }

    function claimWithMintpass(address to, uint256 amount) external override {
        require(msg.sender == address(mintable), "Only from mintable");

        _requestRandomness(to, amount);
    }

    /**
     * @notice Change Chainlink VRF V2 configuration
     */
    function configureVRF(
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint16 _vrfRequestConfirmations,
        uint32 _vrfCallbackGasLimit
    ) external onlyOwner {
        VRFConfig storage vrf = vrfConfig;
        vrf.subscriptionId = _vrfSubscriptionId;
        vrf.keyHash = _vrfKeyHash;
        vrf.requestConfirmations = _vrfRequestConfirmations;
        vrf.callbackGasLimit = _vrfCallbackGasLimit;
    }

    /**
     * @dev Fallback method in case VRF is stuck
     */
    function fulfillRandomWordsFallback(uint256 requestId, uint256[] calldata randomWords)
        external
        onlyOwner
    {
        emit RandomNumberCompletedFallback(requestId, randomWords);

        _distributeRandomNFTs(requestId, randomWords);
    }

    /**
     * @dev Requests a new random number from the Chainlink VRF
     * @dev The result of the request is returned in the function `fulfillRandomness`
     */ 
    function _requestRandomness(address user, uint256 amount) internal {
        VRFConfig memory vrf = vrfConfig;
        uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
            vrf.keyHash,
            vrf.subscriptionId,
            vrf.requestConfirmations,
            vrf.callbackGasLimit,
            uint32(amount)
        );

        vrfRequestTargets[vrfRequestId] = user;

        emit VRFRequested(user, amount, vrfRequestId);
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        emit RandomNumberCompleted(requestId, randomWords);

        _distributeRandomNFTs(requestId, randomWords);
    }

    function _distributeRandomNFTs(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        address to = vrfRequestTargets[requestId];
        require(to != address(0), "Already fulfilled");
        vrfRequestTargets[requestId] = address(0);

        for (uint256 i = 0; i < randomWords.length; ++i) {
            uint256 index = UniformRandomNumber.uniform(
                randomWords[i],
                mintable.balanceOf(address(this))
            );
            uint256 tokenId = mintable.tokenOfOwnerByIndex(
                address(this),
                index
            );
            mintable.transferFrom(address(this), to, tokenId);
        }
    }
}