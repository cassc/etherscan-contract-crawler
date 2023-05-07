/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

/**
 * PepeGrow
 * Symbol : PEPEGROW
 * Telegram : @pepegrowcom
 * 
 * We won't stop before we reach the Moon. Join us in this journey.
 *
 * Built for the community. 
 * Simply hold PEPEGROW to join the journey and experience all of the benefit from PepeGrow Ecosystem.
 * 
 * 100% SAFU
 * --------------- 
 * We will lock 100% LP right after adding liquidity.
 * You are safe with PepeGrow!
 * 
 * Prize Pool for last buy / 24 hour 
 * ---------------- 
 * 4% of each transaction to the prize pool
 * Reward send to winner if no one buy in 24hour
 * 
 * Hold to Earn
 * ------------------
 * 4% are distributed among all diamond hands holders.
 * 
 * Marketing
 * ---------------
 * 2% will be sent to marketing & development.
 * 
 * Tokenomics
 * ----------
 * Total Supply :     690,000,000,000,000
 * Burn    		:           		42.0%
 * Circulation  :         		    51.1%
 * Cex Reserve  :        			 6.9%
 * 
 * Don't miss your opportunity for the Moon!
 * 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Library

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    
    // DATA

    address private _owner;

    // MAPPING

    mapping(address => bool) internal authorizations;
    mapping(address => bool) internal operators;

    // MODIFIER

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    modifier authorized() {
        _checkAuthorization();
        _;
    }
    
    // CONSTRUCTOR

    constructor(
        address adr
    ) {
        _transferOwnership(adr);
        authorizations[adr] = true;
        operators[adr] = true;
    }

    // EVENT

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // FUNCTION

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function operator(address adr) public view virtual returns (bool) {
        return operators[adr];
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function _checkOperator() internal view virtual {
        require(operator(_msgSender()), "Ownable: caller is not the operator");
    }

    function _checkAuthorization() internal view virtual {
        require(isAuthorized(_msgSender()), "Ownable: caller is not an authorized account");
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function authorize(address adr) public onlyOperator {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function setOperator(address adr) public onlyOwner {
        operators[adr] = true;
    }

    function removeOperator(address adr) public onlyOperator {
        authorizations[adr] = false;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function renounceOperator() public virtual onlyOperator {
        operators[_msgSender()] = false;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    
    // DATA

    bool private _paused;

    // MODIFIER

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    // CONSTRUCTOR

    constructor() {
        _paused = false;
    }

    // EVENT

    event Paused(address account);
    
    event Unpaused(address account);

    // FUNCTION
    
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }
    
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }
    
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// Interface

interface IERC20 {
    
    //EVENT 

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // FUNCTION

    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IFactory {

    // FUNCTION

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {

    // FUNCTION

    function WETH() external pure returns (address);
        
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IPrizeDistributor {
    
    // FUNCTION
    
    function isPrizeDistributor() external pure returns (bool);

    function updateMinPeriod(uint256 period) external;

    function updateMinTransactionAmount(uint256 amount) external;

    function setEligibility(address account, uint256 amount) external;

    function deposit() external payable;

    function distributePrize() external;
}

interface IDividendDistributor {

    // FUNCTION

    function isDividendDistributor() external pure returns (bool);
    
    function setDistributionCriteria(uint256 distribution) external;

    function setShare(address shareholder, uint256 amount) external;

    function process(uint256 gas) external;

    function deposit() external payable;

    function distributeDividend(address shareholder) external;

}

// Prize Distributor

contract PrizeDistributor is IPrizeDistributor, Ownable, Pausable {

    // DATA

    bool private constant ISPRIZEDISTRIBUTOR = true;

    uint256 public lastEligibleTransactionTime = 0;
    uint256 public totalDistributed = 0;
    uint256 public distributionRound = 0;
    uint256 public minPeriod = 24 hours;
    uint256 public minTransactionAmount = 69_000_000 ether;

    address public lastEligibleTransactionWallet = address(0);

    address public immutable token;
    IERC20 rewardToken = IERC20(rewardToken);

    IRouter public router;

    struct PrizeInfo {
        address winner;
        bool claimed;
        uint256 amount;
    }

    // MAPPING

    mapping(uint256 => PrizeInfo) public roundToPoolInfo;
    
    // MODIFIER

    modifier onlyToken() {
        require(_msgSender() == token);
        _;
    }

    // CONSTRUCTOR 

    constructor (
        address tokenAddress,
        address rewardTokenAddress,
        address newOwner, 
        address routerAddress
    ) Ownable (newOwner) {
        require(tokenAddress != address(0), "Prize Distributor: Token address cannot be zero address.");
        require(rewardTokenAddress != address(0), "Prize Distributor: Reward token address cannot be zero address.");
        token = tokenAddress;
        rewardToken = IERC20(rewardTokenAddress);
        _transferOwnership(newOwner);

        router = IRouter(routerAddress);
    }

    // EVENT

    event UpdateMinPeriod(uint256 oldPeriod, uint256 newPeriod, uint256 timestamp);

    event UpdateMinTransactionAmount(uint256 oldTransactionAmount, uint256 newTransactionAmount, uint256 timestamp);

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    // FUNCTION

    /* General */

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function wNative() external onlyOperator {
        address beneficiary = _msgSender();
        payable(beneficiary).transfer(address(this).balance);
    }

    function isPrizeDistributor() external override pure returns (bool) {
        return ISPRIZEDISTRIBUTOR;
    } 

    /* Update */

    function updateMinPeriod(uint256 newPeriod) external authorized {
        require(minPeriod != newPeriod, "Update Min Period: This is the current value for min period.");
        uint256 oldPeriod = minPeriod;
        minPeriod = newPeriod;
        emit UpdateMinPeriod(oldPeriod, newPeriod, block.timestamp);
    }

    function updateMinTransactionAmount(uint256 newTransactionAmount) external authorized {
        require(minTransactionAmount != newTransactionAmount, "Update Min Transaction Amount: This is the current value for min transaction amount.");
        uint256 oldTransactionAmount = minTransactionAmount;
        minTransactionAmount = newTransactionAmount;
        emit UpdateMinTransactionAmount(oldTransactionAmount, newTransactionAmount, block.timestamp);
    }

    function updateRouter(address newRouter) external authorized {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
    }

    /* Check */

    function prizePool() public view returns (uint256) {
        return IERC20(rewardToken).balanceOf(address(this)) * 70 / 100; //70% OF REWARD WILL SEND TO WINNER, 30% GO TO NEXT ROUND
    }

    function getPoolInfo() public view returns(address Lastbuy , uint256 TimeLeft, uint256 PrizePool){
        return (lastEligibleTransactionWallet, minPeriod + lastEligibleTransactionTime, prizePool());
    }

    function shouldDistribute() internal view returns (bool) {
        return minPeriod + lastEligibleTransactionTime <= block.timestamp && lastEligibleTransactionTime > 0 && lastEligibleTransactionWallet != address(0);
    }

    /* Eligibility */
    

    function setEligibility(address account, uint256 amount) external override onlyToken whenNotPaused {
        if (shouldDistribute()) {
            distributePrize();
        }

        if (minTransactionAmount <= amount) {
            lastEligibleTransactionWallet = account;
            lastEligibleTransactionTime = block.timestamp;
        }
    } 

    /* Prize */

    function deposit() external payable override authorized whenNotPaused {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: msg.value
        } (0, path, address(this), block.timestamp);
    }

    function distributePrize() public {
        require(shouldDistribute(), "Distribute Prize: Does not fit the criteria for distribution initiation.");
        uint256 amount = prizePool();
        roundToPoolInfo[distributionRound + 1].winner = lastEligibleTransactionWallet;
        roundToPoolInfo[distributionRound + 1].claimed = true;
        roundToPoolInfo[distributionRound + 1].amount = amount;

        require(
            IERC20(rewardToken).transfer(roundToPoolInfo[distributionRound + 1].winner,
            roundToPoolInfo[distributionRound + 1].amount),
            "Distribute Prize: There's something wrong with transfer function."
        );

        distributionRound += 1;
        totalDistributed += amount;
        lastEligibleTransactionWallet = address(0);
        lastEligibleTransactionTime = block.timestamp;
        

    }
}

// Dividend Distributor

contract DividendDistributor is IDividendDistributor, Ownable, Pausable {

    // DATA

    bool private constant ISDIVIDENDDISTRIBUTOR = true;

    uint256 public minDistribution = 6_900_000 ether;
    uint256 public maxContinuousDistribution = 10;
    uint256 public dividendsPerShare = 0;
    uint256 public currentIndex = 0;
    uint256 public totalShares = 0;
    uint256 public totalDividends = 0; 
    uint256 public totalDistributed = 0;

    uint256 public constant ACCURACY = 1_000_000_000_000_000_000 ether;

    address[] public shareholders;

    address public immutable token;
    IERC20 public immutable rewardToken;

    IRouter public router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // MAPPING

    mapping(address => Share) public shares;
    mapping(address => uint256) public shareholderIndexes;
    mapping(address => uint256) public shareholderClaims;

    // MODIFIER

    modifier onlyToken() {
        require(_msgSender() == token);
        _;
    }

    // CONSTRUCTOR 

    constructor (
        address tokenAddress,
        address rewardTokenAddress,
        address newOwner, 
        address routerAddress
    ) Ownable (newOwner) {
        require(tokenAddress != address(0), "Dividend Distributor: Token address cannot be zero address.");
        require(rewardTokenAddress != address(0), "Dividend Distributor: Reward token address cannot be zero address.");
        token = tokenAddress;
        rewardToken = IERC20(rewardTokenAddress);
        _transferOwnership(newOwner);

        router = IRouter(routerAddress);
        shareholderClaims[newOwner] = 0;
    }

    // EVENT

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    event UpdateMaxContinuousDistribution(uint256 oldMaxContinuousDistribution, uint256 newMaxContinuousDistribution, uint256 timestamp);

    // FUNCTION

    /* General */

    receive() external payable {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function wNative() external onlyOperator {
        address beneficiary = _msgSender();
        payable(beneficiary).transfer(address(this).balance);
    }

    function isDividendDistributor() external override pure returns (bool) {
        return ISDIVIDENDDISTRIBUTOR;
    } 

    /* Update */

    function updateMaxContinuousDistribution(uint256 newMaxContinuousDistribution) external authorized {
        require(maxContinuousDistribution <= 20, "Update Max Continuous Distribution: Max distribution for dividend should be lesser or equal to 20 at one time.");
        require(newMaxContinuousDistribution != maxContinuousDistribution, "Update Max Continuous Distribution: This is the current value for max distribution");
        uint256 oldMaxContinuousDistribution = maxContinuousDistribution;
        maxContinuousDistribution = newMaxContinuousDistribution;
        emit UpdateMaxContinuousDistribution(oldMaxContinuousDistribution, newMaxContinuousDistribution, block.timestamp);
    }

    function updateRouter(address newRouter) external authorized {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
    }

    function setDistributionCriteria(uint256 distributionMin) external override authorized {
        require(minDistribution != distributionMin, "Set Distribution Criteria: This is the current value.");
        minDistribution = distributionMin;
    }

    /* Check */

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return getUnpaidEarnings(shareholder) > minDistribution;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / ACCURACY;
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    /* Dividend */

    function deposit() external payable override authorized whenNotPaused {
        uint256 balanceBefore = IERC20(rewardToken).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardToken);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens {
            value: msg.value
        } (0, path, address(this), block.timestamp);

        uint256 amount = IERC20(rewardToken).balanceOf(address(this)) - balanceBefore;

        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + (ACCURACY * amount / totalShares);
    }

    function process(uint256 gas) external override authorized whenNotPaused {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < maxContinuousDistribution && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex -= shareholderCount;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            iterations++;
        }
        
    }

    function distributeDividend(address shareholder) public authorized {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        
        if (amount > 0) {
            totalDistributed += amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            require(IERC20(rewardToken).transfer(shareholder, amount), "Distribute Dividend: There's something wrong with transfer function.");
        }
    }

    function tallyDividend(uint256 initialShares, uint256 amount, address shareholder) internal {
        if (initialShares == 0) {
            return;
        }

        if (amount > 0) {
            totalDistributed += amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(initialShares);
            require(IERC20(rewardToken).transfer(shareholder, amount), "Tally Dividend: There's something wrong with transfer function.");
        }
    }

    function claimDividend() external {
        distributeDividend(_msgSender());
    }

    /* Shares */
    
    function setShare(address shareholder, uint256 amount) external override onlyToken whenNotPaused {
        uint256 initialShares = shares[shareholder].amount;
        uint256 unpaid = getUnpaidEarnings(shareholder);

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount  + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);

        if (initialShares > 0) {
            tallyDividend(initialShares, unpaid, shareholder);
        }
    } 

    /* Shareholders */

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

}

// Token

contract PEPEGrow is Ownable, IERC20 {

    // DATA

    string private constant NAME = "PEPEGrow";
    string private constant SYMBOL = "PEPEGROW";

    uint8 private constant DECIMALS = 18;

    uint256 private _totalSupply;
    
    uint256 public constant FEEDENOMINATOR = 10_000;

    uint256 public buyPrizeFee = 400;
    uint256 public buyMarketingFee = 200;
    uint256 public buyDividendFee = 400;
    uint256 public sellPrizeFee = 300;
    uint256 public sellMarketingFee = 200;
    uint256 public sellDividendFee = 500;
    uint256 public transferPrizeFee = 0;
    uint256 public transferMarketingFee = 0;
    uint256 public transferDividendFee = 0;
    uint256 public marketingFeeCollected = 0;
    uint256 public prizeFeeCollected = 0;
    uint256 public dividendFeeCollected = 0;
    uint256 public totalFeeCollected = 0;
    uint256 public marketingFeeRedeemed = 0;
    uint256 public prizeFeeRedeemed = 0;
    uint256 public dividendFeeRedeemed = 0;
    uint256 public totalFeeRedeemed = 0;
    uint256 public distributorGas = 500_000;
    uint256 public minSwap = 6_900_000_000 ether;

    bool private constant ISPEPEGROW = true;

    bool public isDividendActive = false;
    bool public isPrizeActive = false;
    bool public isFeeActive = false;
    bool public isFeeLocked = false;
    bool public isSwapEnabled = false;
    bool public inSwap = false;

    address public constant ZERO = address(0);
    address public constant DEAD = address(0xdead);

    address public pair;
    address public marketingReceiver;

    IRouter public router;
    IDividendDistributor public distributor;
    IPrizeDistributor public prize;

    // MAPPING

    mapping(address => bool) public isExcludeFromFees;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isPrizeExempt;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // MODIFIER

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // CONSTRUCTOR

    constructor(
        address routerAddress,
        address marketingReceiverAddress,
        address rewardTokenAddress
    ) Ownable (_msgSender()) {
        require(marketingReceiverAddress != address(0), "PEPEGrow: Marketing receiver cannot be zero address.");
        _mint(_msgSender(), 690_000_000_000_000 ether);
        marketingReceiver = marketingReceiverAddress;

        distributor = new DividendDistributor(address(this), rewardTokenAddress, _msgSender(), routerAddress);
        prize = new PrizeDistributor(address(this), rewardTokenAddress, _msgSender(), routerAddress);

        router = IRouter(routerAddress);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        isExcludeFromFees[address(distributor)] = true;
        isExcludeFromFees[address(prize)] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(distributor)] = true;
        isDividendExempt[address(prize)] = true;
        //isPrizeExempt[pair] = true;
        isPrizeExempt[DEAD] = true;
        isPrizeExempt[ZERO] = true;
        isPrizeExempt[address(this)] = true;
        isPrizeExempt[address(distributor)] = true;
        isPrizeExempt[address(prize)] = true;

        authorize(address(distributor));
        authorize(address(prize));
    }

    // EVENT

    event UpdateRouter(address oldRouter, address newRouter, uint256 timestamp);

    event UpdatePrizePool(address oldPool, address newPool, uint256 timestamp);

    event UpdateMinSwap(uint256 oldMinSwap, uint256 newMinSwap, uint256 timestamp);

    event UpdateDistributorGas(uint256 oldDistributorGas, uint256 newDistributorGas, uint256 timestamp);

    event UpdateDividendDistributor(address oldDistributor, address newDistributor, uint256 timestamp);

    event UpdatePrizeDistributor(address oldPrize, address newPrize, uint256 timestamp);

    event UpdateFeeActive(bool oldStatus, bool newStatus, uint256 timestamp);

    event UpdateSwapEnabled(bool oldStatus, bool newStatus, uint256 timestamp);

    event RedeemPrize(uint256 amountToken, uint256 amountETH, uint256 prize, uint256 timestamp);
    
    event UpdateMarketingReceiver(address oldMarketingReceiver, address newMarketingReceiver, uint256 timestamp);

    event AutoRedeem(uint256 prizeFeeDistribution, uint256 marketingFeeDistribution, uint256 dividendFeeDistribution, uint256 amountToRedeem, uint256 timestamp);

    // FUNCTION

    /* General */

    receive() external payable {}

    function claimDividend() external {
        require(distributor.isDividendDistributor(), "Claim Dividend: This is not the correct dividend distributor address.");
        try distributor.distributeDividend(_msgSender()) {} catch {}
    }

    function startDividend() external authorized {
        require(!isDividendActive, "Start Dividend: Dividend distribution started.");
        isDividendActive = true;
    }

    function stopDividend() external authorized {
        require(isDividendActive, "Stop Dividend: Dividend distribution stopped.");
        isDividendActive = false;
    }

    function claimPrize() external {
        require(prize.isPrizeDistributor(), "Claim Prize: This is not the correct prize distributor address.");
        try prize.distributePrize() {} catch {}
    }

    function startPrize() external authorized {
        require(!isPrizeActive, "Start Prize: Prize distribution started.");
        isPrizeActive = true;
    }

    function stopPrize() external authorized {
        require(isPrizeActive, "Stop Prize: Prize distribution stopped.");
        isPrizeActive = false;
    }

    function finalizePresale() external authorized {
        require(!isFeeActive, "Finalize Presale: Fee already active.");
        require(!isSwapEnabled, "Finalize Presale: Swap already enabled.");
        require(!isDividendActive, "Finalize Presale: Dividend already enabled active.");
        require(!isPrizeActive, "Finalize Presale: Prize already active.");
        isFeeActive = true;
        isSwapEnabled = true;
        isDividendActive = true;
        isPrizeActive = true;
    }

    function lockFees() external authorized {
        require(!isFeeLocked, "Lock Fees: All fees were already locked.");
        isFeeLocked = true;
    }

    function redeemAllMarketingFee() external {
        uint256 amountToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        _approve(address(this), address(router), amountToRedeem);
        
        _redeemMarketingFee(amountToRedeem);
    }

    function redeemPartialMarketingFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= marketingFeeCollected - marketingFeeRedeemed, "Redeem Partial Marketing Fee: Insufficient marketing fee collected.");
        _approve(address(this), address(router), amountToRedeem);
        
        _redeemMarketingFee(amountToRedeem);
    }

    function _redeemMarketingFee(uint256 amountToRedeem) internal swapping { 
        marketingFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );
    }

    function redeemAllPrizeFee() external {
        uint256 amountToRedeem = prizeFeeCollected - prizeFeeRedeemed;
        _approve(address(this), address(router), amountToRedeem);
        
        _redeemPrizeFee(amountToRedeem);
    }

    function redeemPartialPrizeFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= prizeFeeCollected - prizeFeeRedeemed, "Redeem Partial Prize Fee: Insufficient prize fee collected.");
        _approve(address(this), address(router), amountToRedeem);
        
        _redeemPrizeFee(amountToRedeem);
    }

    function _redeemPrizeFee(uint256 amountToRedeem) internal swapping {   
        prizeFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            address(this),
            block.timestamp
        );      

        uint256 balanceNow = address(this).balance - balanceBefore;
        
        try prize.deposit {value: balanceNow} () {} catch {}
    }

    function redeemAllDividendFee() external {
        uint256 amountToRedeem = dividendFeeCollected - dividendFeeRedeemed;
        _approve(address(this), address(router), amountToRedeem);

        _redeemDividendFee(amountToRedeem);
    }

    function redeemPartialDividendFee(uint256 amountToRedeem) external {
        require(amountToRedeem <= dividendFeeCollected - dividendFeeRedeemed, "Redeem Partial Dividend Fee: Insufficient dividend fee collected.");
        _approve(address(this), address(router), amountToRedeem);

        _redeemDividendFee(amountToRedeem);
    }

    function _redeemDividendFee(uint256 amountToRedeem) internal swapping {        
        dividendFeeRedeemed += amountToRedeem;
        totalFeeRedeemed += amountToRedeem;
 
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToRedeem,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceNow = address(this).balance - balanceBefore;
        
        try distributor.deposit {value: balanceNow} () {} catch {}
    }

    /* Check */

    function isPepeGrow() external pure returns (bool) {
        return ISPEPEGROW;
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    /* Update */

    function updateRouter(address newRouter) external authorized {
        require(address(router) != newRouter, "Update Router: This is the current router address.");
        address oldRouter = address(router);
        router = IRouter(newRouter);
        emit UpdateRouter(oldRouter, newRouter, block.timestamp);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
    }

    function updateMinSwap(uint256 newMinSwap) external authorized {
        require(minSwap != newMinSwap, "Update Min Swap: This is the current value of min swap.");
        uint256 oldMinSwap = minSwap;
        minSwap = newMinSwap;
        emit UpdateMinSwap(oldMinSwap, newMinSwap, block.timestamp);
    }

    function updateDistributorGas(uint256 newDistributorGas) external authorized {
        require(distributorGas != newDistributorGas, "Update Distributor Gas: This is the current value of distributor gas.");
        uint256 oldDistributorGas = distributorGas;
        distributorGas = newDistributorGas;
        emit UpdateDistributorGas(oldDistributorGas, newDistributorGas, block.timestamp);
    }

    function updateDividendDistributor(address newDistributor) external authorized {
        require(IDividendDistributor(newDistributor).isDividendDistributor(), "Update Dividend Distributor: This is not the correct dividend distributor contract.");
        address oldDistributor = address(distributor);
        distributor = DividendDistributor(payable(newDistributor));
        emit UpdateDividendDistributor(oldDistributor, newDistributor, block.timestamp);
    }

    function updatePrizeDistributor(address newPrize) external authorized {
        require(IPrizeDistributor(newPrize).isPrizeDistributor(), "Update Prize Distributor: This is not the correct prize distributor contract.");
        address oldPrize = address(prize);
        prize = PrizeDistributor(payable(newPrize));
        emit UpdatePrizeDistributor(oldPrize, newPrize, block.timestamp);
    }

    function updateBuyFee(uint256 newPrizeFee, uint256 newMarketingFee, uint256 newDividendFee) external authorized {
        require(!isFeeLocked, "Update Buy Fee: All buy fees were locked and cannot be updated.");
        require(newPrizeFee + newMarketingFee + newDividendFee <= 1000, "Update Buy Fee: Total fees cannot exceed 10%.");
        buyPrizeFee = newPrizeFee;
        buyMarketingFee = newMarketingFee;
        buyDividendFee = newDividendFee;
    }

    function updateSellFee(uint256 newPrizeFee, uint256 newMarketingFee, uint256 newDividendFee) external authorized {
        require(!isFeeLocked, "Update Sell Fee: All sell fees were locked and cannot be updated.");
        require(newPrizeFee + newMarketingFee + newDividendFee <= 1000, "Update Sell Fee: Total fees cannot exceed 10%.");
        sellPrizeFee = newPrizeFee;
        sellMarketingFee = newMarketingFee;
        sellDividendFee = newDividendFee;
    }

    function updateTransferFee(uint256 newPrizeFee, uint256 newMarketingFee, uint256 newDividendFee) external authorized {
        require(!isFeeLocked, "Update Transfer Fee: All transfer fees were locked and cannot be updated.");
        require(newPrizeFee + newMarketingFee + newDividendFee <= 1000, "Update Transfer Fee: Total fees cannot exceed 10%.");
        transferPrizeFee = newPrizeFee;
        transferMarketingFee = newMarketingFee;
        transferDividendFee = newDividendFee;
    }

    function updateFeeActive(bool newStatus) external authorized {
        require(isFeeActive != newStatus, "Update Fee Active: This is the current state for the fee.");
        bool oldStatus = isFeeActive;
        isFeeActive = newStatus;
        emit UpdateFeeActive(oldStatus, newStatus, block.timestamp);
    }

    function updateSwapEnabled(bool newStatus) external authorized {
        require(isSwapEnabled != newStatus, "Update Swap Enabled: This is the current state for the swap.");
        bool oldStatus = isSwapEnabled;
        isSwapEnabled = newStatus;
        emit UpdateSwapEnabled(oldStatus, newStatus, block.timestamp);
    }

    function updateMarketingReceiver(address newMarketingReceiver) external authorized {
        require(marketingReceiver != newMarketingReceiver, "Update Marketing Receiver: This is the current marketing receiver address.");
        address oldMarketingReceiver = marketingReceiver;
        marketingReceiver = newMarketingReceiver;
        emit UpdateMarketingReceiver(oldMarketingReceiver, newMarketingReceiver, block.timestamp);
    }

    function setExcludeFromFees(address user, bool status) external authorized {
        require(isExcludeFromFees[user] != status, "Set Exclude From Fees: This is the current state for this address.");
        isExcludeFromFees[user] = status;
    }

    function setExemptFromDividend(address user, bool status) external authorized {
        require(isDividendExempt[user] != status, "Set Exempt From Dividend: This is the current state for this address.");
        isDividendExempt[user] = status;
    }

    function setExemptFromPrize(address user, bool status) external authorized {
        require(isPrizeExempt[user] != status, "Set Exempt From Prize: This is the current state for this address.");
        isPrizeExempt[user] = status;
    }
    
    function setDistributionCriteria(uint256 distributionMin) external authorized {
        require(distributor.isDividendDistributor(), "Set Distribution Criteria: This is not the correct dividend distributor address.");
        try distributor.setDistributionCriteria(distributionMin) {} catch {}
    }
    
    function setPrizeMinPeriod(uint256 minPeriod) external authorized {
        require(prize.isPrizeDistributor(), "Set Prize Min Period: This is not the correct prize distributor address.");
        try prize.updateMinPeriod(minPeriod) {} catch {}
    }
    
    function setPrizeMinTransactionAmount(uint256 minAmount) external authorized {
        require(prize.isPrizeDistributor(), "Set Prize Min Transaction Amount: This is not the correct prize distributor address.");
        try prize.updateMinTransactionAmount(minAmount) {} catch {}
    }

    /* Fee */

    function takeBuyFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = buyPrizeFee + buyMarketingFee + buyDividendFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyBuyFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeSellFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = sellPrizeFee + sellMarketingFee + sellDividendFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallySellFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function takeTransferFee(address from, uint256 amount) internal swapping returns (uint256) {
        uint256 feeTotal = transferPrizeFee + transferMarketingFee + transferDividendFee;
        uint256 feeAmount = amount * feeTotal / FEEDENOMINATOR;
        uint256 newAmount = amount - feeAmount;
        tallyTransferFee(from, feeAmount, feeTotal);
        return newAmount;
    }

    function tallyBuyFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectPrize = amount * buyPrizeFee / fee;
        uint256 collectMarketing = amount * buyMarketingFee / fee;
        uint256 collectDividend = amount - collectPrize - collectMarketing;
        tallyCollection(collectPrize, collectMarketing, collectDividend, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallySellFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectPrize = amount * sellPrizeFee / fee;
        uint256 collectMarketing = amount * sellMarketingFee / fee;
        uint256 collectDividend = amount - collectPrize- collectMarketing ;
        tallyCollection(collectPrize, collectMarketing, collectDividend, amount);
        
        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyTransferFee(address from, uint256 amount, uint256 fee) internal swapping {
        uint256 collectPrize = amount * transferPrizeFee / fee;
        uint256 collectMarketing = amount * transferMarketingFee / fee;
        uint256 collectDividend = amount - collectMarketing - collectPrize;
        tallyCollection(collectPrize, collectMarketing, collectDividend, amount);

        _balances[from] -= amount;
        _balances[address(this)] += amount;
    }

    function tallyCollection(uint256 collectPrize, uint256 collectMarketing, uint256 collectDividend, uint256 amount) internal swapping {
        prizeFeeCollected += collectPrize;
        marketingFeeCollected += collectMarketing;
        dividendFeeCollected += collectDividend;
        totalFeeCollected += amount;
    }

    function autoRedeem(uint256 amountToRedeem) public swapping {  
        uint256 prizeToRedeem = prizeFeeCollected - prizeFeeRedeemed;
        uint256 marketingToRedeem = marketingFeeCollected - marketingFeeRedeemed;
        uint256 totalToRedeem = totalFeeCollected - totalFeeRedeemed;

        uint256 marketingFeeDistribution = amountToRedeem * marketingToRedeem / totalToRedeem;
        uint256 prizeFeeDistribution = amountToRedeem * prizeToRedeem / totalToRedeem;
        uint256 dividendFeeDistribution = amountToRedeem - prizeFeeDistribution - marketingFeeDistribution;
        uint256 redeemAmount = amountToRedeem;

        marketingFeeRedeemed += marketingFeeDistribution;
        prizeFeeRedeemed += prizeFeeDistribution;
        dividendFeeRedeemed += dividendFeeDistribution;
        totalFeeRedeemed += amountToRedeem;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amountToRedeem);
    
        emit AutoRedeem(prizeFeeDistribution, marketingFeeDistribution, dividendFeeDistribution, redeemAmount, block.timestamp);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            marketingFeeDistribution,
            0,
            path,
            marketingReceiver,
            block.timestamp
        );
        
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            prizeFeeDistribution,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceNow = address(this).balance - balanceBefore;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            dividendFeeDistribution,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceFinal = address(this).balance - balanceNow;
        
        try prize.deposit {value: balanceNow} () {} catch {}
        try distributor.deposit {value: balanceFinal} () {} catch {}
    }

    /* Buyback */

    function triggerZeusBuyback(uint256 amount) external authorized {
        buyTokens(amount, DEAD);
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        require(msg.sender != DEAD, "Buy Tokens: Dead address cannot call this function.");
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    /* ERC20 Standard */

    function name() external view virtual override returns (string memory) {
        return NAME;
    }
    
    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }
    
    function decimals() external view virtual override returns (uint8) {
        return DECIMALS;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address provider = _msgSender();
        return _transfer(provider, to, amount);
    }
    
    function allowance(address provider, address spender) public view virtual override returns (uint256) {
        return _allowances[provider][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address provider = _msgSender();
        _approve(provider, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        return _transfer(from, to, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address provider = _msgSender();
        _approve(provider, spender, allowance(provider, spender) + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address provider = _msgSender();
        uint256 currentAllowance = allowance(provider, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(provider, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address provider, address spender, uint256 amount) internal virtual {
        require(provider != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[provider][spender] = amount;
        emit Approval(provider, spender, amount);
    }
    
    function _spendAllowance(address provider, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(provider, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(provider, spender, currentAllowance - amount);
            }
        }
    }

    /* Additional */

    function _basicTransfer(address from, address to, uint256 amount ) internal returns (bool) {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }
    
    /* Overrides */
 
    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (inSwap || isExcludeFromFees[from]) {
            return _basicTransfer(from, to, amount);
        }

        if (from != pair && isSwapEnabled && totalFeeCollected - totalFeeRedeemed >= minSwap) {
            autoRedeem(minSwap);
        }

        uint256 newAmount = amount;

        if (isFeeActive && !isExcludeFromFees[from]) {
            newAmount = _beforeTokenTransfer(from, to, amount);
        }

        require(_balances[from] >= newAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = _balances[from] - newAmount;
            _balances[to] += newAmount;
        }

        emit Transfer(from, to, newAmount);

        if (isDividendActive) {
            _afterTokenTransfer(from, to);
        }

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal swapping virtual returns (uint256) {
        if (from == pair && (buyPrizeFee + buyMarketingFee + buyDividendFee > 0)) {
            if (isPrizeActive && !isPrizeExempt[from]) {
                try prize.setEligibility(to, amount) {} catch {}
            }
            return takeBuyFee(from, amount);
        }
        if (to == pair && (sellPrizeFee + sellMarketingFee + sellDividendFee > 0)) {
            return takeSellFee(from, amount);
        }
        if (from != pair && to != pair && (transferPrizeFee + transferMarketingFee + transferDividendFee > 0)) {
            return takeTransferFee(from, amount);
        }
        return amount;
    }

    function _afterTokenTransfer(address from, address to) internal virtual {
        require(distributor.isDividendDistributor(), "After Token Transfer: This is not the correct dividend distributor address.");

        if (!isDividendExempt[from]) {
            try distributor.setShare(from, _balances[from]) {} catch {}
        }
        if (!isDividendExempt[to]) {
            try distributor.setShare(to, _balances[to]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}
    }

}