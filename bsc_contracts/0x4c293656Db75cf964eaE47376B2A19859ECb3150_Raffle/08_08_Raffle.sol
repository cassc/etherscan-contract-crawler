// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IPrizeMatrix.sol";
import "./interfaces/IRaffleResults.sol";
import "./interfaces/ICoupons.sol";
import "./interfaces/IPrizeStorage.sol";
//import "hardhat/console.sol";

/* Errors */
    error Raffle__UpkeepNotNeeded();
    error Raffle__ChangeTransferFailed();
    error Raffle__TransferToWinnerFailed();
    error Raffle__TransferToSafeFailed();
    error Raffle__PartnerIdTooLong();
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__MaxTicketsLimit();
    error Raffle__RaffleNotOpen();
    error Raffle__OnlyOwnerAllowed();
    error Raffle__OnlyAtMaintenanceAllowed();
    error Raffle__MustUpdatePrizeMatrix();
    error Raffle__PrizeMatrixWrongBalance();
    error Raffle__PrizeMatrixDirectPrizesLimit();
    error Raffle__PrizeMatrixTotalPrizesLimit();
    error Raffle__PrizeMatrixIsEmpty();

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface, IRaffleResults, IPrizeMatrix {
    string private constant VERSION = "0.6.1";

    /* Type declarations */
    enum RaffleState {
        OPEN,
        DRAW_PENDING,    // pending the draw. Use this stage for data sync
        DRAW,            // CALCULATING a winner
        MAINTENANCE      // State to change contract settings, between DRAW and OPEN.
    }
    /* State variables */
    // ChainLink VRF constants
    struct ChainLinkConstants {
        address vrfCoordinatorAddress;
        uint16 requestConfirmations;
        bytes32 gasLane;
    }
    // ChainLink VRF parameters
    struct ChainLinkParams {
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    // Lottery parameters
    struct RaffleParams {
        uint256 entranceFee;
        uint256 prize;
        bool autoStart;
        uint8 prizePct;
        uint32 maxTickets;
        address payable safeAddress;
    }
    // Coupon manager constants
    ICoupons public couponManager;
    IPrizeStorage public prizeStorage;
    // ChainLink constants
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    address private immutable i_vrfCoordinatorAddress;
    uint16 private immutable i_requestConfirmations;
    bytes32 private immutable i_gasLane;
    // ChainLink parameters
    ChainLinkParams private s_chainLinkParams;
    // Lottery parameters
    RaffleParams private s_raffleParams;
    mapping(uint32 => IPrizeMatrix.PrizeLevel[]) private s_prizeMatrix;
    // Lottery variables
    address private s_owner;
    uint32 private s_raffleId;
    uint256 private s_targetBalance;
    mapping(uint32 => address payable []) private s_tickets;
    mapping(uint32 => mapping(address => uint32)) private s_nTickets;
    // raffleId => partnerIDs
    mapping(uint32 => string[]) private s_partnerIDs;
    // raffleId => partnerId => balance
    mapping(uint32 => mapping(string => uint256)) private s_partnerBalance;
    RaffleState private s_raffleState;
    // Lottery results
    mapping(uint32 => mapping(uint8 => uint32[])) private s_winnerIndexes;
    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(
        address indexed player,
        RaffleState raffleState,
        uint32 ticketsSold,
        uint32 bonusTickets,
        string partnerID
    );
    event WinnerPicked(uint256[] randomWords, uint256 ownerIncome, RaffleState raffleState);
    event CheckUpkeepCall(address indexed keeper, RaffleState raffleState, bool upkeepNeeded);
    event ChangeState(RaffleState raffleState);
    event ChangeRaffleParams(RaffleParams raffleParams);
    event CouponError(string reason);

    /* Functions */
    constructor(
        address couponManagerAddress,
        address prizeStorageAddress,
        ChainLinkConstants memory _chainLinkConstants,
        ChainLinkParams memory _chainLinkParams,
        RaffleParams memory _raffleParams
    ) VRFConsumerBaseV2(_chainLinkConstants.vrfCoordinatorAddress) {
        couponManager = ICoupons(couponManagerAddress);
        prizeStorage = IPrizeStorage(prizeStorageAddress);
        i_vrfCoordinator = VRFCoordinatorV2Interface(_chainLinkConstants.vrfCoordinatorAddress);
        i_vrfCoordinatorAddress = _chainLinkConstants.vrfCoordinatorAddress;
        i_requestConfirmations = _chainLinkConstants.requestConfirmations;
        i_gasLane = _chainLinkConstants.gasLane;
        s_chainLinkParams.subscriptionId = _chainLinkParams.subscriptionId;
        s_chainLinkParams.callbackGasLimit = _chainLinkParams.callbackGasLimit;
        _setRaffleParams(_raffleParams);
        s_owner = msg.sender;
        s_raffleId = 1;
        s_raffleState = RaffleState.MAINTENANCE;
        setTargetBalance();
        setPrizeMatrix(new IPrizeMatrix.PrizeLevel[](0));
    }

    function enterRaffle(string memory couponKey, string memory partnerID) public payable {
        if (bytes(partnerID).length > 256) {
            revert Raffle__PartnerIdTooLong();
        }
        if (msg.value < s_raffleParams.entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value > s_raffleParams.entranceFee * s_raffleParams.maxTickets) {
            revert Raffle__MaxTicketsLimit();
        }

        // The overbooking must be sent back to the player as change.
        uint256 overbooking = 0;
        if (address(this).balance >= s_targetBalance) {
            s_raffleState = RaffleState.DRAW_PENDING;
            overbooking = address(this).balance - s_targetBalance;
        }
        uint32 realTickets = uint32((msg.value - overbooking) / s_raffleParams.entranceFee);
        uint32 bonusTickets;

        // Update partner balance
        if (bytes(partnerID).length > 0) {
            if (s_partnerBalance[s_raffleId][partnerID] == 0) {
                s_partnerIDs[s_raffleId].push(partnerID);
            }
            s_partnerBalance[s_raffleId][partnerID] += msg.value - overbooking;
        }

        // Check coupons
        if (bytes(couponKey).length > 0) {
            try couponManager.useCoupon(keccak256(abi.encodePacked(couponKey)), msg.sender, s_raffleId)
            returns (ICoupons.Coupon memory coupon) {
                uint256 startBalancePct = uint16(100 * (address(this).balance - msg.value) / s_targetBalance);
                if (coupon.minPct <= startBalancePct && startBalancePct <= coupon.maxPct) {
                    bonusTickets += (realTickets * coupon.multiplierPct) / 100;
                }
            } catch Error(string memory reason) {
                emit CouponError(reason);
            }
        }

        for (uint ticketId = 0; ticketId < realTickets + bonusTickets; ticketId++) {
            s_tickets[s_raffleId].push(payable(msg.sender));
        }
        s_nTickets[s_raffleId][msg.sender] += (realTickets + bonusTickets);
        // Try to send change
        if (overbooking > 0) {
            (bool changeTxSuccess, ) = msg.sender.call{value: overbooking}("");
            if (!changeTxSuccess) {
                revert Raffle__ChangeTransferFailed();
            }
        }
        emit RaffleEnter(msg.sender, s_raffleState, realTickets, bonusTickets, partnerID);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     */
    function checkUpkeep(
        bytes calldata upkeepData
    )
    public
    override
    returns (
        bool upkeepNeeded,
        bytes memory _upkeepData
    )
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool isDrawPending = RaffleState.DRAW_PENDING == s_raffleState;
        bool hasPlayers = s_tickets[s_raffleId].length > 0;
        bool bankCollected = (s_targetBalance > 0 && address(this).balance >= s_targetBalance);
        upkeepNeeded = (hasPlayers && (isOpen || isDrawPending) && bankCollected);

        if (upkeepNeeded) {
            s_raffleState = RaffleState.DRAW_PENDING;
        }
        _upkeepData = upkeepData;
        emit CheckUpkeepCall(msg.sender, s_raffleState, upkeepNeeded);
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata upkeepData
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep(upkeepData);
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        s_raffleState = RaffleState.DRAW;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            s_chainLinkParams.subscriptionId,
            i_requestConfirmations,
            s_chainLinkParams.callbackGasLimit,
            getNumWords()
        );
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        uint unpaidPrize = s_raffleParams.prize;
        uint winnerId;
        uint nLevels = s_prizeMatrix[s_raffleId].length;
        uint32 raffleId = s_raffleId;

        IRaffleResults.RaffleResults memory raffleResults;
        raffleResults.raffleId = raffleId;
        raffleResults.timestamp = block.timestamp;
        raffleResults.winnersMatrix =
            new IRaffleResults.PrizeLevelWinners[](nLevels);

        for (uint levelId; levelId < nLevels; levelId++) {
            uint nPrizes = s_prizeMatrix[raffleId][levelId].nWinners;
            raffleResults.winnersMatrix[levelId].winners = new address payable [](nPrizes);

            for (uint prizeId; prizeId < nPrizes; prizeId++) {
                uint32 indexOfWinner = uint32(randomWords[winnerId] % s_tickets[raffleId].length);
                raffleResults.winnersMatrix[levelId].winners[prizeId] = s_tickets[raffleId][indexOfWinner];
                s_winnerIndexes[raffleId][uint8(levelId)].push(indexOfWinner);
                address payable winnerAddress = s_tickets[raffleId][indexOfWinner];
                uint prize = s_prizeMatrix[raffleId][levelId].prize;
                if (s_prizeMatrix[raffleId][levelId].directPayment) {
                    (bool winnerTxSuccess, ) = winnerAddress.call{value: prize}("");
                    if (winnerTxSuccess) {
                        unpaidPrize -= prize;
                    }
                }
                // console.log('fulfillRandomWords: processed=%s, gas=%s', winnerId, gasleft());
                winnerId++;
            }
        }
        prizeStorage.setPrizes{value: unpaidPrize}(raffleResults, s_prizeMatrix[s_raffleId]);

        uint256 fee = address(this).balance;
        (bool safeTxSuccess, ) = s_raffleParams.safeAddress.call{value: fee}("");
        if (safeTxSuccess) {
            // copy matrix to the new draw
            for (uint prizeLevel; prizeLevel < s_prizeMatrix[s_raffleId].length; prizeLevel++) {
                s_prizeMatrix[s_raffleId + 1].push(s_prizeMatrix[s_raffleId][prizeLevel]);
            }
            if (s_raffleParams.autoStart) {
                s_raffleState = RaffleState.OPEN;
            } else {
                s_raffleState = RaffleState.MAINTENANCE;
            }
        } else {
            s_raffleState = RaffleState.MAINTENANCE;
        }

        // Switch to a new lottery session
        s_raffleId += 1;

        emit WinnerPicked(randomWords, fee, s_raffleState);
//        console.log('fulfillRandomWords: total gas left=%s', gasleft());
    }

    /** Getter Functions */
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function getRaffleParams() public view returns (RaffleParams memory) {
        return s_raffleParams;
    }

    function getPrizeMatrix(uint32 raffleId) public override view returns (IPrizeMatrix.PrizeLevel[] memory) {
        return s_prizeMatrix[raffleId];
    }

    function getNumWords() public view returns (uint32) {
        uint32 numWords;
        for (uint i=0; i < s_prizeMatrix[s_raffleId].length; i++) {
            numWords += s_prizeMatrix[s_raffleId][i].nWinners;
        }
        return numWords;
    }

    function getChainLinkParams() public view returns (ChainLinkParams memory) {
        return s_chainLinkParams;
    }

    function getRaffleId() public view returns(uint32) {
        return s_raffleId;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumberOfTicketsByRaffleId(uint32 raffleId) public view returns (uint256) {
        return s_tickets[raffleId].length;
    }

    function getNumberOfPlayerTickets(address playerAddress) public view returns(uint32) {
        return s_nTickets[s_raffleId][playerAddress];
    }
    function getNumberOfPlayerTicketsByRaffleId(address playerAddress, uint32 raffleId) public view returns(uint32) {
        return s_nTickets[raffleId][playerAddress];
    }

    function getPlayerByTicketIdByRaffleId(uint256 ticketIndex, uint32 raffleId) public view returns (address) {
        return s_tickets[raffleId][ticketIndex];
    }

    function getTargetBalance() public view returns (uint256) {
        return s_targetBalance;
    }

    function getBalancePct() public view returns (uint16) {
        return uint16(100 * address(this).balance / s_targetBalance);
    }

    function getPartnerIDs(uint32 raffleId) public view returns (string[] memory) {
        return s_partnerIDs[raffleId];
    }

    function getPartnerBalance(uint32 raffleId, string memory partnerID) public view returns (uint256) {
        if (bytes(partnerID).length > 256) {
            revert Raffle__PartnerIdTooLong();
        }
        return s_partnerBalance[raffleId][partnerID];
    }

    function getRaffleResults(uint32 raffleId) public override view returns (IRaffleResults.RaffleResults memory) {
        IRaffleResults.RaffleResults memory raffleResults;
        raffleResults.raffleId = raffleId;
        raffleResults.timestamp = prizeStorage.getRaffleDrawTimestamp(address(this), raffleId);
        raffleResults.winnersMatrix =
            new IRaffleResults.PrizeLevelWinners[](s_prizeMatrix[raffleId].length);
        for (uint levelId; levelId < s_prizeMatrix[raffleId].length; levelId++) {
            uint nPrizes = s_prizeMatrix[raffleId][levelId].nWinners;
            raffleResults.winnersMatrix[levelId].winners = new address payable [](nPrizes);
            for (uint prizeId; prizeId < nPrizes; prizeId++) {
                uint32 indexOfWinner = s_winnerIndexes[raffleId][uint8(levelId)][prizeId];
                raffleResults.winnersMatrix[levelId].winners[prizeId] = s_tickets[raffleId][indexOfWinner];
            }
        }
        return raffleResults;
    }


    /** Setter Functions **/
    function setTargetBalance() private {
        uint bank = (s_raffleParams.prize / s_raffleParams.prizePct) * 100;
        if (bank % s_raffleParams.entranceFee > 0) {
            s_targetBalance = (bank / s_raffleParams.entranceFee + 1) * s_raffleParams.entranceFee;
        } else {
            s_targetBalance = bank;
        }
    }

    function setSubscriptionId(uint32 subscriptionId) public onlyOwner {
        s_chainLinkParams.subscriptionId = subscriptionId;
    }

    function setCallbackGasLimit(uint32 gasLimit) public onlyOwner {
        s_chainLinkParams.callbackGasLimit = gasLimit;
    }

    function setAutoStart(bool isEnabled) public onlyOwner {
        s_raffleParams.autoStart = isEnabled;
    }

    function setRaffleParams(RaffleParams memory raffleParams) public onlyOwner atMaintenance {
        _setRaffleParams(raffleParams);
        emit ChangeRaffleParams(raffleParams);
    }

    function _setRaffleParams(RaffleParams memory raffleParams) private {
        s_raffleParams.entranceFee = raffleParams.entranceFee;
        s_raffleParams.prize = raffleParams.prize;
        s_raffleParams.autoStart = raffleParams.autoStart;
        s_raffleParams.prizePct = raffleParams.prizePct;
        s_raffleParams.maxTickets = raffleParams.maxTickets;
        s_raffleParams.safeAddress = raffleParams.safeAddress;
        setTargetBalance();
    }

    function setPrizeMatrix(IPrizeMatrix.PrizeLevel[] memory prizeMatrix) public onlyOwner atMaintenance {
        _checkCurrentPrizeMatrix(prizeMatrix);
        if (prizeMatrix.length == 0) {
            delete s_prizeMatrix[s_raffleId];
            s_prizeMatrix[s_raffleId].push(IPrizeMatrix.PrizeLevel(1, s_raffleParams.prize, true));
        } else {
            delete s_prizeMatrix[s_raffleId];
            for (uint levelId=0; levelId < prizeMatrix.length; levelId++) {
                s_prizeMatrix[s_raffleId].push(prizeMatrix[levelId]);
            }
        }
    }

    function _checkCurrentPrizeMatrix(IPrizeMatrix.PrizeLevel[] memory prizeMatrix) internal view {
        if (s_raffleId > 0 && prizeMatrix.length > 0) {
            uint directPrizesNumber;
            uint prizesTotalNumber;
            uint matrixBalance;
            for (uint levelId=0; levelId < prizeMatrix.length; levelId++) {
                matrixBalance += prizeMatrix[levelId].nWinners * prizeMatrix[levelId].prize;
                if (prizeMatrix[levelId].directPayment) {
                    directPrizesNumber += prizeMatrix[levelId].nWinners;
                }
                prizesTotalNumber += prizeMatrix[levelId].nWinners;
            }
            if (matrixBalance != s_raffleParams.prize) {
                revert Raffle__PrizeMatrixWrongBalance();
            }
            // TODO Make dynamic limits that depend on gas limit
//            if (directPrizesNumber > 10) {   // limit for 1.5M callback gas limit
//                revert Raffle__PrizeMatrixDirectPrizesLimit();
//            }
//            if (prizesTotalNumber > 60) {    // limit for 1.5M callback gas limit
//                revert Raffle__PrizeMatrixTotalPrizesLimit();
//            }
        }
    }

    function setRaffleMaintenance() public onlyOwner {
        s_raffleState = RaffleState.MAINTENANCE;
        emit ChangeState(s_raffleState);
    }

    function setRaffleOpen() public onlyOwner atMaintenance {
        _checkCurrentPrizeMatrix(s_prizeMatrix[s_raffleId]);
        s_raffleState = RaffleState.OPEN;
        emit ChangeState(s_raffleState);
    }

    receive() external payable atMaintenance {
        // Set start bonus balance
    }

    function rawFulfillRandomWinner(uint32 indexOfWinner) public onlyOwner atMaintenance {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(indexOfWinner);
        fulfillRandomWords(0, randomWords);
    }

    function setCouponManager(address couponManagerAddress) public onlyOwner atMaintenance {
        couponManager = ICoupons(couponManagerAddress);
    }

    function setPrizeStorage(address prizeStorageAddress) public onlyOwner atMaintenance {
        prizeStorage = IPrizeStorage(prizeStorageAddress);
    }

    function changeOwner(address owner) public onlyOwner {
        s_owner = owner;
    }

    /** Modifiers **/
    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Raffle__OnlyOwnerAllowed();
        }
        _;
    }

    modifier atMaintenance() {
        if (s_raffleState != RaffleState.MAINTENANCE) {
            revert Raffle__OnlyAtMaintenanceAllowed();
        }
        _;
    }
}