// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpacecowsLottery is ReentrancyGuard, Ownable {
    address public immutable BURN_ADDRESS;
    uint256 private lotteryId;
    uint256 public maxTicketsPerTransaction;

    IERC20 public smilkToken;

    enum Status {
        Open,
        Close,
        WinnerFound
    }

    struct Lottery {
        Status status;
        uint32 ticketId;
        uint16 playerId;
        uint32 finalNumber;
        uint16 winnerPlayerId;
        uint64 startTime;
        uint64 endTime;
        uint128 ticketPriceInSmilk;
        uint128 amountCollectedInSmilk;
        address winner;
    }

    struct Reward {
        string chain;
        string rewardTitle;
        string rewardLink;
        string rewardTransaction;
    }

    struct Player {
        uint32 ticketStart;
        uint32 ticketEnd;
        uint32 quantityTickets;
        address owner;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Reward) private _rewards;
    mapping(uint256 => mapping(uint256 => Player)) private _tickets;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _smilkTokenAddress: address of the SMILK token
     */
    constructor(address _smilkTokenAddress) {
        smilkToken = IERC20(_smilkTokenAddress);

        BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _numberOfTickets: amount of tickets to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint32 _numberOfTickets)
        external
        notContract
        nonReentrant
    {
        Lottery storage selectLottery = _lotteries[_lotteryId];  
        require(_numberOfTickets != 0, "No ticket amount specified");
        require(_numberOfTickets < maxTicketsPerTransaction + 1, "Too many tickets");

        require(selectLottery.status == Status.Open, "Lottery is not open");
        require(block.timestamp < selectLottery.endTime, "Lottery is over");

        unchecked {
            // Calculate number of SMILK to this contract
            uint256 amountSmilkToTransfer = selectLottery.ticketPriceInSmilk * _numberOfTickets;

            // Transfer smilk tokens to this contract
            smilkToken.transferFrom(address(msg.sender), address(this), amountSmilkToTransfer);

            uint256 endToken = selectLottery.ticketId;
            for (uint256 i = 1; i < _numberOfTickets; ++i) {
                ++endToken;
            }

            Player storage tmpPlayer = _tickets[_lotteryId][selectLottery.playerId];
            tmpPlayer.quantityTickets = _numberOfTickets;
            tmpPlayer.ticketStart = uint32(selectLottery.ticketId);
            tmpPlayer.ticketEnd = uint32(endToken);
            tmpPlayer.owner = msg.sender;

            selectLottery.playerId = uint16(selectLottery.playerId + 1);
            selectLottery.ticketId = uint32(endToken + 1);

            // Increment the total amount collected for the lottery round
            selectLottery.amountCollectedInSmilk = uint128(selectLottery.amountCollectedInSmilk + amountSmilkToTransfer);
        }
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by owner
     */
    function closeLottery(uint256 _lotteryId) external onlyOwner nonReentrant {
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp > _lotteries[_lotteryId].endTime, "Lottery not over");

        _lotteries[_lotteryId].status = Status.Close;
    }

    /**
     * @notice Draw the final number, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _tweetId: tweet id from the tweet about the lottery is closed
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryFinal(uint256 _lotteryId, uint256 _tweetId)
        external
        onlyOwner
        nonReentrant
    {
        Lottery storage selectLottery = _lotteries[_lotteryId];
        require(selectLottery.status == Status.Close, "Lottery not close");
        uint256 tmpTicketId = selectLottery.ticketId;

        // Calculate the finalNumber based on the tweet ID
        if (tmpTicketId != 0) {
            uint256 randomNumber = random(_tweetId);
            uint256 finalNumber = randomNumber % tmpTicketId;

            unchecked {
                for (uint256 i = 0; i < selectLottery.playerId; ++i) {
                    if (finalNumber <= _tickets[_lotteryId][i].ticketEnd && finalNumber >= _tickets[_lotteryId][i].ticketStart) {
                        selectLottery.winner = _tickets[_lotteryId][i].owner;
                        selectLottery.winnerPlayerId = uint16(i);
                        break;
                    }
                }
            }

            // Update internal statuses for lottery
            selectLottery.finalNumber = uint32(finalNumber);
        }

        selectLottery.status = Status.WinnerFound;
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _ticketPriceInSmilk: price of a ticket in SMILK
     * @param _rewardChain: Which blockchain the reward is on
     * @param _rewardTitle: Description of the reward like Spacecows #7544
     * @param _rewardLink: Link to rewards marketplace
     */
    function startLottery(
        uint64 _endTime,
        uint128 _ticketPriceInSmilk,
        string memory _rewardChain,
        string memory _rewardTitle,
        string memory _rewardLink
    ) external onlyOwner {
        uint256 currentLotteryId = lotteryId;

        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.WinnerFound),
            "Not time to start lottery"
        );

        unchecked {
            ++currentLotteryId;
        }
        
        Lottery storage tmpLottery = _lotteries[currentLotteryId];
        tmpLottery.status = Status.Open;
        tmpLottery.startTime = uint64(block.timestamp);
        tmpLottery.endTime = _endTime;
        tmpLottery.ticketPriceInSmilk = _ticketPriceInSmilk;

        Reward storage tmpReward = _rewards[currentLotteryId];
        tmpReward.chain = _rewardChain;
        tmpReward.rewardTitle = _rewardTitle;
        tmpReward.rewardLink = _rewardLink;

        lotteryId = currentLotteryId;
    }

    /**
     * @notice Set blockchain transaction for reward winner
     * @param _rewardId: reward id
     * @param _rewardTransaction: blockchain transaction url to prove NFT is sent 
     */
    function setRewardTransaction(uint256 _rewardId, string memory _rewardTransaction) external onlyOwner {
        require(_lotteries[_rewardId].winner != address(0), "Winner not found");

        Reward storage tmpReward = _rewards[_rewardId];
        tmpReward.rewardTransaction = _rewardTransaction;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(smilkToken), "Cannot be SMILK token");

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice Set SMILK ticket price
     * @dev Only callable by owner
     * @param _ticketPriceInSmilk: price of a ticket in SMILK
     */
    function setTicketPriceInSmilk(uint256 _lotteryId, uint128 _ticketPriceInSmilk)
        external
        onlyOwner
    {
        require(_ticketPriceInSmilk != 0, "Must be > 0");

        Lottery storage tmpLottery = _lotteries[_lotteryId];
        tmpLottery.ticketPriceInSmilk = _ticketPriceInSmilk;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxTicketsPerTransaction(uint256 _maxNumberTicketsPerRound) external onlyOwner {
        require(_maxNumberTicketsPerRound != 0, "Must be > 0");
        maxTicketsPerTransaction = _maxNumberTicketsPerRound;
    }

    /**
     * @notice Burn all SMILK token inside contract
     * @dev Only callable by owner
     */
    function burnSmilk() external onlyOwner nonReentrant {
        uint256 smilkBalance = smilkToken.balanceOf(address(this));
        smilkToken.transfer(address(BURN_ADDRESS), smilkBalance);
    }

    /**
     * @notice View current ticket id
     */
    function viewCurrentTicketId() external view returns (uint256) {
        return _lotteries[lotteryId].ticketId;
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view returns (uint256) {
        return lotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View reward information
     * @param _rewardId: reward id same as lottery id
     */
    function viewReward(uint256 _rewardId) external view returns (Reward memory) {
        return _rewards[_rewardId];
    }

    /**
     * @notice View ticket information
     * @param _lotteryId: lottery id
     * @param _playerId: player id
     */
    function viewTicket(uint256 _lotteryId, uint32 _playerId) external view returns (Player memory) {
        return _tickets[_lotteryId][_playerId];
    }

    /**
     * @notice Get all user owned tickets by lottery id
     * @param _lotteryId: lottery id
     * @param _player: user address
     */
    function playerTicketsByLottery(uint256 _lotteryId, address _player) external view returns (uint32[] memory) {
        Lottery memory currentLottery = _lotteries[_lotteryId];
        uint256 index = 0;

        uint256 ticketCount = _playerTicketCountByLottery(_lotteryId, _player);  
        uint32[] memory tickets = new uint32[](ticketCount);
    
        for (uint256 i = 0; i < currentLottery.ticketId; ++i) {
            Player memory tmpPlayer = _tickets[_lotteryId][i];
            
            if (tmpPlayer.owner == _player) {
                for (uint32 j = tmpPlayer.ticketStart; j <= tmpPlayer.ticketEnd; ++j) {
                    tickets[index] = j;
                    ++index;
                }
            }
        }

        return tickets;
    }

    /**
     * @notice Get count of all tickets user owned by lottery id by calling interval function
     * @param _lotteryId: lottery id
     * @param _player: user address
     */
    function playerTicketCountByLottery(uint256 _lotteryId, address _player) external view returns (uint256) {
        return _playerTicketCountByLottery(_lotteryId, _player);
    }

    /**
     * @notice Get count of all tickets user owned by lottery id
     * @param _lotteryId: lottery id
     * @param _player: user address
     * @dev Only callable by contract
     */
    function _playerTicketCountByLottery(uint256 _lotteryId, address _player) internal view returns (uint32) {
        Lottery memory currentLottery = _lotteries[_lotteryId];
        uint32 index = 0;
        for (uint32 i = 0; i < currentLottery.ticketId; ++i) {
            Player memory tmpPlayer = _tickets[_lotteryId][i];
            
            if (tmpPlayer.owner == _player) {
                index += tmpPlayer.quantityTickets;
            }
        }

        return index;
    }

    /**
    * @param _tweetId: tweet id from the tweet about the lottery is closed
     */
    function random(uint256 _tweetId) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_tweetId, lotteryId, _lotteries[lotteryId].ticketId)));
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}