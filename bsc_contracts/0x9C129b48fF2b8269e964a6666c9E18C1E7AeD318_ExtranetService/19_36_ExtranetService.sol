// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

import "./interfaces/IQueueEntry.sol";
// import "./interfaces/celer/IBridgeMinMaxSend.sol";
import "./lib/Tools.sol";
import "./interfaces/ISwapHelper.sol";

import "./Locking.sol";
import "./IMCeler.sol";
import "./ExtranetToken.sol";

contract ExtranetService is IMCeler {
    using SafeERC20Upgradeable for IERC20Upgradeable;

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
    address[] private allowedQuoteToken;

    uint8 constant private INVEST_PAUSED        = 1 << 0;
    uint8 constant private INVEST_TOSS_PAUSED   = 1 << 1;
    uint8 constant private WITHDRAW_PAUSED      = 1 << 2;
    uint8 constant private WITHDRAW_TOSS_PAUSED = 1 << 3;

    uint8 constant private MAX_PAUSED = INVEST_PAUSED | INVEST_TOSS_PAUSED | WITHDRAW_PAUSED | WITHDRAW_TOSS_PAUSED;

    uint8 constant private MAX_QUEUE_LENGTH = 10;

    address public extranetToken;

    QueueEntry[] public investQueue;
    QueueEntry[] public withdrawQueue;

    uint256 private roundtripNonce = 1;

    bytes32 public withdrawRoundtripId;
    bytes32 public investRoundtripId;

    uint8 public pauses = MAX_PAUSED;

    event InvestQueued(bytes32 roundtripId, address sender, uint256 amount);
    event InvestSent(bytes32 roundtripId, uint256 amount);
    event InvestFinished(bytes32 roundtripId);

    event WithdrawQueued(bytes32 roundtripId, address sender, uint256 amount);
    event WithdrawSent(bytes32 roundtripId, uint256 amount);
    event WithdrawFinished(bytes32 roundtripId);

    event RewardReceived(bytes32 roundtripId, uint256 amount);

    function initialize(
        address _messageBus,
        address _quoteToken,
        address _peerAddress,
        uint64 _peerChainId,
        address[] memory _allowedQuoteToken,
        address _extranetToken,
        Settings memory _settings
    )
        public
        initializer
    {
        __IMCeler_initialize(_messageBus, _quoteToken, _peerAddress, _peerChainId);

        settings = _settings;
        extranetToken = _extranetToken;
        allowedQuoteToken = _allowedQuoteToken;

        investRoundtripId = generateRoundtripId(MESSAGE_KIND_INVEST);
        withdrawRoundtripId = generateRoundtripId(MESSAGE_KIND_WITHDRAW);
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
        require(investQueue.length < MAX_QUEUE_LENGTH, "QUEUE");

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, settings.swapHelper, amount);
        uint256 quoteTokenAmount = ISwapHelper(settings.swapHelper).swap(token, quoteToken, address(this));

        require(quoteTokenAmount >= settings.investMinAmount && quoteTokenAmount > 0, "MIN_AMOUNT");
        require(settings.investMaxAmount == 0 || quoteTokenAmount <= settings.investMaxAmount, "MAX_AMOUNT");

        // (uint256 minSend, uint256 maxSend) = getBridgeMinMaxSend(quoteToken);

        // require(quoteTokenAmount > minSend, "MIN_SEND"); // celer bug, should be >= but they have >
        // require(maxSend == 0 || quoteTokenAmount <= maxSend, "MAX_SEND");

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

        // (uint256 minSend, uint256 maxSend) = getBridgeMinMaxSend(quoteToken);

        // require(investQueueTotalAmount >= minSend, "MIN_SEND");
        // require(maxSend == 0 || investQueueTotalAmount <= maxSend, "MAX_SEND");

        bytes memory message = Serializer.createQueueMessage(investRoundtripId, 0, investQueue);
        uint256 fee = sendMessageWithTransfer(investQueueTotalAmount, message);

        emit InvestSent(investRoundtripId, investQueueTotalAmount); // FIXME remove this event?

        delete investQueue;

        investRoundtripId = generateRoundtripId(MESSAGE_KIND_INVEST);

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

        bytes memory message = Serializer.createQueueMessage(withdrawRoundtripId, 0, withdrawQueue);

        uint256 fee = sendMessage(message);

        uint256 withdrawQueueTotalAmount = Tools.sumAmountFromQueue(withdrawQueue);
        emit WithdrawSent(withdrawRoundtripId, withdrawQueueTotalAmount);

        delete withdrawQueue;

        withdrawRoundtripId = generateRoundtripId(MESSAGE_KIND_WITHDRAW);

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
        uint8 messageKind = Serializer.getMessageKindFromMessage(message);

        if (messageKind == MESSAGE_KIND_REWARD) {
            onMessageReward(message);

        } else if (messageKind == MESSAGE_KIND_INVEST || messageKind == MESSAGE_KIND_WITHDRAW) {
            onMessageRoundtrip(message);

        } else {
            revert("MESSAGE_KIND");
        }
    }

    function onMessageReward(bytes memory message)
        internal
    {
        (bytes32 rewardMessageId, uint256 rewardAmount) = Serializer.parseRewardMessage(message);

        ExtranetToken(extranetToken).onReward(rewardAmount);

        emit RewardReceived(rewardMessageId, rewardAmount);
    }

    function onMessageRoundtrip(bytes memory message)
        internal
    {
        (bytes32 incomingRoundtripId, , QueueEntry[] memory queue) = Serializer.parseQueueMessage(message);

        for (uint i=0; i<queue.length; i++) {
            QueueEntry memory entry = queue[i];
            ExtranetToken(extranetToken).mintTo(entry.account, entry.amount);
        }

        emit InvestFinished(incomingRoundtripId);
    }

    function onMessageWithTransfer(bytes memory message, uint256 amount)
        override
        internal
    {
        (bytes32 incomingRoundtripId, uint256 quoteTokenAmount, QueueEntry[] memory incomingQueue) = Serializer.parseQueueMessage(message);

        for (uint256 i=0; i<incomingQueue.length; i++) {
            QueueEntry memory entry = incomingQueue[i];
            IERC20Upgradeable(quoteToken).safeTransfer(entry.account, entry.amount * amount / quoteTokenAmount);
        }

        emit WithdrawFinished(incomingRoundtripId);
    }

    function setAllowedQuoteToken(address[] calldata _allowedQuoteToken)
        public
        onlyOwner
    {
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
        require(pauses == MAX_PAUSED, "PAUSE");
        require(investQueue.length == 0, "QUEUE");
        require(withdrawQueue.length == 0, "QUEUE");

        _shutdown();

        pauses = MAX_PAUSED;

        delete settings;
        delete allowedQuoteToken;
        delete investQueue;
        delete withdrawQueue;
    }

    function generateRoundtripId(uint8 kind)
        internal
        returns (bytes32)
    {
        bytes memory roundtripId = abi.encode(keccak256(abi.encode(kind, block.timestamp, block.number, address(this), block.chainid, roundtripNonce++)));
        roundtripId[0] = bytes1(kind);
        return bytes32(roundtripId);
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

    // function getBridgeMinMaxSend(address token)
    //     internal
    //     view
    //     returns (uint256 minSend, uint256 maxSend)
    // {
    //     IBridgeMinMaxSend bridge = IBridgeMinMaxSend(IMessageBus(messageBus).liquidityBridge());

    //     minSend = bridge.minSend(token) + 1; // celer Bridge.sol bug: they use > instead of >=
    //     maxSend = bridge.maxSend(token);
    // }
}