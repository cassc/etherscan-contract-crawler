// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./chainlink/VRFConsumerBaseV2Upgradeable.sol"; // Custom implementation
import "./ReferralSystem.sol";

contract RandomNumber is ReferralSystem, VRFConsumerBaseV2Upgradeable {
    uint16 public constant MAX_NUMBER = 10000;
    uint16 public constant MIN_NUMBER = 1;
    // This callback gas limit will change if the logic of the fulfillRandomWords function changes
    uint32 internal constant CALLBACK_GAS_LIMIT = 200000;
    uint32 internal constant MAX_VERIFICATION_GAS = 200000;
    uint16 private constant REQUESTS_CONFIRMATION = 3;

    VRFCoordinatorV2Interface public coordinator;
    LinkTokenInterface private linkToken;

    // Your subscription ID.
    uint64 public subscriptionId;
    bytes32 public keyHash;
    mapping(uint256 => uint256) public responseBlockByRequestId;
    mapping(address => uint256) public totalInBetsPerToken;
    mapping(uint256 => UserGuess[]) public guessByRequestId;

    // Read about gaps before adding new variables below:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[50] private __gap;

    struct UserGuess {
        address payable user;
        uint16 lowerNumber;
        uint16 upperNumber;
        uint256 prizeAmount;
        uint256 betAmount;
        uint256 multiplier;
        IERC20Upgradeable token;
    }

    event BetResult(
        uint256 indexed requestId,
        uint256 betIndex,
        address payable indexed user,
        address influencer,
        uint256 winningNumber,
        UserGuess userGuess,
        bool didUserWin,
        bool success,
        bool isPrize
    );

    function __RandomNumber_init(
        uint256 withdrawalWaitingPeriod_,
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address linkToken_
    ) internal {
        __ReferralSystem_init(withdrawalWaitingPeriod_);
        __VRFConsumerBaseV2_init(vrfCoordinator_);
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        linkToken = LinkTokenInterface(linkToken_);
        subscriptionId = subscriptionId_;
        keyHash = keyHash_;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(
        uint16[] memory lowerNumbers,
        uint16[] memory upperNumbers,
        uint256[] memory prizeAmounts,
        uint256[] memory betAmounts,
        uint256[] memory multipliers,
        IERC20Upgradeable[] memory tokens
    ) internal virtual returns (uint256) {
        // Will revert if subscription is not set and funded.
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUESTS_CONFIRMATION,
            CALLBACK_GAS_LIMIT * uint32(tokens.length),
            uint32(tokens.length)
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            guessByRequestId[requestId].push(
                UserGuess(
                    payable(msg.sender),
                    lowerNumbers[i],
                    upperNumbers[i],
                    prizeAmounts[i],
                    betAmounts[i],
                    multipliers[i],
                    tokens[i]
                )
            );
        }

        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // It will be used to facilitate event filtering later.
        responseBlockByRequestId[requestId] = block.number;

        for (uint256 i = 0; i < randomWords.length; i++) {
            // Valid numbers must be from 1 to 10000 or 0.01 to 100.00
            uint16 winningNumber = uint16(randomWords[i] % MAX_NUMBER) + 1;
            UserGuess memory userGuess = guessByRequestId[requestId][i];
            uint256 totalInBets = totalInBetsPerToken[address(userGuess.token)];
            totalInBetsPerToken[address(userGuess.token)] -= userGuess
                .betAmount;

            (address influencer, bool isEnabled) = getUserReferredBy(
                userGuess.user
            );
            if (!isEnabled) influencer = address(0);

            // If the user guessed incorrectly then stop
            if (
                userGuess.lowerNumber > winningNumber ||
                userGuess.upperNumber < winningNumber
            ) {
                updateTotalUserLosses(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );

                emit BetResult(
                    requestId,
                    i,
                    userGuess.user,
                    influencer,
                    winningNumber,
                    userGuess,
                    false,
                    true,
                    false
                );
                continue;
            }

            bool success;
            bool isRefund;
            if (userGuess.token == IERC20Upgradeable(address(0))) {
                uint256 available = address(this).balance -
                    (totalInBets - userGuess.betAmount);
                if (available >= userGuess.prizeAmount) {
                    // Pay the prize amount (native token)
                    (success, ) = userGuess.user.call{
                        value: userGuess.prizeAmount
                    }("");
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        true
                    );
                } else {
                    isRefund = true;
                    // Refund the bet amount (native token)
                    (success, ) = userGuess.user.call{
                        value: userGuess.betAmount
                    }("");
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        false
                    );
                }
            } else {
                uint256 available = userGuess.token.balanceOf(address(this)) -
                    (totalInBets - userGuess.betAmount);
                if (available >= userGuess.prizeAmount) {
                    // Pay the prize amount (ERC20 token)
                    success = userGuess.token.transfer(
                        userGuess.user,
                        userGuess.prizeAmount
                    );
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        true
                    );
                } else {
                    isRefund = true;
                    // Refund the bet amount (ERC20 token)
                    success = userGuess.token.transfer(
                        userGuess.user,
                        userGuess.betAmount
                    );
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        false
                    );
                }
            }
            if (influencer == address(0)) continue;
            if (!success) {
                updateTotalUserLosses(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );
                continue;
            }
            if (isRefund) {
                updateTotalUserRefunds(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );
                continue;
            }
            updateTotalUserWins(
                userGuess.prizeAmount,
                userGuess.betAmount,
                address(userGuess.token),
                influencer
            );
        }
    }

    /// @notice Allows the admin to set a new subscription id for the chainlink service
    /// @dev The susbscription id should not change so often, and only the owner can do it
    /// @param subscriptionId_ new subscription id from the chainlink service
    function editSubscriptionId(uint64 subscriptionId_) external onlyOwner {
        subscriptionId = subscriptionId_;
    }

    function editKeyHash(bytes32 keyHash_) external onlyOwner {
        keyHash = keyHash_;
    }

    /// @notice Overrides the renounceOwnership function, it won't be possible to renounce the ownership
    function renounceOwnership() public pure override {
        require(false, "DiceGame: renounceOwnership has been disabled");
    }

    function getGuessesByRequestId(uint256 requestId)
        external
        view
        returns (UserGuess[] memory)
    {
        return guessByRequestId[requestId];
    }
}