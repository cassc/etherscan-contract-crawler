// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract MOMO_Relaunched is ERC20, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    
    // Variables for Uniswap
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    // Constants
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_VESTING_AMOUNT = 500e6 * 1e18;
    uint256 public constant VESTING_DURATION = 420 hours;
    uint256 public constant MAX_WITHDRAWAL_AMOUNT = 1000000000;
    
    // State variables
    uint256 public taxRate = 1;
    uint256 public sellTaxRate = 99;
    uint256 public buyTaxRate = 99;
    uint256 public accumulatedTax = 0;
    uint256 public redistributionThreshold = 420000 * 10 ** decimals();
    uint256 public rewardPool;
    uint256 public minBet = 100000;
    uint256 public houseEdge = 2;
    uint256 public totalPot;
    uint256 public currentLotteryIndex = 0;
    uint256 public cliffDuration = 30 days;
    mapping(uint256 => Ticket) public tickets;
    uint256 public currentTicketID = 0;
    uint256 public lotteryVersion = 0;
    bool public isLotteryLive = false;
    uint256 public ticketPriceInMOMO = 100000; // You can initialize this with an initial value or set it post-deployment


    // Lottery
    struct Ticket {
    address owner;
    uint256 lotteryVersion;
}

    // Betting
    enum BetOutcome { WIN, LOSE, DRAW }
    enum BetChoice { HEADS, TAILS }
    struct Bet {
        address user;
        uint256 amount;
        BetChoice choice;
        BetOutcome outcome;
        uint256 potentialWinning;
        uint256 blockToResolve;
    }
    mapping(bytes32 => Bet) public bets;

    // Mars Missions
    enum MissionOutcome { LOSE_ALL, LOSE_HALF, PUSH, WIN_SMALL, WIN_BIG }
    struct Mission {
        uint256 amountSent;
        MissionOutcome outcome;
    }
    mapping(address => Mission) public userMissions;

    // Vesting
    struct VestingInfo {
        uint256 totalAmount;
        uint256 startTime;
        uint256 claimedAmount;
        uint256 duration;
        uint256 lastClaimTime;
    }
    mapping(address => VestingInfo) public vestingBeneficiaries;

    // Events
    event TicketPurchased(address indexed user, uint256 amount);
    event TicketPriceUpdated(uint256 newPrice);
    event WinnerDrawn(address indexed winner, uint256 prizeAmount);
    event BetPlaced(bytes32 indexed betId, address indexed user, uint256 amount, BetChoice choice);
    event BetResolved(bytes32 indexed betId, BetOutcome outcome, uint256 amount);
    event MarsMissionStarted(address indexed participant, uint256 amount);
    event MarsMissionCompleted(address indexed participant, MissionOutcome outcome, uint256 amount);
    event TaxRedistributed(uint256 tokensSwapped, uint256 ethReceived);
    event VestedTokensClaimed(address indexed beneficiary, uint256 amount);
    event TokenBurned(uint256 amount);
    event CallerRewarded(address indexed caller, uint256 reward);
    event TokensSwapped(uint256 tokensSwapped, uint256 ethReceived);
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);
    event LotteryReset();

       constructor() ERC20("CYBERTRUCK", "CYBR") {
    _mint(msg.sender, 800 * 10**12 * 10**18);
    // Initialize Uniswap Router
    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
}    
    function setPairAddress() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f).getPair(address(this), uniswapV2Router.WETH());
        require(uniswapV2Pair != address(0), "Pair address not found");
    }

    // Burning Function
    function burn(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "Cannot burn more than you hold");
        _transfer(msg.sender, BURN_ADDRESS, amount);
    }

    // Check Burn Amount
    function totalBurned() external view returns (uint256) {
        return balanceOf(BURN_ADDRESS);
    }

    // Tax functions
    // Set TaxRate
    function setTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate >= 0 && newTaxRate <= 99, "Invalid tax rate");
        taxRate = newTaxRate;
    }
    // Set BuyTax
    function setBuyTaxRate(uint256 newBuyTaxRate) external onlyOwner {
        require(newBuyTaxRate >= 0 && newBuyTaxRate <= 99, "Invalid buy tax rate");
        buyTaxRate = newBuyTaxRate;
    }
    // Set SellTax
    function setSellTaxRate(uint256 newSellTaxRate) external onlyOwner {
        require(newSellTaxRate >= 0 && newSellTaxRate <= 99, "Invalid sell tax rate");
        sellTaxRate = newSellTaxRate;
    }


    function transfer(address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 tax = 0;
        if (recipient == uniswapV2Pair) {
            // It's a sell
            tax = (amount * sellTaxRate) / 100;
        } else {
            // It's a buy
            tax = (amount * buyTaxRate) / 100;
        }

        uint256 amountAfterTax = amount - tax;
        accumulatedTax += tax;
        super.transfer(recipient, amountAfterTax);

        if (tax > 0) {
            super.transfer(address(this), tax);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override nonReentrant returns (bool) {
        uint256 tax = 0;
        if (recipient == uniswapV2Pair) {
            // It's a sell
            tax = (amount * sellTaxRate) / 100;
        } else {
            // It's a buy
            tax = (amount * buyTaxRate) / 100;
        }

        uint256 amountAfterTax = amount - tax;
        accumulatedTax += tax;
        super.transferFrom(sender, recipient, amountAfterTax);

        if (tax > 0) {
            super.transferFrom(sender, address(this), tax);
        }
        return true;
    }

    function redistributeTax() external nonReentrant {
        require(accumulatedTax >= redistributionThreshold, "Insufficient accumulated tax for redistribution");
        uint256 reward = (accumulatedTax * 42) / 1000; // 4.2% of accumulatedTax
        accumulatedTax -= reward;
        uint256 halfTax = accumulatedTax / 2;

        // Swap tokens for ETH
        uint256 ethReceived = _swapTokensForETH(halfTax);

        // Add liquidity to Uniswap
        _addLiquidity(halfTax, ethReceived);
        accumulatedTax = 0;

        // Reward the caller
        super.transfer(msg.sender, reward);
        emit CallerRewarded(msg.sender, reward);
    }

    function getPathForTokenToETH() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        return path;
    }

    function _swapTokensForETH(uint256 tokenAmount) internal returns (uint256) {
        uint256 initialBalance = address(this).balance;

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Swap tokens for ETH
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            getPathForTokenToETH(),
            address(this),
            block.timestamp
        );

        return address(this).balance - initialBalance;
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    // Vesting Mechanism
    function enrollInVesting(uint256 amount) external {
        require(amount <= MAX_VESTING_AMOUNT, "Exceeds max vesting amount");
        require(vestingBeneficiaries[msg.sender].totalAmount == 0, "Already enrolled");
        _transfer(msg.sender, address(this), amount);
        vestingBeneficiaries[msg.sender] = VestingInfo({
            totalAmount: amount,
            startTime: block.timestamp,
            claimedAmount: 0,
            duration: VESTING_DURATION,
            lastClaimTime: block.timestamp
        });
    }

    function claimVestedInterest() external {
        VestingInfo storage vesting = vestingBeneficiaries[msg.sender];
        require(vesting.totalAmount > 0, "Not a vesting beneficiary");

        uint256 elapsedSinceStart = block.timestamp - vesting.startTime;
        require(elapsedSinceStart > cliffDuration, "Cliff period not over");

        uint256 elapsedSinceLastClaim = block.timestamp - vesting.lastClaimTime;
        require(elapsedSinceLastClaim >= VESTING_DURATION || vesting.lastClaimTime == 0, "Cannot claim now");

        uint256 totalInterest = (vesting.totalAmount * 42 / 1000) * elapsedSinceStart / 365 days; // 4.2% APY
        uint256 claimableInterest = totalInterest - vesting.claimedAmount;

        require(claimableInterest > 0, "No interest to claim or already claimed");

        vesting.claimedAmount = vesting.claimedAmount + claimableInterest;
        vesting.lastClaimTime = block.timestamp;  // Update the last claim time
        _transfer(address(this), msg.sender, claimableInterest);

        emit VestedTokensClaimed(msg.sender, claimableInterest);
    }

    function withdrawPrincipal() external {
    VestingInfo storage vesting = vestingBeneficiaries[msg.sender];
    require(block.timestamp > vesting.startTime + vesting.duration, "Vesting period not over yet");
    require(vesting.totalAmount > vesting.claimedAmount, "No principal left to claim");

    uint256 principal = vesting.totalAmount - vesting.claimedAmount;
    _transfer(address(this), msg.sender, principal);
    vesting.claimedAmount = vesting.totalAmount;  // Set claimed amount to total to prevent re-claiming
}

    // Lottery functions
    function startLottery() external onlyOwner {
        require(!isLotteryLive, "Lottery is already live");
        lotteryVersion++;
        currentTicketID = 0;
        isLotteryLive = true;
    }

    function endLottery() external onlyOwner {
        require(isLotteryLive, "Lottery is not live");
        isLotteryLive = false;
    }

    function setTicketPriceInMOMO(uint256 _price) external onlyOwner {
        ticketPriceInMOMO = _price;
        emit TicketPriceUpdated(_price);
    }

    function buyTicket() external {
        require(isLotteryLive, "Lottery is not live");
    
        // Transfer the MOMO tokens from the user to the contract
        _transfer(msg.sender, address(this), ticketPriceInMOMO);

        currentTicketID++;
        tickets[currentTicketID] = Ticket({
            owner: msg.sender,
            lotteryVersion: lotteryVersion
        });
        totalPot += ticketPriceInMOMO;
    }

    function drawWinner() external onlyOwner {
        require(!isLotteryLive, "Lottery is still live");
        require(currentTicketID > 0, "No tickets sold");

        uint256 winningTicketID = (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % currentTicketID) + 1;
        Ticket memory winnerTicket = tickets[winningTicketID];

        require(winnerTicket.lotteryVersion == lotteryVersion, "Invalid ticket version");

        uint256 commission = totalPot * 5 / 100;
        uint256 prize = totalPot - commission;

        // Transfer the prize in MOMO tokens to the winner
        _transfer(address(this), winnerTicket.owner, prize);
        // Transfer the commission to the reward pool
        _transfer(address(this), address(this), commission);
        totalPot = 0;

        emit WinnerDrawn(winnerTicket.owner, prize);
    }

    // Betting functions
    function placeBet(BetChoice _choice, uint256 amount) external {
    require(amount >= minBet, "Bet amount is below minimum");
    require(balanceOf(msg.sender) >= amount, "Insufficient MOMO tokens");
    
    // Transfer the MOMO tokens from the user to the contract
    _transfer(msg.sender, address(this), amount);

    bytes32 betId = keccak256(abi.encodePacked(msg.sender, block.timestamp, amount));

    uint256 potentialWinning = amount * (100 - houseEdge) / 100;
    bool isHeads = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 2 == 0;

    BetOutcome outcome;

    if ((isHeads && _choice == BetChoice.HEADS) || (!isHeads && _choice == BetChoice.TAILS)) {
        outcome = BetOutcome.WIN;
        _transfer(address(this), msg.sender, potentialWinning);
    } else {
        outcome = BetOutcome.LOSE;
        rewardPool = rewardPool + amount;
    }

    bets[betId] = Bet({
        user: msg.sender,
        amount: amount,
        choice: _choice,
        outcome: outcome,
        potentialWinning: potentialWinning,
        blockToResolve: block.number
    });

    emit BetPlaced(betId, msg.sender, amount, _choice);
    emit BetResolved(betId, outcome, potentialWinning);
}

    function startMarsMission(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _transfer(msg.sender, address(this), amount);

        uint256 outcomeProbability = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        MissionOutcome outcome;

        // Determine outcome based on static odds
        if (outcomeProbability < 38) {
            outcome = MissionOutcome.LOSE_ALL;
        } else if (outcomeProbability < 68) {
            _transfer(address(this), msg.sender, amount / 2); // Lose half
            outcome = MissionOutcome.LOSE_HALF;
        } else if (outcomeProbability < 85) {
            _transfer(address(this), msg.sender, amount); // Push
            outcome = MissionOutcome.PUSH;
        } else if (outcomeProbability < 95) {
            _transfer(address(this), msg.sender, (amount * 15) / 10); // Win 1.5x
            outcome = MissionOutcome.WIN_SMALL;
        } else {
            _transfer(address(this), msg.sender, amount * 5); // Win 5x
            outcome = MissionOutcome.WIN_BIG;
        }

        userMissions[msg.sender] = Mission({
            amountSent: amount,
            outcome: outcome
        });

        // Emit events
        emit MarsMissionStarted(msg.sender, amount);
        emit MarsMissionCompleted(msg.sender, outcome, amount);

    }

    function setUniswapRouterAddress(address _router) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_router);
    }

    function setUniswapFactoryAddress(address _factory) external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(_factory).getPair(address(this), uniswapV2Router.WETH());
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        payable(owner()).transfer(amount);
    }

    function withdrawMOMO(uint256 amount) external onlyOwner {
        _transfer(address(this), owner(), amount);
    }

    // This function allows the contract to receive ETH
    receive() external payable {}
}