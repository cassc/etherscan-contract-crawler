pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./BoringOwnable.sol";

interface IPancakeFactory {
  function getPair(address token1, address token2) external pure returns (address);
}


contract PepeMints is BoringOwnable, ReentrancyGuard {

    address launchpadContract;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address payable public _dev;
    address payable public buyBackContract; // receives BNB
    bool public settingDone = false;
    uint public dripBuyAuctionFee = 500;
    uint public devAuctionBuyFee = 1250;
    // 2.5% of lobby entried goto lottery pot
    uint public lotterySharePercentage = 250;

    address public contrAddr;

    address public constant _pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IUniswapV2Router02 _pancakeRouter;
    address public constant _pancakeFactoryAddress = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    IPancakeFactory _pancakeFactory;
    address public tradingPair = address(0);

    uint public usedETHforBuyBack;
    uint public lpBal;

    uint public overallStakedToken;
    uint public overallCollectedDividends;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Stake(address indexed user, uint stakeAmount, uint indexed stakeIdx, uint stakeTime);
    event EnterAuction(address indexed user, uint rawAmount, uint entryTime);
    event ClaimRewards(address indexed user, uint indexed stakeIdx, uint rewardAmount, uint claimTime);
    event DayAuctionEntry(uint day, uint value);

    event LotteryWinner(address indexed addr, uint amount, uint lastRecord);
    event LotteryUpdate(uint newPool, uint lastRecord);

    string public constant name = "PepeMints.vip";
    string public constant symbol = "PM";
    uint public constant decimals = 18;

    uint public totalBurned;

    uint private _totalSupply;

    mapping(address => uint) private _Balances;

    /* Time of contract launch */
    uint public immutable LAUNCH_TIME;
    uint public oneDay = 15 minutes;  // TODO: make 1 day again
    uint public immutable offDays = oneDay; 
    uint public currentDay = 0;
    uint public lastBUYINday;
    uint public buyBackPerecent = 500;
    uint public taxFactor = 10000;
    uint public percentToReceiveOnSell = 9000; // percentage of tokens to be received when buying from PancakeSwap
    uint public percentToReceiveOnBuy = 2000; // percentage of tokens to be received when buying from PancakeSwap
    
    bool public sellTaxOn = false;
    bool public buyTaxOn = true;

    function toggleSellTaxOn() external onlyOwner {
      sellTaxOn = !sellTaxOn;
    }

    function toggleBuyTaxOn() external onlyOwner {
      buyTaxOn = !buyTaxOn;
    }

    struct StakeData{
      uint stakeTime;
      uint amount;
      uint claimed;
      uint lastUpdate;
      uint collected;
    }

    uint private weiPerSforOnePoint5perDay = 17361111111111;  // this token/wei amount need to be accounted per second to have 1.5 ETH per day

    uint public dailyAvailableTokens = 20000 ether;

    mapping(uint => uint) dailyAvailableTokensHistory;

    /* Every day's lobby pool is % lower than previous day's */
    uint public dailyAvailableTokensDecreasePercentage = 150; // 1.5%

    mapping(address => mapping(uint => StakeData)) public stakes;
    mapping(address => uint) public stakeNumber;
    mapping(address => address) public myRef;

    /* day's total auction entry */ 
    mapping(uint => uint) public auctionEntry;
    /* day's liq already added? */ 
    mapping(uint => bool) public liqAdded;
    // total auction entry  
    uint public auctionEntry_allDays;

    // counting unique (unique for every day only) Auction enteries for each day
    mapping(uint => uint) public usersCountDaily;
    // counting unique (unique for every day only) users
    uint public usersCount = 0;

    // mapping for allowance
    mapping(address => mapping (address => uint)) private _allowance;

    
    // Auction memebrs overall data 
    struct memberAuction_overallData{
        uint overall_collectedTokens;
        uint total_auctionEnteries;
        uint overall_stakedTokens;
    }
    // new map for every user's overall data  
    mapping(address => memberAuction_overallData) public mapMemberAuction_overallData;
    
    /* Auction memebrs data */ 
    struct memberAuction{
        uint memberAuctionValue;
        uint memberAuctionEntryDay;
        bool hasChangedShareToToken;
        address referrer;
    }
    /* new map for every entry (users are allowed to enter multiple times a day) */ 
    mapping(address => mapping(uint => memberAuction)) public mapMemberAuction;

    /* new map for the referrers tokens */
    struct refData{
      uint refEarnedTokens;
    }
    mapping(address => mapping(uint => refData)) public mapRefData;
    
    // Addresses that excluded from transferTax when receiving
    mapping(address => bool) private _excludedFromSellTaxSender;
    // Addresses that excluded from transferTax when receiving
    mapping(address => bool) private _excludedFromBuyTaxReceiver;


    constructor(uint _LAUNCH_TIME) {
        LAUNCH_TIME = _LAUNCH_TIME;
  
        _dev = payable(msg.sender);

        _pancakeRouter = IUniswapV2Router02(_pancakeRouterAddress);
        _pancakeFactory = IPancakeFactory(_pancakeFactoryAddress);

        contrAddr = address(this);

        _excludedFromSellTaxSender[msg.sender] = true;
        _excludedFromSellTaxSender[contrAddr] = true;
        _excludedFromSellTaxSender[_pancakeRouterAddress] = true;
        _excludedFromSellTaxSender[_dev] = true;

        _excludedFromBuyTaxReceiver[BURN_ADDRESS] = true;
        _excludedFromBuyTaxReceiver[msg.sender] = true;
        _excludedFromBuyTaxReceiver[contrAddr] = true;
        _excludedFromBuyTaxReceiver[_pancakeRouterAddress] = true;
        _excludedFromBuyTaxReceiver[_dev] = true;

        _mint(contrAddr, 1 ether);
    }
    
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _Balances[account];
    }

    function allowance(address owner_, address spender) external view returns (uint) {
        return _allowance[owner_][spender];
    }

    function approve(address spender, uint value) public returns (bool) {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _allowance[msg.sender][spender] =
          _allowance[msg.sender][spender] + addedValue;
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }

      
    function setDailyAvailableTokens(uint _dailyAvailableTokens) external onlyOwner {
        dailyAvailableTokens = _dailyAvailableTokens;
    }

    function setDailyAvailableTokensDecreasePercentage(uint _dailyAvailableTokensDecreasePercentage) external onlyOwner {
        require(_dailyAvailableTokensDecreasePercentage <= 1000, "Can't decrease by more than 10% per day");
        dailyAvailableTokensDecreasePercentage = _dailyAvailableTokensDecreasePercentage;
    }

    // Set addresses of dev
    function setDev(address payable dev) external onlyOwner {
      _dev = dev;

      _excludedFromSellTaxSender[dev] = true;  
      _excludedFromBuyTaxReceiver[dev] = true; 
    }

      // Set addresses of dev
    function setBuyBackContract( address payable _buyBackContract) external onlyOwner {
      buyBackContract = _buyBackContract;

      _excludedFromSellTaxSender[_buyBackContract] = true;  
      _excludedFromBuyTaxReceiver[_buyBackContract] = true;  
    }

    function setLaunchpad(address _launchpadContract) external onlyOwner {
      launchpadContract = _launchpadContract;
    }

    // Set the setting Done boolean to true (after all userstakes are set and all needed WC are minted!)
    function setSettingDone() external onlyOwner {
        settingDone = true;
     }

        // Set the fee that goes to dev with each auction entry
    function setLotterySharePercentage(uint _lotterySharePercentage) external onlyOwner {
      require(_lotterySharePercentage <= 250, "setDevAuctionFee: Dev Auction Fee cant be above 2.5%" );
        lotterySharePercentage = _lotterySharePercentage;
    }

    // Set the fee that goes to dev with each auction entry
    function setDevAuctionBuyFee(uint _devAuctionBuyFee) external onlyOwner {
      require(_devAuctionBuyFee <= 1250, "setDevAuctionBuyFee: Dev Auction Fee cant be above 12.5%" );
        devAuctionBuyFee = _devAuctionBuyFee;
    }

    // Set the fee that goes to dev with each auction entry
    function setDripBuyAuctionFee(uint _dripBuyAuctionFee) external onlyOwner {
      require(_dripBuyAuctionFee <= 500, "setDripBuAuctionFee: Drip Buy Auction Fee cant be above 5%" );
        dripBuyAuctionFee = _dripBuyAuctionFee;
     }

    // Set the Buyback Percentage
    function setBuyBackPercent(uint _buyBackPerecent) external onlyOwner {
        require(50 <= _buyBackPerecent, "Value to small, use at least 50!");
        require(_buyBackPerecent <= 1000, "Value to big, use at max 1000!");
        buyBackPerecent = _buyBackPerecent;
     }

    // Set the Tax Factor for the discounted buy from Pancake
     function setTaxFactor(uint _taxFactor) external onlyOwner {
        require(10000 <= _taxFactor, "Value to small, use at least 10000!");
        require(_taxFactor <= 20000, "Value to big, use at max 20000!");
        taxFactor = _taxFactor;
     }


    // Set the percentage to be received when buying from PancakeSwap
     function setPercentToReceiveOnSell(uint _percentToReceiveOnSell) external onlyOwner {
        require(9000 <= _percentToReceiveOnSell, "Value to small, use at least 9000!");
        require(_percentToReceiveOnSell <= 10000, "Value to big, use at max 10000!");
        percentToReceiveOnSell = _percentToReceiveOnSell;
     }
    function setPercentToReceiveOnBuy(uint _percentToReceiveOnBuy) external onlyOwner {
        require(2000 <= _percentToReceiveOnBuy, "Value to small, use at least 2000!");
        require(_percentToReceiveOnBuy <= 10000, "Value to big, use at max 10000!");
        percentToReceiveOnBuy = _percentToReceiveOnBuy;
     }
     
     
    // Set address to be in- or excluded from Tax when receiving
    function setExcludedFromSellTaxReceiver(address _account, bool _excluded) external onlyOwner {
        _excludedFromSellTaxSender[_account] = _excluded;
     }
    
    // Returns if the address is excluded from Tax or not when receiving.    
    function isExcludedFromSellTaxSender(address _account) public view returns (bool) {
        return _excludedFromSellTaxSender[_account];
    }
    
    // Set address to be in- or excluded from Tax when receiving
    function setExcludedFromBuyTaxReceiver(address _account, bool _excluded) external onlyOwner {
        _excludedFromBuyTaxReceiver[_account] = _excluded;
     }
    
    // Returns if the address is excluded from Tax or not when receiving.    
    function isExcludedFromBuyTaxReceiver(address _account) public view returns (bool) {
        return _excludedFromBuyTaxReceiver[_account];
    }

    function transfer(address to, uint amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }  

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        if( msg.sender != contrAddr ) {
          _allowance[from][msg.sender] = _allowance[from][msg.sender] - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    // internal transfer function to apply the transfer tax ONLY for buys from liquidity
    function _transfer(address from, address to, uint amount) internal virtual {
        // For Taxed Transfer
        bool _isSellTaxedSender = !isExcludedFromSellTaxSender(from);
        bool _isBuyTaxedRecipient = !isExcludedFromBuyTaxReceiver(to);

        require(amount <= _Balances[from], "transfer amount exceeds balance");

        bool didTax = false;
        uint amountAfterTax = amount;

        if (sellTaxOn && to == tradingPair && _isSellTaxedSender) {   // if sender is pair (its a buy tx) AND is a TaxedRecipient  
          didTax = true;
          amountAfterTax = amount * percentToReceiveOnSell / 10000;
        } else if (buyTaxOn && from == tradingPair && _isBuyTaxedRecipient) {
          didTax = true;
          amountAfterTax = amount * percentToReceiveOnBuy / 10000;
        }

        _Balances[to] = _Balances[to] + amountAfterTax;
        emit Transfer(from, to, amountAfterTax);

        if (didTax)
          _burn(from, amount - amountAfterTax);

        _Balances[from] = _Balances[from] - amountAfterTax;
    }

    function _mint(address _user, uint _amount) internal { 
      _Balances[_user] = _Balances[_user] + _amount;
      _totalSupply = _totalSupply + _amount;
      emit Transfer(address(0), _user, _amount);
    }

    function _devMint(uint _amount) external onlyOwner {
      require(settingDone == false, "devMint: dev can not mint any more!");
      _Balances[_dev] = _Balances[_dev] + _amount;
      _totalSupply = _totalSupply + _amount;
      emit Transfer(address(0), _dev, _amount);
    }

    function burn(uint _amount) external {
      _burn(msg.sender, _amount);
    }

    function _burn(address _user, uint _amount) internal {
      if (_amount == 0) return;

      totalBurned = totalBurned + _amount;

      _Balances[_user] = _Balances[_user] - _amount;
      _totalSupply = _totalSupply - _amount;
      emit Transfer(_user, address(0), _amount);
    }

    // function for users to stake Token they have in their wallet
    function stake(uint _amount) external {
      require(_Balances[msg.sender] >= _amount, "not enough token to stake");
      require(_amount > 0, "can't stake 0 tokens");

      require(_amount <= _Balances[msg.sender], "transfer amount exceeds balance");
      _Balances[msg.sender] = _Balances[msg.sender] - _amount;
      _Balances[contrAddr] = _Balances[contrAddr] + _amount;
      emit Transfer(msg.sender, contrAddr, _amount);

      stakes[msg.sender][stakeNumber[msg.sender]].amount = _amount;
      stakes[msg.sender][stakeNumber[msg.sender]].stakeTime = block.timestamp;
      stakes[msg.sender][stakeNumber[msg.sender]].lastUpdate = LAUNCH_TIME > block.timestamp ? LAUNCH_TIME : block.timestamp;

      stakeNumber[msg.sender]++;
      overallStakedToken += _amount;
      emit Stake(msg.sender, _amount, stakeNumber[msg.sender] - 1, block.timestamp);
    }

    // internal function for to stake user Token
    function stakeInt(uint _amount) internal {
      if (_amount == 0)
        return;
      stakes[msg.sender][stakeNumber[msg.sender]].amount = _amount;
      stakes[msg.sender][stakeNumber[msg.sender]].stakeTime = block.timestamp;
      stakes[msg.sender][stakeNumber[msg.sender]].lastUpdate = LAUNCH_TIME > block.timestamp ? LAUNCH_TIME : block.timestamp;

      stakeNumber[msg.sender]++;
      overallStakedToken += _amount;
      emit Stake(msg.sender, _amount, stakeNumber[msg.sender] - 1, block.timestamp);
    }
 
    // internal function to stake refferal earnings with no claim fee
    function refStake(uint _amount) internal {     
      if (_amount == 0)
        return; 
      stakes[msg.sender][stakeNumber[msg.sender]].amount = _amount;
      stakes[msg.sender][stakeNumber[msg.sender]].stakeTime = block.timestamp;
      stakes[msg.sender][stakeNumber[msg.sender]].lastUpdate = LAUNCH_TIME > block.timestamp ? LAUNCH_TIME : block.timestamp;

      stakeNumber[msg.sender]++;
      overallStakedToken += _amount;
      emit Stake(msg.sender, _amount, stakeNumber[msg.sender] - 1, block.timestamp);
    }

    // function to set the right amount of userstakes for UI ( in case errors occur when setting stakes)
    function setUsersStakeNumber(address user, uint _stakeNumber) external {
      require(settingDone == false, "setStakesUser: dev can not set any more!");
      require(msg.sender == _dev, "setStakesUser: you are not allowed to set Stakes!");

      stakeNumber[user] = _stakeNumber;
    }

    // function to set the right amount of overallStakedToken for UI (in case errors occur when setting stakes)
    function setOverallStakedToken(uint _amount) external {
      require(settingDone == false, "setStakesUser: dev can not set any more!");
      require(msg.sender == _dev, "setStakesUser: you are not allowed to set Stakes!");
      
      overallStakedToken = _amount;
    }

    // function to set the right amount of auctionEntry_allDays (total ETH collected) for UI (in case errors occur when setting stakes)
    function setAuctionEntry_allDays(uint _auctionEntry_allDays) external {
      require(settingDone == false, "setStakesUser: dev can not set any more!");
      require(msg.sender == _dev, "setStakesUser: you are not allowed to set Stakes!");
      
      auctionEntry_allDays = _auctionEntry_allDays;
    }
    

    // function for devs to set previous contracts userstakings
    function addStakesUser(address user,uint _amount) external {
      require(settingDone == false, "setStakesUser: dev can not set any more!");
      require(msg.sender == launchpadContract || msg.sender == _dev || msg.sender == owner, "setStakesUser: you are not allowed to set Stakes!");
      stakes[user][stakeNumber[user]].stakeTime = block.timestamp;
      stakes[user][stakeNumber[user]].amount = _amount;
      stakes[user][stakeNumber[user]].lastUpdate = LAUNCH_TIME > block.timestamp ? LAUNCH_TIME : block.timestamp;

      stakeNumber[user]++;
      overallStakedToken += _amount;
      emit Stake(user, _amount, stakeNumber[msg.sender] - 1, block.timestamp);
    }

    function setStakesUser(address user, uint _stakeNumber, uint _stakeTime, uint _amount, uint _claimed, uint _lastUpdate) external {
      require(settingDone == false, "setStakesUser: dev can not set any more!");
      require(msg.sender == _dev || msg.sender == owner, "setStakesUser: you are not allowed to set Stakes!");

      overallStakedToken -= stakes[user][_stakeNumber].amount;
      overallStakedToken += _amount;

      stakes[user][_stakeNumber].stakeTime = _stakeTime;
      stakes[user][_stakeNumber].amount = _amount;
      stakes[user][_stakeNumber].claimed = _claimed;
      stakes[user][_stakeNumber].lastUpdate = LAUNCH_TIME > _lastUpdate ? LAUNCH_TIME : _lastUpdate;
      stakes[user][_stakeNumber].collected = _claimed;
    }

    // function to see which day it is
    function thisDay() public view returns (uint) {
        return ((block.timestamp - LAUNCH_TIME) / oneDay);
    }

    // function to get amount out from buying from LP
    function getAmountFromLiq(uint amountIn) public view returns (uint) {
      address[] memory path;
      path = new address[](2);
      path[0] = _pancakeRouter.WETH();
      path[1] = contrAddr;

      uint[] memory amountOutMins = _pancakeRouter.getAmountsOut(amountIn, path);
      return amountOutMins[amountOutMins.length - 1];
    }

    // function to do a "discounted" buy from liq and do a stake for the user
    // "discounted" buy means that the tax will be less than if users buy in pancake
    function buyAndStake(address _referrer) external nonReentrant payable returns (bool) {
      uint rawAmount = msg.value;
      require(rawAmount > 0, "No ETH to buy Token!");

      uint devFee = rawAmount * devAuctionBuyFee / 10000;
      sendETH(_dev, devFee); // transfer dev share of ETH to dev d
  
      uint buyBackContractFee = rawAmount * dripBuyAuctionFee / 10000;
      sendETH(buyBackContract, buyBackContractFee); // transfer share of ETH to buyBackContract

      uint lotteryFee = rawAmount * lotterySharePercentage / 10000;

      uint stakeAmount = getAmountFromLiq(rawAmount * taxFactor / 10000);

      address[] memory path = new address[](2);
      path[0] = _pancakeRouter.WETH();
      path[1] = contrAddr;

      uint ethToBuyWith = rawAmount - (devFee + buyBackContractFee + lotteryFee);

      // Buy and Burn Token from LP with ETH
      _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethToBuyWith} (
        0,
        path,
        BURN_ADDRESS,
        block.timestamp+1
      );

      _burn(BURN_ADDRESS, _Balances[BURN_ADDRESS]);

      bool isValidReferral = (_referrer != address(0) && _referrer != msg.sender);
      bool doingReferralLogic = false;

      if (isValidReferral)
        myRef[msg.sender] = _referrer;
      if (isValidReferral || myRef[msg.sender] != address(0))
        doingReferralLogic = true;

      if (doingReferralLogic) {
        // earned ref tokens are accounted for the next day so be sure ref can claim all past days token at once
        mapRefData[myRef[msg.sender]][currentDay + 1].refEarnedTokens += stakeAmount * 5 / 100;

        // referee gets 1% boost too for partaking in ref scheme
        stakeAmount = stakeAmount * 101 / 100;
      }

      stakeInt(stakeAmount);
      return true;
    }

    // function to add last days collected ETH to new liquiity and update the day
    function updateDaily() public {
      // this is true once per day
      if (currentDay != thisDay()) {
        // 2.5% of lobby entry of each day goes to lottery_Pool
        lottery_Pool += (auctionEntry[currentDay] * lotterySharePercentage) /10000;
        if (block.timestamp >= LAUNCH_TIME + offDays + oneDay) {
          uint contractETHBalance = lottery_Pool < contrAddr.balance ? contrAddr.balance - lottery_Pool : 0;
          if (contractETHBalance > 100000) {
              uint percentageToUse = 10000 - (devAuctionBuyFee + dripBuyAuctionFee + lotterySharePercentage);

              uint collectedThatDay = auctionEntry[lastBUYINday] * percentageToUse / 10000;
              if (collectedThatDay != 0 && !liqAdded[lastBUYINday] ) {
                  uint ETHtoAdd;
                  if (collectedThatDay < contractETHBalance) {
                    ETHtoAdd = collectedThatDay;
                  } else { ETHtoAdd = contractETHBalance;}

                  uint tokenToAdd = (dailyAvailableTokens * (percentageToUse - (percentageToUse / 10))) / 10000;
                  _mint(contrAddr, tokenToAdd);
                  _mint(_dev, dailyAvailableTokens * 5 / 100);

                  if (IERC20(contrAddr).allowance( contrAddr, _pancakeRouterAddress ) == 0) {
                      approve(_pancakeRouterAddress, type(uint).max);
                      IERC20(contrAddr).approve(_pancakeRouterAddress, type(uint).max);
                  }

                  uint addedEth;
                  uint addedToken;
                  if (ETHtoAdd > 100000) {
                    (uint addedTokenTmp, uint addedEthTmp,) = 
                    _pancakeRouter.addLiquidityETH{value: ETHtoAdd} (
                      contrAddr,
                      tokenToAdd,
                      0,
                      0,
                      contrAddr,
                      block.timestamp+1
                    );
                    addedEth = addedEthTmp;
                    addedToken = addedTokenTmp;
                  }

                  liqAdded[lastBUYINday] = true; 

                  uint ethBal = lottery_Pool < contrAddr.balance ? contrAddr.balance - lottery_Pool : 0;

                  if (addedEth > 100000000 && ethBal > 100000) {
                    uint currentLiqRatio = addedToken * 1e24 / addedEth;
                    uint neededToken = currentLiqRatio * ethBal / 1e24;

                    _mint(contrAddr, neededToken);

                    _pancakeRouter.addLiquidityETH{value: ethBal} (
                      contrAddr,
                      neededToken,
                      0,
                      0,
                      contrAddr,
                      block.timestamp+1
                    );

                    uint leftOverToken = IERC20(contrAddr).balanceOf(contrAddr);

                    if (leftOverToken > 1.1 ether) {
                      _burn(contrAddr, leftOverToken - 1 ether);
                    }
                  }
                }
            }

            dailyAvailableTokensHistory[currentDay] = dailyAvailableTokens;
            _updateDailyAvailableTokens();
            currentDay = thisDay();

            if (tradingPair == address(0)) {
              tradingPair = _pancakeFactory.getPair(_pancakeRouter.WETH(), contrAddr);
            }

            lpBal = IERC20(tradingPair).balanceOf(contrAddr);

            if (lpBal > 100000) { 
              burnAndBuyback();    
            }
          } else {
            currentDay = thisDay();
          }

          checkLottery();

          emit DayAuctionEntry(currentDay, auctionEntry[currentDay - 1]);
        }
    }

      /* Every day's lobby pool reduces by a % */
    function _updateDailyAvailableTokens() internal {
        dailyAvailableTokens -= ((dailyAvailableTokens * dailyAvailableTokensDecreasePercentage) /10000);
    }


    // to make the contract being able to receive ETH from Router
    receive() external payable {}

    // function to remove some of the collected LP, and use funds to buyback and burn token, daily
    function burnAndBuyback() internal {   
        if( IERC20(tradingPair).allowance(contrAddr, _pancakeRouterAddress ) == 0) {
          IERC20(tradingPair).approve(_pancakeRouterAddress, type(uint).max);
        }

        uint lpBalToRemove = lpBal * buyBackPerecent / 10000;

        uint ethBalBefore = contrAddr.balance;

        if (lpBalToRemove > 100000) {
          // remove X% of the colected Liq daily to buyback Token
          _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            contrAddr,
            lpBalToRemove,
            0,
            0,
            contrAddr,
            block.timestamp+1
          );
        }

        uint ethGain = contrAddr.balance - ethBalBefore;
        usedETHforBuyBack += ethGain;

          address[] memory path = new address[](2);
          path[0] = _pancakeRouter.WETH();
          path[1] = contrAddr;

        if (ethGain > 100000) {
          // Buyback token from LP from received ETH
          _pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethGain } (
            0,
            path,
            BURN_ADDRESS,
            block.timestamp+1
          );
        }

        _burn(BURN_ADDRESS, _Balances[BURN_ADDRESS]);
        _burn(address(0), _Balances[address(0)]);

        // Burn Token received from Liq removal
        uint receivedToken = IERC20(contrAddr).balanceOf(contrAddr);
        if (receivedToken > 100000) {
          _burn(contrAddr, receivedToken);
        }      
    }

    // function for users to participate in the daily auctions
    function buyShareFromAuction() external nonReentrant payable returns (bool) {
        uint rawAmount = msg.value;
        require(rawAmount > 0, "No ETH to buy Shares!");
        require(block.timestamp >= LAUNCH_TIME + offDays, "Auctions have not started yet!");

        uint devAmount = rawAmount * devAuctionBuyFee / 10000;
        uint buyBackContractAmount = rawAmount * dripBuyAuctionFee / 10000;

        sendETH(_dev, devAmount); // transfer dev share of ETH to dev
        sendETH(buyBackContract, buyBackContractAmount); // transfer buyBack share of ETH to buyBackContract

        updateDaily();

        auctionEntry[currentDay] += rawAmount;
        auctionEntry_allDays += rawAmount;
        lastBUYINday = currentDay;
        liqAdded[currentDay] = false;
    
        if (mapMemberAuction[msg.sender][currentDay].memberAuctionValue == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        mapMemberAuction_overallData[msg.sender].total_auctionEnteries += rawAmount;

        mapMemberAuction[msg.sender][currentDay].memberAuctionValue += rawAmount; 
        mapMemberAuction[msg.sender][currentDay].memberAuctionEntryDay = currentDay;
        mapMemberAuction[msg.sender][currentDay].hasChangedShareToToken = false;      


        if (mapMemberAuction[msg.sender][currentDay].memberAuctionValue > lottery_topBuy_today) {
            // new top buyer
            lottery_topBuy_today = mapMemberAuction[msg.sender][currentDay].memberAuctionValue;
            lottery_topBuyer_today = msg.sender;
        }

        emit EnterAuction(msg.sender, rawAmount, block.timestamp);
        return true;        
    }


    function calculateTokenPerShareOnDay(uint _day) public view returns (uint) {
      uint collectedThatDay = auctionEntry[_day];
      uint tokenPerShare = collectedThatDay > 0 ? dailyAvailableTokensHistory[_day] * 1e24 / collectedThatDay : 0;
      return tokenPerShare;
    }

    // function for users to change their shares from last day into token and immediately stakeInt
    function claimTokenFromSharesAndStake(uint _day, address _referrer) external nonReentrant returns (bool) {
      updateDaily();
      require(_day < currentDay, "Day must be over to claim!");
      require(mapMemberAuction[msg.sender][_day].hasChangedShareToToken == false, "User has already changed his shares to Token that Day!");
      uint userShares = mapMemberAuction[msg.sender][_day].memberAuctionValue; 

      uint amountUserTokens = calculateTokenPerShareOnDay(_day) * userShares / 1e24;      

      bool isValidReferral = (_referrer != address(0) && _referrer != msg.sender);
      bool doingReferralLogic = false;

      if (isValidReferral)
        myRef[msg.sender] = _referrer;
      if (isValidReferral || myRef[msg.sender] != address(0))
        doingReferralLogic = true;

      if (doingReferralLogic) {
        // earned ref tokens are accounted for the next day so be sure ref can claim all past days token at once
        mapRefData[myRef[msg.sender]][_day + 1].refEarnedTokens += amountUserTokens * 5 / 100;

        // referee gets 1% boost too for partaking in ref scheme
        amountUserTokens = amountUserTokens * 101 / 100;
      }

      stakeInt(amountUserTokens);

      mapMemberAuction[msg.sender][_day].hasChangedShareToToken = true;

      return true;
    }

    // function for refs to claim the past days tokens and stakeInt them fee free
    function claimRefTokensAndStake(uint _day) external nonReentrant returns (bool) {
      updateDaily();
      require(_day < currentDay, "Refs Day must be over to claim!");
      require(mapRefData[msg.sender][_day].refEarnedTokens != 0, "Ref has not earned Token that day!");

      uint refTokens = mapRefData[msg.sender][_day].refEarnedTokens;

      refStake(refTokens);

      mapRefData[msg.sender][_day].refEarnedTokens = 0;
      return true;
    }

    // only called when claim (collect) is called
    // calculates the earned rewards since LAST UPDATE
    // earning is 1.5% per day
    // earning stopps after 240 days
    function calcReward(address _user, uint _stakeIndex) public view returns (uint) {
      if(stakes[_user][_stakeIndex].stakeTime == 0) {
        return 0;
      }
      // value 17361111111111 gives 1 ether per day as multiplier!
      uint multiplier = (block.timestamp - stakes[_user][_stakeIndex].lastUpdate) * weiPerSforOnePoint5perDay;
      // for example: if user amount is 100 and user has staked for 240 days and not collected so far,
      // reward would be 240, if 240 was already collected reward will be 0
      if((stakes[_user][_stakeIndex].amount * multiplier / 100 ether) + stakes[_user][_stakeIndex].collected > 
          stakes[_user][_stakeIndex].amount * 240 / 100) {
        return (stakes[_user][_stakeIndex].amount * 240 / 100) - stakes[_user][_stakeIndex].collected;
      }
      // in same example: below 240 days of stakeInt the reward is stakes.amount * days/100
      return stakes[_user][_stakeIndex].amount * multiplier / 100 ether;
    }


    // (not called internally) Only for viewing the earned rewards in UI
    // caculates claimable rewards
    function calcClaim(address _user, uint _stakeIndex) external view returns (uint) {
      if (stakes[_user][_stakeIndex].stakeTime == 0) {
        return 0;
      }
      // value 17361111111111 gives 1 ether per day as multiplier!
      uint multiplier = (block.timestamp - stakes[_user][_stakeIndex].lastUpdate) * weiPerSforOnePoint5perDay;

      if ((multiplier * stakes[_user][_stakeIndex].amount / 100 ether) + stakes[_user][_stakeIndex].collected >
          stakes[_user][_stakeIndex].amount * 240 / 100) {
        return (stakes[_user][_stakeIndex].amount * 240 / 100) - stakes[_user][_stakeIndex].claimed;
      }
      return ((stakes[_user][_stakeIndex].amount * multiplier / 100 ether) + stakes[_user][_stakeIndex].collected)
        - stakes[_user][_stakeIndex].claimed;
    }

    // function to update the collected rewards to user stakeInt collected value and update the last updated value
    function _collect(address _user, uint _stakeIndex) internal {
      stakes[_user][_stakeIndex].collected = stakes[_user][_stakeIndex].collected + calcReward(_user, _stakeIndex);
      stakes[_user][_stakeIndex].lastUpdate = LAUNCH_TIME > block.timestamp ? LAUNCH_TIME : block.timestamp;
    }

    // function for users to claim rewards and also pay claim fee
    function claimRewards(uint _stakeIndex) public nonReentrant {
      _collect(msg.sender, _stakeIndex);
      uint reward = stakes[msg.sender][_stakeIndex].collected - stakes[msg.sender][_stakeIndex].claimed;
      stakes[msg.sender][_stakeIndex].claimed = stakes[msg.sender][_stakeIndex].collected;
      _mint(msg.sender, reward);
      overallCollectedDividends += reward;

      emit ClaimRewards(msg.sender, _stakeIndex, reward, block.timestamp);
    }

    // function for users to create a new stakeInt from earnings of another stakeInt
    function reinvest(uint _stakeIndex, address _referrer) public nonReentrant {
      _collect(msg.sender, _stakeIndex); // collected amount and lastUpdate gets updated
      // calculate Reward = _amount
      uint _amount = stakes[msg.sender][_stakeIndex].collected - stakes[msg.sender][_stakeIndex].claimed;
      
      bool isValidReferral = (_referrer != address(0) && _referrer != msg.sender);
      bool doingReferralLogic = false;

      if (isValidReferral)
        myRef[msg.sender] = _referrer;
      if (isValidReferral || myRef[msg.sender] != address(0))
        doingReferralLogic = true;

      _mint(_dev, _amount * 5 / 100); // 5% for dev
      if (doingReferralLogic) {
        // earned ref tokens are accounted for the next day so be sure ref can claim all past days token at once
        mapRefData[myRef[msg.sender]][currentDay + 1].refEarnedTokens += _amount * 5 / 100;

        // referee gets 33.34% for reinvesting and  1% boost too for partaking in ref scheme
        _amount = _amount * 13433 / 10000;
      } else {
        _amount = _amount * 13333 / 10000;
      }

      // new stakeInt is opened with reward = _amount of "old" stakeInt!
      stakeInt(_amount);
      overallCollectedDividends += _amount;
      // the the "old" stakeInt of which the rewards were reinvested in a new stakeInt gets updated!
      stakes[msg.sender][_stakeIndex].claimed = stakes[msg.sender][_stakeIndex].collected;

      
      updateDaily();
      emit ClaimRewards(msg.sender, _stakeIndex, _amount, block.timestamp);
    }

    function claimRewardsInRange(uint idx0, uint idx1) external {
      require(idx0 < stakeNumber[msg.sender], "idx0 is too high for the number of user stakes!");

      if (idx1 <= idx0) {
        claimRewards(idx0);
        return;
      }

      uint lastIndex = stakeNumber[msg.sender] < idx1 + 1 ? stakeNumber[msg.sender] : idx1 + 1;

      uint cumulativeRewardsAmount = 0;

      for (uint i = idx0;i<lastIndex;i++) {
        _collect(msg.sender, idx0);
        uint reward = stakes[msg.sender][i].collected - stakes[msg.sender][i].claimed;
        stakes[msg.sender][i].claimed = stakes[msg.sender][i].collected;
        

        cumulativeRewardsAmount += reward;
        overallCollectedDividends += reward;

        emit ClaimRewards(msg.sender, i, reward, block.timestamp);
      }

      _mint(msg.sender, cumulativeRewardsAmount);

      updateDaily();
    }

    function reinvestInRange(uint idx0, uint idx1, address _referrer) external {
      require(idx0 < stakeNumber[msg.sender], "idx0 is too high for the number of user stakes!");

      if (idx1 <= idx0) {
        reinvest(idx0, _referrer);
        return;
      }

      uint lastIndex = stakeNumber[msg.sender] < idx1 + 1 ? stakeNumber[msg.sender] : idx1 + 1;
  
      uint cumulativeReinvestmentAmount = 0;
      uint cumulativeDevCutAmount = 0;

      bool isValidReferral = (_referrer != address(0) && _referrer != msg.sender);
      bool doingReferralLogic = false;

      if (isValidReferral)
        myRef[msg.sender] = _referrer;
      if (isValidReferral || myRef[msg.sender] != address(0))
        doingReferralLogic = true;


      for (uint i = idx0;i<lastIndex;i++) {
        _collect(msg.sender, i); // collected amount and lastUpdate gets updated
        // calculate Reward = _amount
        uint _amount = stakes[msg.sender][i].collected - stakes[msg.sender][i].claimed;

        cumulativeDevCutAmount += _amount * 5 / 100; // 5% for dev
        if (doingReferralLogic) {
          // earned ref tokens are accounted for the next day so be sure ref can claim all past days token at once
          mapRefData[myRef[msg.sender]][currentDay + 1].refEarnedTokens += _amount * 5 / 100;

          // referee gets 33.34% for reinvesting and  1% boost too for partaking in ref scheme
          _amount = _amount * 13433 / 10000;
        } else {
          _amount = _amount * 13333 / 10000;
        }

        cumulativeReinvestmentAmount += _amount;
        overallCollectedDividends += _amount;
        // the the "old" stakeInt of which the rewards were reinvested in a new stakeInt gets updated!

        emit ClaimRewards(msg.sender, i, _amount, block.timestamp);
      }

      _mint(_dev, cumulativeDevCutAmount);
      // new stakeInt is opened with reward = _amount of "old" stakeInt!
      stakeInt(cumulativeReinvestmentAmount);

      updateDaily();
    }

    function getUserStakesInRange(address _user, uint idx0, uint idx1) external view returns (StakeData[] memory) {
      require(idx0 < stakeNumber[_user], "idx0 is too high for the number of user stakes!");

      StakeData[] memory stakesTmp;

      if (idx1 <= idx0) {
        stakesTmp = new StakeData[](1);
        stakesTmp[0] = stakes[_user][idx0];
        return stakesTmp;
      }

      uint lastIndex = stakeNumber[_user] < idx1 + 1 ? stakeNumber[_user] : idx1 + 1;
      uint arraySize = lastIndex - idx0;
      
      stakesTmp = new StakeData[](arraySize);
      uint c = 0;
      for (uint i = idx0;i<lastIndex;i++) {
        stakesTmp[c] = stakes[_user][i];
        c++;
      }
      return stakesTmp;
    }

    /* top lottery buyer of the day (so far) */
    uint public lottery_topBuy_today;
    address public lottery_topBuyer_today;

    /* latest top lottery bought amount*/
    uint public lottery_topBuy_latest;

    /* lottery reward pool */
    uint public lottery_Pool;

  /**
   * @dev Runs once a day and checks for lottry winner
   */
  function checkLottery() internal {
    if (lottery_Pool > 0 && lottery_topBuy_today > lottery_topBuy_latest) {
      // we have a winner
      // 50% of the pool goes to the winner

      lottery_topBuy_latest = lottery_topBuy_today;

      uint winnerAmount = (lottery_Pool * 30) /100;
      lottery_Pool -= winnerAmount;
      sendETH(lottery_topBuyer_today, winnerAmount);

      emit LotteryWinner(lottery_topBuyer_today, winnerAmount, lottery_topBuy_latest);
    } else {
      // no winner, reducing the record by 20%
      lottery_topBuy_latest -= (lottery_topBuy_latest * 100) /1000;
    }

    lottery_topBuyer_today = address(0);
    lottery_topBuy_today = 0;

    emit LotteryUpdate(lottery_Pool, lottery_topBuy_latest);
  }

  function sendETH(address to, uint amount) internal {
    if (amount > 0) {
      (bool transferSuccess, ) = payable(to).call{
          value: amount
      }("");
      require(transferSuccess, "ETH transfer failed");
    }
  }

  function getAllToken(address token) public onlyOwner {
      uint256 amountToken = IERC20(token).balanceOf(contrAddr);
      IERC20(token).transfer(_dev, amountToken);
  }

  function recoverETH(address to, uint amount) external onlyOwner {
    if (amount > 0) {
      (bool transferSuccess, ) = payable(to).call{
          value: amount
      }("");
      require(transferSuccess, "ETH transfer failed");
    }
  }
}