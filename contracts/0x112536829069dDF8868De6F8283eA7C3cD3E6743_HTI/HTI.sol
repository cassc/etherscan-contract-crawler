/**
 *Submitted for verification at Etherscan.io on 2020-05-23
*/

pragma solidity ^0.5.13;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

contract DIST {
    function accounting() public;
}

contract EXCH {
    function appreciateTokenPrice(uint256 _amount) public;
}

contract TOKEN {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;
    function stakeCount(address stakerAddr) external view returns (uint256);
    function stakeLists(address owner, uint256 stakeIndex) external view returns (uint40, uint72, uint72, uint16, uint16, uint16, bool);
    function currentDay() external view returns (uint256);
}

contract Ownable {
    address public owner;

    constructor() public {
      owner = address(0x583A013373A9e91fB64CBFFA999668bEdfdcf87C);
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract HTI is Ownable {
    using SafeMath for uint256;

    uint256 ACTIVATION_TIME = 1590274800;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);

        if (now <= (ACTIVATION_TIME + 2 minutes)) {
            require(tx.gasprice <= 0.2 szabo);
        }
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodianAddress);
        _;
    }

    modifier hasDripped {
        if (dividendPool > 0) {
          uint256 secondsPassed = SafeMath.sub(now, lastDripTime);
          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          profitPerShare = SafeMath.add(profitPerShare, (dividends * divMagnitude) / tokenSupply);
          dividendPool = dividendPool.sub(dividends);
          lastDripTime = now;
        }

        if (hexToSendFund("hexmax") >= 10000e8) {
            payFund("hexmax");
        }

        if (hexToSendFund("stableth") >= 10000e8) {
            payFund("stableth");
        }
        _;
    }

    modifier onlyTokenHolders {
        require(myTokens(true) > 0);
        _;
    }

    modifier onlyDivis {
        require(myDividends(true) > 0);
        _;
    }

    modifier isStakeActivated {
        require(stakeActivated == true);
        _;
    }

    event onDonation(
        address indexed customerAddress,
        uint256 tokens
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingHEX,
        uint256 tokensMinted,
        address indexed referredBy,
        uint256 timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 hexEarned,
        uint256 timestamp
    );

    event onRoll(
        address indexed customerAddress,
        uint256 hexRolled,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 hexWithdrawn
    );

    event onStakeStart(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 timestamp
    );

    event onStakeEnd(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 returnAmount,
        uint256 timestamp
    );

    string public name = "Infinihex";
    string public symbol = "HEX5";
    uint8 constant public decimals = 8;
    uint256 constant private divMagnitude = 2 ** 64;

    uint8 public percentage1 = 2;
    uint8 public percentage2 = 2;
    uint32 public dailyRate = 4320000;
    uint8 constant private buyInFee = 40;
    uint8 constant private rewardFee = 5;
    uint8 constant private referralFee = 1;
    uint8 constant private devFee = 1;
    uint8 constant private hexMaxFee = 1;
    uint8 constant private stableETHFee = 2;
    uint8 constant private sellOutFee = 9;
    uint8 constant private transferFee = 1;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) public lockedTokenBalanceLedger;
    mapping(address => uint256) private referralBalance;
    mapping(address => int256) private payoutsTo;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 staked;
       uint256 activeStakes;
    }

    mapping(address => Stats) public playerStats;

    uint256 public dividendPool = 0;
    uint256 public lastDripTime = ACTIVATION_TIME;
    uint256 public referralRequirement = 1000e8;
    uint256 public totalStakeBalance = 0;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;
    uint256 public totalStableFundReceived = 0;
    uint256 public totalStableFundCollected = 0;
    uint256 public totalMaxFundReceived = 0;
    uint256 public totalMaxFundCollected = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;

    address public uniswapAddress;
    address public approvedAddress1;
    address public approvedAddress2;
    address public distributionAddress;
    address public custodianAddress;

    EXCH hexmax;
    DIST stablethdist;

    TOKEN erc20;

    struct StakeStore {
      uint40 stakeID;
      uint256 hexAmount;
      uint72 stakeShares;
      uint16 lockedDay;
      uint16 stakedDays;
      uint16 unlockedDay;
      bool started;
      bool ended;
    }

    bool stakeActivated = true;
    bool feedActivated = true;
    mapping(address => mapping(uint256 => StakeStore)) public stakeLists;

    constructor() public {
        custodianAddress = address(0x24B23bB643082026227e945C7833B81426057b10);
        hexmax = EXCH(address(0xd52dca990CFC3760e0Cb0A60D96BE0da43fEbf19));
        uniswapAddress = address(0x05cDe89cCfa0adA8C88D5A23caaa79Ef129E7883);
        distributionAddress = address(0x699C01b92f2b036A1879416fC1977f60153A1729);
        stablethdist = DIST(distributionAddress);
        erc20 = TOKEN(address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39));
    }

    function() payable external {
        revert();
    }

    function checkAndTransferHEX(uint256 _amount) private {
        require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function distribute(uint256 _amount) isActivated public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferHEX(_amount);
        totalDonation += _amount;
        profitPerShare = SafeMath.add(profitPerShare, (_amount * divMagnitude) / tokenSupply);
        emit onDonation(msg.sender, _amount);
    }

    function distributePool(uint256 _amount) public {
        require(_amount > 0 && tokenSupply > 0, "must be a positive value and have supply");
        checkAndTransferHEX(_amount);
        totalDonation += _amount;
        dividendPool = dividendPool.add(_amount);
        emit onDonation(msg.sender, _amount);
    }

    function payFund(bytes32 exchange) public {
        if (exchange == "hexmax") {
          uint256 _hexToPay = totalMaxFundCollected.sub(totalMaxFundReceived);
          require(_hexToPay > 0);
          totalMaxFundReceived = totalMaxFundReceived.add(_hexToPay);
          erc20.approve(address(0xd52dca990CFC3760e0Cb0A60D96BE0da43fEbf19), _hexToPay);
          hexmax.appreciateTokenPrice(_hexToPay);
        } else if (exchange == "stableth") {
          uint256 _hexToPay = totalStableFundCollected.sub(totalStableFundReceived);
          require(_hexToPay > 0);
          totalStableFundReceived = totalStableFundReceived.add(_hexToPay);

          if (feedActivated && uniswapAddress.balance >= 500e18) {
            erc20.transfer(distributionAddress, _hexToPay);
            uint256 _balance = erc20.balanceOf(distributionAddress);

            if (_balance >= 10000e8) {
              stablethdist.accounting();
            }
          } else {
            profitPerShare = SafeMath.add(profitPerShare, (_hexToPay * divMagnitude) / tokenSupply);
          }
        }
    }

    function roll() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] +=  (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(address(0), _customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function withdraw() hasDripped onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        erc20.transfer(_customerAddress, _dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function buy(address _referredBy, uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferHEX(_amount);
        return purchaseTokens(_referredBy, msg.sender, _amount);
    }

    function buyFor(address _referredBy, address _customerAddress, uint256 _amount) hasDripped public returns (uint256) {
        checkAndTransferHEX(_amount);
        return purchaseTokens(_referredBy, _customerAddress, _amount);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingHEX, uint256 _rewards) private returns(uint256) {
        uint256 _amountOfTokens = _incomingHEX;
        uint256 _fee = _rewards * divMagnitude;

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        if (tokenSupply > 0) {
            tokenSupply = tokenSupply.add(_amountOfTokens);
            profitPerShare += (_rewards * divMagnitude / tokenSupply);
            _fee = _fee - (_fee - (_amountOfTokens * (_rewards * divMagnitude / tokenSupply)));
        } else {
            tokenSupply = _amountOfTokens;
        }

        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens - _fee);
        payoutsTo[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), _customerAddress, _amountOfTokens);

        return _amountOfTokens;
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingHEX) isActivated private returns (uint256) {
        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingHEX;

        require(_incomingHEX > 0);

        uint256 _dividendFee = _incomingHEX.mul(buyInFee).div(100);
        uint256 _rewardFee = _incomingHEX.mul(rewardFee).div(100);
        uint256 _referralBonus = _incomingHEX.mul(referralFee).div(100);
        uint256 _devFee = _incomingHEX.mul(devFee).div(100);
        uint256 _hexMaxFee = _incomingHEX.mul(hexMaxFee).div(100);
        uint256 _stableETHFee = _incomingHEX.mul(stableETHFee).div(100);

        uint256 _entryFee = _incomingHEX.mul(50).div(100);
        uint256 _taxedHEX = _incomingHEX.sub(_entryFee);

        _purchaseTokens(owner, _devFee, 0);

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger[_referredBy] >= referralRequirement) {
            referralBalance[_referredBy] = referralBalance[_referredBy].add(_referralBonus);
        } else {
            _rewardFee = _rewardFee.add(_referralBonus);
        }

        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _taxedHEX, _rewardFee);

        dividendPool = dividendPool.add(_dividendFee);
        totalMaxFundCollected = totalMaxFundCollected.add(_hexMaxFee);
        totalStableFundCollected = totalStableFundCollected.add(_stableETHFee);

        emit onTokenPurchase(_customerAddress, _incomingHEX, _amountOfTokens, _referredBy, now);

        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress].sub(lockedTokenBalanceLedger[_customerAddress]));

        uint256 _dividendFee = _amountOfTokens.mul(sellOutFee).div(100);
        uint256 _devFee = _amountOfTokens.mul(devFee).div(100);
        uint256 _taxedHEX = _amountOfTokens.sub(_dividendFee).sub(_devFee);

        _purchaseTokens(owner, _devFee, 0);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens + (_taxedHEX * divMagnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        dividendPool = dividendPool.add(_dividendFee);

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedHEX, now);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) isActivated hasDripped onlyTokenHolders external returns (bool) {
        address _customerAddress = msg.sender;
        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress].sub(lockedTokenBalanceLedger[_customerAddress]));

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = _amountOfTokens.mul(transferFee).div(100);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);

        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_taxedTokens);
        tokenBalanceLedger[owner] = tokenBalanceLedger[owner].add(_tokenFee);

        payoutsTo[_customerAddress] -= (int256) (profitPerShare * _amountOfTokens);
        payoutsTo[_toAddress] += (int256) (profitPerShare * _taxedTokens);
        payoutsTo[owner] += (int256) (profitPerShare * _tokenFee);

        emit Transfer(_customerAddress, owner, _tokenFee);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        return true;
    }

    function stakeStart(uint256 _amount, uint256 _days) public isStakeActivated {
        require(_amount <= 4722366482869645213695);
        require(balanceOf(msg.sender, true) >= _amount);

        erc20.stakeStart(_amount, _days); // revert or succeed

        uint256 _stakeIndex;
        uint40 _stakeID;
        uint72 _stakeShares;
        uint16 _lockedDay;
        uint16 _stakedDays;

        _stakeIndex = erc20.stakeCount(address(this));
        _stakeIndex = SafeMath.sub(_stakeIndex, 1);

        (_stakeID,,_stakeShares,_lockedDay,_stakedDays,,) = erc20.stakeLists(address(this), _stakeIndex);

        uint256 _uniqueID =  uint256(keccak256(abi.encodePacked(_stakeID, _stakeShares))); // unique enough
        require(stakeLists[msg.sender][_uniqueID].started == false); // still check for collision
        stakeLists[msg.sender][_uniqueID].started = true;

        stakeLists[msg.sender][_uniqueID] = StakeStore(_stakeID, _amount, _stakeShares, _lockedDay, _stakedDays, uint16(0), true, false);

        totalStakeBalance = SafeMath.add(totalStakeBalance, _amount);

        playerStats[msg.sender].activeStakes += 1;
        playerStats[msg.sender].staked += _amount;

        lockedTokenBalanceLedger[msg.sender] = SafeMath.add(lockedTokenBalanceLedger[msg.sender], _amount);

        emit onStakeStart(msg.sender, _uniqueID, now);
    }

    function _stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) private view returns (uint16){
        uint40 _stakeID;
        uint72 _stakedHearts;
        uint72 _stakeShares;
        uint16 _lockedDay;
        uint16 _stakedDays;
        uint16 _unlockedDay;

        (_stakeID,_stakedHearts,_stakeShares,_lockedDay,_stakedDays,_unlockedDay,) = erc20.stakeLists(address(this), _stakeIndex);
        require(stakeLists[msg.sender][_uniqueID].started == true && stakeLists[msg.sender][_uniqueID].ended == false);
        require(stakeLists[msg.sender][_uniqueID].stakeID == _stakeIdParam && _stakeIdParam == _stakeID);
        require(stakeLists[msg.sender][_uniqueID].hexAmount == uint256(_stakedHearts));
        require(stakeLists[msg.sender][_uniqueID].stakeShares == _stakeShares);
        require(stakeLists[msg.sender][_uniqueID].lockedDay == _lockedDay);
        require(stakeLists[msg.sender][_uniqueID].stakedDays == _stakedDays);

        return _unlockedDay;
    }

    function stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) hasDripped public {
        uint16 _unlockedDay = _stakeEnd(_stakeIndex, _stakeIdParam, _uniqueID);

        if (_unlockedDay == 0){
          stakeLists[msg.sender][_uniqueID].unlockedDay = uint16(erc20.currentDay()); // no penalty/penalty/reward
        } else {
          stakeLists[msg.sender][_uniqueID].unlockedDay = _unlockedDay;
        }

        uint256 _balance = erc20.balanceOf(address(this));

        erc20.stakeEnd(_stakeIndex, _stakeIdParam); // revert or 0 or less or equal or more hex returned.
        stakeLists[msg.sender][_uniqueID].ended = true;

        uint256 _amount = SafeMath.sub(erc20.balanceOf(address(this)), _balance);
        uint256 _stakedAmount = stakeLists[msg.sender][_uniqueID].hexAmount;
        uint256 _difference;

        if (_amount <= _stakedAmount) {
          _difference = SafeMath.sub(_stakedAmount, _amount);
          tokenSupply = SafeMath.sub(tokenSupply, _difference);
          tokenBalanceLedger[msg.sender] = SafeMath.sub(tokenBalanceLedger[msg.sender], _difference);
          int256 _updatedPayouts = (int256) (profitPerShare * _difference);
          payoutsTo[msg.sender] -= _updatedPayouts;
          emit Transfer(msg.sender, address(0), _difference);
        } else if (_amount > _stakedAmount) {
          _difference = SafeMath.sub(_amount, _stakedAmount);
          _difference = purchaseTokens(address(0), msg.sender, _difference);
        }

        totalStakeBalance = SafeMath.sub(totalStakeBalance, _stakedAmount);
        playerStats[msg.sender].activeStakes -= 1;

        lockedTokenBalanceLedger[msg.sender] = SafeMath.sub(lockedTokenBalanceLedger[msg.sender], _stakedAmount);

        emit onStakeEnd(msg.sender, _uniqueID, _amount, now);
    }

    function setName(string memory _name) onlyOwner public
    {
        name = _name;
    }

    function setSymbol(string memory _symbol) onlyOwner public
    {
        symbol = _symbol;
    }

    function setHexStaking(bool _stakeActivated) onlyOwner public
    {
        stakeActivated = _stakeActivated;
    }

    function setFeeding(bool _feedActivated) onlyOwner public
    {
        feedActivated = _feedActivated;
    }

    function setUniswapAddress(address _proposedAddress) onlyOwner public
    {
       uniswapAddress = _proposedAddress;
    }

    function approveAddress1(address _proposedAddress) onlyOwner public
    {
       approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian public
    {
       approvedAddress2 = _proposedAddress;
    }

    function setDistributionAddress() public
    {
        require(approvedAddress1 != address(0) && approvedAddress1 == approvedAddress2);
        distributionAddress = approvedAddress1;
        stablethdist = DIST(approvedAddress1);
    }

    function approveDrip1(uint8 _percentage) onlyOwner public
    {
        require(_percentage > 1 && _percentage < 6);
        percentage1 = _percentage;
    }

    function approveDrip2(uint8 _percentage) onlyCustodian public
    {
        require(_percentage > 1 && _percentage < 6);
        percentage2 = _percentage;
    }

    function setDripPercentage() public
    {
        require(percentage1 == percentage2);
        dailyRate = 86400 / percentage1 * 100;
    }

    function totalHexBalance() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function totalSupply() public view returns(uint256) {
        return tokenSupply;
    }

    function myTokens(bool _stakeable) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress, _stakeable);
    }

    function myEstimateDividends(bool _includeReferralBonus, bool _dayEstimate) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? estimateDividendsOf(_customerAddress, _dayEstimate) + referralBalance[_customerAddress] : estimateDividendsOf(_customerAddress, _dayEstimate) ;
    }

    function estimateDividendsOf(address _customerAddress, bool _dayEstimate) public view returns (uint256) {
        uint256 _profitPerShare = profitPerShare;

        if (dividendPool > 0) {
          uint256 secondsPassed = 0;

          if (_dayEstimate == true){
            secondsPassed = 86400;
          } else {
            secondsPassed = SafeMath.sub(now, lastDripTime);
          }

          uint256 dividends = secondsPassed.mul(dividendPool).div(dailyRate);

          if (dividends > dividendPool) {
            dividends = dividendPool;
          }

          _profitPerShare = SafeMath.add(_profitPerShare, (dividends * divMagnitude) / tokenSupply);
        }

        return (uint256) ((int256) (_profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function balanceOf(address _customerAddress, bool _stakeable) public view returns (uint256) {
        if (_stakeable == false) {
            return tokenBalanceLedger[_customerAddress];
        }
        else if (_stakeable == true) {
            return (tokenBalanceLedger[_customerAddress].sub(lockedTokenBalanceLedger[_customerAddress]));
        }
    }

    function sellPrice() public view returns (uint256) {
        uint256 _hex = 1e8;
        uint256 _dividendFee = _hex.mul(sellOutFee).div(100);
        uint256 _devFee = _hex.mul(devFee).div(100);

        return (_hex.sub(_dividendFee).sub(_devFee));
    }

    function buyPrice() public view returns(uint256) {
        uint256 _hex = 1e8;
        uint256 _entryFee = _hex.mul(50).div(100);
        return (_hex.add(_entryFee));
    }

    function calculateTokensReceived(uint256 _tronToSpend) public view returns (uint256) {
        uint256 _entryFee = _tronToSpend.mul(50).div(100);
        uint256 _amountOfTokens = _tronToSpend.sub(_entryFee);

        return _amountOfTokens;
    }

    function calculateHexReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply);
        uint256 _exitFee = _tokensToSell.mul(10).div(100);
        uint256 _taxedHEX = _tokensToSell.sub(_exitFee);

        return _taxedHEX;
    }

    function hexToSendFund(bytes32 exchange) public view returns(uint256) {
        if (exchange == "hexmax") {
          return totalMaxFundCollected.sub(totalMaxFundReceived);
        } else if (exchange == "stableth") {
          return totalStableFundCollected.sub(totalStableFundReceived);
        }
    }
}