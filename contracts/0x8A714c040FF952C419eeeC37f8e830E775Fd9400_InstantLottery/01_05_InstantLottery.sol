// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Ownable.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";

contract InstantLottery is VRFConsumerBaseV2, Ownable {
    event BetPlaced(uint256 requestId, BetData betData);
    event BetSettled(uint256 requestId, BetData betData);

    uint256 public fee;
    uint256 public minWinChance;
    uint256 public maxWinChance;
    uint256 public maxWin;
    uint256 public minBet;

    uint8 public constant chanceDecimals = 4;

    constructor(
        uint256 _fee,
        uint256 _minWinChance,
        uint256 _maxWinChance,
        uint256 _maxWin,
        uint256 _minBet,
        uint64 _subscriptionId,
        address _coordinatorAddress,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinatorAddress) {
        require(_fee > 0 && _fee < 1000, "Fee must be between 0 and 1000");
        require(
            _minWinChance > 50 && _minWinChance < 950,
            "Min win chance must be between 50 and 950"
        );
        require(
            _maxWinChance > 50 && _maxWinChance < 950,
            "Max win chance must be between 50 and 950"
        );
        require(
            _minWinChance < _maxWinChance,
            "Min win chance must be less than max win chance"
        );

        fee = _fee;
        minWinChance = _minWinChance;
        maxWinChance = _maxWinChance;
        maxWin = _maxWin;
        minBet = _minBet;

        subscriptionId = _subscriptionId;
        coordinator = VRFCoordinatorV2Interface(_coordinatorAddress);
        keyHash = _keyHash;
    }

    function calcBetMultiplier(uint256 _winChance)
        public
        view
        returns (uint256)
    {
        require(
            _winChance >= minWinChance && _winChance <= maxWinChance,
            "Win chance must be between min and max win chance"
        );

        return 1000000 / (_winChance + (_winChance * fee) / 1000);
    }

    function calcMaxBet(uint256 _winChance) public view returns (uint256) {
        require(
            _winChance >= minWinChance && _winChance <= maxWinChance,
            "Win chance must be between min and max win chance"
        );

        uint256 betMultipler = calcBetMultiplier(_winChance);

        return (maxWin * 1000) / betMultipler;
    }

    function addFunds() public payable onlyOwner {
        require(msg.value > 0, "You must send some ether");
    }

    function withdrawFunds(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Not enough funds");

        payable(msg.sender).transfer(_amount);
    }

    function updateBetData(
        uint256 _fee,
        uint256 _minWinChance,
        uint256 _maxWinChance,
        uint256 _maxWin,
        uint256 _minBet
    ) public onlyOwner {
        require(_fee > 0 && _fee < 1000, "Fee must be between 0 and 1000");
        require(
            _minWinChance > 50 && _minWinChance < 950,
            "Min win chance must be between 50 and 950"
        );
        require(
            _maxWinChance > 50 && _maxWinChance < 950,
            "Max win chance must be between 50 and 950"
        );
        require(
            _minWinChance < _maxWinChance,
            "Min win chance must be less than max win chance"
        );
        fee = _fee;
        minWinChance = _minWinChance;
        maxWinChance = _maxWinChance;
        maxWin = _maxWin;
        minBet = _minBet;
    }

    function updateSubscriptionData(
        uint64 _subscriptionId,
        address _coordinatorAddress,
        bytes32 _keyHash
    ) public onlyOwner {
        subscriptionId = _subscriptionId;
        coordinator = VRFCoordinatorV2Interface(_coordinatorAddress);
        keyHash = _keyHash;
    }

    function updateCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    function transferOwnership(address newOwner)
        public
        view
        override
        onlyOwner
    {
        revert("Ownership cannot be transferred");
    }

    enum BetStatus {
        Pending,
        Won,
        Lost
    }

    struct BetData {
        bool exists;
        address payable client;
        uint256 betAmount;
        uint256 winChance;
        uint256 betMultiplier;
        BetStatus winResult;
        uint256 random;
    }

    VRFCoordinatorV2Interface coordinator;
    uint64 subscriptionId;
    bytes32 keyHash;
    // Need to be tested, probably needs futher adjustments
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    mapping(uint256 => BetData) public bets;

    function bet(uint256 _winChance) public payable {
        require(
            msg.value >= minBet && msg.value <= calcMaxBet(_winChance),
            "Bet amount must be between min and max bet"
        );

        uint256 betMultipler = calcBetMultiplier(_winChance);

        // Will revert if subscription is not set and funded.
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        BetData memory betData = BetData({
            exists: true,
            client: payable(msg.sender),
            betAmount: msg.value,
            winChance: _winChance,
            betMultiplier: betMultipler,
            winResult: BetStatus.Pending,
            random: 0
        });
        bets[requestId] = betData;

        emit BetPlaced(requestId, betData);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        BetData storage bet = bets[_requestId];
        require(bet.exists, "Bet not found");
        uint16 rnd = uint16(_randomWords[0] % 1000);
        bet.random = rnd;

        if (rnd < bet.winChance) {
            bet.winResult = BetStatus.Won;
            uint256 winAmount = (bet.betAmount * bet.betMultiplier) / 1000;
            bet.client.transfer(winAmount);
        } else {
            bet.winResult = BetStatus.Lost;
        }

        emit BetSettled(_requestId, bet);
    }
}