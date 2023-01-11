// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "../utils/UniformRandomNumber.sol";

interface ICAT is IERC721Enumerable {
    function achievementId(uint256 tokenId) external view returns (uint256);
    function achievementIds(address account) external view returns (uint256 ids);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}



contract RareboardCATRaffle is VRFConsumerBaseV2, Ownable {
    uint8 private constant TOKEN_TYPE_ERC20 = 1;
    uint8 private constant TOKEN_TYPE_ERC721 = 2;
    uint8 private constant TOKEN_TYPE_ERC1155 = 3;

    ICAT private immutable CAT;
    VRFCoordinatorV2Interface private immutable vrfCoordinator;
    VRFConfig private vrfConfig;

    event RaffleSubmitted(uint256 indexed raffleIdStart, uint256 raffles, uint256 indexed vrfRequestId);
    event RaffleResult(uint256 indexed raffleId, RafflePrize prize, RaffleWinner winner);
    event RaffleFallbackRequsted(address indexed sender);

    struct VRFConfig {
        bytes32 keyHash;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        uint64 subscriptionId;
    }

    struct RafflePrize {
        address tokenAddress;
        uint8 tokenType;
        uint32 tokenIdOrAmount;
        uint32 catSupply;
    }

    struct RaffleWinner {
        address winner;
        uint8 catId;
        uint8 catCount;
        uint16 redrawn;
    }

    mapping(uint256 => RafflePrize) public rafflePrizes;
    mapping(uint256 => RaffleWinner) public raffleWinners;
    mapping(uint256 => uint256) public vrfRequests;
    uint256 public lastRaffleId;

    constructor(
        address cat_, 
        address _vrfCoordinator,
        uint64 _vrfSubscriptionId,
        bytes32 _vrfKeyHash,
        uint32 _vrfCallbackGasLimit,
        uint16 _vrfRequestConfirmations) 
    VRFConsumerBaseV2(_vrfCoordinator) {
        CAT = ICAT(cat_);

        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfConfig = VRFConfig({
            subscriptionId: _vrfSubscriptionId,
            keyHash: _vrfKeyHash,
            callbackGasLimit: _vrfCallbackGasLimit,
            requestConfirmations: _vrfRequestConfirmations
        });
    }

    function submitRaffle(RafflePrize[] calldata prizes) external onlyOwner {
        require(prizes.length != 0, "Invalid length");
        uint256 raffleId = lastRaffleId;


        uint32 catSupply = uint32(CAT.totalSupply());

        for (uint256 i = 0; i < prizes.length; ++i) {
            RafflePrize storage prize = rafflePrizes[++raffleId];
            prize.tokenAddress = prizes[i].tokenAddress;
            prize.tokenType = prizes[i].tokenType;
            prize.tokenIdOrAmount = prizes[i].tokenIdOrAmount;
            prize.catSupply = catSupply;
        }

        _drawWinners(lastRaffleId+1, prizes.length);

        lastRaffleId = raffleId;
    }

    function redrawRaffle(uint256 raffleId) external onlyOwner {
        RaffleWinner storage winner = raffleWinners[raffleId];
        require(winner.winner != address(0), "Request not fulfilled");
        winner.winner = address(0);
        winner.redrawn += 1;
        winner.catCount = 0;
        winner.catId = 0;
        _drawWinners(raffleId, 1);
    }

    function sendPrizes(uint256[] calldata raffleIds, address[] calldata from) external onlyOwner {
        for (uint256 i = 0; i < raffleIds.length; ++i) {
            RafflePrize memory prize = rafflePrizes[raffleIds[i]];
            RaffleWinner memory winner = raffleWinners[raffleIds[i]];

            require(winner.winner != address(0), "No winner yet");

            if (prize.tokenType == TOKEN_TYPE_ERC20) {
                IERC20(prize.tokenAddress).transferFrom(from[i], winner.winner, uint256(prize.tokenIdOrAmount) * 1 ether);
            } else if (prize.tokenType == TOKEN_TYPE_ERC721) {
                IERC721(prize.tokenAddress).safeTransferFrom(from[i], winner.winner, prize.tokenIdOrAmount);
            } else if (prize.tokenType == TOKEN_TYPE_ERC1155) {
                IERC1155(prize.tokenAddress).safeTransferFrom(from[i], winner.winner, prize.tokenIdOrAmount, 1, "");
            }
        }
    }

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
     * @notice Callback function used by VRF Coordinator
     * @dev The VRF Coordinator will only send this function verified responses.
     * @dev The VRF Coordinator will not pass randomness that could not be verified.
     */
    function fulfillRandomWords(uint256 vrfRequestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleIdStart = vrfRequests[vrfRequestId];
        require(raffleIdStart != 0, "Invalid request");
        for (uint256 i = 0; i < randomWords.length; ++i) {
            _selectWinner(raffleIdStart + i, randomWords[i]);
        }
    }

    function fallbackFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external onlyOwner {
        emit RaffleFallbackRequsted(msg.sender);
        fulfillRandomWords(requestId, randomWords);
    }

    function _drawWinners(uint256 raffleIdStart, uint256 prizes) internal {
        VRFConfig memory vrf = vrfConfig;
        uint256 vrfRequestId = vrfCoordinator.requestRandomWords(
            vrf.keyHash,
            vrf.subscriptionId,
            vrf.requestConfirmations,
            vrf.callbackGasLimit,
            uint32(prizes)
        );
        vrfRequests[vrfRequestId] = raffleIdStart;
        emit RaffleSubmitted(raffleIdStart, prizes, vrfRequestId);
    }

    function _selectWinner(uint256 raffleId, uint256 randomSeed) internal {
        RafflePrize memory prize = rafflePrizes[raffleId];
        uint256 tokenId = CAT.tokenByIndex(
            UniformRandomNumber.uniform(randomSeed, prize.catSupply)
        );
        RaffleWinner storage winner = raffleWinners[raffleId];
        address winnerAddress = CAT.ownerOf(tokenId);
        winner.winner = winnerAddress;
        winner.catId = uint8(CAT.achievementId(tokenId));
        winner.catCount = uint8(CAT.balanceOf(winnerAddress));

        emit RaffleResult(raffleId, prize, winner);
    }
}