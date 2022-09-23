// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFlypeNFT.sol";
import "./interfaces/IaFLYP.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

contract FlypeTokenSale is AccessControl, ReentrancyGuard {
    /// @notice Contains parameters, necessary for the pool
    /// @dev to see this parameters use getPoolInfo, checkUsedAddress and checkUsedNFT functions
    struct PoolInfo {
        uint256 takenSeats;
        uint256 maxSeats;
        uint256 maxTicketsPerUser;
        // Price in USD
        uint256 ticketPrice;
        uint256 ticketReward;
        uint256 lockup;
        mapping(address => uint256) takenTickets;
    }

    /// @notice pool ID for Econom class
    uint256 public constant ECONOM_PID = 0;
    /// @notice pool ID for Buisness class
    uint256 public constant BUISNESS_PID = 1;
    /// @notice pool ID for First class
    uint256 public constant FIRST_CLASS_PID = 2;

    /// @notice address of Flype NFT
    IFlypeNFT public immutable Flype_NFT;

    /// @notice address of aFLYP
    IaFLYP public immutable aFLYP;

    // Chainlink interface
    AggregatorV3Interface internal priceFeed;

    /// @notice True if minting is paused
    bool public onPause;
    bool public allowedOnly;

    mapping(uint256 => PoolInfo) poolInfo;
    mapping(address => bool) public banlistAddress;

    /// @notice Restricts from calling function with non-existing pool id
    modifier poolExist(uint256 pid) {
        require(pid <= 2, "Wrong pool ID");
        _;
    }

    /// @notice Restricts from calling function when sale is on pause
    modifier OnPause() {
        require(!onPause, "Sale is on pause");
        _;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Only owner can use this function"
        );
        _;
    }

    /// @notice event emmited on each token sale
    /// @dev all events whould be collected after token sale and then distributed
    /// @param user address of buyer
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event Sale(
        address indexed user,
        uint256 pid,
        uint256 takenSeat,
        uint256 reward,
        uint256 lockup,
        uint256 blockNumber,
        uint256 timestamp
    );

    /// @notice event emmited on each pool initialization
    /// @param pid pool id
    /// @param takenSeat № of last taken seat
    /// @param maxSeats maximum number of participants
    /// @param ticketPrice Price in USD
    /// @param ticketReward reward, which must be sent
    /// @param blockNumber on which block transaction was mined
    /// @param timestamp timestamp on the block when it was mined
    event InitializePool(
        uint256 pid,
        uint256 takenSeat,
        uint256 maxSeats,
        uint256 maxTicketsPerUser,
        uint256 ticketPrice,
        uint256 ticketReward,
        uint256 lockup,
        uint256 blockNumber,
        uint256 timestamp
    );

    /// @notice Performs initial setup.
    /// @param _FlypeNFT address of Flype NFT
    constructor(
        IFlypeNFT _FlypeNFT,
        IaFLYP _aFLYP,
        AggregatorV3Interface _priceFeed
    ) ReentrancyGuard() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        Flype_NFT = _FlypeNFT;
        aFLYP = _aFLYP;
        allowedOnly = true;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice Function that allows contract owner to initialize and update update pool settings
    /// @param pid pool id
    /// @param _maxSeats maximum number of participants
    /// @param _ticketPrice amount of eth which must be sended to participate
    /// @param _ticketReward reward, which must be sent
    /// @param _lockup time before token can be collected
    function initializePool(
        uint256 pid,
        uint256 _takenSeats,
        uint256 _maxSeats,
        uint256 _maxTicketPerUser,
        uint256 _ticketPrice,
        uint256 _ticketReward,
        uint256 _lockup
    ) external onlyOwner poolExist(pid) {
        PoolInfo storage pool = poolInfo[pid];
        pool.takenSeats = _takenSeats;
        pool.maxSeats = _maxSeats;
        pool.ticketPrice = _ticketPrice;
        pool.ticketReward = _ticketReward;
        pool.lockup = _lockup;
        pool.maxTicketsPerUser = _maxTicketPerUser;
        emit InitializePool(
            pid,
            pool.takenSeats,
            pool.maxSeats,
            pool.maxTicketsPerUser,
            pool.ticketPrice,
            pool.ticketReward,
            pool.lockup,
            block.number,
            block.timestamp
        );
    }

    /// @notice Function that allows contract owner to ban address from sale
    /// @param user address which whould be banned or unbanned
    /// @param isBanned state of ban
    function banAddress(address user, bool isBanned) external onlyOwner {
        banlistAddress[user] = isBanned;
    }

    function setAllowedOnly(bool newState) external onlyOwner {
        allowedOnly = newState;
    }

    /// @notice Function that allows contract owner to pause sale
    /// @param _onPause state of pause
    function setOnPause(bool _onPause) external onlyOwner {
        onPause = _onPause;
    }

    /// @notice Function that allows contract owner to receive eth from sale
    /// @param receiver address which whould receive eth
    function takeEth(address receiver) external onlyOwner {
        safeTransferETH(receiver, address(this).balance);
    }

    /// @notice emit Sale event for chosen pool
    /// @dev to use it send enough eth
    /// @param pid Pool id

    function buyTokens(uint256 pid, uint256 amountOfTickets)
        external
        payable
        OnPause
        nonReentrant
        poolExist(pid)
    {
        require(!banlistAddress[_msgSender()], "This address is banned");
        require(amountOfTickets > 0, "Amount of tickets cannot be zero");
        if (allowedOnly)
            require(Flype_NFT.allowList(_msgSender()), "Not in WL");
        PoolInfo storage pool = poolInfo[pid];
        require(pool.takenSeats < pool.maxSeats, "No seats left");
        require(
            pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser,
            "User cannot buy more than maxTicketsPerUser"
        );
        uint256 priceinEth = getTicketPriceInEth(pid);
        uint256 totalPayment;
        uint256 totalRewards;

        for (
            uint256 i = 0;
            i < amountOfTickets &&
                pool.takenSeats < pool.maxSeats &&
                pool.takenTickets[_msgSender()] < pool.maxTicketsPerUser;
            i++
        ) {
            totalPayment += priceinEth;
            pool.takenSeats++;
            pool.takenTickets[_msgSender()]++;
            totalRewards += pool.ticketReward;

            emit Sale(
                _msgSender(),
                pid,
                pool.takenSeats,
                pool.ticketReward,
                pool.lockup,
                block.number,
                block.timestamp
            );
        }

        // uint256 totalPaymentInEth = totalPayment / getEthPriceInUSD();

        require(msg.value >= totalPayment, "Insufficient funds sent");
        aFLYP.mintFor(_msgSender(), totalRewards);
        if (msg.value > totalPayment)
            safeTransferETH(_msgSender(), msg.value - totalPayment);
    }

    /// @notice get pool setting and parameters
    /// @param pid pool id
    /// @return takenSeats № of last taken seat
    /// @return maxSeats maximum number of participants
    /// @return maxTicketsPerUser maximum number of participations per user
    /// @return ticketPrice amount of eth which must be send to participate in pool
    function getPoolInfo(uint256 pid)
        external
        view
        poolExist(pid)
        returns (
            uint256 takenSeats,
            uint256 maxSeats,
            uint256 maxTicketsPerUser,
            uint256 ticketPrice,
            uint256 ticketReward,
            uint256 lockup
        )
    {
        return (
            poolInfo[pid].takenSeats,
            poolInfo[pid].maxSeats,
            poolInfo[pid].maxTicketsPerUser,
            poolInfo[pid].ticketPrice,
            poolInfo[pid].ticketReward,
            poolInfo[pid].lockup
        );
    }

    function getUserTicketsAmount(uint256 pid, address user)
        external
        view
        returns (uint256)
    {
        return (poolInfo[pid].takenTickets[user]);
    }

    /// @notice sends eth to given address
    /// @param to address of receiver
    /// @param value amount of eth to send
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function getEthPriceInUSD() public view returns (uint256) {
        (, int256 price, , uint256 timeStamp, ) = priceFeed.latestRoundData();

        require(timeStamp > 0, "Round not complete");
        return uint256(price * 1e10);
    }

    function getTicketPriceInEth(uint256 pid)
        public
        view
        poolExist(pid)
        returns (uint256)
    {
        uint256 ethPriceBy18Decimals = getEthPriceInUSD();
        return ((poolInfo[pid].ticketPrice * 1e18) / ethPriceBy18Decimals);
    }
}