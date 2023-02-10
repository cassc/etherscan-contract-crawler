// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./interfaces/IQueueEntry.sol";
import "./interfaces/celer/IBridgeMinMaxSend.sol";
import "./lib/Serializer.sol";
import "./lib/Tools.sol";
import "./interfaces/ISwapHelper.sol";

import "./Locking.sol";
import "./IMCeler.sol";
import "./ExtranetToken.sol";

contract ExtranetService is IMCeler {
    using SafeERC20 for IERC20;

    struct Settings {
        uint256 investMinAmount;
        uint256 investMaxAmount;
        uint256 investQueueMinAmount;
        uint256 withdrawMinAmount;
        uint256 withdrawMaxAmount;

        address swapHelper;
        address locking;

        uint256 minLockedPower;
        uint256 minLockedPowerPerQuoteTokenAmount;
    }

    Settings public settings;

    // allowedQuoteToken must be outside of Settings because some libraries refuse to return array within structs.
    // so in order to maintain logical consistency quoteToken is also a public property.
    address public quoteToken;
    address[] private allowedQuoteToken;

    uint8 constant private INVEST_PAUSED        = 1 << 0;
    uint8 constant private INVEST_TOSS_PAUSED   = 1 << 1;
    uint8 constant private WITHDRAW_PAUSED      = 1 << 2;
    uint8 constant private WITHDRAW_TOSS_PAUSED = 1 << 3;

    uint8 constant private MAX_QUEUE_LENGTH = 10;

    address public immutable extranetToken;

    QueueEntry[] public investQueue;
    QueueEntry[] public withdrawQueue;

    uint256 private roundtripNonce = 1;

    bytes32 public withdrawRoundtripId;
    bytes32 public investRoundtripId;

    uint8 public pauses = INVEST_PAUSED | INVEST_TOSS_PAUSED | WITHDRAW_PAUSED | WITHDRAW_TOSS_PAUSED;

    event InvestQueued(bytes32 roundtripId, address sender, uint256 amount);
    event InvestSent(bytes32 roundtripId, uint256 amount);
    event InvestFinished(bytes32 roundtripId);

    event WithdrawQueued(bytes32 roundtripId, address sender, uint256 amount);
    event WithdrawSent(bytes32 roundtripId, uint256 amount);
    event WithdrawFinished(bytes32 roundtripId);

    event RewardReceived(bytes32 roundtripId, uint256 amount);

    constructor(
        Settings memory _settings,
        address _quoteToken,
        address[] memory _allowedQuoteToken,
        address _extranetToken,
        address _messageBus,
        address _homenetServiceAddress,
        uint64 _homenetChainId
    )
        IMCeler(_messageBus)
    {
        settings = _settings;
        extranetToken = _extranetToken;
        quoteToken = _quoteToken;
        allowedQuoteToken = _allowedQuoteToken;

        generateInvestRoundtripId();
        generateWithdrawRoundtripId();

        peerAddress = _homenetServiceAddress;
        peerChainId = _homenetChainId;
    }

    modifier onlyAllowedQuoteToken(address token) {
        for (uint i=0; i<allowedQuoteToken.length; i++) {
            if (token == allowedQuoteToken[i]) {
                _;
                return;
            }
        }

        revert("QUOTE_TOKEN");
    }

    modifier whenNotPaused(uint8 whatExactly) {
        require((pauses & whatExactly) != whatExactly, "PAUSED");
        _;
    }

    function getAllowedQuoteToken()
        public
        view
        returns (address[] memory)
    {
        return allowedQuoteToken;
    }

    function getQueueLengths()
        public
        view
        returns (
            uint256 investQueueLength,
            uint256 withdrawQueueLength,
            uint256 incomingMessageQueueLength
        )
    {
        investQueueLength = investQueue.length;
        withdrawQueueLength = withdrawQueue.length;
        incomingMessageQueueLength = incomingMessageQueue.length;
    }

    function invest(uint256 amount, address token)
        public
        whenNotPaused(INVEST_PAUSED)
        onlyAllowedQuoteToken(token)
    {
        IERC20(token).safeTransferFrom(msg.sender, settings.swapHelper, amount);

        uint256 quoteTokenAmount = ISwapHelper(settings.swapHelper).swap(token, quoteToken, address(this));

        require(investQueue.length < MAX_QUEUE_LENGTH, "QUEUE");
        require(quoteTokenAmount >= settings.investMinAmount && quoteTokenAmount > 0, "MIN_AMOUNT");
        require(settings.investMaxAmount == 0 || quoteTokenAmount <= settings.investMaxAmount, "MAX_AMOUNT");

        (uint256 minSend, uint256 maxSend) = getBridgeMinMaxSend(quoteToken);

        require(quoteTokenAmount > minSend, "MIN_SEND"); // celer bug, should be >= but they have >
        require(maxSend == 0 || quoteTokenAmount <= maxSend, "MAX_SEND");

        checkIfHasMinLockedPower(quoteTokenAmount);

        investQueue.push(QueueEntry({
            account: msg.sender,
            amount: quoteTokenAmount
        }));

        emit InvestQueued(investRoundtripId, msg.sender, quoteTokenAmount);
    }

    function withdraw(uint256 amount)
        public
        whenNotPaused(WITHDRAW_PAUSED)
    {
        require(withdrawQueue.length < MAX_QUEUE_LENGTH, "QUEUE");
        require(amount > 0 && amount >= settings.withdrawMinAmount, "MIN_AMOUNT");
        require(settings.withdrawMaxAmount == 0 || amount <= settings.withdrawMaxAmount, "MAX_AMOUNT");

        ExtranetToken(extranetToken).burnFrom(msg.sender, amount);

        withdrawQueue.push(QueueEntry({
            account: msg.sender,
            amount: amount
        }));

        emit WithdrawQueued(withdrawRoundtripId, msg.sender, amount);
    }

    function tossInvestQueue()
        public
        payable
        whenNotPaused(INVEST_TOSS_PAUSED)
    {
        require(investQueue.length > 0, "EMPTY");

        uint256 investQueueTotalAmount = Tools.sumAmountFromQueue(investQueue);
        require(investQueueTotalAmount >= settings.investQueueMinAmount, "MIN_AMOUNT");

        (uint256 minSend, uint256 maxSend) = getBridgeMinMaxSend(quoteToken);

        require(investQueueTotalAmount >= minSend, "MIN_SEND");
        require(maxSend == 0 || investQueueTotalAmount <= maxSend, "MAX_SEND");

        bytes memory message = Serializer.createInvestMessage(investRoundtripId, investQueue);
        uint256 fee = sendMessageWithTransfer(quoteToken, investQueueTotalAmount, message);

        emit InvestSent(investRoundtripId, investQueueTotalAmount);

        delete investQueue;

        generateInvestRoundtripId();

        if (fee < msg.value) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }

    function clearInvestQueue()
        public
        onlyOwner
    {
        delete investQueue;
    }

    function tossWithdrawQueue()
        public
        payable
        whenNotPaused(WITHDRAW_TOSS_PAUSED)
    {
        require(withdrawQueue.length > 0, "EMPTY");

        bytes memory message = Serializer.createWithdrawMessage(withdrawRoundtripId, withdrawQueue);

        uint256 fee = sendMessage(message);

        uint256 withdrawQueueTotalAmount = Tools.sumAmountFromQueue(withdrawQueue);
        emit WithdrawSent(withdrawRoundtripId, withdrawQueueTotalAmount);

        delete withdrawQueue;

        generateWithdrawRoundtripId();

        if (fee < msg.value) {
            payable(msg.sender).transfer(msg.value - fee);
        }
    }

    function clearWithdrawQueue()
        public
        onlyOwner
    {
        delete withdrawQueue;
    }

    function onMessage(bytes memory message)
        override
        internal
    {
        (, uint8 messageKind) = abi.decode(message, (bytes32, uint8));

        if (messageKind == MESSAGE_KIND_ROUNDTRIP) {
            onMessageRoundtrip(message);

        } else if (messageKind == MESSAGE_KIND_REWARD) {
            onMessageReward(message);

        } else {
            revert("MESSAGE_KIND");
        }
    }

    function onMessageReward(bytes memory message)
        internal
    {
        (bytes32 rewardMessageId, , uint256 rewardAmount) = abi.decode(message, (bytes32, uint8, uint256));

        ExtranetToken(extranetToken).onReward(rewardAmount);

        emit RewardReceived(rewardMessageId, rewardAmount);
    }

    function onMessageRoundtrip(bytes memory message)
        internal
    {
        (bytes32 incomingRoundtripId, , QueueEntry[] memory queue) = abi.decode(message, (bytes32, uint8, QueueEntry[]));

        for (uint i=0; i<queue.length; i++) {
            QueueEntry memory entry = queue[i];
            ExtranetToken(extranetToken).mintTo(entry.account, entry.amount);
        }

        emit InvestFinished(incomingRoundtripId);
    }

    function onMessageWithTransfer(bytes memory message, address token, uint256 amount)
        override
        internal
    {
        require(token == quoteToken, "QUOTE");

        (, uint8 messageKind) = abi.decode(message, (bytes32, uint8));
        require(messageKind == MESSAGE_KIND_ROUNDTRIP, "MESSAGE_KIND");

        (bytes32 incomingRoundtripId, , uint256 quoteTokenAmount, QueueEntry[] memory incomingQueue) = abi.decode(message, (bytes32, uint8, uint256, QueueEntry[]));

        for (uint256 i=0; i<incomingQueue.length; i++) {
            QueueEntry memory entry = incomingQueue[i];
            IERC20(quoteToken).safeTransfer(entry.account, entry.amount * amount / quoteTokenAmount);
        }

        emit WithdrawFinished(incomingRoundtripId);
    }

    function setQuoteToken(address _quoteToken, address[] calldata _allowedQuoteToken)
        public
        onlyOwner
    {
        quoteToken = _quoteToken;
        allowedQuoteToken = _allowedQuoteToken;
        emit ConfigurationUpdated();
    }

    function setSettings(Settings calldata _settings)
        public
        onlyOwner
    {
        settings = _settings;
        emit ConfigurationUpdated();
    }

    function setPauses(uint8 _pauses)
        public
        onlyOwner
    {
        pauses = _pauses;

        emit ConfigurationUpdated();
    }

    function shutdown()
        public
        onlyOwner
    {
        selfdestruct(payable(msg.sender));
    }

    function generateInvestRoundtripId()
        internal
    {
        investRoundtripId = keccak256(abi.encode(1, block.timestamp, block.number, address(this), block.chainid, roundtripNonce));
        roundtripNonce++;
    }

    function generateWithdrawRoundtripId()
        internal
    {
        withdrawRoundtripId = keccak256(abi.encode(2, block.timestamp, block.number, address(this), block.chainid, roundtripNonce));
        roundtripNonce++;
    }

    function checkIfHasMinLockedPower(uint256 quoteTokenAmount)
        internal
        view
    {
        if (settings.locking == address(0) || settings.minLockedPower == 0) {
            return;
        }

        uint256 requiredPower = settings.minLockedPower * quoteTokenAmount / settings.minLockedPowerPerQuoteTokenAmount * 99 / 100; // allow for some slack for stableSwap

        require(Locking(settings.locking).powerBy(msg.sender) >= requiredPower, "MIN_LOCKED");
    }

    function getBridgeMinMaxSend(address token)
        internal
        view
        returns (uint256 minSend, uint256 maxSend)
    {
        IBridgeMinMaxSend bridge = IBridgeMinMaxSend(IMessageBus(messageBus).liquidityBridge());

        minSend = bridge.minSend(token) + 1; // celer Bridge.sol bug: they use > instead of >=
        maxSend = bridge.maxSend(token);
    }
}