// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC1155Transfer.sol";
import {OwnableTwoSteps} from "@looksrare/contracts-libs/contracts/OwnableTwoSteps.sol";
import {PackableReentrancyGuard} from "@looksrare/contracts-libs/contracts/PackableReentrancyGuard.sol";
import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";
import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {Arrays} from "./libraries/Arrays.sol";

import {WinningEntrySearchLogicV2} from "./WinningEntrySearchLogicV2.sol";

import {IRaffleV2} from "./interfaces/IRaffleV2.sol";

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
// ..............+????S%%%%%%S%???????????%%??*???+:+#@@@@@SS@@#:...,;????+,....;@@@@@%@@@#+...:???:...
// .............:?????S%%%%%%S*????%%%%%%%??????+,.,#+S@@@;.+@@@%.....+%*,.....,S@@@@@?;*#@@+...,+?,...
// .............*?????S%%%%%%S*????%**???**???+,...?@#@@@S..,#@@@;....;*.......+%?@@@%...;@@#,....;:...
// ............;??????S%%%%%%S?????%%???????+,....,#@@@@@#:.,#@@@%....;,.......S@@@@@*....#@@+....,;...
// ...........,???????S%%%%%%S????????%%%%:,......:@@@@@@@S*%@@@@#,..,;.......,#@@@@@?....S@@%....:;...
// ...........;???????%S%%%%%SS*??????**???:......:@@@@@@@@@@@@@@@+..::.......,@@@@@@#;,.;@@@#,..,+,...
// ..........,?????????S%%%%%%S?????????????*:....,#@@@@@@@@@@@@@@?.,+:.......,@@@@@@@@#S@@@@@:.;+,....
// ..........;????????*S%%%%%%SS*?????????????*:...S@@@@@@@@@@@@@@S+?%*::,....,#@@@@@@@@@@@@@@?*%;.....
// ..........*????????*SS%S#S?%S??????????%?**??*;,*@@@@@@@@@@@@#S%???%???**+;:S@@@@@@@@##S%?????:.....
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
// %%%%%%%%%%%%%%%%%%S#%%%%%%%%%%%%%%%%%%#S%S@%#S%%%%%%%%%%%%%%%%%S%,..................................
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
 * @title RaffleV2
 * @notice This contract allows anyone to permissionlessly host raffles on LooksRare.
 * @author LooksRare protocol team (👀,💎)
 */
contract RaffleV2 is
    IRaffleV2,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable,
    WinningEntrySearchLogicV2
{
    using Arrays for uint256[];

    address private immutable WETH;

    uint256 private constant ONE_DAY = 86_400 seconds;
    uint256 private constant ONE_WEEK = 604_800 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_BP = 10_000;

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
     * @dev 0 is not allowed, 1 is allowed.
     */
    mapping(address => uint256) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per raffle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE = 200;

    /**
     * @notice The maximum number of winners per raffle.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 200;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 private immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

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
     * @notice The number of raffles created.
     * @dev In this smart contract, raffleId is an uint256 but its
     *      max value can only be 2^80 - 1. Realistically we will still
     *      not reach this number.
     */
    uint80 public rafflesCount;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice The maximum number of pricing options per raffle.
     */
    uint256 public constant MAXIMUM_PRICING_OPTIONS_PER_RAFFLE = 5;

    /**
     * @notice Transfer manager faciliates token transfers.
     */
    ITransferManager private immutable transferManager;

    /**
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     * @param _transferManager The transfer manager address
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp,
        address _transferManager
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
        transferManager = ITransferManager(_transferManager);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function createRaffle(CreateRaffleCalldata calldata params)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 raffleId)
    {
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
            _validateCurrency(feeTokenAddress);
        }

        uint256 prizesCount = params.prizes.length;
        if (prizesCount == 0 || prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE) {
            revert InvalidPrizesCount();
        }

        unchecked {
            raffleId = ++rafflesCount;
        }

        // The storage layout of a prize struct (3 slots) is as follows:
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeAddress (160 bits) | prizeTier (8 bits) | prizeType (8 bits) | cumulativeWinnersCount (40 bits) | winnersCount (40 bits) |
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeId (256 bits)                                                                                                            |
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeAmount (256 bits)                                                                                                        |
        //
        // The slot keccak256(raffleId, rafflesSlot) + 4 is used to store the length of the prizes array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 4) + i * 3 is used to store the prize at the i-th index
        // (x 3 because each prize consumes 3 slots).
        //
        // The assembly blocks are equivalent to `raffle.prizes.push(prize);`
        //
        // The primary benefit of using assembly is we only write the prizes length once instead of once per prize.
        uint256 raffleSlot;
        uint256 prizesLengthSlot;
        uint256 individualPrizeSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            raffleSlot := keccak256(0x00, 0x40)

            prizesLengthSlot := add(keccak256(0x00, 0x40), 4)

            mstore(0x00, prizesLengthSlot)
            individualPrizeSlotOffset := keccak256(0x00, 0x20)
        }

        uint256 expectedEthValue;
        uint40 cumulativeWinnersCount;
        {
            uint8 currentPrizeTier;
            for (uint256 i; i < prizesCount; ) {
                Prize memory prize = params.prizes[i];
                uint8 prizeTier = prize.prizeTier;
                if (prizeTier < currentPrizeTier) {
                    revert InvalidPrize();
                }
                _validatePrize(prize);

                TokenType prizeType = prize.prizeType;
                uint40 winnersCount = prize.winnersCount;
                address prizeAddress = prize.prizeAddress;
                uint256 prizeId = prize.prizeId;
                uint256 prizeAmount = prize.prizeAmount;
                if (prizeType == TokenType.ERC721) {
                    transferManager.transferItemERC721(prizeAddress, msg.sender, address(this), prizeId);
                } else if (prizeType == TokenType.ERC20) {
                    transferManager.transferERC20(prizeAddress, msg.sender, address(this), prizeAmount * winnersCount);
                } else if (prizeType == TokenType.ETH) {
                    expectedEthValue += (prizeAmount * winnersCount);
                } else {
                    transferManager.transferItemERC1155(
                        prizeAddress,
                        msg.sender,
                        address(this),
                        prizeId,
                        prizeAmount * winnersCount
                    );
                }

                cumulativeWinnersCount += winnersCount;
                currentPrizeTier = prizeTier;

                assembly {
                    let prizeSlotOne := winnersCount
                    prizeSlotOne := or(prizeSlotOne, shl(40, cumulativeWinnersCount))
                    prizeSlotOne := or(prizeSlotOne, shl(80, prizeType))
                    prizeSlotOne := or(prizeSlotOne, shl(88, prizeTier))
                    prizeSlotOne := or(prizeSlotOne, shl(96, prizeAddress))

                    let currentPrizeSlotOffset := add(individualPrizeSlotOffset, mul(i, 3))
                    sstore(currentPrizeSlotOffset, prizeSlotOne)
                    sstore(add(currentPrizeSlotOffset, 1), prizeId)
                    sstore(add(currentPrizeSlotOffset, 2), prizeAmount)
                }

                unchecked {
                    ++i;
                }
            }

            assembly {
                sstore(prizesLengthSlot, prizesCount)
            }
        }
        _validateExpectedEthValueOrRefund(expectedEthValue);

        uint40 minimumEntries = params.minimumEntries;
        if (cumulativeWinnersCount > minimumEntries || cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(raffleId, minimumEntries, params.pricingOptions);

        bool isMinimumEntriesFixed = params.isMinimumEntriesFixed;
        uint40 maximumEntriesPerParticipant = params.maximumEntriesPerParticipant;
        // The storage layout of a raffle's first 2 slots is as follows:
        // ---------------------------------------------------------------------------------------------------------------------------------|
        // | drawnAt (40 bits) | cutoffTime (40 bits) | isMinimumEntriesFixed (8 bits) | status (8 bits) | owner (160 bits)                 |
        // ---------------------------------------------------------------------------------------------------------------------------------|
        // | agreedProtocolFeeBp (16 bits) | feeTokenAddress (160 bits) | maximumEntriesPerParticipant (40 bits) | minimumEntries (40 bits) |
        // ---------------------------------------------------------------------------------------------------------------------------------|
        //
        // And the slots for these values are calculated by the following formulas:
        // slot 1 = keccak256(raffleId, rafflesSlot)
        // slot 2 = keccak256(raffleId, rafflesSlot) + 1
        //
        // This assembly block is equivalent to
        // raffle.owner = msg.sender;
        // raffle.status = RaffleStatus.Open;
        // raffle.isMinimumEntriesFixed = isMinimumEntriesFixed;
        // raffle.cutoffTime = cutoffTime;
        // raffle.minimumEntries = minimumEntries;
        // raffle.maximumEntriesPerParticipant = maximumEntriesPerParticipant;
        // raffle.protocolFeeBp = agreedProtocolFeeBp;
        // raffle.feeTokenAddress = feeTokenAddress;
        assembly {
            let raffleSlotOneValue := caller()
            raffleSlotOneValue := or(raffleSlotOneValue, shl(160, 1))
            raffleSlotOneValue := or(raffleSlotOneValue, shl(168, isMinimumEntriesFixed))
            raffleSlotOneValue := or(raffleSlotOneValue, shl(176, cutoffTime))

            let raffleSlotTwoValue := minimumEntries
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(40, maximumEntriesPerParticipant))
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(80, feeTokenAddress))
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(240, agreedProtocolFeeBp))

            sstore(raffleSlot, raffleSlotOneValue)
            sstore(add(raffleSlot, 1), raffleSlotTwoValue)
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Open);
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
     * @inheritdoc IRaffleV2
     * @notice If it is a delegated recipient, the amount paid should still be accrued to the payer.
     *         If a raffle is cancelled, the payer should be refunded and not the recipient.
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable nonReentrant whenNotPaused {
        (address feeTokenAddress, uint208 expectedValue) = _enterRaffles(entries);
        _chargeUser(feeTokenAddress, expectedValue);
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
                randomnessRequests[_requestId].randomWord = _randomWords[0];
            }
        }
    }

    /**
     * @inheritdoc IRaffleV2
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

        uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
        for (uint256 i; i < entriesCount; ) {
            currentEntryIndexArray[i] = entries[i].currentEntryIndex;
            unchecked {
                ++i;
            }
        }

        uint256 currentEntryIndex = uint256(currentEntryIndexArray[entriesCount - 1]);

        uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

        uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
        for (uint256 i; i < prizesCount; ) {
            cumulativeWinnersCountArray[i] = prizes[i].cumulativeWinnersCount;
            unchecked {
                ++i;
            }
        }

        uint256 randomWord = randomnessRequest.randomWord;
        uint256 winningEntry;

        // The storage layout of a winner slot is as follows:
        // ------------------------------------------------------------------------------------------------------------|
        // | unused (40 bits) | entryIndex (40 bits) | prizeIndex (8 bits) | claimed (8 bits) | participant (160 bits) |
        // ------------------------------------------------------------------------------------------------------------|
        //
        // The slot keccak256(raffleId, rafflesSlot) + 6 is used to store the length of the winners array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 6) + i is used to store the winner at the i-th index.
        //
        // The assembly blocks are equivalent to
        // raffle.winners.push(
        //   Winner({
        //     participant: entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant,
        //     claimed: false,
        //     prizeIndex: uint8(cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1))),
        //     entryIndex: uint40(winningEntry)
        //   })
        // );
        //
        // The primary benefit of using assembly is we only write the winners length once instead of once per winner.
        uint256 winnersLengthSlot;
        uint256 individualWinnerSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            winnersLengthSlot := add(keccak256(0x00, 0x40), 6)

            mstore(0x00, winnersLengthSlot)
            individualWinnerSlotOffset := keccak256(0x00, 0x20)
        }

        for (uint256 i; i < winnersCount; ) {
            (randomWord, winningEntry, winningEntriesBitmap) = _searchForWinningEntryUntilThereIsNotADuplicate(
                randomWord,
                currentEntryIndex,
                winningEntriesBitmap
            );

            address participant = entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant;
            uint256 prizeIndex = cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1));

            assembly {
                let winnerSlotValue := participant
                winnerSlotValue := or(winnerSlotValue, shl(168, prizeIndex))
                winnerSlotValue := or(winnerSlotValue, shl(176, winningEntry))

                sstore(add(individualWinnerSlotOffset, i), winnerSlotValue)
            }

            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));

            unchecked {
                ++i;
            }
        }

        assembly {
            sstore(winnersLengthSlot, winnersCount)
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function claimPrize(uint256 raffleId, uint256 winnerIndex) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.Drawn) {
            _validateRaffleStatus(raffle, RaffleStatus.Complete);
        }

        Winner[] storage winners = raffle.winners;
        if (winnerIndex >= winners.length) {
            revert InvalidIndex();
        }

        Winner storage winner = winners[winnerIndex];
        if (winner.claimed) {
            revert NothingToClaim();
        }
        _validateCaller(winner.participant);
        winner.claimed = true;

        _transferPrize({prize: raffle.prizes[winner.prizeIndex], recipient: msg.sender, multiplier: 1});

        emit PrizeClaimed(raffleId, winnerIndex);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;

        for (uint256 i; i < claimPrizesCalldata.length; ) {
            ClaimPrizesCalldata calldata perRaffleClaimPrizesCalldata = claimPrizesCalldata[i];
            uint256 raffleId = perRaffleClaimPrizesCalldata.raffleId;
            Raffle storage raffle = raffles[raffleId];
            if (raffle.status != RaffleStatus.Drawn) {
                _validateRaffleStatus(raffle, RaffleStatus.Complete);
            }

            Winner[] storage winners = raffle.winners;
            uint256[] calldata winnerIndices = perRaffleClaimPrizesCalldata.winnerIndices;
            uint256 winnersCount = winners.length;
            uint256 claimsCount = winnerIndices.length;

            for (uint256 j; j < claimsCount; ) {
                uint256 winnerIndex = winnerIndices[j];

                if (winnerIndex >= winnersCount) {
                    revert InvalidIndex();
                }

                Winner storage winner = winners[winnerIndex];
                if (winner.claimed) {
                    revert NothingToClaim();
                }
                _validateCaller(winner.participant);
                winner.claimed = true;

                Prize storage prize = raffle.prizes[winner.prizeIndex];
                if (prize.prizeType > TokenType.ERC1155) {
                    address prizeAddress = prize.prizeAddress;
                    if (prizeAddress == transferAccumulator.tokenAddress) {
                        transferAccumulator.amount += prize.prizeAmount;
                    } else {
                        if (transferAccumulator.amount != 0) {
                            _transferFungibleTokens(transferAccumulator);
                        }

                        transferAccumulator.tokenAddress = prizeAddress;
                        transferAccumulator.amount = prize.prizeAmount;
                    }
                } else {
                    _transferPrize({prize: prize, recipient: msg.sender, multiplier: 1});
                }

                unchecked {
                    ++j;
                }
            }

            emit PrizesClaimed(raffleId, winnerIndices);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferFungibleTokens(transferAccumulator);
        }
    }

    /**
     * @inheritdoc IRaffleV2
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
            _transferFungibleTokens(feeTokenAddress, protocolFeeRecipient, protocolFees);
        }

        emit FeesClaimed(raffleId, claimableFees);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function cancel(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRafflePostCutoffTimeStatusTransferability(raffle);
        if (block.timestamp < raffle.cutoffTime + 1 hours) {
            _validateCaller(raffle.owner);
        }
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffleV2
     * @notice A raffle cannot be drawn if there are less entries than prizes.
     */
    function drawWinners(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        Entry[] storage entries = raffle.entries;
        uint256 entriesCount = entries.length;
        if (entriesCount == 0) {
            revert NotEnoughEntries();
        }

        Prize[] storage prizes = raffle.prizes;

        if (prizes[prizes.length - 1].cumulativeWinnersCount > entries[entriesCount - 1].currentEntryIndex + 1) {
            revert NotEnoughEntries();
        }

        _validateRafflePostCutoffTimeStatusTransferability(raffle);
        _validateCaller(raffle.owner);
        _drawWinners(raffleId, raffle);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Drawing);

        if (block.timestamp < raffle.drawnAt + ONE_DAY) {
            revert DrawExpirationTimeNotReached();
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffleV2
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
     * @inheritdoc IRaffleV2
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function claimRefund(uint256[] calldata raffleIds) external nonReentrant whenNotPaused {
        (address feeTokenAddress, uint208 refundAmount) = _claimRefund(raffleIds);
        _transferFungibleTokens(feeTokenAddress, msg.sender, refundAmount);
    }

    /**
     * @inheritdoc IRaffleV2
     * @notice The fee token address for all the raffles involved must be the same.
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function rollover(uint256[] calldata refundableRaffleIds, EntryCalldata[] calldata entries)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (address refundFeeTokenAddress, uint208 rolloverAmount) = _claimRefund(refundableRaffleIds);
        (address enterRafflesFeeTokenAddress, uint208 expectedValue) = _enterRaffles(entries);

        if (refundFeeTokenAddress != enterRafflesFeeTokenAddress) {
            revert InvalidCurrency();
        }

        if (rolloverAmount > expectedValue) {
            _transferFungibleTokens(refundFeeTokenAddress, msg.sender, _unsafeSubtract(rolloverAmount, expectedValue));
        } else if (rolloverAmount < expectedValue) {
            _chargeUser(refundFeeTokenAddress, _unsafeSubtract(expectedValue, rolloverAmount));
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = (isAllowed ? 1 : 0);
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory winners) {
        winners = raffles[raffleId].winners;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory prizes) {
        prizes = raffles[raffleId].prizes;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory entries) {
        entries = raffles[raffleId].entries;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getPricingOptions(uint256 raffleId) external view returns (PricingOption[] memory pricingOptions) {
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
        uint40 minimumEntries,
        PricingOption[] calldata pricingOptions
    ) private {
        uint256 count = pricingOptions.length;

        if (count == 0 || count > MAXIMUM_PRICING_OPTIONS_PER_RAFFLE) {
            revert InvalidPricingOptionsCount();
        }

        uint40 lowestEntriesCount = pricingOptions[0].entriesCount;

        // The storage layout of a pricing option slot is as follows:
        // ---------------------------------------------------------------|
        // | unused (8 bits) | price (208 bits) | entries count (40 bits) |
        // ---------------------------------------------------------------|
        //
        // The slot keccak256(raffleId, rafflesSlot) + 3 is used to store the length of the pricing options array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 3) + i is used to store the pricing option at the i-th index.
        //
        // The assembly blocks are equivalent to `raffles[raffleId].pricingOptions.push(pricingOption);`
        //
        // The primary benefit of using assembly is we only write the pricing options length once instead of once per pricing option.
        uint256 pricingOptionsLengthSlot;
        uint256 individualPricingOptionSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            pricingOptionsLengthSlot := add(keccak256(0x00, 0x40), 3)

            mstore(0x00, pricingOptionsLengthSlot)
            individualPricingOptionSlotOffset := keccak256(0x00, 0x20)
        }

        for (uint256 i; i < count; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            uint40 entriesCount = pricingOption.entriesCount;
            uint208 price = pricingOption.price;

            if (i == 0) {
                if (minimumEntries % entriesCount != 0 || price == 0) {
                    revert InvalidPricingOption();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[_unsafeSubtract(i, 1)];
                uint208 lastPrice = lastPricingOption.price;
                uint40 lastEntriesCount = lastPricingOption.entriesCount;

                if (
                    entriesCount % lowestEntriesCount != 0 ||
                    price % entriesCount != 0 ||
                    entriesCount <= lastEntriesCount ||
                    price <= lastPrice ||
                    price / entriesCount > lastPrice / lastEntriesCount
                ) {
                    revert InvalidPricingOption();
                }
            }

            assembly {
                let pricingOptionValue := entriesCount
                pricingOptionValue := or(pricingOptionValue, shl(40, price))
                sstore(add(individualPricingOptionSlotOffset, i), pricingOptionValue)
            }

            unchecked {
                ++i;
            }
        }

        assembly {
            sstore(pricingOptionsLengthSlot, count)
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        TokenType prizeType = prize.prizeType;
        if (prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1 || prize.winnersCount != 1) {
                revert InvalidPrize();
            }
        } else {
            if (prizeType == TokenType.ERC20) {
                _validateCurrency(prize.prizeAddress);
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
     * @param transferAccumulator The transfer accumulator.
     */
    function _transferFungibleTokens(TransferAccumulator memory transferAccumulator) private {
        _transferFungibleTokens(transferAccumulator.tokenAddress, msg.sender, transferAccumulator.amount);
    }

    /**
     * @param raffleId The ID of the raffle to draw winners for.
     * @param raffle The raffle to draw winners for.
     */
    function _drawWinners(uint256 raffleId, Raffle storage raffle) private {
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawing);
        raffle.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: SUBSCRIPTION_ID,
            minimumRequestConfirmations: uint16(3),
            callbackGasLimit: uint32(500_000),
            numWords: uint32(1)
        });

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].raffleId = uint80(raffleId);

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
     * @param entries The entries to enter.
     */
    function _enterRaffles(EntryCalldata[] calldata entries)
        private
        returns (address feeTokenAddress, uint208 expectedValue)
    {
        uint256 count = entries.length;
        for (uint256 i; i < count; ) {
            EntryCalldata calldata entry = entries[i];

            address recipient = entry.recipient == address(0) ? msg.sender : entry.recipient;

            uint256 raffleId = entry.raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (i == 0) {
                feeTokenAddress = raffle.feeTokenAddress;
            } else if (raffle.feeTokenAddress != feeTokenAddress) {
                revert InvalidCurrency();
            }

            if (entry.pricingOptionIndex >= raffle.pricingOptions.length) {
                revert InvalidIndex();
            }

            _validateRaffleStatus(raffle, RaffleStatus.Open);

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            uint40 entriesCount;
            uint208 price;
            {
                PricingOption memory pricingOption = raffle.pricingOptions[entry.pricingOptionIndex];

                uint40 multiplier = entry.count;
                if (multiplier == 0) {
                    revert InvalidCount();
                }

                entriesCount = pricingOption.entriesCount * multiplier;
                price = pricingOption.price * multiplier;

                uint40 newParticipantEntriesCount = rafflesParticipantsStats[raffleId][recipient].entriesCount +
                    entriesCount;
                if (newParticipantEntriesCount > raffle.maximumEntriesPerParticipant) {
                    revert MaximumEntriesPerParticipantReached();
                }
                rafflesParticipantsStats[raffleId][recipient].entriesCount = newParticipantEntriesCount;
            }

            expectedValue += price;

            uint256 raffleEntriesCount = raffle.entries.length;
            uint40 currentEntryIndex;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = uint40(_unsafeSubtract(entriesCount, 1));
            } else {
                currentEntryIndex =
                    raffle.entries[_unsafeSubtract(raffleEntriesCount, 1)].currentEntryIndex +
                    entriesCount;
            }

            if (raffle.isMinimumEntriesFixed) {
                if (currentEntryIndex >= raffle.minimumEntries) {
                    revert MaximumEntriesReached();
                }
            }

            _pushEntry(raffle, currentEntryIndex, recipient);
            raffle.claimableFees += price;

            rafflesParticipantsStats[raffleId][msg.sender].amountPaid += price;

            emit EntrySold(raffleId, msg.sender, recipient, entriesCount, price);

            if (currentEntryIndex >= _unsafeSubtract(raffle.minimumEntries, 1)) {
                _drawWinners(raffleId, raffle);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param feeTokenAddress The address of the token to charge the fee in.
     * @param expectedValue The expected value of the fee.
     */
    function _chargeUser(address feeTokenAddress, uint256 expectedValue) private {
        if (feeTokenAddress == address(0)) {
            _validateExpectedEthValueOrRefund(expectedValue);
        } else {
            transferManager.transferERC20(feeTokenAddress, msg.sender, address(this), expectedValue);
        }
    }

    /**
     * @param raffleIds The IDs of the raffles to claim refunds for.
     */
    function _claimRefund(uint256[] calldata raffleIds)
        private
        returns (address feeTokenAddress, uint208 refundAmount)
    {
        uint256 count = raffleIds.length;

        for (uint256 i; i < count; ) {
            uint256 raffleId = raffleIds[i];
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status < RaffleStatus.Refundable) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];
            uint208 amountPaid = stats.amountPaid;

            if (stats.refunded || amountPaid == 0) {
                revert NothingToClaim();
            }

            if (i == 0) {
                feeTokenAddress = raffle.feeTokenAddress;
            } else if (feeTokenAddress != raffle.feeTokenAddress) {
                revert InvalidCurrency();
            }

            stats.refunded = true;
            refundAmount += amountPaid;

            emit EntryRefunded(raffleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
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
     * @param currency The currency to validate.
     */
    function _validateCurrency(address currency) private view {
        if (isCurrencyAllowed[currency] != 1) {
            revert InvalidCurrency();
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
     * @param raffle The raffle to validate.
     */
    function _validateRafflePostCutoffTimeStatusTransferability(Raffle storage raffle) private view {
        _validateRaffleStatus(raffle, RaffleStatus.Open);

        if (raffle.cutoffTime > block.timestamp) {
            revert CutoffTimeNotReached();
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

    /**
     * @param raffle The raffle to add the entry to.
     * @param currentEntryIndex The cumulative number of entries in the raffle minus one.
     * @param recipient The recipient of the entry.
     */
    function _pushEntry(
        Raffle storage raffle,
        uint40 currentEntryIndex,
        address recipient
    ) private {
        raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: recipient}));
    }

    /**
     * Unsafe math functions.
     */

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