// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./EcoGames.sol";
import "./TokensVesting.sol";

contract Crowdsale {

    TokensVesting public vestingContract;
    EcoGames public ecoGamesContract;

    address _owner;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    bool public startCrowdsale = true;
    uint256 public tokensRaised;

    uint256[] public limit = [300000000000000000000000000, 1200000000000000000000000000, 2700000000000000000000000000]; // 300m, 1200m, 2700m
    uint256[] public usdRATE = [375, 500, 750]; // 0.00375, 0.005, 0.0075
    uint256 round;

    uint256 public saleEndDate; // timestamp when sale round ends
    uint256 public ethPricePerDAI = 1400000000000000000000; // $1400
    uint256 public DAItoUSDT = 10**12; // used for decimal conversion

    mapping(address=>uint256) private usdBalances;
    mapping(address=>uint256) private daiBalances;

    event TokenBought(address indexed buyer, uint256 value, uint256 amount, string token, uint256 round);

    modifier onlyWhenNotPaused() {
        require(startCrowdsale, "Crowdsale: crowdsale has paused");
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Crowdsale: Caller is not the owner");
        _;
    }

    constructor(
        address payable _ecoGamesContract,
        address payable _vestingContract
    ) {
        vestingContract = TokensVesting(_vestingContract);
        ecoGamesContract = EcoGames(_ecoGamesContract);
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    function buyWithDAI(uint256 amount)
        public
        onlyWhenNotPaused
    {
        require(amount + tokensRaised <= limit[round], "Amount exceeds sale round limit");
        require(saleEndDate >= block.timestamp, "Sale round is over or has not started");
        
        uint256 usdAmount = getTotalPriceInDAI(amount);
        require(usdAmount >= 10000000000000000000, "Buy amount must be above 10 USD");
        
        bool success = vestingContract._vest(msg.sender, amount, round);
        require(success, "Vesting: failed to vest");
        usdBalances[msg.sender] += usdAmount;

        require(usdBalances[msg.sender] <= ethPricePerDAI, "Balance cannot exceed 1 Eth");
        tokensRaised += amount;

        success = IERC20(dai).transferFrom(msg.sender, _owner, usdAmount);
        require(success, "Transfer has failed");
        emit TokenBought(msg.sender, usdAmount, amount, "DAI", round);
    }

    function buyWithUSDT(uint256 amount)
        public
        onlyWhenNotPaused
    {
        require(amount + tokensRaised <= limit[round], "Amount exceeds sale round limit");
        require(saleEndDate >= block.timestamp, "Sale round is over or has not started");
        
        uint256 usdAmount = getTotalPriceInDAI(amount);
        require(usdAmount >= 10000000000000000000, "Buy amount must be above 10 USD");

        bool success = vestingContract._vest(msg.sender, amount, round);
        require(success, "Vesting: failed to vest");
        usdBalances[msg.sender] += usdAmount;

        require(usdBalances[msg.sender] <= ethPricePerDAI, "Balance cannot exceed 1 Eth");
        uint256 usdtAmount = usdAmount / DAItoUSDT;
        tokensRaised += amount;

        success = IERC20(usdt).transferFrom(msg.sender, _owner, usdtAmount);
        require(success, "Transfer has failed");
        emit TokenBought(msg.sender, usdAmount, amount, "USDT", round);
    }

    function buyWithUSDC(uint256 amount)
        public
        onlyWhenNotPaused
    {
        require(amount + tokensRaised <= limit[round], "Amount exceeds sale round limit");
        require(saleEndDate >= block.timestamp, "Sale round is over or has not started");
        
        uint256 usdAmount = getTotalPriceInDAI(amount);
        require(usdAmount >= 10000000000000000000, "Buy amount must be above 10 USD");

        bool success = vestingContract._vest(msg.sender, amount, round);
        require(success, "Vesting: failed to vest");
        usdBalances[msg.sender] += usdAmount;

        require(usdBalances[msg.sender] <= ethPricePerDAI, "Balance cannot exceed 1 Eth");
        uint256 usdtAmount = usdAmount / DAItoUSDT;
        tokensRaised += amount;

        success = IERC20(usdc).transferFrom(msg.sender, _owner, usdtAmount);
        require(success, "Transfer has failed");
        emit TokenBought(msg.sender, usdAmount, amount, "USDC", round);
    }
    
    function buyWithETH(uint256 amount)
        public payable onlyWhenNotPaused
    {
        require(amount + tokensRaised <= limit[round], "Amount exceeds sale round limit");
        require(saleEndDate >= block.timestamp, "Sale round is over or has not started");

        uint256 usdAmount = getTotalPriceInDAI(amount);
        require(usdAmount >= 10000000000000000000, "Buy amount must be above 10 USD");
        require((msg.value * (ethPricePerDAI / 1 ether)) >= usdAmount, "Not enough ETHs sent");

        bool success = vestingContract._vest(msg.sender, amount, round);
        require(success, "Vesting: failed to vest");
        
        usdBalances[msg.sender] += usdAmount;
        require(usdBalances[msg.sender] <= ethPricePerDAI, "Balance cannot exceed 1 Eth");

        tokensRaised += amount;
        emit TokenBought(msg.sender, msg.value, amount, "ETH", round);
    }

    function setEthPrice(uint256 newethPrice) public onlyOwner {
        ethPricePerDAI = newethPrice;
    }

    function setUSDT(address newAddress) public onlyOwner {
        usdt = newAddress;
    }

    function setDAI(address newAddress) public onlyOwner {
        dai = newAddress;
    }

    function setUSDC(address newAddress) public onlyOwner {
        usdc = newAddress;
    }

    function initiateRound(uint256 newRound) public onlyOwner {
        round = newRound;
    }

    function startSalePeriod(uint256 _salePeriod) public onlyOwner {
        saleEndDate = block.timestamp + _salePeriod;
    }

    function togglePauseCrowdsale() public onlyOwner {
        startCrowdsale = !startCrowdsale;
    }

    function endCrowdsale() public onlyOwner {
        vestingContract.initiateVesting();
        togglePauseCrowdsale();
        uint256 bal = address(this).balance;
        if (bal > 0) {
            (bool success, ) = payable(vestingContract).call{value: bal}("");
            require(success, "Failed to send ether to vesting contract");
        }
    }

    function withdraw() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "Contract has no balance.");
        (bool success, ) = payable(msg.sender).call{value: bal}("");
        require(success, "Withdrawal has failed.");
    }

    function getTotalPriceInDAI(uint256 _amount) 
        public view returns (uint256) 
    {
        return (_amount * usdRATE[round]) / 100000;
    }

    function usdBalance(address account) public view returns (uint256) {
        return usdBalances[account];
    }

    function getRound() public view returns (uint256) {
        return round + 1;
    }

}