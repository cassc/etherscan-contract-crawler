// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libs/IPermit.sol";
import "./libs/IDEX.sol";
import "./libs/guard.sol";
import "./libs/IAllowed.sol";

contract Lottery is VRFConsumerBaseV2, Ownable, ReentrancyGuard {
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }

    address public gasAddress;

    mapping(address => uint256) public gasForHostingAmount;
    mapping(address => uint256) public gasForEntriesAmount;
    mapping(address => uint256) public gasForEndLotteryAmount;
    mapping(address => uint256) public gasForBurnAmount;
    mapping(address => uint256) public gasForDistributeAmount;
    address public router;
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyhash;

    // rto burn fee and maxHostFee
    uint256 public burnFee = 2;
    uint256 public maxHostFee = 20;

    uint256 public feeForLink = 300000000000000;

    mapping(address => bool) public allowedTokens;

    address public rtoAddress;

    struct Premium {
        uint256 index;
        string name;
        uint256 price;
        bool exists;
    }

    mapping(uint256 => Premium) public premium;
    mapping(string => uint256[]) public premiumBuys;
    address public premiumAddressFee;
    address public premiumPayToken;

    struct Host {
        uint256 amountPerNumber;
        uint256 maxBetsPerAddress;
        address token;
        address hostAddress;
        uint256 hostFee;
        uint256[] winnerPercentages;
        LOTTERY_STATE state;
        uint256 totalEntriesAmount;
        uint256 deadline;
        // string[] memory socials;
    }

    struct UserEntry {
        address user;
        bool entered;
    }

    struct Winners {
        bool isEnd;
        address winner1;
        address winner2;
        address winner3;
        uint256 num1;
        uint256 num2;
        uint256 num3;
        uint256 amount1;
        uint256 amount2;
        uint256 amount3;
    }
    mapping(string => Winners) public winners;
    mapping(string => Host) public games;
    mapping(string => bool) public isChallengeExists;
    mapping(uint256 => string) public requestToChallenge;
    mapping(string => uint256) public challengeToRequest;
    mapping(string => uint256[]) public allEntries;
    mapping(string => mapping(uint256 => UserEntry)) public entriesOwnedByUser;
    mapping(string => mapping(address => uint256[]))
        public allEntriesOwnedByUser;

    mapping(address => uint256) public forBurn;

    address private _manager;
    modifier onlyMananger() {
        require(msg.sender == _manager, "Ownable: only mananger can call");
        _;
    }

    // cl
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 public subscriptionId;
    uint256[] public requestIds;
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    uint32 public callbackGasLimit = 2000000;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    uint256 public minDeadlineSec = 86400;
    uint256 public maxDeadlineSec = 604800;

    bool public isAutomaticDistribution = false;

    IAllowed private calc =
        IAllowed(0xE7F325D73cF851b2FaEC0037ED359e4920deC28d);

    // 0
    // 1
    // 2
    constructor(
        address _vrfCoordinator,
        bytes32 _keyhash,
        uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        keyhash = _keyhash;
        subscriptionId = _subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns (string memory) {
        return "1";
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function setAddPremium(
        uint256 index,
        string memory name,
        uint256 price,
        bool exists
    ) external onlyOwner {
        premium[index] = Premium(index, name, price, exists);
    }

    function setPremium(address _feeAddress, address _token)
        external
        onlyOwner
    {
        premiumAddressFee = _feeAddress;
        premiumPayToken = _token;
    }

    function setAllowedTokens(address _token, bool allow) external onlyOwner {
        allowedTokens[_token] = allow;
    }

    function setManager(address _new_men) external onlyOwner {
        _manager = _new_men;
    }

    function setCalcContract(address _calc) external onlyOwner {
        calc = IAllowed(_calc);
    }

    function updateCBFee(uint32 _fee) external onlyOwner {
        callbackGasLimit = _fee;
    }

    function setRTOContract(address _rto) external onlyOwner {
        rtoAddress = _rto;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
    }

    function setGasAddress(address _gasAddr) external onlyOwner {
        gasAddress = _gasAddr;
    }

    function setAutoDistribution(bool _auto) external onlyOwner {
        isAutomaticDistribution = _auto;
    }

    function setMinMaxDeadline(uint256 _min, uint256 _max) external onlyOwner {
        minDeadlineSec = _min;
        maxDeadlineSec = _max;
    }

    function resetGasFees(address _token) external onlyOwner {
        gasForEndLotteryAmount[_token] = 0;
        gasForEntriesAmount[_token] = 0;
        gasForHostingAmount[_token] = 0;
    }

    function hostLottery(
        string memory challengeId,
        uint256 deadlineInSeconds,
        uint256[] memory numbers, // maxNumber [0] amountPerNumber [1]
        address _token,
        uint256[] memory _winnerPercentages,
        address host,
        uint256 hostFee,
        uint256[] memory nonceExpiry,
        uint8 v,
        bytes32[] memory rs
    ) external nonReentrant {
        uint256 startGas = gasleft();
        _hostLottery(
            challengeId,
            deadlineInSeconds,
            numbers,
            _token,
            _winnerPercentages,
            host,
            hostFee,
            nonceExpiry,
            v,
            rs
        );
        gasForHostingAmount[_token] =
            (startGas - gasleft() + 21000) *
            tx.gasprice;
    }

    function _hostLottery(
        string memory challengeId,
        uint256 deadlineInSeconds,
        uint256[] memory numbers, // maxNumber [0] amountPerNumber [1]
        address _token,
        uint256[] memory _winnerPercentages,
        address host,
        uint256 hostFee,
        uint256[] memory nonceExpiry,
        uint8 v,
        bytes32[] memory rs
    ) internal {
        calc.isCustomFeeReceiverOrSender(host, msg.sender);
        challengeId = _toLower(challengeId);
        require(
            deadlineInSeconds >= minDeadlineSec &&
                deadlineInSeconds <= maxDeadlineSec,
            "Deadline must be in range"
        );
        require(!isChallengeExists[challengeId], "Use another challenge id");
        require(allowedTokens[_token], "This token is not allowed");
        require(
            hostFee <= maxHostFee && hostFee >= 0,
            "Host fee cannot be more then 20%"
        );
        require(
            _winnerPercentages.length == 3 &&
                _winnerPercentages[0] +
                    _winnerPercentages[1] +
                    _winnerPercentages[2] ==
                100 &&
                _winnerPercentages[0] > _winnerPercentages[1] &&
                _winnerPercentages[1] >= _winnerPercentages[2],
            "Select right percentages for winners"
        );
        require(
            numbers[0] < 50 && numbers[0] > 0,
            "Max numbers per address should be less then 50"
        );

        IPermit(_token).permit(
            host,
            address(this),
            nonceExpiry[0],
            nonceExpiry[1],
            true,
            v,
            rs[0],
            rs[1]
        );
        if (gasForHostingAmount[_token] > 0) {
            IERC20(_token).transferFrom(
                host,
                gasAddress,
                BNBToTokenAmount(
                    gasForHostingAmount[_token] + feeForLink,
                    _token
                )
            );
        }

        games[challengeId] = Host(
            numbers[1],
            numbers[0],
            _token,
            host,
            hostFee,
            _winnerPercentages,
            LOTTERY_STATE.OPEN,
            0,
            block.timestamp + deadlineInSeconds
        );
        isChallengeExists[challengeId] = true;
    }

    function hostLotteryPremium(
        string memory challengeId,
        address host,
        uint256[] memory nonceExpiry,
        uint8 v,
        bytes32[] memory rs,
        uint256[] memory premiumSelected
    ) external nonReentrant {
        uint256 amount;
        for (uint256 i = 0; i < premiumSelected.length; i++) {
            require(premium[premiumSelected[i]].exists, "Premium must exist");
            amount = amount + premium[premiumSelected[i]].price;
        }
        IPermit(premiumPayToken).permit(
            host,
            address(this),
            nonceExpiry[0],
            nonceExpiry[1],
            true,
            v,
            rs[0],
            rs[1]
        );
        IERC20(premiumPayToken).transferFrom(host, premiumAddressFee, amount);
        premiumBuys[challengeId] = premiumSelected;
    }

    function BNBToTokenAmount(uint256 amountInBNB, address _token)
        internal
        view
        returns (uint256)
    {
        if(amountInBNB == 0) {
            return 0;
        }
        address WETH = IDEXRouter(router).WETH();
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint256[] memory amounts = IDEXRouter(router).getAmountsIn(
            amountInBNB,
            path
        );
        return amounts[0];
    }

    function getGasFee(address _token, uint256 funcNum)
        external
        view
        returns (uint256)
    {
        uint256 _fee;
        if (funcNum == 0) {
            _fee = BNBToTokenAmount(gasForHostingAmount[_token], _token);
        } else if (funcNum == 1) {
            _fee = BNBToTokenAmount(gasForEntriesAmount[_token], _token);
        } else if (funcNum == 2) {
            _fee = BNBToTokenAmount(gasForEndLotteryAmount[_token], _token);
        } else if (funcNum == 3) {
            _fee = BNBToTokenAmount(gasForBurnAmount[_token], _token);
        } else if (funcNum == 4) {
            _fee = BNBToTokenAmount(gasForDistributeAmount[_token], _token);
        }
        return _fee;
    }

    function getLinkFee(address _token) external view returns (uint256) {
        return BNBToTokenAmount(feeForLink, _token);
    }

    function enter(
        string memory challengeId,
        uint256[] memory numbersToPlay,
        address player,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        uint256 startGas = gasleft();
        calc.isCustomFeeReceiverOrSender(player, msg.sender);
        challengeId = _toLower(challengeId);
        Host memory game = games[challengeId];
        uint256 amountToEnter = game.amountPerNumber * numbersToPlay.length;
        require(
            game.deadline > block.timestamp,
            "You missed deadline for this lottery"
        );
        require(
            game.state == LOTTERY_STATE.OPEN,
            "You can submit entry only when lottery is open"
        );
        require(
            numbersToPlay.length <= game.maxBetsPerAddress,
            "Seletected to many numbers"
        );
        IPermit(game.token).permit(
            player,
            address(this),
            nonce,
            expiry,
            true,
            v,
            r,
            s
        );

        if (gasForEntriesAmount[game.token] > 0) {
            IERC20(game.token).transferFrom(
                player,
                gasAddress,
                BNBToTokenAmount(
                    gasForEntriesAmount[game.token] + feeForLink,
                    game.token
                )
            );
        }
        IERC20(game.token).transferFrom(player, address(this), amountToEnter);
        games[challengeId].totalEntriesAmount =
            games[challengeId].totalEntriesAmount +
            amountToEnter;
        for (uint256 i; i < numbersToPlay.length; i++) {
            require(
                !entriesOwnedByUser[challengeId][numbersToPlay[i]].entered,
                "Some numbers already played"
            );
            require(
                numbersToPlay[i] > 0 && numbersToPlay[i] < 11111111111111,
                "number should be greater then 0"
            );
            allEntries[challengeId].push(numbersToPlay[i]);
            entriesOwnedByUser[challengeId][numbersToPlay[i]] = UserEntry(
                player,
                true
            );
            allEntriesOwnedByUser[challengeId][player].push(numbersToPlay[i]);
        }
        uint256 gasUsed = (startGas - gasleft() + 21000) * tx.gasprice;
        gasForEntriesAmount[game.token] = gasUsed;
    }

    function getAllMyEntries(string memory challengeId, address player)
        external
        view
        returns (uint256[] memory)
    {
        return allEntriesOwnedByUser[challengeId][player];
    }

    function RTOBurn(
        address _token,
        address caller,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        uint256 startGas = gasleft();
        require(allowedTokens[_token], "Token not allowed");

        IPermit(_token).permit(
            caller,
            address(this),
            nonce,
            expiry,
            true,
            v,
            r,
            s
        );
        if (gasForBurnAmount[_token] > 0) {
            IERC20(_token).transferFrom(
                caller,
                gasAddress,
                BNBToTokenAmount(gasForBurnAmount[_token] + feeForLink, _token)
            );
        }
        if (
            keccak256(abi.encodePacked(IERC20Metadata(_token).symbol())) ==
            keccak256(abi.encodePacked("RTO"))
        ) {
            IERC20(_token).transfer(
                0x000000000000000000000000000000000000dEaD,
                forBurn[_token]
            );
            forBurn[_token] = 0;
        } else {
            IERC20(_token).approve(router, forBurn[_token]);
            address[] memory path = new address[](3);
            address WETH = IDEXRouter(router).WETH();
            path[0] = _token;
            path[1] = WETH;
            path[2] = rtoAddress;
            uint256 deadline = block.timestamp + 1000;
            IDEXRouter(router)
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    forBurn[_token],
                    0,
                    path,
                    0x000000000000000000000000000000000000dEaD,
                    deadline
                );
            forBurn[_token] = 0;
        }

        uint256 gasUsed = (startGas - gasleft() + 21000) * tx.gasprice;
        gasForBurnAmount[_token] = gasUsed;
    }

    function endLottery(
        string memory challengeId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        uint256 startGas = gasleft();
        challengeId = _toLower(challengeId);
        Host memory game = games[challengeId];
        require(
            game.deadline < block.timestamp,
            "Wait till deadline for entries expire"
        );
        require(
            !winners[challengeId].isEnd,
            "We already have winner for this lottery"
        );
        IPermit(game.token).permit(
            game.hostAddress,
            address(this),
            nonce,
            expiry,
            true,
            v,
            r,
            s
        );

        if (gasForEndLotteryAmount[game.token] > 0) {
            IERC20(game.token).transferFrom(
                game.hostAddress,
                gasAddress,
                BNBToTokenAmount(
                    gasForEndLotteryAmount[game.token] + feeForLink,
                    game.token
                )
            );
        }
        requestRandomNumbers(challengeId);
        uint256 gasUsed = (startGas - gasleft() + 21000) * tx.gasprice;
        gasForEndLotteryAmount[game.token] = gasUsed;
    }

    function endLotteryMenager(string memory challengeId)
        public
        nonReentrant
        onlyMananger
    {
        challengeId = _toLower(challengeId);
        Host memory game = games[challengeId];
        require(
            game.deadline < block.timestamp,
            "Wait till deadline for entries expire"
        );
        require(
            !winners[challengeId].isEnd,
            "We already have winner for this lottery"
        );
        requestRandomNumbers(challengeId);
    }

    function requestRandomNumbers(string memory challengeId) internal {
        games[challengeId].state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyhash,
            subscriptionId,
            3,
            callbackGasLimit, // 1276287
            3
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        requestToChallenge[requestId] = challengeId;
        challengeToRequest[challengeId] = requestId;
        emit RequestSent(requestId, 3);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomness
    ) internal override {
        string memory challengeId = requestToChallenge[_requestId];
        Host memory game = games[challengeId];

        require(
            game.state == LOTTERY_STATE.CALCULATING_WINNER,
            "You aren't there yet!"
        );
        require(s_requests[_requestId].exists, "request not found");
        require(!s_requests[_requestId].fulfilled, "Request already fulfilled");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomness;
        if (isAutomaticDistribution) {
            distribute(game, _randomness, challengeId);
        }
        emit RequestFulfilled(_requestId, _randomness);
    }

    function distributeManuallyManager(string memory challengeId)
        external
        onlyMananger
        nonReentrant
    {
        challengeId = _toLower(challengeId);
        uint256 _requestId = challengeToRequest[challengeId];
        require(s_requests[_requestId].exists, "request not found");
        require(s_requests[_requestId].fulfilled, "Request must be fulfilled");
        require(
            !winners[challengeId].isEnd,
            "We already have winner for this lottery"
        );
        distribute(
            games[challengeId],
            s_requests[_requestId].randomWords,
            challengeId
        );
    }

    function distributeManually(
        string memory challengeId,
        address user,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        uint256 startGas = gasleft();
        challengeId = _toLower(challengeId);
        uint256 _requestId = challengeToRequest[challengeId];
        require(s_requests[_requestId].exists, "request not found");
        require(s_requests[_requestId].fulfilled, "Request must be fulfilled");
        require(
            !winners[challengeId].isEnd,
            "We already have winner for this lottery"
        );
        Host memory game = games[challengeId];

        IPermit(game.token).permit(
            user,
            address(this),
            nonce,
            expiry,
            true,
            v,
            r,
            s
        );

        if (gasForDistributeAmount[game.token] > 0) {
            IERC20(game.token).transferFrom(
                user,
                gasAddress,
                BNBToTokenAmount(
                    gasForDistributeAmount[game.token] + feeForLink,
                    game.token
                )
            );
        }

        distribute(
            games[challengeId],
            s_requests[_requestId].randomWords,
            challengeId
        );
        uint256 gasUsed = (startGas - gasleft() + 21000) * tx.gasprice;
        gasForDistributeAmount[game.token] = gasUsed;
    }

    function getWinners(string memory challengeId)
        external
        view
        returns (Winners memory)
    {
        challengeId = _toLower(challengeId);
        Host memory game = games[challengeId];
        uint256 _requestId = challengeToRequest[challengeId];
        uint256[] memory _randomness = s_requests[_requestId].randomWords;
        uint256 feeToHost = (game.totalEntriesAmount * game.hostFee) / 100;
        uint256 feeToBurn = (game.totalEntriesAmount * burnFee) / 100;
        uint256 amountForWinners = game.totalEntriesAmount -
            feeToBurn -
            feeToHost;

        uint256 winningNumber = allEntries[challengeId][
            _randomness[0] % allEntries[challengeId].length
        ];

        uint256 winningNumber1 = allEntries[challengeId][
            _randomness[1] % allEntries[challengeId].length
        ];

        uint256 winningNumber2 = allEntries[challengeId][
            _randomness[2] % allEntries[challengeId].length
        ];

        return
            Winners(
                true,
                entriesOwnedByUser[challengeId][winningNumber].user,
                entriesOwnedByUser[challengeId][winningNumber1].user,
                entriesOwnedByUser[challengeId][winningNumber2].user,
                winningNumber,
                winningNumber1,
                winningNumber2,
                (amountForWinners * game.winnerPercentages[0]) / 100,
                (amountForWinners * game.winnerPercentages[1]) / 100,
                (amountForWinners * game.winnerPercentages[2]) / 100
            );
    }

    function distribute(
        Host memory game,
        uint256[] memory _randomness,
        string memory challengeId
    ) internal {
        require(
            !winners[challengeId].isEnd,
            "We already have winner for this lottery"
        );
        uint256 indexOfWinner = _randomness[0] % allEntries[challengeId].length;
        uint256 winningNumber = allEntries[challengeId][indexOfWinner];
        address winner = entriesOwnedByUser[challengeId][winningNumber].user;

        uint256 feeToHost = (game.totalEntriesAmount * game.hostFee) / 100;
        uint256 feeToBurn = (game.totalEntriesAmount * burnFee) / 100;
        uint256 amountForWinners = game.totalEntriesAmount -
            feeToBurn -
            feeToHost;

        games[challengeId].state = LOTTERY_STATE.CLOSED;
        winners[challengeId].isEnd = true;

        uint256 prize1 = (amountForWinners * game.winnerPercentages[0]) / 100;
        IERC20(game.token).transfer(winner, prize1);
        winners[challengeId].winner1 = winner;
        winners[challengeId].num1 = winningNumber;
        winners[challengeId].amount1 = prize1;
        IERC20(game.token).transfer(game.hostAddress, feeToHost);
        forBurn[game.token] = feeToBurn;

        if (game.winnerPercentages[1] > 0) {
            uint256 indexOfWinner1 = _randomness[1] %
                allEntries[challengeId].length;
            uint256 winningNumber1 = allEntries[challengeId][indexOfWinner1];
            address winner1 = entriesOwnedByUser[challengeId][winningNumber1]
                .user;
            uint256 prize2 = (amountForWinners * game.winnerPercentages[1]) /
                100;
            IERC20(game.token).transfer(winner1, prize2);
            winners[challengeId].winner2 = winner1;
            winners[challengeId].num2 = winningNumber1;
            winners[challengeId].amount2 = prize2;
        }

        if (game.winnerPercentages[2] > 0) {
            uint256 indexOfWinner2 = _randomness[2] %
                allEntries[challengeId].length;
            uint256 winningNumber2 = allEntries[challengeId][indexOfWinner2];
            address winner2 = entriesOwnedByUser[challengeId][winningNumber2]
                .user;
            uint256 prize3 = (amountForWinners * game.winnerPercentages[2]) /
                100;
            IERC20(game.token).transfer(winner2, prize3);
            winners[challengeId].winner3 = winner2;
            winners[challengeId].num3 = winningNumber2;
            winners[challengeId].amount3 = prize3;
        }
    }
}