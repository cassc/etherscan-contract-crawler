// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CoinFlip is VRFV2WrapperConsumerBase, Ownable {

    using SafeERC20 for IERC20;

    address public feeReceiver;
    address public token;
    address public link;

    bytes32 internal keyHash;

    uint256 public feePercent;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public expiry;
    uint256 public betNum;
    uint256 internal chainlinkFee;
    uint256 public randomResult;

    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    mapping(uint => BetDetails) public bets;
    mapping(uint => uint) public requestToBetDetails;

    struct BetDetails {
        address player;
        address taker;
        uint amount;
        Side side;
        uint timestamp;
        bool isSettled;
        bool isCancelled;
        uint requestId;
    }

    enum Side {
        HEAD,
        TAIL
    }

    event BetCreated(uint betID);
    event BetTaken(uint betID);
    event BetSettled(uint betID);
    event BetCancelled(uint betID);

    constructor()
    VRFV2WrapperConsumerBase(
        0x404460C6A5EdE2D891e8297795264fDe62ADBB75,  // LINK Token
        0x721DFbc5Cfe53d32ab00A9bdFa605d3b8E1f3f42 // VRF Wrapper
    )
    {
        keyHash = 0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;
        chainlinkFee = 0.005 * 10 ** 18; // 0.1 LINK (Varies by network)
        feeReceiver = msg.sender;
        feePercent = 100;   // 1% fee
        link = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;
    }

    function createBet(uint _amount, Side side) external {
        require(_amount >= minAmount && _amount <= maxAmount, "Amount out of range");
        betNum++;
        // Transfer token to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        bets[betNum] = BetDetails(msg.sender, address(0), _amount, side, block.timestamp, false, false, 0);
        emit BetCreated(betNum);
    }

    function takeBet(uint _betID) external {
        require(bets[_betID].player != address(0), "Bet does not exist");
        require(bets[_betID].player != msg.sender, "Cannot take your own bet");
        require(bets[_betID].isSettled == false, "Bet is already settled");
        require(bets[_betID].isCancelled == false, "Bet is already cancelled");
        require(bets[_betID].taker == address(0), "Bet is already taken");
        // Transfer token to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), bets[_betID].amount);
        // Get random number
        uint256 requestId = getRandomNumber();
        bets[_betID].requestId = requestId;
        bets[_betID].taker = msg.sender;
        emit BetTaken(_betID);
    }

    function settleBet(uint _betID) external {
        require(bets[_betID].isSettled == false, "Bet is already settled");
        require(bets[_betID].isCancelled == false, "Bet is already cancelled");
        require(bets[_betID].taker != address(0), "Bet should be takem first");
        uint result = requestToBetDetails[bets[_betID].requestId];
        require(result != 0, "Result is not ready");
        uint amount = bets[_betID].amount * 2;
        uint fee = amount * feePercent / 10000;
        IERC20(token).safeTransfer(feeReceiver, fee);
        if(result == uint(bets[_betID].side) + 1) {
            // Winner
            IERC20(token).safeTransfer(bets[_betID].player, amount - fee);
        } else {
            // Loser
            IERC20(token).safeTransfer(bets[_betID].taker, amount - fee);
        }
        bets[_betID].isSettled = true;
        emit BetSettled(_betID);
    }

    function cancelBet(uint _betID) external {
        require(bets[_betID].isSettled == false, "Bet is already settled");
        require(bets[_betID].isCancelled == false, "Bet is already cancelled");
        require(bets[_betID].player == msg.sender, "Only player can cancel the bet");
        require(bets[_betID].taker == address(0), "Bet is already taken");
        require(block.timestamp - bets[_betID].timestamp > expiry, "Bet is not expired");
        IERC20(token).safeTransfer(bets[_betID].player, bets[_betID].amount);
        bets[_betID].isCancelled = true;
        emit BetCancelled(_betID);
    }

    // Request randomness
    function getRandomNumber() internal returns (uint requestId) {
        require(LINK.balanceOf(address(this)) >= chainlinkFee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
    }

    // Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 _requestId, uint256[] memory randomness) internal override {
        randomResult = (randomness[0] % 2) + 1;
        requestToBetDetails[_requestId] = randomResult;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setPlatformFee(address _feeReceiver, uint _feePercent) external onlyOwner {
        feeReceiver = _feeReceiver;
        feePercent = _feePercent;
    }

    function setMinMaxAmount(uint _minAmount, uint _maxAmount) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setExpiry(uint _expiry) external onlyOwner {
        expiry = _expiry;
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function getBetDetails(uint _startIndex, uint _endIndex) external view returns (BetDetails[] memory) {
        require(_startIndex < _endIndex, "Start index should be less than end index");
        require(_endIndex <= betNum, "End index should be less than equal to betNum");
        BetDetails[] memory betDetails = new BetDetails[](_endIndex - _startIndex + 1);
        for(uint i = _startIndex; i <= _endIndex; i++) {
            betDetails[i - _startIndex] = bets[i];
        }
        return betDetails;
    }
}