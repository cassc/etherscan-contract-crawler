// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

import "./Events.sol";
import "./Helpers.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract LotteryETH is Helpers, Events, VRFConsumerBaseV2 {

    ILinkToken immutable LINK;
    IVRFCoordinatorV2 immutable COORDINATOR;

    modifier onlyMaster() {
        require(
            msg.sender == master,
            "LotteryETH: NOT_MASTER"
        );
        _;
    }

    modifier onlyPurchasePhase(
        uint256 _lotteryIndex
    ) {
        require(
            getStatus(_lotteryIndex) == Status.PURCHASING,
            "LotteryETH: NOT_PURCHASING_PHASE"
        );
        _;
    }

    modifier onlyOraclePhase(
        uint256 _lotteryIndex
    ) {
        if (readyForOracle(_lotteryIndex) == false) {
            revert("LotteryETH: NOT_READY_YET");
        }

        if (getStatus(_lotteryIndex) == Status.FINALIZED) {
            revert("LotteryETH: ALREADY_FINALIZED");
        }

        if (_getRetry(_lotteryIndex) == false) {
            revert("LotteryETH: INVALID_RETRY");
        }
        _;
    }

    modifier onlyFinalizedPhase(
        uint256 _lotteryIndex
    ) {
        require(
            getStatus(_lotteryIndex) == Status.FINALIZED,
            "LotteryETH: LOTTERY_NOT_FINALIZED"
        );
        _;
    }

    constructor(
        address _coordinatorAddress
    )
        VRFConsumerBaseV2(
            _coordinatorAddress
        )
    {
        master = msg.sender;
        usageFee = 5;

        COORDINATOR = IVRFCoordinatorV2(
            _coordinatorAddress
        );

        LINK = ILinkToken(
            LINK_TOKEN_ADDRESS
        );

        subscriptionId = COORDINATOR.createSubscription();

        COORDINATOR.addConsumer(
            subscriptionId,
            address(this)
        );
    }

    function createLottery(
        address _nftAddress,
        uint256 _nftId,
        address _sellToken,
        uint256 _totalPrice,
        uint256 _ticketCount,
        uint256 _lotteryTime
    )
        external
    {
        _createLottery(
            msg.sender,
            _nftAddress,
            _nftId,
            _sellToken,
            _totalPrice,
            _ticketCount,
            _lotteryTime
        );

        _transferNFT(
            msg.sender,
            address(this),
            _nftAddress,
            _nftId
        );

        emit LotteryCreated(
            msg.sender,
            lotteryCount,
            _nftAddress,
            _nftId,
            _sellToken,
            _totalPrice,
            _ticketCount,
            _lotteryTime
        );

        _increaseLotteryCount();
    }

    function buyTickets(
        uint256 _lotteryIndex,
        uint256 _ticketCount
    )
        external
        payable
        onlyPurchasePhase(
            _lotteryIndex
        )
    {
        _enoughTickets(
            _lotteryIndex,
            _ticketCount
        );

        (
            uint256 startNumber,
            uint256 finalNumber

        ) = _performTicketBuy(
            _lotteryIndex,
            _ticketCount,
            msg.sender,
            msg.value
        );

        emit BuyTickets(
            _lotteryIndex,
            startNumber,
            finalNumber,
            msg.sender
        );
    }

    function giftTickets(
        uint256 _lotteryIndex,
        uint256 _ticketCount,
        address _recipient
    )
        external
        payable
        onlyPurchasePhase(
            _lotteryIndex
        )
    {
        _enoughTickets(
            _lotteryIndex,
            _ticketCount
        );

        (
            uint256 startNumber,
            uint256 finalNumber

        ) = _performTicketBuy(
            _lotteryIndex,
            _ticketCount,
            _recipient,
            msg.value
        );

        emit GiftTickets(
            _lotteryIndex,
            startNumber,
            finalNumber,
            msg.sender,
            _recipient
        );
    }

    function _performTicketBuy(
        uint256 _lotteryIndex,
        uint256 _ticketCount,
        address _recipient,
        uint256 _payment
    )
        internal
        returns (
            uint256 startNumber,
            uint256 finalNumber
        )
    {
        TicketData storage data = ticketData[
            _lotteryIndex
        ];

        require(
            _payment == data.ticketPrice * _ticketCount,
            "LotteryETH: INVALID_PAYMENT_AMOUNT"
        );

        startNumber = data.soldTickets;
        finalNumber = startNumber + _ticketCount;

        for (uint256 i = startNumber; i < finalNumber; ++i) {
            tickets[_lotteryIndex][i] = _recipient;
        }

        data.soldTickets =
        data.soldTickets + _ticketCount;
    }

    function claimLottery(
        uint256 _lotteryIndex
    )
        external
    {
        BaseData memory baseData = baseData[
            _lotteryIndex
        ];

        require(
            msg.sender == baseData.winner,
            "LotteryETH: INVALID_CALLER"
        );

        _transferNFT(
            address(this),
            baseData.winner,
            baseData.nftAddress,
            baseData.nftId
        );
    }

    function rescueLottery(
        uint256 _lotteryIndex
    )
        external
    {
        BaseData memory baseData = baseData[
            _lotteryIndex
        ];

        if (block.timestamp < baseData.closingTime + DEADLINE_REDEEM) {
            revert("LotteryETH: STILL_CLAIMABLE");
        }

        _transferNFT(
            address(this),
            master,
            baseData.nftAddress,
            baseData.nftId
        );
    }

    function concludeLottery(
        uint256 _lotteryIndex
    )
        external
        onlyFinalizedPhase(
            _lotteryIndex
        )
    {
        BaseData memory baseDataRound = baseData[
            _lotteryIndex
        ];

        (
            address winner,
            uint256 luckyNumber,
            uint256 soldAmount

        ) = _getLuckyNumber(
            _lotteryIndex
        );

        address winnerAddress = winner == ZERO_ADDRESS
            ? baseDataRound.owner
            : winner;

        uint256 fee = applyUsageFee(
            usageFee,
            soldAmount
        );

        _closeRound(
            _lotteryIndex,
            luckyNumber,
            winnerAddress
        );

        payable(baseDataRound.owner).transfer(
            soldAmount - fee
        );

        payable(master).transfer(
            fee
        );

        emit ConcludeRound(
            baseDataRound.nftAddress,
            winnerAddress,
            baseDataRound.nftId,
            luckyNumber,
            _lotteryIndex
        );
    }

    function requestRandomNumber(
        uint256 _lotteryIndex
    )
        external
        onlyOraclePhase(
            _lotteryIndex
        )
    {
        uint256 requestId = COORDINATOR.requestRandomWords(
            KEY_HASH,
            subscriptionId,
            CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            1
        );

        _setRequested(
            _lotteryIndex
        );

        requestIdToIndex[requestId] = _lotteryIndex;

        emit RequestRandomNumberForRound(
            _lotteryIndex,
            requestId,
            true
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    )
        internal
        override
    {
        uint256 lotteryIndex = requestIdToIndex[
            _requestId
        ];

        ticketData[lotteryIndex].luckyNumber = uniform(
            _randomWords[0],
            ticketData[lotteryIndex].totalTickets
        );

        _setFinalized(
            lotteryIndex
        );

        emit RandomWordsFulfilled(
            lotteryIndex,
            ticketData[lotteryIndex].luckyNumber
        );
    }

    function loadSubscription(
        uint256 _amount
    )
        external
    {
        _safeTransferFrom(
            LINK_TOKEN_ADDRESS,
            msg.sender,
            address(this),
            _amount
        );

        LINK.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(subscriptionId)
        );
    }

    function changeUsageFee(
        uint256 _amount
    )
        external
        onlyMaster
    {
        if (_amount > MAX_FEE_PERCENTAGE) {
            revert("LotteryETH: FEE_TOO_HIGH");
        }

        usageFee = _amount;
    }
}