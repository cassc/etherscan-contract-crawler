// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {OwnableUpgradeable} from "./ownable/OwnableUpgradeable.sol";
import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {ExtendedVRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/VRFV2Wrapper.sol";
import {LinkTokenInterface, VRFCoordinatorV2, VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/VRFCoordinatorV2.sol";

import {IVRFNFTRandomDraw} from "./interfaces/IVRFNFTRandomDraw.sol";
import {Version} from "./utils/Version.sol";



/// @notice VRFNFTRandom Draw with NFT Tickets
/// @author @isiain
contract VRFNFTRandomDraw is
    IVRFNFTRandomDraw,
    VRFConsumerBaseV2,
    OwnableUpgradeable,
    Version(3)
{
    /// @notice Our callback is just setting a few variables, 200k should be more than enough gas.
    uint32 constant CALLBACK_GAS_LIMIT = 200_000;
    // /// @notice Chainlink request confirmations, left at the default
    uint16 constant REQUEST_CONFIRMATIONS = 6;
    /// @notice Number of words requested in a drawing
    uint16 constant WORDS_REQUESTED = 1;

    /// @notice keyHash for chain.link gas lane
    bytes32 immutable keyHash;

    /// @notice chain.link subscription id
    uint64 public subscriptionId;

    /// @notice Reference to chain-specific coordinator contract
    VRFCoordinatorV2 immutable coordinator;

    /// @notice Settings used for the contract.
    IVRFNFTRandomDraw.Settings public settings;

    /// @notice Details about the current request to chainlink
    IVRFNFTRandomDraw.CurrentRequest public request;

    /// @dev Only when the contract is not finalized
    modifier onlyNotFinalized() {
        if (request.finalizedAt > 0) {
            revert OnlyNotFinalized();
        }
        _;
    }

    /// @dev Recovery timelock gate
    modifier onlyRecoveryTimelock() {
        // If recoverTimelock is not setup, or if not yet occurred
        if (request.recoverTimelock > block.timestamp) {
            // Stop the withdraw
            revert RECOVERY_IS_NOT_YET_POSSIBLE();
        }
        _;
    }

    /// @dev Save the coordinator to the contract
    /// @param _coordinator Address for VRF Coordinator V2 Interface
    /// @param _keyHash Preset gas keyhash for given chain
    constructor(
        address _coordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinator) initializer {
        if (address(_coordinator) == address(0)) {
            revert InvalidCoordinatorSetup();
        }

        if (_keyHash == bytes32(0)) {
            revert InvalidKeyHash();
        }

        coordinator = VRFCoordinatorV2(_coordinator);
        keyHash = _keyHash;
    }

    /// @notice Getter for request details, does not include picked tokenID
    /// @return currentChainlinkRequestId Current Chainlink Request ID
    /// @return hasChosenRandomNumber If the random number for the drawing has been chosen
    /// @return drawTimelock block.timestamp when a redraw can be issued
    function getRequestDetails()
        external
        view
        returns (
            uint256 currentChainlinkRequestId,
            bool hasChosenRandomNumber,
            uint256 drawTimelock
        )
    {
        currentChainlinkRequestId = request.currentChainlinkRequestId;
        hasChosenRandomNumber = request.hasChosenRandomNumber;
        drawTimelock = request.drawTimelock;
    }

    function _checkSettingsValid(Settings memory _settings) internal {
        // Check values in memory:
        if (_settings.drawBufferTime < 1 days) {
            revert REDRAW_TIMELOCK_NEEDS_TO_BE_MORE_THAN_A_DAY();
        }
        if (_settings.drawBufferTime > 4 weeks) {
            revert REDRAW_TIMELOCK_NEEDS_TO_BE_LESS_THAN_A_MONTH();
        }

        if (_settings.recoverBufferTime < 1 weeks) {
            revert RECOVER_TIMELOCK_NEEDS_TO_BE_AT_LEAST_A_WEEK();
        }
        if (_settings.recoverBufferTime > 365 days) {
            revert RECOVER_TIMELOCK_NEEDS_TO_BE_LESS_THAN_A_YEAR();
        }

        // If NFT contract address is not a contract
        if (_settings.token.code.length == 0) {
            revert TOKEN_NEEDS_TO_BE_A_CONTRACT(_settings.token);
        }

        // If drawing token is not a contract
        if (_settings.drawingToken.code.length == 0) {
            revert TOKEN_NEEDS_TO_BE_A_CONTRACT(_settings.drawingToken);
        }

        // Validate token range: end needs to be greater than start
        // and the size of the range needs to be at least 2 (end is exclusive)
        if (
            _settings.drawingTokenEndId < _settings.drawingTokenStartId ||
            _settings.drawingTokenEndId - _settings.drawingTokenStartId < 2
        ) {
            revert DRAWING_TOKEN_RANGE_INVALID();
        }
    }

    function _checkAndEscrowNFT(address token, uint256 tokenId) internal {
        // Get owner of raffled tokenId and ensure the current owner is the admin
        try IERC721EnumerableUpgradeable(token).ownerOf(tokenId) returns (
            address nftOwner
        ) {
            if (nftOwner != address(this)) {
                revert TOKEN_BEING_OFFERED_NEEDS_TO_EXIST();
            }
        } catch {
            revert TOKEN_BEING_OFFERED_NEEDS_TO_EXIST();
        }
    }

    /// @notice Initialize the contract with settings and an admin
    /// @param admin initial admin user
    /// @param _settings initial settings for draw
    function initialize(
        address admin,
        Settings memory _settings
    ) public initializer returns (uint256) {
        // Check if settings are valid
        _checkSettingsValid(_settings);

        // Sets up chainlink subscription
        subscriptionId = coordinator.createSubscription();
        coordinator.addConsumer(subscriptionId, address(this));

        // Saves new settings
        settings = _settings;

        // Setup owner as admin
        __Ownable_init(admin);

        _checkAndEscrowNFT(_settings.token, _settings.tokenId);

        // Emit initialized event for indexing
        emit InitializedDraw(msg.sender, settings);

        // Request initial roll
        _requestRoll();

        // Return the current chainlink request id
        return request.currentChainlinkRequestId;
    }

    /// @notice Internal function to request entropy
    function _requestRoll() internal {
        unchecked {
            // Setup redraw timelock
            request.drawTimelock = uint64(
                block.timestamp + settings.drawBufferTime
            );
            // Setup recover timelock
            request.recoverTimelock = uint64(
                block.timestamp + settings.recoverBufferTime
            );
        }

        // Get the price in LINK
        uint256 price = _calculateRequestPriceInternal();

        // Calculate needed link
        LinkTokenInterface link = LinkTokenInterface(
            VRFCoordinatorV2(address(coordinator)).LINK()
        );
        (uint256 subscriptionBalance, , , ) = coordinator.getSubscription(
            subscriptionId
        );
        // Transfer needed link
        if (price > subscriptionBalance) {
            // Transfer from caller
            link.transferFrom(
                owner(),
                address(this),
                price - subscriptionBalance
            );

            // Fund subscription
            link.transferAndCall(
                address(coordinator),
                price - subscriptionBalance,
                abi.encode(subscriptionId)
            );
        }

        // Request first random round
        request.currentChainlinkRequestId = coordinator.requestRandomWords({
            subId: subscriptionId,
            keyHash: keyHash,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: CALLBACK_GAS_LIMIT,
            numWords: WORDS_REQUESTED
        });
    }

    function _calculateRequestPriceInternal() internal returns (uint256) {
        (, , uint32 stalenessSeconds, ) = coordinator.getConfig();
        (uint32 fulfillmentFlatFeeLinkPPM, , , , , , , , ) = VRFCoordinatorV2(
            address(coordinator)
        ).getFeeConfig();

        int256 fallbackWeiPerUnitLink = coordinator.getFallbackWeiPerUnitLink();

        (, int256 weiPerUnitLink, , uint256 timestamp, ) = coordinator
            .LINK_ETH_FEED()
            .latestRoundData();

        if (stalenessSeconds < block.timestamp - timestamp) {
            weiPerUnitLink = fallbackWeiPerUnitLink;
        }
        if (weiPerUnitLink == 0) {
            revert InvalidLINKWeiPrice();
        }

        uint256 coordinatorGasOverhead = 60_000;
        uint256 gasLaneMaxPrice = 200000000000; // 200 gwei
        uint256 wrapperPremiumPercentage = 12;

        uint256 baseFee = (1e18 *
            gasLaneMaxPrice *
            (CALLBACK_GAS_LIMIT + coordinatorGasOverhead)) /
            uint256(weiPerUnitLink);

        uint256 feeWithPremium = (baseFee * (wrapperPremiumPercentage + 100)) /
            100;

        return feeWithPremium + (1e12 * uint256(fulfillmentFlatFeeLinkPPM));
    }

    function calculateRequestPrice() external returns (uint256) {
        return _calculateRequestPriceInternal();
    }

    /// @notice Call this to re-draw the raffle
    /// @return chainlink request ID
    function redraw() external onlyNotFinalized returns (uint256) {
        if (request.drawTimelock >= block.timestamp) {
            revert TOO_SOON_TO_REDRAW();
        }

        // TODO(iain): Do we need this check?
        if (request.currentChainlinkRequestId != 0) {
            revert REQUEST_IN_FLIGHT();
        }

        // Reset request
        delete request;

        // Re-roll
        _requestRoll();

        emit RedrawRequested(msg.sender);

        // Return current chainlink request ID
        return request.currentChainlinkRequestId;
    }

    /// @notice Function called by chainlink to resolve random words
    /// @param _requestId ID of request sent to chainlink VRF
    /// @param _randomWords List of uint256 words of random entropy
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        // Validate request ID
        if (_requestId != request.currentChainlinkRequestId) {
            emit FULFILL_REQUEST_DOES_NOT_MATCH_CURRENT_ID();
            return;
        }

        // Validate number of words returned
        // Words requested is an immutable set to 1
        if (_randomWords.length != WORDS_REQUESTED) {
            revert RANDOM_WORDS_WRONG_LENGTH();
        }

        // Set request details
        request.hasChosenRandomNumber = true;

        // Get total token range
        uint256 tokenRange = settings.drawingTokenEndId -
            settings.drawingTokenStartId;

        // Store a number from it here (reduce number here to reduce gas usage)
        // We know there will only be 1 word sent at this point.
        request.currentChosenTokenId =
            (_randomWords[0] % tokenRange) +
            settings.drawingTokenStartId;

        // Reset request Id
        request.currentChainlinkRequestId = 0;

        // Emit completed event.
        emit DiceRollComplete(msg.sender, request);
    }

    /// @notice Function to determine if the user has won in the current drawing
    /// @param user address for the user to check if they have won in the current drawing
    function hasUserWon(
        address user
    ) public view onlyNotFinalized returns (bool) {
        if (!request.hasChosenRandomNumber) {
            revert NEEDS_TO_HAVE_CHOSEN_A_NUMBER();
        }

        return
            user ==
            IERC721EnumerableUpgradeable(settings.drawingToken).ownerOf(
                request.currentChosenTokenId
            );
    }

    /// @notice Function for the winner to call to retrieve their NFT
    function winnerClaimNFT() external {
        // Assume (potential) winner calls this fn, cache.
        address user = msg.sender;

        // Check if this user has indeed won.
        if (!hasUserWon(user)) {
            revert USER_HAS_NOT_WON();
        }

        unchecked {
            request.finalizedAt = uint64(block.timestamp);
        }

        // Emit a celebratory event
        emit WinnerSentNFT(
            user,
            address(settings.token),
            settings.tokenId,
            settings
        );

        // Transfer token to the winter.
        IERC721EnumerableUpgradeable(settings.token).transferFrom(
            address(this),
            msg.sender,
            settings.tokenId
        );
    }

    /// @notice Optional last resort admin reclaim nft function
    /// @dev Only callable by the owner
    function lastResortTimelockOwnerClaimNFT()
        external
        onlyOwner
        onlyRecoveryTimelock
    {
        // Send event for indexing that the owner reclaimed the NFT
        emit OwnerReclaimedNFT(owner());

        // Transfer token to the admin/owner.
        IERC721EnumerableUpgradeable(settings.token).transferFrom(
            address(this),
            owner(),
            settings.tokenId
        );
    }

    /// @notice Token reclaim ERC20 – used for accidentally sent tokens and .
    /// @param token token to reclaim address
    function ownerReclaimERC20Tokens(
        address token
    ) external onlyOwner onlyRecoveryTimelock {
        address self = address(this);
        LinkTokenInterface linkAddress = VRFCoordinatorV2(address(coordinator))
            .LINK();
        uint256 balance = linkAddress.balanceOf(self);

        emit OwnerReclaimedERC20(msg.sender, address(linkAddress), balance);

        // While this function signature works for ERC20,
        //  it is only able to be called after the draw.
        linkAddress.transferFrom(self, owner(), balance);
    }

    function ownerCloseSubscription() external onlyOwner onlyRecoveryTimelock {
        coordinator.recoverFunds(msg.sender);
    }
}