// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IContracts {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function lock(address owner, address token, bool isLpToken, uint256 amount, uint256 unlockDate, string memory description) external returns (uint256 lockId);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract TokenPreSale is ReentrancyGuard, Ownable {
    uint256 public BASE_MULTIPLIER;
    address public ROUTER;
    address public FACTORY;
    address public WETH;
    address public LOCKER;

    uint256 public startTimeSeedSale;
    uint256 public endTimeSeedSale;
    uint256 public startTimePrivateSale;
    uint256 public endTimePrivateSale;
    uint256 public startTimePublicSale;
    uint256 public endTimePublicSale;

    address public saleToken;
    uint256 public baseDecimals;
    uint256 public amountTokensForLiquidity;
    uint256 public timeUnlockLiquidity;
    uint256 public treasuryPercentage;
    address payable public treasuryAddress;

    uint256 public priceSeedSale;
    uint256 public pricePrivateSale;
    uint256 public pricePublicSale;

    uint256 public tokensToSellSeedSale;
    uint256 public tokensToSellPrivateSale;
    uint256 public tokensToSellPublicSale;
    uint256 public maxAmountTokensForSalePerUserForSeed;
    uint256 public maxAmountTokensForSalePerUserForPrivate;
    uint256 public maxAmountTokensForSalePerUserForPublic;
    uint256 public tokensToSellTotal;

    uint256 private ethInvestedSeedSale;
    uint256 private ethInvestedPrivateSale;
    uint256 private ethInvestedPublicSale;

    uint256 public vestingStartTime;
    uint256 public vestingCliff;
    uint256 public vestingPeriod;

    bool private presaleTimeInitiated = false;
    bool private seedSaleTreasuryClaimed = false;
    bool private privateSaleTreasuryClaimed = false;
    bool private publicSaleTreasuryClaimed = false;

    bool public liquidityFinalized = false;
    bool public tokensaleCanceled = false;

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 claimStart;
        uint256 claimEnd;
    }

    mapping(address => Vesting) public userVesting;
    mapping(address => bool) public whitelistSeedSale;
    mapping(address => bool) public whitelistPrivateSale;
    mapping(address => uint256) private userDepositETH;
    mapping(address => uint256) private userAmountBoughtSeed;
    mapping(address => uint256) private userAmountBoughtPrivate;
    mapping(address => uint256) private userAmountBoughtPublic;

    constructor(address _router, address _factory, address _weth, address _locker) public {
        BASE_MULTIPLIER = (10**18);
        ROUTER = _router;
        FACTORY = _factory;
        WETH = _weth;
        LOCKER = _locker;
    }

     /**
     * @dev To add the sale times, can only be called once
     * @param _startTimeSeedSale Unix timestamp seed sale start
     * @param _endTimeSeedSale Unix timestamp seed sale end
     * @param _startTimePrivateSale; Unix timestamp private sale start
     * @param _endTimePrivateSale Unix timestamp private sale end
     * @param _startTimePublicSale Unix timestamp public sale start
     * @param _endTimePublicSale Unix timestamp public sale end
     * @param _vestingStartTime Unix timestamp vesting start
     */
    function addSaleTimes(
        uint256 _startTimeSeedSale,
        uint256 _endTimeSeedSale,
        uint256 _startTimePrivateSale,
        uint256 _endTimePrivateSale,
        uint256 _startTimePublicSale,
        uint256 _endTimePublicSale,
        uint256 _vestingStartTime 
    ) external onlyOwner {
        require(presaleTimeInitiated == false, "already initiated");
        require(_startTimeSeedSale > 0 || _endTimeSeedSale > 0 || _startTimePrivateSale > 0 || _endTimePrivateSale > 0 || _startTimePublicSale > 0 || _endTimePublicSale > 0 || _vestingStartTime > 0, "Invalid parameters");
        
        if (_startTimeSeedSale > 0) {
            require(block.timestamp < _startTimeSeedSale, "in past");
            startTimeSeedSale = _startTimeSeedSale;
        }

        if (_endTimeSeedSale > 0) {
            require(block.timestamp < _endTimeSeedSale, "in past");
            require(_endTimeSeedSale > _startTimeSeedSale, "ends before start");
            endTimeSeedSale = _endTimeSeedSale;
        }

        if (_startTimePrivateSale > 0) {
            require(block.timestamp < _startTimePrivateSale, "in past");
            startTimePrivateSale = _startTimePrivateSale;
        }

        if (_endTimePrivateSale > 0) {
            require(block.timestamp < _endTimePrivateSale, "in past");
            require(_endTimePrivateSale > _startTimePrivateSale, "ends before start");
            endTimePrivateSale = _endTimePrivateSale;
        }

        if (_startTimePublicSale > 0) {
            require(block.timestamp < _startTimePublicSale, "in past");
            startTimePublicSale = _startTimePublicSale;
        }

        if (_endTimePublicSale > 0) {
            require(block.timestamp < _endTimePublicSale, "in past");
            require(_endTimePublicSale > _startTimePublicSale, "ends before start");
            endTimePublicSale = _endTimePublicSale;
        }

        if (_vestingStartTime > 0) {
            require(
            _vestingStartTime >= endTimePublicSale,
            "Vesting starts before Presale ends"
        );
            vestingStartTime = _vestingStartTime;
        }
        presaleTimeInitiated = true;
        
    }


    /**
     * @dev Creates a new presale
     * @param _saleToken address of token to be sold
     * @param _baseDecimals No of decimals for the token. (10**18), for 18 decimal token
     * @param _amountTokensForLiquidity Amount of tokens for liq. if 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _vestingCliff Cliff period for vesting in seconds
     * @param _vestingPeriod Total vesting period(after vesting cliff) in seconds
     * @param _treasuryPercentage Percentage of raised funds that will go to the team
     * @param _treasuryAddress address to receive treasury percentage
     * @param _whitelistSeedSale array of addresses that are allowed to buy in Seed
     * @param _whitelistPrivateSale array of addresses that are allowed to buy in Private
     */
    function createPresale(
        address _saleToken,
        uint256 _baseDecimals,
        uint256 _amountTokensForLiquidity,
        uint256 _timeUnlockLiquidity,
        uint256 _vestingCliff,
        uint256 _vestingPeriod,
        uint256 _treasuryPercentage,
        address payable _treasuryAddress,
        address[] memory _whitelistSeedSale,
        address[] memory _whitelistPrivateSale
    )
        external
        onlyOwner
        checkSaleNotStartedYet()
    {   
        require(presaleTimeInitiated == true, "Time not set");
        require(_treasuryPercentage <= 30, ">30");
        
        saleToken = _saleToken;
        baseDecimals = _baseDecimals;
        amountTokensForLiquidity = _amountTokensForLiquidity;
        timeUnlockLiquidity = _timeUnlockLiquidity;
        vestingCliff = _vestingCliff;
        vestingPeriod = _vestingPeriod;
        treasuryPercentage = _treasuryPercentage;
        treasuryAddress = _treasuryAddress;
        for (uint i = 0; i < _whitelistSeedSale.length; i++) {
            whitelistSeedSale[_whitelistSeedSale[i]] = true;
        }
        for (uint i = 0; i < _whitelistPrivateSale.length; i++) {
            whitelistPrivateSale[_whitelistPrivateSale[i]] = true;
        }
    }

   

    /**
     * @dev To update the sale times
     * @param _startTimeSeedSale New start time
     * @param _endTimeSeedSale New end time
     * @param _startTimePrivateSale New start time
     * @param _endTimePrivateSale New end time
     * @param _startTimePublicSale New start time
     * @param _endTimePublicSale New end time
     * @param _vestingStartTime New start time
     */
    function changeSaleTimes(
        uint256 _startTimeSeedSale,
        uint256 _endTimeSeedSale,
        uint256 _startTimePrivateSale,
        uint256 _endTimePrivateSale,
        uint256 _startTimePublicSale,
        uint256 _endTimePublicSale,
        uint256 _vestingStartTime 
    )
        external
        onlyOwner
    {
        require(_startTimeSeedSale > 0 || _endTimeSeedSale > 0 || _startTimePrivateSale > 0 || _endTimePrivateSale > 0 || _startTimePublicSale > 0 || _endTimePublicSale > 0, "Invalid");

        if (_startTimeSeedSale > 0) {
            require(
                block.timestamp < startTimeSeedSale,
                "already started"
            );
            require(block.timestamp < _startTimeSeedSale, "time in past");
            startTimeSeedSale = _startTimeSeedSale;
        }

        if (_endTimeSeedSale > 0) {
            require(
                block.timestamp < endTimeSeedSale,
                "already ended"
            );
            require(_endTimeSeedSale > startTimeSeedSale, "Invalid");
            endTimeSeedSale = _endTimeSeedSale;
        }

        if (_startTimePrivateSale > 0) {
            require(
                block.timestamp < startTimePrivateSale,
                "already started"
            );
            require(block.timestamp < _startTimePrivateSale, "time in past");
            startTimePrivateSale = _startTimePrivateSale;
        }

        if (_endTimePrivateSale > 0) {
            require(
                block.timestamp < endTimePrivateSale,
                "already ended"
            );
            require(_endTimeSeedSale > endTimePrivateSale, "Invalid");
            endTimePrivateSale = _endTimePrivateSale;
        }

        if (_startTimePublicSale > 0) {
            require(
                block.timestamp < startTimePublicSale,
                "already started"
            );
            require(block.timestamp < _startTimePublicSale, "time in past");
            startTimePublicSale = _startTimePublicSale;
        }

        if (_endTimePublicSale > 0) {
            require(
                block.timestamp < endTimePublicSale,
                "already ended"
            );
            require(_endTimePublicSale > startTimePublicSale, "Invalid");
            endTimePublicSale = _endTimePublicSale;
        }

        if (_vestingStartTime > 0) {
            require(
            _vestingStartTime >= endTimePublicSale,
            "Vesting starts before Presale ends"
        );
            vestingStartTime = _vestingStartTime;
        }
    }


    /**
     * @dev To add presale sale data
     * @param _tokensToSellSeedSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _tokensToSellPrivateSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _tokensToSellPublicSale No of tokens to sell without denomination. If 1 million tokens to be sold then - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForSeed max tokens each user in seed can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForPrivate max tokens each user in private can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _maxAmountTokensForSalePerUserForPublic max tokens each user in public can buy. 1 million tokens - 1_000_000 has to be passed
     * @param _priceSeedSale Per token price for seed multiplied by (10**18). how much ETH does 1 token cost
     * @param _pricePrivateSale Per token price for private multiplied by (10**18). how much ETH does 1 token cost
     * @param _pricePublicSale Per token price for public multiplied by (10**18). how much ETH does 1 token cost
     */
    function addPresaleSaleData(
        uint256 _tokensToSellSeedSale,
        uint256 _tokensToSellPrivateSale,
        uint256 _tokensToSellPublicSale,
        uint256 _maxAmountTokensForSalePerUserForSeed,
        uint256 _maxAmountTokensForSalePerUserForPrivate,
        uint256 _maxAmountTokensForSalePerUserForPublic,
        uint256 _priceSeedSale,
        uint256 _pricePrivateSale,
        uint256 _pricePublicSale
    )
        external
        onlyOwner
        checkSaleNotStartedYet()
    {
        require(presaleTimeInitiated == true, "Time not set");
        
        if (_tokensToSellSeedSale > 0) {
            tokensToSellSeedSale = _tokensToSellSeedSale;
        }
        if (_tokensToSellPrivateSale > 0) {
            tokensToSellPrivateSale = _tokensToSellPrivateSale;
        }
        if (_tokensToSellPublicSale > 0) {
            tokensToSellPublicSale = _tokensToSellPublicSale;
        }

        uint256 totalTokens = tokensToSellSeedSale + tokensToSellPrivateSale + tokensToSellPublicSale;
        tokensToSellTotal = totalTokens;

        if (_maxAmountTokensForSalePerUserForSeed > 0) {
            maxAmountTokensForSalePerUserForSeed = _maxAmountTokensForSalePerUserForSeed;
        }
        if (_maxAmountTokensForSalePerUserForPrivate > 0) {
            maxAmountTokensForSalePerUserForPrivate = _maxAmountTokensForSalePerUserForPrivate;
        }
        if (_maxAmountTokensForSalePerUserForPublic > 0) {
            maxAmountTokensForSalePerUserForPublic = _maxAmountTokensForSalePerUserForPublic;
        }

        if (_priceSeedSale > 0) {
            priceSeedSale = _priceSeedSale;
        }
        if (_pricePrivateSale > 0) {
            pricePrivateSale = _pricePrivateSale;
        }
        if (_pricePublicSale > 0) {
            pricePublicSale = _pricePublicSale;
        }
                
    }



    /**
     * @dev To whitelist addresses for Seed, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function addToWhitelistSeedSale(address[] memory _wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            whitelistSeedSale[_wallets[i]] = true;
        }
    }


    /**
     * @dev To whitelist addresses for Private, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function addToWhitelistPrivateSale(address[] memory _wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            whitelistPrivateSale[_wallets[i]] = true;
        }
    }

    /**
     * @dev To remove addresses from the Seed whitelist, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function removeFromWhitelistSeedSale(address[] memory _wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            delete whitelistSeedSale[_wallets[i]];
        }
    }

    /**
     * @dev To remove addresses from the Private whitelist, can also be called durinig sale
     * @param _wallets Array of wallet addresses
     */
    function removeFromWhitelistPrivateSale(address[] memory _wallets)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            delete whitelistPrivateSale[_wallets[i]];
        }
    }

    /**
     * @dev To cancel the presale and let user withdraw their funds
     */
    function cancelPresale() external onlyOwner {
        require(!liquidityFinalized, "Liq already added");
        require(!tokensaleCanceled, "Already canceled");
        tokensaleCanceled = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromSeed()
        external
        onlyOwner
    {
        require(tokensaleCanceled == false, "Sale canceled");
        require(seedSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimeSeedSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedSeedSale * treasuryPercentage) / 100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        seedSaleTreasuryClaimed = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromPrivate()
        external
        onlyOwner
    {
        require(tokensaleCanceled == false, "Sale canceled");
        require(privateSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimePrivateSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedPrivateSale * treasuryPercentage) / 100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        privateSaleTreasuryClaimed = true;
    }

    /**
     * @dev sending the treasury percentage to the team. can only be called once. should be called before the next sale phase starts
     */
    function claimTreasuryPercentageFromPublic()
        external
        onlyOwner
    {
        require(tokensaleCanceled == false, "Sale canceled");
        require(publicSaleTreasuryClaimed == false, "Already finalized");
        require(block.timestamp > endTimePublicSale, "Sale not finished yet");
        uint256 treasuryAmountETH = (ethInvestedPublicSale * treasuryPercentage) / 100;

        if (treasuryAmountETH > 0) {
            treasuryAddress.transfer(treasuryAmountETH);
        }
        publicSaleTreasuryClaimed = true;
    }


    /**
     * @dev To finalize the sale by adding the tokens to liquidity and sending the treasury percentage to the team. can only be called once. 
     */
    function finalizeLiquidity()
        external
        onlyOwner
        checkSaleEnded()
    {
        require(seedSaleTreasuryClaimed == true && privateSaleTreasuryClaimed == true && publicSaleTreasuryClaimed == true, "Treasury not claimed");
        require(tokensaleCanceled == false, "Tokensale canceled");
        require(liquidityFinalized == false, "Already finalized");
        require(block.timestamp > endTimePublicSale, "Sale not over yet");
        uint256 LiquidityAmountETH = address(this).balance;
        uint256 tokensForLiquidity = amountTokensForLiquidity * baseDecimals;

        bool approveStatus = IContracts(saleToken).approve(
            ROUTER,
            tokensForLiquidity
        );
        require(approveStatus, "approve failed");

        (bool successAddLiq, ) = address(ROUTER).call{value: LiquidityAmountETH}(
            abi.encodeWithSignature(
                "addLiquidityAVAX(address,uint256,uint256,uint256,address,uint256)",
                saleToken,
                tokensForLiquidity,
                0,
                0,
                address(this),
                block.timestamp + 600
            )
        );
        require(successAddLiq, "liq failed");
        liquidityFinalized = true;
    }

    /**
     * @dev To send the LP tokens to a locker
     */
    function lockLiquidity()
        external
        onlyOwner
    {
        require(liquidityFinalized == true, "Liquidity not finalized");
        
        address pair = IContracts(FACTORY).getPair(saleToken, WETH);
        uint256 pairBalance = IContracts(pair).balanceOf(address(this));

        bool approveStatus = IContracts(pair).approve(
            LOCKER,
            pairBalance
        );
        require(approveStatus, "approve failed");

        IContracts(LOCKER).lock(treasuryAddress, pair, true, pairBalance, timeUnlockLiquidity, "LP Lock");
    }


    function _checkSaleNotStartedYet() private view {
        require(
            block.timestamp <= startTimeSeedSale, "Sale already started"
        );
    }

    modifier checkSaleNotStartedYet() {
        _checkSaleNotStartedYet();
        _;
    }

    function _checkSaleActive(uint256 amount) private view {
        require(block.timestamp >= startTimeSeedSale && block.timestamp <= endTimeSeedSale || block.timestamp >= startTimePrivateSale && block.timestamp <= endTimePrivateSale || block.timestamp >= startTimePublicSale && block.timestamp <= endTimePublicSale,
            "Sale not active"
        );
        require(
            amount > 0 && amount <= tokensToSellTotal,
            "Invalid amount"
        );
    }

    modifier checkSaleActive(uint256 amount) {
        _checkSaleActive(amount);
        _;
    }

    function _checkSaleEnded() private view {
        require(
            block.timestamp >= endTimePublicSale, "Sale not over yet"
        );
    }

    modifier checkSaleEnded() {
        _checkSaleEnded();
        _;
    }

    function isSaleActive(uint256 startTime, uint256 endTime) internal view returns (bool) {
        return block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function isSeedSaleActive() internal view returns (bool) {
        return isSaleActive(startTimeSeedSale, endTimeSeedSale);
    }

    function isPrivateSaleActive() internal view returns (bool) {
        return isSaleActive(startTimePrivateSale, endTimePrivateSale);
    }

    function isPublicSaleActive() internal view returns (bool) {
        return isSaleActive(startTimePublicSale, endTimePublicSale);
    }


    /**
     * @dev To buy into a presale using ETH. can only be called if any sale is currently active
     * @param amount No of tokens to buy. not in wei
     */
    function buyWithEth(uint256 amount)
        external
        payable
        checkSaleActive(amount)
        nonReentrant
        returns (bool)
    {
        require(tokensaleCanceled == false, "Sale canceled");
        require(msg.value > 0, "no ETH sent");

        
        uint256 ethAmount;
        if (isSeedSaleActive()) {
            require(whitelistPrivateSale[_msgSender()], "Not whitelisted");
            require(amount <= maxAmountTokensForSalePerUserForSeed , "Buying too many");
            require(userAmountBoughtSeed[_msgSender()] <= maxAmountTokensForSalePerUserForSeed, "Buying too many");
            require(tokensToSellSeedSale > 0, "All tokens have been sold");
            ethAmount = amount * priceSeedSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellSeedSale -= amount;
            userAmountBoughtSeed[_msgSender()] += amount;
            ethInvestedSeedSale += msg.value;
            
        }

        if (isPrivateSaleActive()) {
            require(whitelistPrivateSale[_msgSender()], "Not whitelisted");
            require(amount <= maxAmountTokensForSalePerUserForPrivate, "Buying too many");
            require(userAmountBoughtPrivate[_msgSender()] <= maxAmountTokensForSalePerUserForPrivate, "Buying too many");
            require(tokensToSellPrivateSale > 0, "All tokens have been sold");
            ethAmount = amount * pricePrivateSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellPrivateSale -= amount;
            userAmountBoughtPrivate[_msgSender()] += amount;
            ethInvestedPrivateSale += msg.value;
        }

        if (isPublicSaleActive()) {
            require(amount <= maxAmountTokensForSalePerUserForPublic, "Buying too many");
            require(userAmountBoughtPublic[_msgSender()] <= maxAmountTokensForSalePerUserForPublic, "Buying too many");
            require(tokensToSellPublicSale > 0, "All tokens have been sold");
            ethAmount = amount * pricePublicSale;
            require(msg.value == ethAmount, "Wrong ETH amount");
            tokensToSellPublicSale -= amount;
            userAmountBoughtPublic[_msgSender()] += amount;
            ethInvestedPublicSale += msg.value;
        }

        tokensToSellTotal -= amount;
        userDepositETH[_msgSender()] += ethAmount;

        if (userVesting[_msgSender()].totalAmount > 0) {
        userVesting[_msgSender()].totalAmount += (amount *
            baseDecimals);
        } else {
            userVesting[_msgSender()] = Vesting(
                (amount * baseDecimals),
                0,
                vestingStartTime + vestingCliff,
                vestingStartTime +
                    vestingCliff +
                    vestingPeriod
            );
        }
        return true;
    }


    /**
     * @dev Helper funtion to get claimable tokens for a given presale.
     * @param user User address
     */
    function claimableAmount(address user)
        public
        view
        returns (uint256)
    {
        Vesting memory _user = userVesting[user];
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");
        if (block.timestamp < _user.claimStart) return 0;
        if (block.timestamp >= _user.claimEnd) return amount;


        uint256 vestingDuration = _user.claimEnd - _user.claimStart;
        uint256 timeSinceStart = block.timestamp - _user.claimStart;
        uint256 ClaimablePerSecond = _user.totalAmount / vestingDuration;
        uint256 amountToClaim = (ClaimablePerSecond * timeSinceStart) - _user.claimedAmount;

        return amountToClaim;
    }

    /**
     * @dev To claim tokens after vesting cliff from a presale
     * @param user User address
     */
    function claim(address user) public returns (bool) {
        uint256 amount = claimableAmount(user);
        require(tokensaleCanceled == false, "Tokensale canceled");
        require(liquidityFinalized == true, "Liquidity not added yet");

        require(amount > 0, "Zero claim amount");
        require(
            saleToken != address(0),
            "Token address not set"
        );
        require(
            amount <=
                IContracts(saleToken).balanceOf(
                    address(this)
                ),
            "Not enough tokens in the contract"
        );
        userVesting[user].claimedAmount += amount;
        bool status = IContracts(saleToken).transfer(
            user,
            amount
        );
        require(status, "transfer failed");
        return true;
    }

    function withdrawETHPresaleCanceled() external {
        require(tokensaleCanceled == true, "Sale not canceled");
        require(userDepositETH[_msgSender()] > 0, "No ETH to withdraw");

        uint256 userETH = userDepositETH[_msgSender()];
        userDepositETH[_msgSender()] = 0;
        (bool success, ) = _msgSender().call{value: userETH}("");
        require(success, "Withdrawal failed");
    }
}