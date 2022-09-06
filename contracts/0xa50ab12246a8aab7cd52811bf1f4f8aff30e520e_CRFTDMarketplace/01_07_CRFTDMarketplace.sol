// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {utils} from "./utils/utils.sol";
import {choice} from "./utils/choice.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

error NotActive();
error NoSupplyLeft();
error NotAuthorized();
error InvalidReceiver();
error InvalidEthAmount();
error InsufficientValue();
error InvalidPaymentToken();
error MaxPurchasesReached();
error ContractCallNotAllowed();
error RandomSeedAlreadyChosen();

//       ___           ___           ___                    _____
//      /  /\         /  /\         /  /\       ___        /  /::\
//     /  /:/        /  /::\       /  /:/_     /__/\      /  /:/\:\
//    /  /:/        /  /:/\:\     /  /:/ /\    \  \:\    /  /:/  \:\
//   /  /:/  ___   /  /::\ \:\   /  /:/ /:/     \__\:\  /__/:/ \__\:|
//  /__/:/  /  /\ /__/:/\:\_\:\ /__/:/ /:/      /  /::\ \  \:\ /  /:/
//  \  \:\ /  /:/ \__\/~|::\/:/ \  \:\/:/      /  /:/\:\ \  \:\  /:/
//   \  \:\  /:/     |  |:|::/   \  \::/      /  /:/__\/  \  \:\/:/
//    \  \:\/:/      |  |:|\/     \  \:\     /__/:/        \  \::/
//     \  \::/       |__|:|        \  \:\    \__\/          \__\/
//      \__\/         \__\|         \__\/

/// @title CRFTDMarketplace
/// @author phaze (https://github.com/0xPhaze)
/// @notice Marketplace that supports purchasing limited off-chain items
contract CRFTDMarketplace is Owned(msg.sender) {
    using SafeTransferLib for ERC20;

    /* ------------- events ------------- */

    event MarketItemPurchased(
        uint256 indexed marketId,
        bytes32 indexed itemHash,
        address indexed account,
        bytes32 userHash,
        address paymentToken,
        uint256 price
    );

    /* ------------- structs ------------- */

    struct MarketItem {
        uint256 marketId;
        uint256 start;
        uint256 end;
        uint256 expiry;
        uint256 maxPurchases;
        uint256 maxSupply;
        uint256 raffleNumPrizes;
        address[] raffleControllers;
        address receiver;
        bytes32 dataHash;
        address[] acceptedPaymentTokens;
        uint256[] tokenPricesStart;
        uint256[] tokenPricesEnd;
    }

    /* ------------- storage ------------- */

    /// @dev (bytes32 itemHash) => (uint256 totalSupply)
    mapping(bytes32 => uint256) public totalSupply;
    /// @dev (bytes32 itemHash) => (address user) => (uint256 numPurchases)
    mapping(bytes32 => mapping(address => uint256)) public numPurchases;
    /// @dev (bytes32 itemHash) => (uint256 tokenId) => (address user)
    mapping(bytes32 => mapping(uint256 => address)) public raffleEntries;
    /// @dev (bytes32 itemHash) => (uint256 seed)
    mapping(bytes32 => uint256) public raffleRandomSeeds;

    /* ------------- external ------------- */

    function purchaseMarketItems(
        MarketItem[] calldata items,
        address[] calldata paymentTokens,
        bytes32 userHash
    ) external payable {
        uint256 msgValue = msg.value;

        for (uint256 i; i < items.length; ++i) {
            MarketItem calldata item = items[i];

            bytes32 itemHash = keccak256(abi.encode(item));

            uint256 supply = ++totalSupply[itemHash];

            unchecked {
                if (block.timestamp < item.start || item.expiry < block.timestamp) revert NotActive();
                if (++numPurchases[itemHash][msg.sender] > item.maxPurchases) revert MaxPurchasesReached();
                if (supply > item.maxSupply) revert NoSupplyLeft();
            }

            address paymentToken = paymentTokens[i];

            (bool found, uint256 tokenIndex) = utils.indexOf(item.acceptedPaymentTokens, paymentToken);
            if (!found) revert InvalidPaymentToken();

            uint256 tokenPrice = item.tokenPricesStart[tokenIndex];

            // dutch auction item
            if (item.end != 0) {
                uint256 timestamp = block.timestamp > item.end ? item.end : block.timestamp;

                tokenPrice -=
                    ((item.tokenPricesStart[tokenIndex] - item.tokenPricesEnd[tokenIndex]) * (timestamp - item.start)) /
                    (item.end - item.start);
            }

            // raffle item; store id ownership
            if (item.raffleNumPrizes != 0) {
                raffleEntries[itemHash][supply] = msg.sender;
            }

            if (paymentToken == address(0)) {
                msgValue -= tokenPrice;

                payable(item.receiver).transfer(tokenPrice);
            } else {
                require(paymentToken.code.length != 0);

                ERC20(paymentToken).safeTransferFrom(msg.sender, item.receiver, tokenPrice);
            }

            emit MarketItemPurchased(item.marketId, itemHash, msg.sender, userHash, paymentToken, tokenPrice);
        }

        if (msgValue != 0) payable(msg.sender).transfer(msgValue);
    }

    /* ------------- view (off-chain) ------------- */

    function getRaffleEntrants(bytes32 itemHash) external view returns (address[] memory entrants) {
        uint256 supply = totalSupply[itemHash];

        entrants = new address[](supply);

        for (uint256 i; i < supply; ++i) entrants[i] = raffleEntries[itemHash][i + 1];
    }

    function getRaffleWinners(bytes32 itemHash, uint256 numPrizes) public view returns (address[] memory winners) {
        uint256 randomSeed = raffleRandomSeeds[itemHash];

        if (randomSeed == 0) return winners;

        uint256[] memory winnerIds = choice.selectNOfM(numPrizes, totalSupply[itemHash], randomSeed);

        uint256 numWinners = winnerIds.length;

        winners = new address[](numWinners);

        for (uint256 i; i < numWinners; ++i) winners[i] = raffleEntries[itemHash][winnerIds[i] + 1];
    }

    /* ------------- restricted ------------- */

    function revealRaffle(MarketItem calldata item) external {
        bytes32 itemHash = keccak256(abi.encode(item));

        if (block.timestamp < item.expiry) revert NotActive();

        (bool found, ) = utils.indexOf(item.raffleControllers, msg.sender);

        if (!found) revert NotAuthorized();

        if (raffleRandomSeeds[itemHash] != 0) revert RandomSeedAlreadyChosen();

        raffleRandomSeeds[itemHash] = uint256(keccak256(abi.encode(blockhash(block.number - 1), itemHash)));
    }

    /* ------------- owner ------------- */

    function recoverToken(ERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverNFT(ERC721 token, uint256 id) external onlyOwner {
        token.transferFrom(address(this), msg.sender, id);
    }
}