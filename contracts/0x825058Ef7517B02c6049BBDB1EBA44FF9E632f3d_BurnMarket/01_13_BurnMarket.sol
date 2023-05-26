// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

enum ItemType {
    Undefined,
    Winnable,
    Buyable
}

enum PaymentType {
    Chronicles,
    Coin,
    Eth
}

enum RewardType {
    ERC20,
    ERC1155,
    ERC721,
    External
}

struct Item {
    ItemType itemType;
    PaymentType paymentType;
    uint256 price;
    address paymentCoinAddress;
    address coinReceiver;
    uint32 startTime;
    uint32 endTime;
    uint32 limit;
    uint32 allowance;
    address signer;
    Reward[] rewards;
    Reward[] entryRewards;
    uint32 entryRewardTreshold;
}

struct Reward {
    RewardType rewardType;
    address vault;
    address rewarder;
    uint256 tokenId;
    uint256 amount;
    uint256 repeats;
}

interface IKillaCredits {
    function addCredits(address wallet, uint256 amount) external;

    function useCredits(address wallet, uint256 amount) external;

    function getCredits(address wallet) external view returns (uint256);
}

interface IKillaChronicles is IERC1155 {
    function burn(uint256 tokenId, address owner, uint256 qty) external;
}

interface IKillaChroniclesSBT {
    function increaseBalance(
        address recipient,
        uint256 volumeId,
        uint256 qty
    ) external;
}

interface IExternalRewarder {
    function reward(address recipient, uint256 id, uint256 amount) external;
}

contract BurnMarket is Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using ECDSA for bytes32;

    IKillaCredits public immutable creditsContract;
    IKillaChronicles public immutable chroniclesContract;
    IKillaChroniclesSBT public immutable sbtContract;

    uint256 public itemCount;
    mapping(uint256 => Item) public items;

    mapping(uint256 => uint256) public participationCounters;
    mapping(uint256 => mapping(address => uint256)) public countersPerWallet;

    mapping(uint256 => mapping(uint256 => address)) public entries;
    mapping(uint256 => mapping(uint256 => address)) public winners;
    mapping(address => bool) public authorities;

    VRFCoordinatorV2Interface public immutable chainlinkContract;
    bytes32 public chainlinkKeyHash;
    uint64 public chainlinkSubscriptionId;
    uint16 public chainlinkConfirmations;
    uint32 public chainlinkGasLimit;
    mapping(uint256 => uint256) public requestIdToItemId;
    mapping(uint256 => uint256) public itemSeeds;

    /* --------
        Errors
       -------- */

    error NotFound();
    error AllowanceExceeded();
    error Overpaid();
    error Underpaid();
    error AlreadyRewarded();
    error NotAllowed();
    error InvalidPaymentType();
    error SignatureRequired();
    error NoEntriesFound();
    error TooSoon();
    error TooLate();
    error LimitReached();
    error InvalidSeed();
    error InvalidSignature();
    error OutOfBounds();

    /* --------
        Events
       -------- */

    event Participated(
        address indexed wallet,
        uint256 indexed itemId,
        uint256 qty
    );
    event ItemAdded(uint256 indexed itemId, Item item);
    event ItemUpdated(uint256 indexed itemId, Item item);
    event RewardSent(
        uint256 indexed itemId,
        uint256 indexed rewardIndex,
        address indexed winner
    );

    /* -------------
        Constructor
       ------------- */

    constructor(
        address chroniclesAddress,
        address sbtAddress,
        address creditsAddress,
        address chainlinkAddress
    ) VRFConsumerBaseV2(chainlinkAddress) {
        chroniclesContract = IKillaChronicles(chroniclesAddress);
        sbtContract = IKillaChroniclesSBT(sbtAddress);
        creditsContract = IKillaCredits(creditsAddress);
        chainlinkContract = VRFCoordinatorV2Interface(chainlinkAddress);
    }

    /* ---------------
        Participation
       --------------- */

    function participate(
        uint256 id,
        uint256 qty,
        uint256 vol1,
        uint256 vol2,
        uint256 vol3
    ) external {
        if (items[id].signer != address(0)) revert SignatureRequired();

        _pay(id, qty, vol1, vol2, vol3);
        _participate(id, qty);
    }

    function participate(
        uint256 id,
        uint256 qty,
        uint256 vol1,
        uint256 vol2,
        uint256 vol3,
        bytes calldata signature
    ) external {
        _checkSignature(id, qty, signature);
        _pay(id, qty, vol1, vol2, vol3);
        _participate(id, qty);
    }

    function participate(uint256 id, uint256 qty) external payable {
        if (items[id].signer != address(0)) revert SignatureRequired();
        _pay(id, qty);
        _participate(id, qty);
    }

    function participate(
        uint256 id,
        uint256 qty,
        bytes calldata signature
    ) external payable {
        _checkSignature(id, qty, signature);
        _pay(id, qty);
        _participate(id, qty);
    }

    function _participate(uint256 id, uint256 qty) private nonReentrant {
        Item storage item = items[id];

        if (block.timestamp < item.startTime) revert TooSoon();
        if (block.timestamp > item.endTime) revert TooLate();

        if (item.itemType == ItemType.Winnable) {
            entries[id][participationCounters[id]] = msg.sender;
        } else if (item.itemType == ItemType.Buyable) {
            for (uint256 i = 0; i < item.rewards.length; i++) {
                sendReward(msg.sender, item.rewards[i], qty, false);
            }
        } else {
            revert NotFound();
        }
        if (qty >= item.entryRewardTreshold) {
            for (uint256 i = 0; i < item.entryRewards.length; i++) {
                sendReward(
                    msg.sender,
                    item.entryRewards[i],
                    qty / item.entryRewardTreshold,
                    true
                );
            }
        }

        participationCounters[id] += qty;
        if (participationCounters[id] > item.limit) revert LimitReached();

        countersPerWallet[id][msg.sender] += qty;
        if (countersPerWallet[id][msg.sender] > item.allowance)
            revert AllowanceExceeded();

        emit Participated(msg.sender, id, qty);
    }

    function _checkSignature(
        uint256 id,
        uint256 qty,
        bytes calldata signature
    ) internal view {
        if (
            items[id].signer !=
            ECDSA
                .toEthSignedMessageHash(abi.encodePacked(msg.sender, id, qty))
                .recover(signature)
        ) revert InvalidSignature();
    }

    function _pay(
        uint256 id,
        uint256 qty,
        uint256 vol1,
        uint256 vol2,
        uint256 vol3
    ) private {
        Item storage item = items[id];

        if (item.paymentType != PaymentType.Chronicles)
            revert InvalidPaymentType();

        uint256 price = item.price * qty;

        uint256 volumeValue = vol1 + vol2 * 3 + vol3 * 8;
        uint256 overage;

        if (volumeValue < price) {
            uint256 shortage = price - volumeValue;
            creditsContract.useCredits(msg.sender, shortage);
        } else if (volumeValue > price) {
            overage = volumeValue - price;
            creditsContract.addCredits(msg.sender, overage);
        }

        if (vol1 > 0) {
            if (overage > 1) revert Overpaid();
            burnVolume(1, vol1);
        }
        if (vol2 > 0) {
            if (overage > 3) revert Overpaid();
            burnVolume(2, vol2);
        }
        if (vol3 > 0) {
            if (overage > 8) revert Overpaid();
            burnVolume(3, vol3);
        }
    }

    function _pay(uint256 id, uint256 qty) private {
        Item storage item = items[id];

        uint256 price = item.price * qty;
        if (item.paymentType == PaymentType.Eth) {
            if (msg.value != price) revert Underpaid();
            return;
        }
        if (item.paymentType == PaymentType.Coin) revert InvalidPaymentType();
        IERC20 c = IERC20(item.paymentCoinAddress);
        c.transferFrom(msg.sender, item.coinReceiver, price);
    }

    function burnVolume(uint256 id, uint256 qty) private {
        chroniclesContract.burn(id, msg.sender, qty);
        sbtContract.increaseBalance(msg.sender, id, qty);
    }

    function sendReward(
        address wallet,
        Reward memory reward,
        uint256 multiplier,
        bool erc20Optional
    ) private {
        uint256 amount = multiplier * reward.amount;
        if (reward.rewardType == RewardType.ERC1155) {
            IERC1155 c = IERC1155(reward.rewarder);
            c.safeTransferFrom(
                reward.vault,
                wallet,
                reward.tokenId,
                amount,
                ""
            );
        } else if (reward.rewardType == RewardType.ERC721) {
            IERC721 c = IERC721(reward.rewarder);
            c.transferFrom(reward.vault, wallet, reward.tokenId);
        } else if (reward.rewardType == RewardType.ERC20) {
            IERC20 c = IERC20(reward.rewarder);
            if (erc20Optional) {
                uint256 balance = c.balanceOf(reward.vault);
                if (balance == 0) return;
                if (balance < amount) amount = balance;
            }
            c.transferFrom(reward.vault, wallet, amount);
        } else {
            IExternalRewarder c = IExternalRewarder(reward.rewarder);
            c.reward(wallet, reward.tokenId, amount);
        }
    }

    /* ---------
        Helpers
       --------- */

    function getItems(
        uint256 start,
        uint256 count
    ) external view returns (Item[] memory, uint256[] memory) {
        uint256 end = start + count - 1;

        if (end > itemCount) {
            end = itemCount;
            if (end < start) revert OutOfBounds();
            count = end - start + 1;
        }

        Item[] memory tempItems = new Item[](count);
        uint256[] memory tempEntries = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = start; i <= end; i++) {
            tempItems[index] = items[i];
            tempEntries[index] = participationCounters[i];
            index++;
        }
        return (tempItems, tempEntries);
    }

    function getParticipations(
        uint256[] calldata ids,
        address wallet
    ) external view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            ret[i] = countersPerWallet[id][wallet];
        }
        return ret;
    }

    function getBalances(
        address wallet
    ) external view returns (uint256, uint256, uint256, uint256) {
        return (
            chroniclesContract.balanceOf(wallet, 1),
            chroniclesContract.balanceOf(wallet, 2),
            chroniclesContract.balanceOf(wallet, 3),
            creditsContract.getCredits(wallet)
        );
    }

    /* -----------
        Modifiers
       ----------- */

    modifier onlyAuthority() {
        if (!authorities[msg.sender]) revert NotAllowed();
        _;
    }

    /* -------
        Admin
       ------- */

    function initializeChainlink(uint256 id) external onlyOwner {
        Item storage item = items[id];
        if (item.itemType != ItemType.Winnable) revert NotFound();
        if (item.endTime == 0 || block.timestamp <= item.endTime)
            revert TooSoon();

        uint256 requestId = chainlinkContract.requestRandomWords(
            chainlinkKeyHash,
            chainlinkSubscriptionId,
            chainlinkConfirmations,
            chainlinkGasLimit,
            1
        );
        requestIdToItemId[requestId] = id;
    }

    /// @notice Callback invoked by chainlink
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 id = requestIdToItemId[requestId];
        uint256 value = randomWords[0];

        if (itemSeeds[id] != 0) return;

        if (value == 0) value = 1;
        itemSeeds[id] = value;
    }

    function setSeedFallback(uint256 id) external onlyOwner {
        if (itemSeeds[id] != 0) return;
        itemSeeds[id] = uint256(
            keccak256(abi.encodePacked(id, blockhash(block.number - 1)))
        );
    }

    function pickWinners(uint256 id, uint256 end) external onlyOwner {
        Item storage item = items[id];
        uint256 seed = itemSeeds[id];

        if (seed == 0) return;

        if (item.itemType != ItemType.Winnable) revert NotFound();
        if (item.endTime == 0 || block.timestamp <= item.endTime)
            revert TooSoon();
        if (participationCounters[id] == 0) revert NoEntriesFound();

        uint256 index = 0;
        for (uint256 i = 0; i < item.rewards.length; i++) {
            Reward storage reward = item.rewards[i];
            uint256 repeats = reward.repeats;
            if (repeats == 0) repeats = 1;

            for (uint256 j = 0; j < repeats; j++) {
                if (winners[id][index] == address(0)) {
                    uint256 winnerIndex = uint256(
                        keccak256(abi.encodePacked(seed, index))
                    ) % participationCounters[id];

                    address winner = entries[id][winnerIndex];

                    while (winner == address(0)) {
                        winnerIndex--;
                        winner = entries[id][winnerIndex];
                    }

                    winners[id][index] = winner;

                    sendReward(winner, reward, 1, false);
                    emit RewardSent(id, index, winner);
                }

                index++;
                if (index >= end) return;
            }
        }
    }

    function bakeEntry(uint256 itemId, uint256 entryId) external onlyOwner {
        if (entryId > participationCounters[itemId]) revert OutOfBounds();
        address wallet = entries[itemId][entryId];
        if (wallet != address(0)) return;

        uint256 index = entryId;
        while (wallet == address(0)) {
            index--;
            wallet = entries[itemId][index];
        }

        entries[itemId][entryId] = wallet;
    }

    function addItem(Item calldata item) external onlyOwner {
        itemCount++;
        items[itemCount] = item;
        emit ItemAdded(itemCount, item);
    }

    function updateItem(uint256 id, Item calldata item) external onlyOwner {
        items[id] = item;
        emit ItemUpdated(itemCount, item);
    }

    function addRewards(
        uint256 id,
        Reward calldata reward,
        uint256 times
    ) external onlyOwner {
        if (id < itemCount) revert NotFound();
        Item storage item = items[id];
        for (uint256 i = 0; i < times; i++) {
            item.rewards.push(reward);
        }
    }

    function testReward(
        address wallet,
        Reward calldata reward,
        uint256 multiplier
    ) external onlyOwner {
        sendReward(wallet, reward, multiplier, false);
    }

    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    /// @notice Configures chainlink
    function configureChainlink(
        bytes32 _keyHash,
        uint64 _subscription,
        uint16 _confirmations,
        uint32 _gasLimit
    ) external onlyOwner {
        chainlinkKeyHash = _keyHash;
        chainlinkSubscriptionId = _subscription;
        chainlinkConfirmations = _confirmations;
        chainlinkGasLimit = _gasLimit;
    }
}