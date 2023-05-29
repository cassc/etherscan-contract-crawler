/**
 *Submitted for verification at Etherscan.io on 2020-03-28
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

contract EXCH {
    function distribute(uint256 _amount) public returns (uint256);
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
    owner = address(0x86d9344094297cf5a6c77c07476F40C2F9903CD8);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract HMX is Ownable {
    using SafeMath for uint256;

    uint ACTIVATION_TIME = 1585440000;

    modifier isActivated {
        require(now >= ACTIVATION_TIME);

        if (now <= (ACTIVATION_TIME + 2 minutes)) {
            require(tx.gasprice <= 0.2 szabo);
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

    event onDistribute(
        address indexed customerAddress,
        uint256 tokens
    );

    event onTokenAppreciation(
        uint256 tokenPrice,
        uint256 timestamp
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
        uint256 currentTokens,
        uint256 timestamp
    );

    event onStakeEnd(
        address indexed customerAddress,
        uint256 uniqueID,
        uint256 returnAmount,
        uint256 difference,
        uint256 timestamp
    );

    string public name = "HEXMAX";
    string public symbol = "HEX4";
    uint8 constant public decimals = 8;
    uint256 constant private priceMagnitude = 1e8;
    uint256 constant private divMagnitude = 2 ** 64;

    uint8 constant private appreciateFee = 2;
    uint8 constant private buyInFee = 6;
    uint8 constant private sellOutFee = 6;
    uint8 constant private transferFee = 1;
    uint8 constant private devFee = 1;
    uint8 constant private hexTewFee = 1;
    uint8 constant private hexRiseFee = 1;

    mapping(address => uint256) private tokenBalanceLedger;
    mapping(address => uint256) private referralBalance;
    mapping(address => int256) private payoutsTo;
    mapping(address => uint256) public lockedHexBalanceLedger;

    struct Stats {
       uint256 deposits;
       uint256 withdrawals;
       uint256 staked;
       uint256 activeStakes;
    }

    mapping(address => Stats) public playerStats;

    uint256 public referralRequirement = 100000e8;
    uint256 public totalStakeBalance = 0;
    uint256 public totalPlayer = 0;
    uint256 public totalDonation = 0;
    uint256 public totalTewFundReceived = 0;
    uint256 public totalTewFundCollected = 0;
    uint256 public totalRiseFundReceived = 0;
    uint256 public totalRiseFundCollected = 0;

    uint256 private tokenSupply = 0;
    uint256 private profitPerShare = 0;
    uint256 private contractValue = 0;
    uint256 private tokenPrice = 100000000;

    EXCH hextew;
    EXCH hexrise;

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
        hextew = EXCH(address(0xD495cC8C7c29c7fA3E027a5759561Ab68C363609));
        hexrise = EXCH(address(0x8D5CA96e9984662625e6cbF490Da40c9D7270865));
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
        emit onDistribute(msg.sender, _amount);
    }

    function appreciateTokenPrice(uint256 _amount) isActivated public {
        require(_amount > 0, "must be a positive value");
        checkAndTransferHEX(_amount);
        totalDonation += _amount;
        contractValue = contractValue.add(_amount);

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        emit onTokenAppreciation(tokenPrice, now);
    }

    function payFund(bytes32 exchange) public {
        if (exchange == "hextew") {
          uint256 _hexToPay = totalTewFundCollected.sub(totalTewFundReceived);
          require(_hexToPay > 0);
          totalTewFundReceived = totalTewFundReceived.add(_hexToPay);
          erc20.approve(address(0xD495cC8C7c29c7fA3E027a5759561Ab68C363609), _hexToPay);
          hextew.distribute(_hexToPay);
        } else if (exchange == "hexrise") {
          uint256 _hexToPay = totalRiseFundCollected.sub(totalRiseFundReceived);
          require(_hexToPay > 0);
          totalRiseFundReceived = totalRiseFundReceived.add(_hexToPay);
          erc20.approve(address(0x8D5CA96e9984662625e6cbF490Da40c9D7270865), _hexToPay);
          hexrise.appreciateTokenPrice(_hexToPay);
        }
    }

    function roll() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] +=  (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(address(0), _customerAddress, _dividends);
        emit onRoll(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _lockedToken = (lockedHexBalanceLedger[_customerAddress].mul(priceMagnitude)) / tokenPrice;
        uint256 _tokens = tokenBalanceLedger[_customerAddress].sub(_lockedToken);
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo[_customerAddress] += (int256) (_dividends * divMagnitude);
        _dividends += referralBalance[_customerAddress];
        referralBalance[_customerAddress] = 0;
        erc20.transfer(_customerAddress, _dividends);
        playerStats[_customerAddress].withdrawals += _dividends;
        emit onWithdraw(_customerAddress, _dividends);
    }

    function buy(address _referredBy, uint256 _amount) public returns (uint256) {
        checkAndTransferHEX(_amount);
        return purchaseTokens(_referredBy, msg.sender, _amount);
    }

    function buyFor(address _referredBy, address _customerAddress, uint256 _amount) public returns (uint256) {
        checkAndTransferHEX(_amount);
        return purchaseTokens(_referredBy, _customerAddress, _amount);
    }

    function _purchaseTokens(address _customerAddress, uint256 _incomingHEX, uint256 _dividends) private returns(uint256) {
        uint256 _amountOfTokens = (_incomingHEX.mul(priceMagnitude)) / tokenPrice;
        uint256 _fee = _dividends * divMagnitude;

        require(_amountOfTokens > 0 && _amountOfTokens.add(tokenSupply) > tokenSupply);

        if (tokenSupply > 0) {
            tokenSupply = tokenSupply.add(_amountOfTokens);
            profitPerShare += (_dividends * divMagnitude / tokenSupply);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * divMagnitude / tokenSupply)));
        } else {
            tokenSupply = _amountOfTokens;
        }

        tokenBalanceLedger[_customerAddress] =  tokenBalanceLedger[_customerAddress].add(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens - _fee);
        payoutsTo[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), _customerAddress, _amountOfTokens);

        return _amountOfTokens;
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingHEX) private isActivated returns (uint256) {
        if (playerStats[_customerAddress].deposits == 0) {
            totalPlayer++;
        }

        playerStats[_customerAddress].deposits += _incomingHEX;

        require(_incomingHEX > 0);

        uint256 _appreciateFee = _incomingHEX.mul(appreciateFee).div(100);
        uint256 _dividendFee = feedActivated == true ? _incomingHEX.mul(buyInFee).div(100) : _incomingHEX.mul(buyInFee+1).div(100);
        uint256 _devFee = _incomingHEX.mul(devFee).div(100);
        uint256 _hexTewFee = feedActivated == true ? _incomingHEX.mul(hexTewFee).div(100) : 0;
        uint256 _taxedHEX = _incomingHEX.sub(_appreciateFee).sub(_dividendFee).sub(_devFee).sub(_hexTewFee);

        _purchaseTokens(owner, _devFee, 0);
        uint256 _amountOfTokens = _purchaseTokens(_customerAddress, _taxedHEX, _dividendFee);

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger[_referredBy] >= referralRequirement) {
            referralBalance[_referredBy] = referralBalance[_referredBy].add(_hexTewFee);
        } else {
            totalTewFundCollected = totalTewFundCollected.add(_hexTewFee);
        }

        contractValue = contractValue.add(_incomingHEX.sub(_hexTewFee).sub(_dividendFee));

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        if (hexToSendFund("hextew") >= 10000e8) {
            payFund("hextew");
        }

        emit onTokenPurchase(_customerAddress, _incomingHEX, _amountOfTokens, _referredBy, now);
        emit onTokenAppreciation(tokenPrice, now);

        return _amountOfTokens;
    }

    function sell(uint256 _amountOfTokens) isActivated onlyTokenHolders public {
        address _customerAddress = msg.sender;
        uint256 _lockedToken = (lockedHexBalanceLedger[_customerAddress].mul(priceMagnitude)) / tokenPrice;

        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress].sub(_lockedToken));

        uint256 _hex = _amountOfTokens.mul(tokenPrice).div(priceMagnitude);
        uint256 _appreciateFee = _hex.mul(appreciateFee).div(100);
        uint256 _dividendFee = feedActivated == true ? _hex.mul(sellOutFee).div(100) : _hex.mul(sellOutFee+1).div(100);
        uint256 _devFee = _hex.mul(devFee).div(100);
        uint256 _hexRiseFee = feedActivated == true ? _hex.mul(hexRiseFee).div(100) : 0;

        _purchaseTokens(owner, _devFee, 0);
        totalRiseFundCollected = totalRiseFundCollected.add(_hexRiseFee);

        _hex = _hex.sub(_appreciateFee).sub(_dividendFee).sub(_devFee).sub(_hexRiseFee);

        tokenSupply = tokenSupply.sub(_amountOfTokens);
        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare * _amountOfTokens + (_hex * divMagnitude));
        payoutsTo[_customerAddress] -= _updatedPayouts;

        if (tokenSupply > 0) {
            profitPerShare = SafeMath.add(profitPerShare, (_dividendFee * divMagnitude) / tokenSupply);
        }

        contractValue = contractValue.sub(_hex.add(_hexRiseFee).add(_dividendFee));

        if (tokenSupply > priceMagnitude) {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        if (hexToSendFund("hexrise") >= 10000e8) {
            payFund("hexrise");
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _hex, now);
        emit onTokenAppreciation(tokenPrice, now);
    }

    function transfer(address _toAddress, uint256 _amountOfTokens) isActivated onlyTokenHolders external returns (bool) {
        address _customerAddress = msg.sender;
        uint256 _lockedToken = (lockedHexBalanceLedger[_customerAddress].mul(priceMagnitude)) / tokenPrice;

        require(_amountOfTokens > 0 && _amountOfTokens <= tokenBalanceLedger[_customerAddress].sub(_lockedToken));

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = _amountOfTokens.mul(transferFee).div(100);
        uint256 _taxedTokens = _amountOfTokens.sub(_tokenFee);

        tokenBalanceLedger[_customerAddress] = tokenBalanceLedger[_customerAddress].sub(_amountOfTokens);
        tokenBalanceLedger[_toAddress] = tokenBalanceLedger[_toAddress].add(_taxedTokens);

        payoutsTo[_customerAddress] -= (int256) (profitPerShare * _amountOfTokens);
        payoutsTo[_toAddress] += (int256) (profitPerShare * _taxedTokens);

        tokenSupply = tokenSupply.sub(_tokenFee);

        if (tokenSupply > priceMagnitude)
        {
            tokenPrice = (contractValue.mul(priceMagnitude)) / tokenSupply;
        }

        emit Transfer(_customerAddress, address(0), _tokenFee);
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
        emit onTokenAppreciation(tokenPrice, now);

        return true;
    }

    function stakeStart(uint256 _amount, uint256 _days) public isStakeActivated {
        require(_amount <= 4722366482869645213695);
        require(hexBalanceOfNoFee(msg.sender, true) >= _amount);

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

        lockedHexBalanceLedger[msg.sender] = SafeMath.add(lockedHexBalanceLedger[msg.sender], _amount);

        emit onStakeStart(msg.sender, _uniqueID, calculateTokensReceived(_amount, false), now);
    }

    function _stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) public view returns (uint16){
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

    function stakeEnd(uint256 _stakeIndex, uint40 _stakeIdParam, uint256 _uniqueID) public {
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
            contractValue = contractValue.sub(_difference);
            _difference = (_difference.mul(priceMagnitude)) / tokenPrice;
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

        lockedHexBalanceLedger[msg.sender] = SafeMath.sub(lockedHexBalanceLedger[msg.sender], _stakedAmount);

        emit onStakeEnd(msg.sender, _uniqueID, _amount, _difference, now);
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

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    function balanceOf(address _customerAddress, bool _stakeable) public view returns (uint256) {
        if (_stakeable == false) {
            return tokenBalanceLedger[_customerAddress];
        }
        else if (_stakeable == true) {
            uint256 _lockedToken = (lockedHexBalanceLedger[_customerAddress].mul(priceMagnitude)) / tokenPrice;
            return (tokenBalanceLedger[_customerAddress].sub(_lockedToken));
        }
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare * tokenBalanceLedger[_customerAddress]) - payoutsTo[_customerAddress]) / divMagnitude;
    }

    function sellPrice(bool _includeFees) public view returns (uint256) {
        uint256 _appreciateFee = 0;
        uint256 _dividendFee = 0;
        uint256 _devFee = 0;
        uint256 _hexRiseFee = 0;

        if (_includeFees) {
            _appreciateFee = tokenPrice.mul(appreciateFee).div(100);
            _dividendFee = feedActivated == true ? tokenPrice.mul(sellOutFee).div(100) : tokenPrice.mul(sellOutFee+1).div(100);
            _devFee = tokenPrice.mul(devFee).div(100);
            _hexRiseFee = feedActivated == true ? tokenPrice.mul(hexRiseFee).div(100) : 0;
        }

        return (tokenPrice.sub(_appreciateFee).sub(_dividendFee).sub(_devFee).sub(_hexRiseFee));
    }

    function buyPrice(bool _includeFees) public view returns(uint256) {
        uint256 _appreciateFee = 0;
        uint256 _dividendFee = 0;
        uint256 _devFee = 0;
        uint256 _hexTewFee = 0;

        if (_includeFees) {
            _appreciateFee = tokenPrice.mul(appreciateFee).div(100);
            _dividendFee = feedActivated == true ? tokenPrice.mul(buyInFee).div(100) : tokenPrice.mul(buyInFee+1).div(100);
            _devFee = tokenPrice.mul(devFee).div(100);
            _hexTewFee = feedActivated == true ? tokenPrice.mul(hexTewFee).div(100) : 0;
        }

        return (tokenPrice.add(_appreciateFee).add(_dividendFee).add(_devFee).add(_hexTewFee));
    }

    function calculateTokensReceived(uint256 _hexToSpend, bool _includeFees) public view returns (uint256) {
        uint256 _appreciateFee = 0;
        uint256 _dividendFee = 0;
        uint256 _devFee = 0;
        uint256 _hexTewFee = 0;

        if (_includeFees) {
            _appreciateFee = _hexToSpend.mul(appreciateFee).div(100);
            _dividendFee = feedActivated == true ? _hexToSpend.mul(buyInFee).div(100) : _hexToSpend.mul(buyInFee+1).div(100);
            _devFee = _hexToSpend.mul(devFee).div(100);
            _hexTewFee = feedActivated == true ? _hexToSpend.mul(hexTewFee).div(100) : 0;
        }

        uint256 _taxedHEX = _hexToSpend.sub(_appreciateFee).sub(_dividendFee).sub(_devFee).sub(_hexTewFee);
        uint256 _amountOfTokens = (_taxedHEX.mul(priceMagnitude)) / tokenPrice;

        return _amountOfTokens;
    }

    function hexBalanceOf(address _customerAddress, bool _stakeable) public view returns(uint256) {
        uint256 _price = sellPrice(true);
        uint256 _balance = balanceOf(_customerAddress, _stakeable);
        uint256 _value = (_balance.mul(_price)) / priceMagnitude;

        return _value;
    }

    function hexBalanceOfNoFee(address _customerAddress, bool _stakeable) public view returns(uint256) {
        uint256 _price = sellPrice(false);
        uint256 _balance = balanceOf(_customerAddress, _stakeable);
        uint256 _value = (_balance.mul(_price)) / priceMagnitude;

        return _value;
    }

    function hexToSendFund(bytes32 exchange) public view returns(uint256) {
        if (exchange == "hextew") {
          return totalTewFundCollected.sub(totalTewFundReceived);
        } else if (exchange == "hexrise") {
          return totalRiseFundCollected.sub(totalRiseFundReceived);
        }
    }
}