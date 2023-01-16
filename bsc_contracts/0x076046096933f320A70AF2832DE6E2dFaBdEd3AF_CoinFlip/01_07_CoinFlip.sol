// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CoinFlip is Ownable, VRFConsumerBaseV2, ReentrancyGuard {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    /* Storage:
     ***********/

    address constant vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    address constant link_token_contract = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;

    bytes32 constant keyHash = 0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;
    uint16 constant requestConfirmations = 3;
    uint32 constant callbackGasLimit = 1e5;
    uint32 constant numWords = 1;
    uint64 subscriptionId;
    uint256 private contractBalance;

    struct Temp {
        uint256 id;
        uint256 result;
        address playerAddress;
    }

    struct PlayerByAddress {
        uint256 balance;
        uint256 betAmount;
        uint256 betChoice;
        address playerAddress;
        bool betOngoing;
    }

    mapping(address => PlayerByAddress) public playersByAddress; //to check who is the player
    mapping(uint256 => Temp) public temps; //to check who is the sender of a pending bet by Id

    /* Events:
     *********/

    event DepositToContract(address user, uint256 depositAmount, uint256 newBalance);
    event Withdrawal(address player, uint256 amount);
    event NewIdRequest(address indexed player, uint256 requestId);
    event GeneratedRandomNumber(uint256 requestId, uint256 randomNumber);
    event BetResult(address indexed player, bool victory, uint256 amount);

    /* Constructor:
     **************/

    constructor(uint64 _subscriptionId) payable initCosts(0.1 ether) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        subscriptionId = _subscriptionId;
        contractBalance += msg.value;
    }

    /* Modifiers:
     ************/

    modifier initCosts(uint256 initCost) {
        require(msg.value >= initCost, "CoinFlip: Contract needs ETH");
        _;
    }

    modifier betConditions() {
        require(msg.value >= 0.001 ether, "CoinFlip: amount insuffisant");
        require(msg.value <= getContractBalance() / 2, "CoinFlip: amount too big");
        require(!playersByAddress[_msgSender()].betOngoing, "CoinFlip: Bet already ongoing");
        _;
    }

    /* Functions:
     *************/

    function bet(uint256 _betChoice) public payable betConditions nonReentrant {
        require(_betChoice == 0 || _betChoice == 1, "CoinFlip: Must be 0 or 1");

        address player = _msgSender();

        playersByAddress[player].playerAddress = player;
        playersByAddress[player].betChoice = _betChoice;
        playersByAddress[player].betOngoing = true;
        playersByAddress[player].betAmount = msg.value;
        contractBalance += playersByAddress[player].betAmount;

        uint256 requestId = requestRandomWords();
        temps[requestId].playerAddress = player;
        temps[requestId].id = requestId;

        emit NewIdRequest(player, requestId);
    }

    /// @notice Assumes the subscription is funded sufficiently.
    function requestRandomWords() public returns (uint256) {
        return
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 randomResult = _randomWords[0] % 2;
        temps[_requestId].result = randomResult;

        checkResult(randomResult, _requestId);
        emit GeneratedRandomNumber(_requestId, randomResult);
    }

    function checkResult(uint256 _randomResult, uint256 _requestId) private returns (bool) {
        address player = temps[_requestId].playerAddress;
        bool win = false;
        uint256 amountWon = 0;

        if (playersByAddress[player].betChoice == _randomResult) {
            win = true;
            amountWon = playersByAddress[player].betAmount * 2;
            playersByAddress[player].balance = playersByAddress[player].balance + amountWon;
            contractBalance -= amountWon;
        }

        emit BetResult(player, win, amountWon);

        playersByAddress[player].betAmount = 0;
        playersByAddress[player].betOngoing = false;

        delete (temps[_requestId]);
        return win;
    }

    function deposit() external payable {
        require(msg.value > 0);
        contractBalance += msg.value;
        emit DepositToContract(_msgSender(), msg.value, contractBalance);
    }

    function withdrawPlayerBalance() external nonReentrant {
        address player = _msgSender();
        require(player != address(0), "CoinFlip: This address doesn't exist");
        require(playersByAddress[player].balance > 0, "CoinFlip: No fund to withdraw");
        require(!playersByAddress[player].betOngoing, "CoinFlip: Bet ongoing");

        uint256 amount = playersByAddress[player].balance;
        payable(player).transfer(amount);
        delete (playersByAddress[player]);

        emit Withdrawal(player, amount);
    }

    /* View functions:
     *******************/

    function getPlayerBalance() external view returns (uint256) {
        return playersByAddress[_msgSender()].balance;
    }

    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    /* Restricted :
     **************/

    function withdrawContractBalance() external onlyOwner {
        _payout();
        if (LINKTOKEN.balanceOf(address(this)) > 0) {
            bool isSuccess = LINKTOKEN.transfer(owner(), LINKTOKEN.balanceOf(address(this)));
            require(isSuccess, "CoinFlip: Link withdraw failed");
        }
    }

    function addConsumer(address consumerAddress) external onlyOwner {
        COORDINATOR.addConsumer(subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) external onlyOwner {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) external onlyOwner nonReentrant {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        uint64 temp = subscriptionId;
        subscriptionId = 0;
        COORDINATOR.cancelSubscription(temp, receivingWallet);
    }

    /* Private :
     ***********/

    function _payout() private returns (uint256) {
        require(contractBalance != 0, "CoinFlip: No funds to withdraw");

        uint256 toTransfer = address(this).balance;
        contractBalance = 0;
        payable(owner()).transfer(toTransfer);
        return toTransfer;
    }
}