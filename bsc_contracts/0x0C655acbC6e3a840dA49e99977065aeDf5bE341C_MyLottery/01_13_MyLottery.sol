pragma solidity ^0.8.13;

//import "ERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
//import "AggregatorV3Interface.sol";
//import "VRFConsumerBase.sol";
import "Strings.sol";

//import "Address.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MyLottery is Ownable, ReentrancyGuard {
    address payable[] public players;
    address payable public recentWinner;
    //address public link;
    uint256 public randomness;
    uint256 public minumumParticipants;
    uint256 public maximumParticipants;
    uint256 public EntryFee;
    mapping(address => bool) public isUserEntered;
    //AggregatorV3Interface internal ethUsdPriceFeed;
    uint256 public pricePercent;
    uint256 public ownerPercent;
    uint256 public contractPercent;
    uint256 public maxTryCounter;
    uint256 public errorFlag;
    uint256 public lotteryStart;
    uint256 public lotteryEnd;
    uint256 public lotteryDuration;
    uint256 public lotteryPrepDuration;
    bool public ownerSent;
    //bool public winnerSent;

    //timestamp ekliyip closeda required bilmem kac saat geçmeden bitemez

    //maxTryCounter  end lottery icin calismali
    //CALCULATING_WINNER da takilabilir
    //lottery no id filan belki 1 le başlıyıp artırıp
    // kazanan için emit event tutar filan
    //hiç kimse katılmamışsa end lotterye gerek yok ilerde python schedule event lazım olucak

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    enum EMERGENCY {
        STOPPED,
        NOT_STOPPED
    }
    EMERGENCY public emergency;
    uint256 public fee;
    bytes32 public keyhash;
    event RequestedRandomness(bytes32 requestId);
    //event ethSendError(address cannotEthSend);
    event cantSendEthOwner(address indexed to, uint256 value);
    event cantSendEthWinner(address indexed to, uint256 value);
    event cantSendEthParticipants(address indexed to, uint256 value);

    // 0
    // 1
    // 2

    constructor() public {
        EntryFee = 0.05 * (10**18); //bura deiscek
        lottery_state = LOTTERY_STATE.CLOSED;
        emergency = EMERGENCY.NOT_STOPPED;
        minumumParticipants = 10;
        maximumParticipants = 150;
        pricePercent = 70;
        ownerPercent = 20;
        contractPercent = 10;
        maxTryCounter = 3;
        lotteryDuration = 259200; //28800 saniye 8 saat *3*3
        lotteryPrepDuration = 14400; //7200 saniye 2 saat*2
    }

    /*nonReentrant*/
    function enter_lottery() public payable nonReentrant {
        require(isUserEntered[msg.sender] == false, "Already entered");
        isUserEntered[msg.sender] = true;
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery Not started");
        require((emergency == EMERGENCY.NOT_STOPPED), "Lottery Stopped");
        require(
            msg.value == EntryFee,
            string.concat(
                "Entry fee must be equal to: ",
                Strings.toString(EntryFee),
                " Eth"
            )
        );
        require(
            players.length <= maximumParticipants,
            "Maximum Number reached for  lottery"
        );
        require((msg.sender).code.length <= 0, "Contract cannot enter");
        players.push(payable(msg.sender));
    }

    function start_lottery() public nonReentrant {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery Already started"
        );
        require(emergency == EMERGENCY.NOT_STOPPED, "Lottery Stopped");
        require(
            block.timestamp > (lotteryEnd + lotteryPrepDuration),
            "min lottery prep duration not passed"
        );
        lottery_state = LOTTERY_STATE.OPEN;
        randomness = 0;
        lotteryStart = block.timestamp;
    }

    function end_lottery() public nonReentrant {
        require(lottery_state == LOTTERY_STATE.OPEN, "Lottery Not started");
        require(emergency == EMERGENCY.NOT_STOPPED, "Lottery Stopped");
        require(
            block.timestamp > (lotteryStart + lotteryDuration),
            "min lottery duration not passed"
        );
        require((msg.sender).code.length <= 0, "Contract cannot enter");
        //some
        //timestamp requirede gerekiyor
        if (players.length < minumumParticipants) {
            not_enough_participant();
        } else {
            lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
            calculate_winner();
        }

        //ERC20 yeterli link var mı diye kontrol et
    }

    //if cant find winner something happens buna gerek kalmadi sanki
    /*function retry_winner() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "wrong state"
        );
        require(randomness == 0, "not random");
        calculate_winner();
    }*/

    function calculate_winner() internal {
        //if players.length>

        //another random not very very random

        randomness = uint256(
            keccak256(
                abi.encodePacked(
                    players[0], //  seenable
                    players[1],
                    players[players.length - 1],
                    block.difficulty, // can actually be manipulated by the miners!
                    block.timestamp // timestamp is predictable
                )
            )
        );
        afterFinish();
    }

    function setPrizePercents(
        uint256 _pricePercent,
        uint256 _ownerPercent,
        uint256 _contractPercent
    ) external onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can Not while lottery ongoing"
        );
        require(
            _pricePercent + _ownerPercent + _contractPercent <= 100,
            "can not over 100"
        );
        require(_pricePercent < 50, "can not less 50");
        pricePercent = _pricePercent;
        ownerPercent = _ownerPercent;
        contractPercent = _contractPercent;
    }

    function setMinumumParticipants(uint256 _minumumParticipants)
        external
        onlyOwner
    {
        minumumParticipants = _minumumParticipants;
    }

    function setLotteryDuration(uint256 _duration) external onlyOwner {
        lotteryDuration = _duration;
    }

    function setEmergencyOpen() external onlyOwner {
        emergency = EMERGENCY.NOT_STOPPED;
    }

    function setEmergencyClose() external onlyOwner {
        emergency = EMERGENCY.STOPPED;
    }

    function setEntranceFee(uint256 _entryFee) external onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can Not while lottery ongoing"
        );
        EntryFee = _entryFee;
    }

    function setMaximumParticipants(uint256 _maximumParticipants)
        external
        onlyOwner
    {
        maximumParticipants = _maximumParticipants;
    }

    function getBalance(address _tokenContractAddress)
        public
        view
        returns (uint256)
    {
        uint256 balance = IERC20(_tokenContractAddress).balanceOf(
            address(this)
        );
        return balance;
    }

    function recoverEth() external onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Can Not while lottery ongoing"
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function afterFinish() internal {
        //mapping clear unutma
        uint256 sentFlag = 0;
        require(randomness != 0, "cant find randomness");
        uint256 indexOfWinner = randomness % players.length;
        recentWinner = players[indexOfWinner];

        sentFlag = sendPrizes();

        if (sentFlag == 0) {
            clearPlayers();
        } else {
            errorFlag = errorFlag + 1;
            if (errorFlag == 3) {
                errorFlag = 0;
                calculate_winner(); //yeni winner secicez
            }
        }

        //require(sent, "Failed to send Ether");
    }

    function retrySendPrizes() external onlyOwner {
        sendPrizes();
    }

    function sendPrizes() internal returns (uint256) {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            " send prize wrong state"
        );
        uint256 total_prize = address(this).balance;
        if (
            !ownerSent
        ) //recentWinner.transfer(total_prize * (pricePercent / 100));
        {
            (bool sent, bytes memory data) = owner().call{
                value: (total_prize * ownerPercent) / 100
            }("");
            ownerSent = sent;
            if (!ownerSent) {
                emit cantSendEthOwner(
                    owner(),
                    (total_prize * ownerPercent) / 100
                );
                return 1;
            }
        }

        (bool sent, bytes memory data) = recentWinner.call{
            value: (total_prize * pricePercent) / 100
        }("");
        if (!sent) {
            emit cantSendEthWinner(
                recentWinner,
                (total_prize * pricePercent) / 100
            );
            return 1;
        }
        return 0;
    }

    /*function test(address sender)
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 total_prize = address(this).balance;
        (bool sent, bytes memory data) = sender.call{
            value: ((total_prize * pricePercent) / 100)
        }("");
        require(sent, "Failed to send Ether");
        uint256 calc_prize = total_prize * (pricePercent / 100);
        return (calc_prize, total_prize, pricePercent);
    }*/

    function not_enough_participant() internal {
        for (uint8 i = 0; i < players.length; i++) {
            //players[i].transfer(EntryFee);
            // burasi değişecek
            (bool sent, bytes memory data) = players[i].call{value: EntryFee}(
                ""
            );
            isUserEntered[players[i]] = false;
            //require(sent, "Failed to send Ether");
            if (!sent) {
                emit cantSendEthParticipants(players[i], EntryFee);
            }
        }
        clearPlayers();
    }

    function transferOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    function clearPlayers() internal {
        for (uint8 i = 0; i < players.length; i++) {
            isUserEntered[players[i]] = false;
        }
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        errorFlag = 0;
        ownerSent = false;
        lotteryEnd = block.timestamp;
        //randomness = 0;
    }
}