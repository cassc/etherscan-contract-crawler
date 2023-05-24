// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/IPancakeRouter.sol';
import '../interfaces/IPRC20.sol';
import '../interfaces/IBNBP.sol';
import '../interfaces/IPotContract.sol';

// File: PotContract.sol

contract PowerBallBNBP is ReentrancyGuard {
    enum STATE {
        WAITING,
        STARTED,
        LIVE,
        CALCULATING_WINNER
    }

    struct Entry {
        address player;
        uint256 amount;
    }

    address public owner;
    address public admin;
    address public tokenAddress;
    uint8 public tokenDecimal;

    STATE public roundStatus;
    uint256 public entryIds;
    uint256 public roundIds;
    uint256 public roundDuration;
    uint256 public roundStartTime;
    uint256 public roundLiveTime;
    uint256 public minEntranceAmount;
    uint256 public currentEntryCount;
    Entry[] public currentEntries;

    uint256 public totalEntryAmount;
    uint256 public nonce;
    uint256 public calculateIndex;

    uint256 public feePercent = 75;

    address public BNBPAddr = 0x4D9927a8Dc4432B93445dA94E4084D292438931F; // mainnet: 0x4D9927a8Dc4432B93445dA94E4084D292438931F, testnet: 0xcAf4f8C9f1e511B3FEb3226Dc3534E4c4b2f3D70
    address public potContractAddr;

    constructor(address _potContractAddr) {
        owner = msg.sender;
        admin = msg.sender;
        tokenAddress = BNBPAddr;
        tokenDecimal = IPRC20(tokenAddress).decimals();
        roundStatus = STATE.WAITING;
        roundDuration = 5; // 5 secs
        roundIds = 1;

        minEntranceAmount = 1 * 10 ** tokenDecimal; // 2 BNBP
        potContractAddr = _potContractAddr;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, '!admin');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, '!owner');
        _;
    }

    modifier validBNBP() {
        require(BNBPAddr != address(0), '!BNBP Addr');
        _;
    }

    modifier excludeContract() {
        require(tx.origin == msg.sender, 'Contract');
        _;
    }

    event EnteredPot(uint256 indexed roundId, uint256 indexed entryId, address indexed player, uint256 amount);
    event StartedCalculating(uint256 indexed roundId);
    event CalculateWinner(
        uint256 indexed roundId,
        address indexed winner,
        uint256 reward,
        uint256 total,
        uint256 index
    );

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function changeAdmin(address _adminAddress) public onlyOwner {
        admin = _adminAddress;
    }

    function setBNBPAddress(address _address) public onlyAdmin {
        BNBPAddr = _address;
    }

    function enterPot(uint256 _amount) external excludeContract {
        unchecked {
            require(_amount >= minEntranceAmount, 'Min');
            require(roundLiveTime == 0 || block.timestamp <= roundLiveTime + roundDuration, 'ended');

            IBNBP token = IBNBP(tokenAddress);
            uint256 beforeBalance = token.balanceOf(address(this));
            token.transferFrom(msg.sender, address(this), _amount);
            uint256 rAmount = token.balanceOf(address(this)) - beforeBalance;

            uint256 count = currentEntryCount;
            if (currentEntries.length == count) {
                currentEntries.push();
            }

            Entry storage entry = currentEntries[count];
            entry.player = msg.sender;
            entry.amount = rAmount;
            ++currentEntryCount;
            ++entryIds;
            totalEntryAmount = totalEntryAmount + rAmount;

            if (
                currentEntryCount >= 2 && currentEntries[count - 1].player != msg.sender && roundStatus == STATE.STARTED
            ) {
                roundStatus = STATE.LIVE;
                roundLiveTime = block.timestamp;
            } else if (currentEntryCount == 1) {
                roundStatus = STATE.STARTED;
                roundStartTime = block.timestamp;
            }

            emit EnteredPot(roundIds, entryIds, msg.sender, rAmount);
        }
    }

    function calculateWinner() public {
        bool isRoundEnded = roundStatus == STATE.LIVE && roundLiveTime + roundDuration < block.timestamp;
        require(isRoundEnded || roundStatus == STATE.CALCULATING_WINNER, 'Not ended');

        if (isRoundEnded) {
            nonce = fullFillRandomness() % totalEntryAmount;
            calculateIndex = 0;
        }
        (address winner, uint256 index) = determineWinner();
        if (winner != address(0)) {
            IBNBP token = IBNBP(tokenAddress);
            uint256 feeAmount = (totalEntryAmount * feePercent) / 1000;
            uint256 reward = totalEntryAmount - feeAmount;

            token.transfer(winner, reward);
            IPRC20(BNBPAddr).approve(potContractAddr, feeAmount);
            IPotLottery(potContractAddr).addAdminTokenValue(feeAmount);

            emit CalculateWinner(roundIds, winner, reward, totalEntryAmount, index);

            initializeRound();
        } else {
            roundStatus = STATE.CALCULATING_WINNER;
            emit StartedCalculating(roundIds);
        }
    }

    /**
     * @dev Attempts to select a random winner
     */
    function determineWinner() internal returns (address winner, uint256 winnerIndex) {
        uint256 start = calculateIndex;
        uint256 length = currentEntryCount;
        uint256 _nonce = nonce;
        for (uint256 index = 0; index < 3000 && (start + index) < length; index++) {
            uint256 amount = currentEntries[start + index].amount;
            if (_nonce <= amount) {
                //That means that the winner has been found here
                winner = currentEntries[start + index].player;
                winnerIndex = start + index;
                return (winner, winnerIndex);
            }
            _nonce -= amount;
        }
        nonce = _nonce;
        calculateIndex = start + 3000;
    }

    function initializeRound() internal {
        delete currentEntryCount;
        delete roundLiveTime;
        delete roundStartTime;
        delete totalEntryAmount;
        roundStatus = STATE.WAITING;
        ++roundIds;
    }

    /**   @dev generates a random number
     */
    function fullFillRandomness() internal view returns (uint256) {
        return uint256(uint128(bytes16(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))));
    }

    /**
     * @dev returns status of current round
     */
    function getRoundStatus()
        external
        view
        returns (
            uint256 _roundIds,
            STATE _roundStatus,
            uint256 _roundStartTime,
            uint256 _roundLiveTime,
            uint256 _roundDuration,
            uint256 _totalAmount,
            uint256 _entryCount,
            uint256 _minEntranceAmount
        )
    {
        _roundIds = roundIds;
        _roundStatus = roundStatus;
        _roundLiveTime = roundLiveTime;
        _roundStartTime = roundStartTime;
        _roundDuration = roundDuration;
        _minEntranceAmount = minEntranceAmount;
        _totalAmount = totalEntryAmount;
        _entryCount = currentEntryCount;
    }

    function setRoundDuration(uint256 value) external onlyAdmin {
        roundDuration = value;
    }

    function setFeePercent(uint256 _value) external onlyAdmin {
        feePercent = _value;
    }

    function withdrawETH(address receiver, uint256 amount) external onlyAdmin {
        bool sent = payable(receiver).send(amount);
        require(sent, 'fail');
    }

    function withdrawToken(address receiver, address _tokenAddr, uint256 amount) external onlyAdmin {
        if (_tokenAddr == tokenAddress) {
            uint256 balance = IPRC20(_tokenAddr).balanceOf(address(this));
            require(balance >= totalEntryAmount + amount, 'f');
        }

        IPRC20(_tokenAddr).transfer(receiver, amount);
    }

    function setPotContractAddr(address addr) external onlyAdmin {
        potContractAddr = addr;
    }
}