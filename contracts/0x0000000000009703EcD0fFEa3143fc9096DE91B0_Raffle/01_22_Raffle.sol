// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {PackableReentrancyGuard} from "@looksrare/contracts-libs/contracts/PackableReentrancyGuard.sol";
import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {Arrays} from "./libraries/Arrays.sol";

import {WinningEntrySearchLogic} from "./WinningEntrySearchLogic.sol";

import "./interfaces/IRaffle.sol";

// ....................................................................................................
// .......................................,,,,,,.......................................................
// ....................................,;+??????*;;:..................,,,,,,,,.........................
// ..................................,+?????????????*;,............:;*????????*;,......................
// ................................,+??????????????*???+,.......:+*??????????????*:....................
// ..............................:+?????????*????????*???+:,.,;*???????????????????*,..................
// ............................,*???????????%%%%%%%%%%??*???*???????????????????????*,.................
// ..........................,;???????????%%??????????%%%?*????????????????????????*?;.................
// .........................:???????????%%???????????????%%???????*?????????????*?**?*.................
// ........................:%%%???????%%?*??????????????**?%?**???%%%%%%%%%%%%%%??????,,,,.............
// ......................,*SSSSS?????%?*??????????*??????%??%%??????????????***???????????*;:..........
// .....................:%S%%%%SS??????????????*??%%%%%%%?????%%%%??*????????????????????????+,........
// ....................:SS%%%%%%#?*????????????%%%????**???????*??%%%?*??%%%%%%%?????????%%%%%:........
// ....................+S?%%%%%%S%*?????????*?%%?**??%%%%%%%%%%%??*?%??%%??????????%%%%%?????%?+,......
// ..................,;%%%%%%%%%%S*???????*??%?*??%%%???????????%%%??S%????%%%%%%???????%%%%????*,.....
// .................;?S#%%%%?SS%%S*???????%%%?*?%%??*??****????????%%%?%%%?????????*++++*?%%%%%??:.....
// ...............,*%?S%%%%%%S%%SS*????%%%????%%??*????%SSS##S***?????%???*????*;,,:::;:,,:+???%S+.....
// ..............,*?*?S%%%%%%#SSS?????%???*?%%???????%@@@@@@##S:.,:+????????+:,..:%@@@%@#*,..:*???+....
// ..............+????S%%%%%%S%???????????%%??*???+:+#@@@@@[email protected]@#:...,;????+,....;@@@@@%@@@#+...:???:...
// .............:?????S%%%%%%S*????%%%%%%%??????+,.,#[email protected]@@;[email protected]@@%.....+%*,.....,[email protected]@@@@?;*#@@+...,+?,...
// .............*?????S%%%%%%S*????%**???**???+,[email protected]#@@@S..,#@@@;....;*.......+%[email protected]@@%...;@@#,....;:...
// ............;??????S%%%%%%S?????%%???????+,....,#@@@@@#:.,#@@@%....;,[email protected]@@@@*....#@@+....,;...
// ...........,???????S%%%%%%S????????%%%%:,......:@@@@@@@S*%@@@@#,..,;.......,#@@@@@[email protected]@%....:;...
// ...........;???????%S%%%%%SS*??????**???:......:@@@@@@@@@@@@@@@+..::.......,@@@@@@#;,.;@@@#,..,+,...
// ..........,?????????S%%%%%%S?????????????*:....,#@@@@@@@@@@@@@@?.,+:.......,@@@@@@@@#[email protected]@@@@:.;+,....
// ..........;????????*S%%%%%%SS*?????????????*:[email protected]@@@@@@@@@@@@@S+?%*::,....,#@@@@@@@@@@@@@@?*%;.....
// ..........*????????*SS%S#S?%S??????????%?**??*;,*@@@@@@@@@@@@#S%???%???**+;:[email protected]@@@@@@@##S%?????:.....
// .........:?????????*%#S%%S%%%S???*??????%%%??????####@@@@#S%?***?%%?????????%%%%??????*****?*:......
// .........*?????????*%#?*%S%%%S?*?%%%%%%%%?%%%%%%%%???????****??%%%????????????????????????%;........
// ........:?????????*%#?**S%?%%%S%%%?????%%%%%????????%%%%%%%%%%%?????????????%%%%%%%%%%%%%%+.........
// ........*??????????#%*?*%SSSS%S#???????????%%%%%??***???????????????????????*??*??*?????*%+:........
// .......:?????????*%#?????%%%S%%S%??????????????%%%%%???***??????????????????????????**??%%%%+.......
// .......*??????????#%*???***S%%%%#????S#S%%?????????%%%%%%?????*?????????????????**???%%%%????.......
// ......:?????????*SS*???????SSSS%SS??SS%S#%%%%???????????%%%%%%%%?????????????????%%%%%???????.......
// ......+????????*?#????????????%S%SSSS%%%SS?%%%%%%?????????????%%%%%%%%%%%%%%%%%%%%?????????%+.......
// ......*?????????#S??????????*?S%%%SS%%%%%S%????%%%%%?????????????????????????????????????%%+,.......
// ......*???????*%#SS?????????*%%%%%%%%%%%%%#???????%%%%%%%?????????????????????????????%%?+:.........
// ......*????????SS%SS?*?????*%%%%%%%%%%%%%%SS???????????%%%%%%%??????????????????%%%%%%%%*...........
// .....;S%???????#%%%SS?*???*%#%%%%%%%%%%%%%%#%%?????????????%%%%%%%%%%%%%%%%%%%%%%%%??????,..........
// ...,?SSS%*???*SS%%%%S#?*?*%#%#%%%%%%%%%%%%%S?%%%%????????????????????????????????????????,..........
// ...?S%%%S?*???S%%%%%%S#?*?#?*%SS%%%%%%%%%%%S?*??%%%%???????????????????????????????????%?...........
// .,?S%%%%SS%?*%S%%%%%%%SS?S%*?*?SS%%%%%%%%%%S????*??%%%%%%%????????????????????????????%%:...........
// .*#%%%%%%%SS%S%%%%%%%%%S#S??????%S#S%%%%?%SS???????*?????%%%%%%%%%%%%%%%%%??????????%%*:............
// ;S%%%%%%%%%S#S%%%%%%%%%S#????????*?SSSSSSS#??????????????*?????????%%%%%%%%%%%%%S%??+,..............
// %S%%%%%%%%%SS%%%%%%%%%%S%*????????**%%%%%##????????????????????????*******??????+,..................
// S%%%%%%%%%SS%%%%%%%%%%S#%%?????**???****?SS%*??????????????????????????????**+:,....................
// %%%%%%%%S#S%%%%%%%%%%%S???%%%%%%?????????SSS*??????????????????***??+;;;::,.........................
// %%%%%%%S#S%%%%%%%%%%%SS?***??????%%%%%%%%SSS?????????????????????%?:................................
// %%%%%%SSS%%%%%%%%%%%S#SS%????*****???????%SS%%%%%%%%%%%%%%%%%??%%+,.................................
// %%%%%%%%%%%%%%%%%%%%SS%SSSSSS%%????******%SS?************?***?%*:...................................
// %%%%%%%%%%%%%%%%%%%%#S%%%%%%SSSSSSS%%%???%SS%???????????????%S#+....................................
// %%%%%%%%%%%%%%%%%%%S#%%%%%%%%%%%%%SSSSSSSS#%#SSSSSSSSSSSSSSSS%S%,...................................
// %%%%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%S####%#%%%%%%%%%%%%%%%%%%S+...................................
// %%%%%%%%%%%%%%%%%%S#%%%%%%%%%%%%%%%%%%#S%[email protected]%#S%%%%%%%%%%%%%%%%%S%,..................................
// %%%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%SS%#S#%SS%%%%%%%%%%%%%%%%%%S*..................................
// %%%%%%%%%%%%%%%%%S#S%%%%%%%%%%%%%%%%%SSSS##S%#%%%%%%%%%%%%%%%%%%%S:.................................
// %%%%%%%%%%%%%%%%%SS%%%%%%%%%%%%%%%%%%%#####%%#%%%%%%%%%%%%%%%%%%%S*.................................
// %%%%%%%%%%%%%%%%%#S%%%%%%%%%%%%%%%%%%%S#S%%?S#%%%%%%%%%%%%%%%%%%%SS,................................
// %%%%%%%%%%%%%%%%S#S%%%%%%%%%%%%%%%%%%%%S#SS##S%%%%%%%%%%%%%%%%%%%%S;................................
// %%%%%%%%%%%%%%%%SS%%%%%%%%%%%%%%%%%%%%%%SS##S%%%%%%%%%%%%%%%%%%%%%S?................................
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SSS%%%%%%%%%%%%%%%%%%%%%S%,...............................
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#SS%%%%%%%%%%%%%%%%%%%%%%S:...............................
// ...................... [Calling the blockchain to get provably fair results] .......................

/**
 * @title Raffle
 * @notice This contract allows anyone to permissionlessly host raffles on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract Raffle is
    IRaffle,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable,
    WinningEntrySearchLogic
{
    using Arrays for uint256[];

    address public immutable WETH;

    uint256 public constant ONE_DAY = 86_400 seconds;
    uint256 public constant ONE_WEEK = 604_800 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 public constant ONE_HUNDRED_PERCENT_BP = 10_000;

    /**
     * @notice The number of raffles created.
     */
    uint256 public rafflesCount;

    /**
     * @notice The raffles created.
     * @dev The key is the raffle ID.
     */
    mapping(uint256 => Raffle) public raffles;

    /**
     * @notice The participants stats of the raffles.
     * @dev The key is the raffle ID and the nested key is the participant address.
     */
    mapping(uint256 => mapping(address => ParticipantStats)) public rafflesParticipantsStats;

    /**
     * @notice It checks whether the currency is allowed.
     */
    mapping(address => bool) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per raffle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE = 20;

    /**
     * @notice The maximum number of winners per raffle.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 110;

    /**
     * @notice A Chainlink node should wait for 3 confirmations before responding.
     */
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 public immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface public immutable VRF_COORDINATOR;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice The claimable fees of the protocol fee recipient.
     * @dev The key is the currency address.
     */
    mapping(address => uint256) public protocolFeeRecipientClaimableFees;

    /**
     * @notice The number of pricing options per raffle.
     */
    uint256 public constant PRICING_OPTIONS_PER_RAFFLE = 5;

    /**
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
    }

    /**
     * @inheritdoc IRaffle
     * @dev This function can still be called when the contract is paused because the raffle creator
     *      would not be able to deposit prizes and open the raffle anyway. The restriction to disallow
     *      raffles creation when the contract is paused will be enforced in the frontend.
     */
    function createRaffle(CreateRaffleCalldata calldata params) external returns (uint256 raffleId) {
        uint40 cutoffTime = params.cutoffTime;
        if (_unsafeAdd(block.timestamp, ONE_DAY) > cutoffTime || cutoffTime > _unsafeAdd(block.timestamp, ONE_WEEK)) {
            revert InvalidCutoffTime();
        }

        uint16 agreedProtocolFeeBp = params.protocolFeeBp;
        if (agreedProtocolFeeBp != protocolFeeBp) {
            revert InvalidProtocolFeeBp();
        }

        address feeTokenAddress = params.feeTokenAddress;
        if (feeTokenAddress != address(0)) {
            if (!isCurrencyAllowed[feeTokenAddress]) {
                revert InvalidCurrency();
            }
        }

        unchecked {
            raffleId = ++rafflesCount;
        }

        uint256 prizesCount = params.prizes.length;
        if (prizesCount == 0 || prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE) {
            revert InvalidPrizesCount();
        }

        Raffle storage raffle = raffles[raffleId];
        uint40 cumulativeWinnersCount;
        uint8 currentPrizeTier;
        for (uint256 i; i < prizesCount; ) {
            Prize memory prize = params.prizes[i];
            if (prize.prizeTier < currentPrizeTier) {
                revert InvalidPrize();
            }
            _validatePrize(prize);

            cumulativeWinnersCount += prize.winnersCount;
            prize.cumulativeWinnersCount = cumulativeWinnersCount;
            currentPrizeTier = prize.prizeTier;
            raffle.prizes.push(prize);

            unchecked {
                ++i;
            }
        }

        uint40 minimumEntries = params.minimumEntries;
        if (cumulativeWinnersCount > minimumEntries || cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(raffleId, params.pricingOptions);

        raffle.owner = msg.sender;
        raffle.isMinimumEntriesFixed = params.isMinimumEntriesFixed;
        raffle.cutoffTime = cutoffTime;
        raffle.minimumEntries = minimumEntries;
        raffle.maximumEntriesPerParticipant = params.maximumEntriesPerParticipant;
        raffle.protocolFeeBp = agreedProtocolFeeBp;
        raffle.feeTokenAddress = feeTokenAddress;
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Created);
    }

    /**
     * @inheritdoc IRaffle
     */
    function depositPrizes(uint256 raffleId) external payable nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Created);
        _validateCaller(raffle.owner);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 expectedEthValue;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = prizes[i];
            TokenType prizeType = prize.prizeType;
            if (prizeType == TokenType.ERC721) {
                _executeERC721TransferFrom(prize.prizeAddress, msg.sender, address(this), prize.prizeId);
            } else if (prizeType == TokenType.ERC20) {
                _executeERC20TransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeAmount * prize.winnersCount
                );
            } else if (prizeType == TokenType.ETH) {
                expectedEthValue += (prize.prizeAmount * prize.winnersCount);
            } else {
                _executeERC1155SafeTransferFrom(
                    prize.prizeAddress,
                    msg.sender,
                    address(this),
                    prize.prizeId,
                    prize.prizeAmount * prize.winnersCount
                );
            }
            unchecked {
                ++i;
            }
        }

        _validateExpectedEthValueOrRefund(expectedEthValue);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Open);
    }

    /**
     * @dev This function is required in order for the contract to receive ERC-1155 tokens.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IRaffle
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable nonReentrant whenNotPaused {
        uint256 entriesCount = entries.length;
        uint208 expectedEthValue;
        for (uint256 i; i < entriesCount; ) {
            EntryCalldata calldata entry = entries[i];

            if (entry.pricingOptionIndex >= PRICING_OPTIONS_PER_RAFFLE) {
                revert InvalidIndex();
            }

            uint256 raffleId = entry.raffleId;
            Raffle storage raffle = raffles[raffleId];

            _validateRaffleStatus(raffle, RaffleStatus.Open);

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            PricingOption memory pricingOption = raffle.pricingOptions[entry.pricingOptionIndex];

            uint40 newParticipantEntriesCount = rafflesParticipantsStats[raffleId][msg.sender].entriesCount +
                pricingOption.entriesCount;
            if (newParticipantEntriesCount > raffle.maximumEntriesPerParticipant) {
                revert MaximumEntriesPerParticipantReached();
            }
            rafflesParticipantsStats[raffleId][msg.sender].entriesCount = newParticipantEntriesCount;

            uint208 price = pricingOption.price;

            if (raffle.feeTokenAddress == address(0)) {
                expectedEthValue += price;
            } else {
                _executeERC20TransferFrom(raffle.feeTokenAddress, msg.sender, address(this), price);
            }

            uint40 currentEntryIndex;
            uint256 raffleEntriesCount = raffle.entries.length;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = uint40(_unsafeSubtract(pricingOption.entriesCount, 1));
            } else {
                currentEntryIndex =
                    raffle.entries[_unsafeSubtract(raffleEntriesCount, 1)].currentEntryIndex +
                    pricingOption.entriesCount;
            }

            if (raffle.isMinimumEntriesFixed) {
                if (currentEntryIndex >= raffle.minimumEntries) {
                    revert MaximumEntriesReached();
                }
            }

            raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: msg.sender}));
            raffle.claimableFees += price;

            rafflesParticipantsStats[raffleId][msg.sender].amountPaid += price;

            emit EntrySold(raffleId, msg.sender, pricingOption.entriesCount, price);

            if (currentEntryIndex >= _unsafeSubtract(raffle.minimumEntries, 1)) {
                _drawWinners(raffleId, raffle);
            }

            unchecked {
                ++i;
            }
        }

        _validateExpectedEthValueOrRefund(expectedEthValue);
    }

    /**
     * @param _requestId The ID of the request
     * @param _randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 raffleId = randomnessRequests[_requestId].raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status == RaffleStatus.Drawing) {
                _setRaffleStatus(raffle, raffleId, RaffleStatus.RandomnessFulfilled);
                // We ignore the most significant byte to pack the random word with `exists`
                randomnessRequests[_requestId].randomWord = uint248(_randomWords[0]);
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function selectWinners(uint256 requestId) external {
        RandomnessRequest memory randomnessRequest = randomnessRequests[requestId];
        if (!randomnessRequest.exists) {
            revert RandomnessRequestDoesNotExist();
        }

        uint256 raffleId = randomnessRequest.raffleId;
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.RandomnessFulfilled);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawn);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 winnersCount = prizes[prizesCount - 1].cumulativeWinnersCount;

        Entry[] memory entries = raffle.entries;
        uint256 entriesCount = entries.length;
        uint256 currentEntryIndex = uint256(entries[entriesCount - 1].currentEntryIndex);

        uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

        uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
        for (uint256 i; i < entriesCount; ) {
            currentEntryIndexArray[i] = entries[i].currentEntryIndex;
            unchecked {
                ++i;
            }
        }

        uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
        for (uint256 i; i < prizesCount; ) {
            cumulativeWinnersCountArray[i] = prizes[i].cumulativeWinnersCount;
            unchecked {
                ++i;
            }
        }

        uint256 randomWord = randomnessRequest.randomWord;

        for (uint256 i; i < winnersCount; ) {
            uint256 winningEntry = randomWord % (currentEntryIndex + 1);
            (winningEntry, winningEntriesBitmap) = _incrementWinningEntryUntilThereIsNotADuplicate(
                currentEntryIndex,
                winningEntry,
                winningEntriesBitmap
            );

            raffle.winners.push(
                Winner({
                    participant: entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant,
                    claimed: false,
                    prizeIndex: uint8(cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1))),
                    entryIndex: uint40(winningEntry)
                })
            );

            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external nonReentrant whenNotPaused {
        uint256 claimsCount = claimPrizesCalldata.length;
        for (uint256 i; i < claimsCount; ) {
            _claimPrizesPerRaffle(claimPrizesCalldata[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimProtocolFees(address currency) external onlyOwner {
        uint256 claimableFees = protocolFeeRecipientClaimableFees[currency];
        protocolFeeRecipientClaimableFees[currency] = 0;
        _transferFungibleTokens(currency, protocolFeeRecipient, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function claimFees(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Drawn);

        address raffleOwner = raffle.owner;
        if (msg.sender != raffleOwner) {
            _validateCaller(owner);
        }

        uint208 claimableFees = raffle.claimableFees;
        uint208 protocolFees = (claimableFees * uint208(raffle.protocolFeeBp)) / uint208(ONE_HUNDRED_PERCENT_BP);
        unchecked {
            claimableFees -= protocolFees;
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Complete);

        raffle.claimableFees = 0;

        address feeTokenAddress = raffle.feeTokenAddress;
        _transferFungibleTokens(feeTokenAddress, raffleOwner, claimableFees);

        if (protocolFees != 0) {
            protocolFeeRecipientClaimableFees[feeTokenAddress] += protocolFees;
        }

        emit FeesClaimed(raffleId, claimableFees);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancel(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        bool isOpen = raffle.status == RaffleStatus.Open;

        if (isOpen) {
            if (raffle.cutoffTime > block.timestamp) {
                revert CutoffTimeNotReached();
            }
        } else {
            _validateRaffleStatus(raffle, RaffleStatus.Created);
        }

        _setRaffleStatus(raffle, raffleId, isOpen ? RaffleStatus.Refundable : RaffleStatus.Cancelled);
    }

    /**
     * @inheritdoc IRaffle
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external onlyOwner nonReentrant {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Drawing);

        if (block.timestamp < raffle.drawnAt + ONE_DAY) {
            revert DrawExpirationTimeNotReached();
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffle
     */
    function withdrawPrizes(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Refundable);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Cancelled);

        uint256 prizesCount = raffle.prizes.length;
        address raffleOwner = raffle.owner;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = raffle.prizes[i];
            _transferPrize({prize: prize, recipient: raffleOwner, multiplier: uint256(prize.winnersCount)});

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function claimRefund(uint256[] calldata raffleIds) external nonReentrant whenNotPaused {
        uint256 count = raffleIds.length;

        for (uint256 i; i < count; ) {
            uint256 raffleId = raffleIds[i];
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status < RaffleStatus.Refundable) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];

            if (stats.refunded) {
                revert AlreadyRefunded();
            }

            stats.refunded = true;

            uint208 amountPaid = stats.amountPaid;
            _transferFungibleTokens(raffle.feeTokenAddress, msg.sender, amountPaid);

            emit EntryRefunded(raffleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IRaffle
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IRaffle
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = isAllowed;
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IRaffle
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IRaffle
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory winners) {
        winners = raffles[raffleId].winners;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory prizes) {
        prizes = raffles[raffleId].prizes;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory entries) {
        entries = raffles[raffleId].entries;
    }

    /**
     * @inheritdoc IRaffle
     */
    function getPricingOptions(uint256 raffleId)
        external
        view
        returns (PricingOption[PRICING_OPTIONS_PER_RAFFLE] memory pricingOptions)
    {
        pricingOptions = raffles[raffleId].pricingOptions;
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _setProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param raffleId The ID of the raffle.
     * @param pricingOptions The pricing options for the raffle.
     */
    function _validateAndSetPricingOptions(
        uint256 raffleId,
        PricingOption[PRICING_OPTIONS_PER_RAFFLE] calldata pricingOptions
    ) private {
        for (uint256 i; i < PRICING_OPTIONS_PER_RAFFLE; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            uint40 entriesCount = pricingOption.entriesCount;
            uint208 price = pricingOption.price;

            if (i == 0) {
                if (entriesCount != 1 || price == 0) {
                    revert InvalidPricingOption();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[_unsafeSubtract(i, 1)];
                uint208 lastPrice = lastPricingOption.price;
                uint40 lastEntriesCount = lastPricingOption.entriesCount;

                if (
                    price % entriesCount != 0 ||
                    entriesCount <= lastEntriesCount ||
                    price <= lastPrice ||
                    price / entriesCount > lastPrice / lastEntriesCount
                ) {
                    revert InvalidPricingOption();
                }
            }

            raffles[raffleId].pricingOptions[i] = pricingOption;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        if (prize.prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1 || prize.winnersCount != 1) {
                revert InvalidPrize();
            }
        } else {
            if (prize.prizeType == TokenType.ERC20) {
                if (!isCurrencyAllowed[prize.prizeAddress]) {
                    revert InvalidCurrency();
                }
            }

            if (prize.prizeAmount == 0 || prize.winnersCount == 0) {
                revert InvalidPrize();
            }
        }
    }

    /**
     * @param prize The prize to transfer.
     * @param recipient The recipient of the prize.
     * @param multiplier The multiplier to apply to the prize amount.
     */
    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        TokenType prizeType = prize.prizeType;
        address prizeAddress = prize.prizeAddress;
        if (prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(prizeAddress, address(this), recipient, prize.prizeId);
        } else if (prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else {
            _transferFungibleTokens(prizeAddress, recipient, prize.prizeAmount * multiplier);
        }
    }

    /**
     * @param currency The currency to transfer.
     * @param recipient The recipient of the currency.
     * @param amount The amount of currency to transfer.
     */
    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function _claimPrizesPerRaffle(ClaimPrizesCalldata calldata claimPrizesCalldata) private {
        uint256 raffleId = claimPrizesCalldata.raffleId;
        Raffle storage raffle = raffles[raffleId];
        RaffleStatus status = raffle.status;
        if (status != RaffleStatus.Drawn) {
            _validateRaffleStatus(raffle, RaffleStatus.Complete);
        }

        Winner[] storage winners = raffle.winners;
        uint256[] calldata winnerIndices = claimPrizesCalldata.winnerIndices;
        uint256 winnersCount = winners.length;
        uint256 claimsCount = winnerIndices.length;
        for (uint256 i; i < claimsCount; ) {
            uint256 winnerIndex = winnerIndices[i];

            if (winnerIndex >= winnersCount) {
                revert InvalidIndex();
            }

            Winner storage winner = winners[winnerIndex];
            if (winner.claimed) {
                revert PrizeAlreadyClaimed();
            }
            _validateCaller(winner.participant);
            winner.claimed = true;

            Prize storage prize = raffle.prizes[winner.prizeIndex];
            _transferPrize({prize: prize, recipient: msg.sender, multiplier: 1});

            unchecked {
                ++i;
            }
        }

        emit PrizesClaimed(raffleId, winnerIndices);
    }

    /**
     * @param raffleId The ID of the raffle to draw winners for.
     * @param raffle The raffle to draw winners for.
     */
    function _drawWinners(uint256 raffleId, Raffle storage raffle) private {
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawing);
        raffle.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords(
            KEY_HASH,
            SUBSCRIPTION_ID,
            REQUEST_CONFIRMATIONS,
            uint32(500_000),
            uint32(1)
        );

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].raffleId = raffleId;

        emit RandomnessRequested(raffleId, requestId);
    }

    /**
     * @param raffle The raffle to check the status of.
     * @param status The expected status of the raffle
     */
    function _validateRaffleStatus(Raffle storage raffle, RaffleStatus status) private view {
        if (raffle.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param caller The expected caller.
     */
    function _validateCaller(address caller) private view {
        if (msg.sender != caller) {
            revert InvalidCaller();
        }
    }

    /**
     * @param expectedEthValue The expected ETH value to be sent by the caller.
     */
    function _validateExpectedEthValueOrRefund(uint256 expectedEthValue) private {
        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(
                WETH,
                msg.sender,
                _unsafeSubtract(msg.value, expectedEthValue),
                gasleft()
            );
        }
    }

    /**
     * @param raffle The raffle to set the status of.
     * @param raffleId The ID of the raffle to set the status of.
     * @param status The status to set.
     */
    function _setRaffleStatus(
        Raffle storage raffle,
        uint256 raffleId,
        RaffleStatus status
    ) private {
        raffle.status = status;
        emit RaffleStatusUpdated(raffleId, status);
    }

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}