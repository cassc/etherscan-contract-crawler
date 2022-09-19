/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IVRFCoordinatorV2 is VRFCoordinatorV2Interface {
    function getFeeConfig()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint24,
            uint24,
            uint24,
            uint24
        );
}

abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    function __VRFConsumerBaseV2_init(address _vrfCoordinator)
        internal
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

interface IWBNB is IERC20Upgradeable {
    function deposit() external payable;
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

contract DiceRoll is
    Initializable,
    OwnableUpgradeable,
    ManageableUpgradeable,
    VRFConsumerBaseV2Upgradeable
{
    address constant priceFeed = 0xB38722F6A608646a538E882Ee9972D15c86Fc597;
    address constant vrfCoordinator =
        0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    address constant link_token_contract =
        0x404460C6A5EdE2D891e8297795264fDe62ADBB75;

    bytes32 constant keyHash =
        0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;
    uint32 callbackGasLimit;
    uint64 subscriptionId;

    IVRFCoordinatorV2 COORDINATOR;
    AggregatorV3Interface PRICE_FEED;

    struct Bet {
        uint256 id;
        bool resolved;
        address payable user;
        address token;
        uint256 amount;
        bool even;
        uint256 multiplier;
        uint256 timestamp;
        uint256 payout;
        uint256 result;
    }

    address public TOKEN;
    address public WBNB;
    address public BUSD;
    address public SENTINEL;
    address public GAME_POOL;
    address public BANK;

    uint256[] public distribution;
    uint256 public multiplier;
    uint256 public houseEdge;

    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) public userBets;
    mapping(address => bool) public acceptedTokens;
    mapping(address => uint256[]) public extremums;

    event betPlaced(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        bool even
    );
    event rollReceived(uint256 id, uint256 result);
    event betResolved(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        bool even,
        uint256 result,
        uint256 payout
    );

    function initialize(
        address token,
        address wbnb,
        address busd,
        address sentinel,
        address pool,
        address bank,
        uint32 _callbackGasLimit,
        uint64 _subscriptionId
    ) public initializer {
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator);
        COORDINATOR = IVRFCoordinatorV2(vrfCoordinator);
        PRICE_FEED = AggregatorV3Interface(priceFeed);
        TOKEN = token;
        WBNB = wbnb;
        BUSD = busd;
        SENTINEL = sentinel;
        GAME_POOL = pool;
        BANK = bank;
        callbackGasLimit = _callbackGasLimit;
        subscriptionId = _subscriptionId;

        distribution = [5000, 5000];
        multiplier = 20000;
        houseEdge = 400;

        acceptedTokens[token] = true;
        acceptedTokens[wbnb] = true;
        acceptedTokens[busd] = true;
        acceptedTokens[sentinel] = true;
    }

    function updateTokenAddress(address value) public onlyOwner {
        TOKEN = value;
    }

    function updateWBNBAddress(address value) public onlyOwner {
        WBNB = value;
    }

    function updateBUSDAddress(address value) public onlyOwner {
        BUSD = value;
    }

    function updateSentinelAddress(address value) public onlyOwner {
        SENTINEL = value;
    }

    function updatePool(address value) public onlyOwner {
        GAME_POOL = value;
    }

    function updateBank(address value) public onlyOwner {
        BANK = value;
    }

    function updateCallbackGasLimit(uint32 value) public onlyOwner {
        callbackGasLimit = value;
    }

    function updateSubscriptionId(uint64 id) public onlyOwner {
        subscriptionId = id;
    }

    function updateDistribution(uint256[] memory value) public onlyOwner {
        distribution = value;
    }

    function updateMultiplier(uint256 value) public onlyOwner {
        multiplier = value;
    }

    function updateHouseEdge(uint256 value) public onlyOwner {
        houseEdge = value;
    }

    function updateAcceptedToken(address token, bool value) public onlyOwner {
        acceptedTokens[token] = value;
    }

    function updateExtremums(address token, uint256[] memory value)
        public
        onlyOwner
    {
        extremums[token] = value;
    }

    function getUserBets(
        address user,
        uint256 start,
        uint256 end
    ) public view returns (Bet[] memory) {
        uint256[] memory userBets_ = userBets[user];
        end = end > userBets_.length ? userBets_.length : end;
        Bet[] memory bets_ = new Bet[](end - start);
        for (uint256 i = start; i < end; i++) {
            bets_[i - start] = (bets[userBets_[i]]);
        }
        return bets_;
    }

    function getLastUserBets(address user, uint256 quantity)
        public
        view
        returns (Bet[] memory)
    {
        uint256[] memory userBets_ = userBets[user];
        uint256 start = quantity > userBets_.length
            ? 0
            : userBets_.length - quantity;
        Bet[] memory bets_ = new Bet[](userBets_.length - start);
        for (uint256 i = start; i < userBets_.length; i++) {
            bets_[i - start] = (bets[userBets_[i]]);
        }
        return bets_;
    }

    function initiateRoll(
        address token,
        uint256 amount,
        bool even
    ) public payable {
        require(acceptedTokens[token], "INITATEROLL: Token not accepted");
        bool isNative = token == SENTINEL;
        uint256 fee = isNative ? msg.value - amount : msg.value;

        uint256 chainlinkVRFCost = getChainlinkVRFCost();
        require(
            fee > (chainlinkVRFCost - ((10 * chainlinkVRFCost) / 100)),
            "INITIATEROLL: Invalid gas fee value"
        );
        require(
            amount >= extremums[token][0],
            "INTIATEROLL: Below minimum bet"
        );
        require(
            amount <= extremums[token][1],
            "INTIATEROLL: Above maximum bet"
        );

        if (!isNative) {
            IERC20Upgradeable(token).transferFrom(
                _msgSender(),
                address(this),
                amount
            );
        }

        uint256 id = requestRandomWords();
        Bet memory newBet = Bet(
            id,
            false,
            payable(_msgSender()),
            token,
            amount,
            even,
            multiplier,
            block.timestamp,
            0,
            0
        );
        userBets[_msgSender()].push(id);
        bets[id] = newBet;
        emit betPlaced(id, _msgSender(), token, amount, even);
    }

    function requestRandomWords() public returns (uint256) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(!bets[_requestId].resolved, "FULFILL: Already resolved");
        uint256 randomResult = _randomWords[0] % 6;
        bool isEven = randomResult % 2 == 0;

        emit rollReceived(_requestId, randomResult);

        bets[_requestId].resolved = true;
        Bet memory bet = bets[_requestId];
        bet.result = randomResult;

        bool isNative = bet.token == SENTINEL;

        bool isWinner = (isEven && bet.even) || (!isEven && !bet.even);
        bet.payout = (isWinner) ? (bet.amount * bet.multiplier) / 10000 : 0;

        if (isWinner) {
            uint256 houseFee = (bet.payout * houseEdge) / 10000;
            uint256 bankFee = (houseFee * distribution[0]) / 10000;
            uint256 gameFee = (houseFee * distribution[1]) / 10000;
            uint256 payment = bet.payout - houseFee;
            if (isNative) {
                {
                    (bool success, ) = bet.user.call{value: payment}("");
                    require(success, "FULFILL: Failed to send winnings");
                }

                {
                    IWBNB(WBNB).deposit{value: bankFee}();
                    IWBNB(WBNB).transfer(BANK, bankFee);
                    IBank(BANK).addRewards(WBNB, bankFee);
                }

                {
                    (bool success, ) = GAME_POOL.call{value: gameFee}("");
                    require(success, "FULFILL: Failed to send game pool fees");
                }
            } else {
                IERC20Upgradeable(bet.token).transfer(bet.user, payment);
                IERC20Upgradeable(bet.token).transfer(BANK, bankFee);
                IBank(BANK).addRewards(bet.token, bankFee);
                IERC20Upgradeable(bet.token).transfer(GAME_POOL, gameFee);
            }
        }

        bets[_requestId] = bet;
        emit betResolved(
            _requestId,
            bet.user,
            bet.token,
            bet.amount,
            bet.even,
            bet.result,
            bet.payout
        );
    }

    function withdrawNative() public onlyOwner {
        (bool sent, ) = payable(owner()).call{
            value: (payable(address(this))).balance
        }("");
        require(sent, "Failed to send Ether to growth");
    }

    function withdrawNativeTwo() public onlyOwner {
        payable(owner()).transfer((payable(address(this))).balance);
    }

    function withdraweErc20(address token) public onlyOwner {
        IERC20Upgradeable(token).transfer(
            owner(),
            IERC20Upgradeable(token).balanceOf(address(this))
        );
    }

    function getChainlinkVRFCost() public view returns (uint256) {
        (, int256 weiPerUnitLink, , , ) = PRICE_FEED.latestRoundData();
        require(weiPerUnitLink > 0, "Invalid price feed value");
        (uint32 fulfillmentFlatFeeLinkPPMTier1, , , , , , , , ) = COORDINATOR
            .getFeeConfig();
        return
            (tx.gasprice * (115000 + callbackGasLimit)) +
            ((1e12 *
                uint256(fulfillmentFlatFeeLinkPPMTier1) *
                uint256(weiPerUnitLink)) / 1e18);
    }

    receive() external payable {}

    fallback() external payable {}
}