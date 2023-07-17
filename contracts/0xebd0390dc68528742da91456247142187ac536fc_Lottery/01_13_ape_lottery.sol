pragma solidity ^0.6.6;
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";


/*
Contract Created by

███████╗ ██╗   ██████╗░██╗██╗░░██╗██╗██╗░░░██╗███╗░░░███╗
███████║ ╚═╝   ██╔══██╗██║╚██╗██╔╝██║██║░░░██║████╗░████║
███████║ ██╗   ██████╔╝██║░╚███╔╝░██║██║░░░██║██╔████╔██║
████╔══╝ ╚═╝   ██╔═══╝░██║░██╔██╗░██║██║░░░██║██║╚██╔╝██║
████║██╗ ██╗   ██║░░░░░██║██╔╝╚██╗██║╚██████╔╝██║░╚═╝░██║
╚═══╝╚═╝ ╚═╝   ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░╚═════╝░╚═╝░░░░░╚═╝

               █▄░█ █▀▀ ▀█▀   █░░ █▀█ ▀█▀ ▀█▀ █▀▀ █▀█ █▄█
               █░▀█ █▀░ ░█░   █▄▄ █▄█ ░█░ ░█░ ██▄ █▀▄ ░█░
               
Lottery on our website:
https://www.pixium-lottery.com

More Informations on our Medium articles:
https://medium.com/@PIXIUM
*/

interface INFTInterface {
    function transferFrom(address from, address to, uint256 tokenId) external payable;
}

contract Lottery is VRFConsumerBase {
    
    // The modifier allows certain functions to be used only by the owner
    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        _;
        
    }

    // Constructor created in order to use Chainlink VRF (nb: more informations on our Medium article)
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator Address
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token Address
        ) public
    
    // 
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; // keyHash of Chainlink
        fee = 2 * 10 ** 18; 
    }
    //44444444444444444// modifier le constructor : adresses + fees=1 quand MainNet
    
    // Set up of the different variables and mappings (how to store the informations)
    address owner = address(0xFF577082f44d17721338BDFff52faA2D0C8f437E);
    address vrfCoordinator = address (0xf0d54349aDdcf704F77AE15b96510dEA15cb7952);
    address payable[] public players;
    address addressToSendNFT = OwnerOfTheNFT[1];

    enum LOTTERY_STATE { CLOSED, OPEN, CALCULATING_WINNER }
    enum WITHDRAWOWNER { OPEN, CLOSED }
    enum REFUND { CLOSED, OPEN }
    enum WITHDRAWNFT { OPEN, CLOSED }

    LOTTERY_STATE public lottery_state; 
    WITHDRAWOWNER public WithdrawOwner;
    REFUND public Refund;
    WITHDRAWNFT public WithdrawNFT;
    
    uint256 internal fee;
    uint256 public most_recent_random;
    uint256 public lotteryId;
    uint256 public totalTicketsSales = 0;
    uint256 public MINIMUM = 10000000000000000; // Price of the Ticket (0.01 eth)
    uint256 public TARGET = 8000000000000000000; // Target of the Lottery (8 eth)
    uint256 public ORACLE_PAYMENT = 2000000000000000000; // Chainlink Fees (2 link)

    mapping (address => uint) public QuantityOfTicket;
    mapping(uint => address) public ticketIndex;
    mapping (address => uint) public pendingWithdrawals;
    mapping (uint => address) public winners;
    mapping (uint => uint) public randomNumber;
    mapping (bytes32 => uint) public requestIds;
    mapping(uint256 => bool) public NFTIsDepositedInContract;
    mapping(uint256 => address) public OwnerOfTheNFT;
    
    bytes32 internal keyHash;

    bool private reentrancyLock = false;

    event Withdraw(address indexed account, uint amount);
    event DepositNFT(uint256 NFTId);
    event NFTGiven(uint256 NFTId);
    event TicketBought (address indexed account, uint NumberOfTicket);
    event initContract (address indexed account);
    event startLottery (address indexed account);
    event CloseLotteryAndPickWinner (address indexed account);
    event CancelLotteryAndRefund (address indexed account);
    
    // Interface of the BAYC contract (in order to interact with it)
    INFTInterface private NFTCore = INFTInterface(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D); //Address of the BAYC Contract
    
    /*

    █▀█ ▄▀█ █▀█ ▀█▀ █ █▀▀ █ █▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█  
    █▀▀ █▀█ █▀▄ ░█░ █ █▄▄ █ █▀▀ █▀█ ░█░ █ █▄█ █░▀█  
    
        █▀█ ▄▀█ █▀█ ▀█▀
        █▀▀ █▀█ █▀▄ ░█░
    */

    /* 
    
    Fᴜɴᴄᴛɪᴏɴ ʙᴜʏᴛɪᴄᴋᴇᴛ
    
    Requires that the lottery has been launched, it allows participants to buy 1 or more tickets.
    The number of tickets increases your chance to win the big prize!
    /!\ WARNING /!\ the TotalToPay expect a value in WEI (the website makes automatically the conversion)
    */

    function BuyTicket (uint256 TotalToPay) public payable reentrancyGuard {
        require(TotalToPay % MINIMUM == 0);
        require(msg.sender != owner);
        require(msg.value >= TotalToPay, "Insufficient funds to purchase.");
        require(lottery_state == LOTTERY_STATE.OPEN);
        uint256 NumberOfTicket = div(TotalToPay,MINIMUM);
        for(uint256 i=0; i < NumberOfTicket; i++){
            totalTicketsSales+=1;
            ticketIndex[totalTicketsSales] = msg.sender;
        }
        QuantityOfTicket[msg.sender] += NumberOfTicket;
        pendingWithdrawals[owner] += msg.value;
        pendingWithdrawals[msg.sender] += msg.value;
        emit Withdraw(msg.sender, NumberOfTicket);
    } 
    
    /*
    
    █░░ █▀█ ▀█▀ ▀█▀ █▀▀ █▀█ █▄█
    █▄▄ █▄█ ░█░ ░█░ ██▄ █▀▄ ░█░
        
        █▀▄▀█ ▄▀█ █▄░█ ▄▀█ █▀▀ █▀▀ █▀▄▀█ █▀▀ █▄░█ ▀█▀
        █░▀░█ █▀█ █░▀█ █▀█ █▄█ ██▄ █░▀░█ ██▄ █░▀█ ░█░
    */
    
    /* 
    Fᴜɴᴄᴛɪᴏɴ sᴛᴀʀᴛʟᴏᴛᴛᴇʀʏ
        
    Can be launched by the Owner Address only.
    Allows the Owner to start the Lottery.
    */
    function StartLottery() public 
    onlyBy(owner)
    {
        require(lottery_state == LOTTERY_STATE.CLOSED, "can't start a new lottery yet");
        lottery_state = LOTTERY_STATE.OPEN;
        WithdrawOwner = WITHDRAWOWNER.CLOSED;
        Refund = REFUND.CLOSED;
        WithdrawNFT = WITHDRAWNFT.CLOSED;
        OwnerOfTheNFT[1] = owner;
        emit startLottery(msg.sender);
    }
    
    /* 
    
    Ｅｎｄｉｎｇ Ｐｏｓｓｉｂｉｌｉｔｉｅｓ

    As explained in our Medium article, 2 situations are possible:
        1) The target has been reached, so we have the possibility to close the lottery.
            The winner is randomly picked and the NFT is transferred to the winner
        2) The lottery has not reached its target, the lottery is canceled, and allows the participants to get a refund. 
            Also, the NFT is returned to the owner.
    */

    // Ｆｉｒｓｔ Ｓｉｔｕａｔｉｏｎ : The target has veen reached, the lottery will happen 
    function CloseLottery () public 
    onlyBy(owner) 
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        require( mul(totalTicketsSales,MINIMUM) > TARGET, "Not enough players to choose a winner");
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        pickWinner();
        WithdrawOwner = WITHDRAWOWNER.OPEN;
        Refund = REFUND.CLOSED;
        WithdrawNFT = WITHDRAWNFT.OPEN;
        emit CloseLotteryAndPickWinner (msg.sender);
    } 

    // Ｓｅｃｏｎｄ Ｓｉｔｕａｔｉｏｎ : The target has not been reached, the lottery is canceled
    function CancelLottery () public
    onlyBy(owner)
    {
        require(lottery_state == LOTTERY_STATE.OPEN, "The lottery hasn't even started!");
        require( mul(totalTicketsSales,MINIMUM) < TARGET, "Enough players to choose a winner");
        WithdrawOwner = WITHDRAWOWNER.CLOSED;
        Refund = REFUND.OPEN;
        WithdrawNFT = WITHDRAWNFT.OPEN;
        emit CancelLotteryAndRefund (msg.sender);
    }

    /*
    
    █░█░█ █ ▀█▀ █░█ █▀▄ █▀█ ▄▀█ █░█░█
    ▀▄▀▄▀ █ ░█░ █▀█ █▄▀ █▀▄ █▀█ ▀▄▀▄▀
    */
    
    /* The  OwnerWithdraw allows the owner to withdraw the amount of ETH deposited by the participants.
        This function is usable ONLY if the target has been reached (the lottery is maintained)
    */
    function  OwnerWithdraw(uint256 amount) public payable
    onlyBy(owner)
    {
		require(WithdrawOwner == WITHDRAWOWNER.OPEN, "Owner can't withdraw");
        pendingWithdrawals[owner] -= amount;
        (bool success, ) = owner.call{value:amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
	}
	
    /* The GetRefund allows the participants to get a refund.
        This function is usable ONLY if the target has not been reached (the lottery is canceled)
    */
	function GetRefund() public payable reentrancyGuard {
    
        require(Refund == REFUND.OPEN, "Owner can't withdraw");
        uint amount = pendingWithdrawals[msg.sender]; 
        pendingWithdrawals[msg.sender] = 0;
        pendingWithdrawals[owner] -= amount;
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
    }

    /*
    
    █▄░█ █▀▀ ▀█▀
    █░▀█ █▀░ ░█░
    
        █▀█ ▄▀█ █▀█ ▀█▀
        █▀▀ █▀█ █▀▄ ░█░

    */

    // The NFT (BAYC) will be transferred to the winner.
    function GiveNFT(uint256 _NFTId) external 
    onlyBy(owner)
    {
        require(WithdrawNFT == WITHDRAWNFT.OPEN, "You aren't at that stage yet!");
        NFTCore.transferFrom(address(this), OwnerOfTheNFT[1], _NFTId);
        emit NFTGiven(_NFTId);
    }

    /*  
        █▀▀ █░█ ▄▀█ █ █▄░█ █░░ █ █▄░█ █▄▀
        █▄▄ █▀█ █▀█ █ █░▀█ █▄▄ █ █░▀█ █░█
    
    Chainlink VRF Tools to generate random number with on-chain verification of randomness
    More informations : https://docs.chain.link/docs/chainlink-vrf/

    */
    
    // The fonction called by CloseLottery to begin the selection of the winner
    function pickWinner() private {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        getRandom(lotteryId, lotteryId);
    }

    // To get a random number to Chainlink
    function getRandom(uint256 userProvidedSeed, uint256 lotteryId) public {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        bytes32 _requestId = requestRandomness(keyHash, fee);
        requestIds[_requestId] = lotteryId;
    }

    // Called by the VRF Coordinator to ful fill the random number
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(msg.sender == vrfCoordinator, "Fulillment only permitted by Coordinator");
        most_recent_random = randomness;
        uint lotteryId = requestIds[requestId];
        randomNumber[lotteryId] = randomness;
        fulfill_random(randomness);
    }

    // To ful fill the randomness to choose the winner[1] and set the owner of the NFT to the winner
    function fulfill_random(uint256 randomness) internal {
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't at that stage yet!");
        require(randomness > 0, "random-not-found");
        uint256 index = randomness % totalTicketsSales;
        address winner = ticketIndex[index];
        lottery_state = LOTTERY_STATE.CLOSED;
        winners[1] = address (winner);
        OwnerOfTheNFT[1] = address (winner);
    }

    /*
    
        █░█ ▀█▀ █ █░░ █ ▀█▀ █▄█
        █▄█ ░█░ █ █▄▄ █ ░█░ ░█░
    */

    // To avoid reentrancy
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    // SafeMath library multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    // SafeMath library division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;    
        return c;
    
    }
    
}