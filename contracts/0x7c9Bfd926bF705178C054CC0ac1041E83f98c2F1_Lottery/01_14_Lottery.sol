//SPDX-License-Identifier:UNLICENSED

pragma solidity =0.8.14; // Audit change to be made.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VRFv2Consumer.sol";
import "./mock_router/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./libraries/RaffleInfo.sol";
import "./interfaces/ILotteryEvents.sol";
import "hardhat/console.sol";

contract Lottery is ReentrancyGuard, Initializable, VRFv2Consumer, ILotteryEvents {
    using SafeERC20 for IERC20;
    uint16 public profitPercent; // in BP
    uint16 public burnPercent;
    uint16 public profitSplit1BP;
    uint16 public basisPoints;
    uint16 public taxBP;
    uint256 public totalRaffles;
    uint256 public totalBurnAmount;
    uint256 public totalRevenue;

    address payable public profitWallet1;
    address payable public profitWallet2;
    address public operator;
    address public admin;
    address public WETH;
    IUniswapV2Router02 public router;

    mapping(uint256 => RaffleStorage.RaffleInfo) public Raffle;
    mapping(uint256 => RaffleStorage.RaffleInfo1) public Raffle1;

    // stores ticket numbers for every user for a given raffle. RaffleNumber => UserAddress => UserTickets
    mapping(uint256 => mapping(address => RaffleStorage.UserTickets)) userTicketNumbersInRaffle;

    mapping(uint256 => uint256) public BurnAmountPerRaffle;

    mapping(uint256 => uint256) public requestIdPerRaffle;
    mapping(uint256 => uint256) private randomNumberPerRaffle;

    modifier onlyAdmin() {
        require(msg.sender == admin, "You are not the admin.");
        _;
    }

    modifier onlyOperator() {
        require(
            msg.sender == operator || msg.sender == admin,
            "You are not the operator."
        );
        _;
    }

    struct init {
        uint16 _basisPoints;
        uint16 _profitPercent;
        uint16 _burnPercent;
        uint16 _profitSplit1BP;
        uint16 _taxBP;
        uint64 _subscriptionId;
        address _operator;
        address _admin;
        address _router;
        address payable _profitWallet1;
        address payable _profitWallet2;
        address _weth;
        address _vrfCoordinator;
        bytes32 _keyhash;
    }
    event endtimeUpdated(uint256 _raffleNumber, uint32 _endtime);

    /**
     * @dev Sets the values for
        uint16 _basisPoints  Kept as 10000
        uint16 _profitPercent, * profit percent to be deducted from the fee paid from ticket buying.
        uint16 _burnPercent, * burn percent to be deducted from the fee paid from ticket buying.
        uint16 _profitSplit1BP. * profit percent 
        uint64 subscriptionId, *id to be received from the Chainlink VRF
        address _operator, *ROLE to be declared for the operator only functions.
        address _admin,    *ROLE to be declared for the admin only functions.
        address _router, * UNISWAP or any other DEX Router contract, for the swap functions.
        address payable _profitWallet1, 
        address payable _profitWallet2,
        address _weth, * WETH Address for the said DEX
        address _vrfCoordinator
        bytes32 _keyhash
    
     */
    function initialize(init memory params) external initializer {
        // require(params._operator != address(0), "Invalid address");
        // require(params._admin != address(0), "Invalid address");
        // require(params._router != address(0), "Invalid address");
        // require(params._profitWallet1 != address(0), "Invalid address");
        // require(params._profitWallet2 != address(0), "Invalid address");
        // require(params._weth != address(0), "Invalid address");
        // require(params._vrfCoordinator != address(0), "Invalid address");
        // require(
        //     params._profitPercent + params._burnPercent < params._basisPoints,
        //     "Cannot be more than 100%"
        // );
        // require(params._profitSplit1BP < params._basisPoints, "Cannot be more than 100%");
        // require(params._taxBP < params._basisPoints, "TaxBP cannot be more than 100%");

        // operator = params._operator;
        // admin = params._admin;
        // router = IUniswapV2Router02(params._router);
        // profitWallet1 = params._profitWallet1;
        // profitWallet2 = params._profitWallet2;
        // WETH = params._weth;
        // basisPoints = params._basisPoints;
        // profitPercent = params._profitPercent;
        // burnPercent = params._burnPercent;
        // profitSplit1BP = params._profitSplit1BP;
        // taxBP = params._taxBP;
        // initializeV2Consumer(
        //     params._subscriptionId,
        //     params._vrfCoordinator,
        //     params._keyhash
        // );
    }

    /**
     * @dev function to be called by the operator.
     *
     * function takes {raffleNumber} as argument.
     *
     * This function will be called by the backend to create the requesID for the random number for the particulare raffle.
       The requestId will be saved in the mapping requestId => raffleNumber.
     */

    function getRandomNumber(uint256 _raffleNumber) external onlyOperator {
        requestIdPerRaffle[requestRandomWords()] = _raffleNumber;
    }

    /**
     * @dev Sets the values for raffleName, maxTickets, ticketPrice, startTime, endTime, rewardToken, and isTaxed(Shows if the token is a taxable token).
     * Values are set at the time of creating a new Raffle.
     * Start time should be always less than the endTime.
     * The function can only be called by the Operator role.
     */
    function createRaffle(
        string memory _raffleName,
        uint16 _maxTickets,
        uint256 _ticketPrice,
        uint32 _startTime,
        uint32 _endTime,
        address _rewardToken,
        bool _isTaxed
    ) public onlyOperator {
        require(
            _startTime > block.timestamp && _startTime < _endTime,
            "Time values invalid!"
        );
        totalRaffles++;
        RaffleStorage.RaffleInfo storage raffleEntry = Raffle[totalRaffles];
        RaffleStorage.RaffleInfo1 storage raffleEntry1 = Raffle1[totalRaffles];

        raffleEntry.raffleName = _raffleName;
        raffleEntry.maxTickets = _maxTickets;
        raffleEntry.number = totalRaffles;
        raffleEntry.ticketPrice = _ticketPrice;
        raffleEntry.startTime = _startTime;
        raffleEntry.endTime = _endTime;
        raffleEntry1.raffleRewardToken = _rewardToken;
        raffleEntry1.burnPercent = burnPercent;
        raffleEntry1.rewardPercent = basisPoints - profitPercent - burnPercent;
        raffleEntry1.isTaxed = _isTaxed;
        emit RaffleCreated(
            totalRaffles,
            _raffleName,
            _maxTickets,
            _ticketPrice,
            _startTime,
            _endTime,
            basisPoints - profitPercent - burnPercent,
            _rewardToken
        );
    }

    /**
     * @dev buyTicket function is to becalled by the User to buy raffle tickets.
     * Raffle number is to be provided to buy ticket from the specific raffle.
     * raffle should not be over at the time of buying ticket.
     *
     * The ticket price should be paid in the multiples of number of tickets.
     */

    function buyTicket(uint256 _raffleNumber, uint16 _noOfTickets)
        external
        payable
        nonReentrant
    {
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];

        require(raffleInfo.endTime > block.timestamp, "Buying ticket time over!");
        require(
            raffleInfo.ticketCounter + _noOfTickets <= raffleInfo.maxTickets,
            "Max amount of tickets exceeded!"
        );
        require(
            msg.value == _noOfTickets * raffleInfo.ticketPrice,
            "Ticket fee exceeds amount!!"
        );
        uint16 ticketStart = raffleInfo.ticketCounter + 1;
        for (uint16 i = 1; i <= _noOfTickets; i++) {
            raffleInfo.ticketCounter += 1;
            userTicketNumbersInRaffle[_raffleNumber][msg.sender].ticketsNumber.push(
                raffleInfo.ticketCounter
            );

            raffleInfo1.ticketOwner[raffleInfo.ticketCounter] = msg.sender;
        }
        totalBurnAmount += (msg.value * raffleInfo1.burnPercent) / basisPoints;
        BurnAmountPerRaffle[_raffleNumber] +=
            (msg.value * raffleInfo1.burnPercent) /
            basisPoints;
        uint256 profitAmount = splitProfit(_raffleNumber, _noOfTickets);
        totalRevenue +=
            (msg.value * (basisPoints - raffleInfo1.rewardPercent)) /
            basisPoints;

        emit BuyTicket(
            _raffleNumber,
            msg.sender,
            ticketStart,
            raffleInfo.ticketCounter,
            BurnAmountPerRaffle[_raffleNumber],
            totalRevenue,
            profitAmount
        );
    }

    /**
     * @dev function to be called byy the Operator.
     *
     * functions needs {Raffle number} as an argument to declare winner in the given raffle.
     * Raffle should be over i.e. the endTime should be met, to run this function.
     * This function declare the winner from chainlink VRF random number and then swaps the amount of ether to the amount of token
       to be provided as the reward.
     */

    function declareWinner(uint256 _raffleNumber) external nonReentrant onlyOperator {
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];

        require(
            block.timestamp > raffleInfo.endTime ||
                raffleInfo.ticketCounter == raffleInfo.maxTickets,
            "Raffle not over yet!"
        );
        require(!raffleInfo1.isWinnerDeclared, "Winner Already Declared");
        require(randomNumberPerRaffle[_raffleNumber] > 0, "Random number not generated.");
        uint256 totalTicketsSold = raffleInfo.ticketCounter;

        uint256 winnerTicketNumber = (randomNumberPerRaffle[_raffleNumber] %
            totalTicketsSold) + 1;

        raffleInfo1.winningTicket = winnerTicketNumber;

        raffleInfo1.winner = raffleInfo1.ticketOwner[winnerTicketNumber];

        raffleInfo1.isWinnerDeclared = true;

        uint256 rewardInEth = ((raffleInfo.ticketPrice * raffleInfo.ticketCounter) *
            raffleInfo1.rewardPercent) / basisPoints;

        uint256 tokenAmount = swapRewardInToken(
            raffleInfo1.raffleRewardToken,
            raffleInfo1.isTaxed,
            rewardInEth
        );

        raffleInfo1.raffleRewardTokenAmount = tokenAmount;

        emit WinnerDeclared(
            _raffleNumber,
            winnerTicketNumber,
            raffleInfo1.ticketOwner[winnerTicketNumber],
            tokenAmount,
            rewardInEth
        );
    }

    /**
     * @dev function to be called by the winner of the raffle.
     *
     * This function takes the {raffle number} as the argument.
     * This function can only be called by the winner of a particular raffle.
     * Reward can only be claimed once.
     * This function transfers the reward token to the winner.
     */

    function claimReward(uint256 _raffleNumber) external nonReentrant returns (bool) {
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];
        require(msg.sender == raffleInfo1.winner, "You are not the winner");
        require(!raffleInfo1.isClaimed, "Reward Already Claimed");

        uint256 rewardAmount = raffleInfo1.raffleRewardTokenAmount;

        raffleInfo1.isClaimed = true;

        bool success = IERC20(raffleInfo1.raffleRewardToken).transfer(
            msg.sender,
            rewardAmount
        );
        require(success, "Token Transfer Failed");

        emit RewardClaimed(
            _raffleNumber,
            msg.sender,
            raffleInfo1.raffleRewardToken,
            rewardAmount
        );

        return success;
    }

    /**
     * @dev function to be called by the Admin.
     *
     * Burn amount is stored in the smart contract at every sale of the ticket.
     *
     * Function takes the {address _to} as an argument.
     * It transfers the Ether stored as burnAmount in the smart contract and transfers to the address given.
     * Total burn gets depleted but for information purpose the value of burn amount per raffle is stored on the smart contract.
     */

    function collectBurnReward(address _to)
        external
        onlyAdmin
        nonReentrant
        returns (bool)
    {
        uint256 amount = totalBurnAmount;
        totalBurnAmount = 0;
        (bool success, ) = _to.call{value: amount}("");
        require(success);
        emit burnCollected(amount, _to);
        return success;
    }

    /**
     * @dev function to be called by the declareWinner function.
     *
     * function takes {token address, isTaxed , amount of ether} as argument.
     *
     * Function takes the ether and swaps it with the token address given from the router given by the admin.
     */

    function swapRewardInToken(
        address _rewardToken,
        bool istaxed,
        uint256 _reward
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _rewardToken;
        uint256[] memory amountOut = router.getAmountsOut(_reward, path);
        uint256 amountOutMin;
        if (istaxed) {
            amountOutMin = (amountOut[1] * (basisPoints - taxBP - 50)) / basisPoints;
            uint256 amountBefore = IERC20(_rewardToken).balanceOf(address(this));
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _reward}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + 60
            );
            uint256 amountAfter = IERC20(_rewardToken).balanceOf(address(this));
            return (amountAfter - amountBefore);
        } else {
            amountOutMin = (amountOut[1] * (basisPoints - 50)) / basisPoints;

            uint256[] memory amounts = router.swapExactETHForTokens{value: _reward}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + 60
            );
            return amounts[1];
        }
    }

    /**
     * @dev function called by the buyTicket function.
     *
     * It takes {raffleNumber, _noOfTickets} as arguments.
     * Function is used to transfer the profit amount set by the admin in every ticket sale, to the profit 
       wallets.
     * 
     */

    function splitProfit(uint256 _raffleNumber, uint16 _noOfTickets)
        internal
        returns (uint256)
    {
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];

        uint256 totalAmount = _noOfTickets * raffleInfo.ticketPrice;
        uint16 profitpercent = basisPoints -
            raffleInfo1.rewardPercent -
            raffleInfo1.burnPercent;
        uint256 profitAmount = (profitpercent * totalAmount) / basisPoints;
        uint256 splitWallet1Amount = (profitAmount * profitSplit1BP) / basisPoints;
        (bool sent, ) = profitWallet1.call{value: splitWallet1Amount}("");
        uint256 splitWallet2Amount = profitAmount - splitWallet1Amount;
        (bool success, ) = profitWallet2.call{value: splitWallet2Amount}("");
        require(sent && success);
        return (profitAmount);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {burnPercent, profitPercent} as arguments.
     *
     * Function updates the values for the profit and burn percent that should be deducted from the sale of tickets.
     */

    function updateBurnAndProfitPercent(uint16 _burnBp, uint16 _profitBp)
        external
        onlyAdmin
    {
        require(_burnBp + _profitBp < basisPoints, "Cannot be more than 100%");
        burnPercent = _burnBp;
        profitPercent = _profitBp;
        emit BurnAndProfitPercentUpdated(_burnBp, _profitBp);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {address profitwallet1} as arguments.
     *
     * Updates the address for the profit wallet 1.
     */

    function updateProfit1Address(address payable _profitWallet1) external onlyAdmin {
        require(_profitWallet1 != address(0), "Invalid address");
        profitWallet1 = _profitWallet1;
        emit ProfitWallet1Updated(_profitWallet1);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {address profitwallet2} as arguments.
     *
     * Updates the address for the profit wallet 2.
     */

    function updateProfit2Address(address payable _profitWallet2) external onlyAdmin {
        require(_profitWallet2 != address(0), "Invalid address");
        profitWallet2 = _profitWallet2;
        emit ProfitWallet2Updated(_profitWallet2);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {uint16 profitSplitPercent} as arguments.
     *
     * Updates the percent that should divide the profit in profit wallet 1 and remaing in the profit wallet 2.
     */

    function updateProfitSplitPercent(uint16 _bp) external onlyAdmin {
        require(_bp < basisPoints, "Cannot be more than 100%");
        profitSplit1BP = _bp;
        emit ProfitSplitPercentUpdated(_bp, basisPoints - _bp);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {address newAdmin} as arguments.
     *
     * Updates the address for the new admin address.
     */

    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid address");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {uint raffleNumber, address tokenAddress} as arguments.
     *
     * Updates the address for the reward token in the given raffle.
     * Token address can be updated in the raffle before its startTime, once the raffle is started or ended the reward token 
       cannot be changed. 
     */

    function updateRewardToken(uint256 _raffleNumber, address _rewardToken)
        external
        onlyAdmin
    {
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];

        require(block.timestamp < raffleInfo.startTime, "Raffle already started.");
        raffleInfo1.raffleRewardToken = _rewardToken;
        emit RewardTokenUpdate(_raffleNumber, _rewardToken);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {uint16 _taxBP} as arguments with 10000 as basis points
     *
     * Updates the address for the Operator role.
     */

    function updateTaxBP(uint16 _taxBP) external onlyAdmin {
        taxBP = _taxBP;
        emit taxBPUpdated(_taxBP);
    }

    /**
     * @dev Function to be called by the Admin.
     *
     * Function takes {address newOperator} as arguments.
     *
     * Updates the address for the Operator role.
     */

    function changeOperator(address _address) external onlyAdmin {
        require(_address != address(0), "Invalid address");
        operator = _address;
        emit OperatorChanged(_address);
    }

    /**
     * @dev Function to be called by the User.
     *
     * Function takes {raffleNumber, address ownerOfTickets} as arguments.
     *
     * Function returns the array for the ticket numbers owned by the User.
     */

    function checkYourTickets(uint256 _raffleNo, address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return userTicketNumbersInRaffle[_raffleNo][_owner].ticketsNumber;
    }

    /**
     * @dev Function to be called by the anyone.
     *
     * Function takes {raffleNumber} as argument.
     * Function returns the boolean for if the raffle is over or not i.e. the endTIme is met or not.
     *
     */

    function checkRaffleOver(uint256 _raffleNumber) external view returns (bool) {
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        return
            (block.timestamp > raffleInfo.endTime) ||
            (raffleInfo.ticketCounter == raffleInfo.maxTickets);
    }

    /**
     * @dev Function to be called by the anyone.
     *
     * Function takes {raffleNumber} as argument.
     * Function returns the {boolean, address, winningTicketNumber} for winner, if the winner is declared.
     *
     */

    function isWinnerDeclared(uint256 _raffleNumber)
        external
        view
        returns (
            bool,
            address,
            uint256
        )
    {
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];
        return (
            raffleInfo1.isWinnerDeclared,
            raffleInfo1.winner,
            raffleInfo1.winningTicket
        );
    }

    /**
     * @dev Function to be called by the anyone.
     *
     * Function takes {raffleNumber} as argument.
     * Function returns the boolean for if the raffle reward is claimed or not.
     *
     */

    function isRewardClaimed(uint256 _raffleNumber) external view returns (bool) {
        RaffleStorage.RaffleInfo1 storage raffleInfo1 = Raffle1[_raffleNumber];
        return raffleInfo1.isClaimed;
    }

    /**
     * @dev Function to be called by the anyone.
     *
     * Function takes {raffleNumber, ticketNumber} as arguments.
     * Function returns the address for the owner of a specific ticket number.
     *
     */

    function checkTicketOwner(uint256 _raffleNumber, uint16 _ticketNumber)
        external
        view
        returns (address)
    {
        return Raffle1[_raffleNumber].ticketOwner[_ticketNumber];
    }

    /**
     * @dev function to be called to check whether the random number is generated or not.
     *
     * function takes {raffleNumber} as argument.
     *
     * To be checked by the backend, only after this function will return true, the declare winner function to be called.
     */

    function raffleRandomGenerated(uint256 _raffleNumber) external view returns (bool) {
        if (randomNumberPerRaffle[_raffleNumber] > 0) return true;
    }

    /**
     * @dev function to be called by the chainlink vrf coordinator.
     *
     * Function will be called by the external contract to provide the random words that will be further used in the declareWinner function.
     */

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords /* internal function (chainlink keepers automatically call this function */
    ) internal override {
        randomNumberPerRaffle[requestIdPerRaffle[requestId]] = randomWords[0];
    }

    function updateRaffleEndtime(uint256 _raffleNumber, uint32 _endTime)
        external
        onlyAdmin
    {
        require(_endTime > block.timestamp, "Provide a future endtime");
        RaffleStorage.RaffleInfo storage raffleInfo = Raffle[_raffleNumber];
        raffleInfo.endTime = _endTime;
        emit endtimeUpdated(_raffleNumber, _endTime);
    }
}