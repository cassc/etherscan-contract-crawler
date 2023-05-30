/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

/*  VidyaFlux 
    ---------
    Launch date set to 12/20/2020 @ 10:00pm (UTC)
    
    5% entry fee
    5% exit fee
    1% transfer fee 
    1% referral fee 
    0.5% generator fee (maintenance)
    
    Maintenance fee is reserved for the Team3D Inventory contract: 
    0x9680223F7069203E361f55fEFC89B7c1A952CDcc
    
    Anyone who calls feedInventory() function sends maintenance 
    balance to Inventory and gets a 1% bonus in VIDYA for the effort 
    
    Call inventoryFund() to view the current accumulated inventory
    balance. */

pragma solidity ^0.5.17;

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

contract TOKEN {
   function totalSupply() external view returns (uint256);
   function balanceOf(address account) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function allowance(address owner, address spender) external view returns (uint256);
   function approve(address spender, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract VidyaFLUX {
    
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 500000e18; // 500k
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    bool public onlyAmbassadors = true;
    uint256 ACTIVATION_TIME =  1608501600; // 12/20/2020 @ 10:00pm (UTC)

    modifier antiEarlyWhale(uint256 _amountOfVIDYA, address _customerAddress){
      if (now >= ACTIVATION_TIME) {
         onlyAmbassadors = false;
      }

      if (onlyAmbassadors) {
         require((ambassadors_[_customerAddress] == true && (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfVIDYA) <= ambassadorMaxPurchase_));
         ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfVIDYA);
         _;
      } else {
         onlyAmbassadors = false;
         _;
      }
    }

    modifier onlyTokenHolders {
        require(myTokens() > 0);
        _;
    }

    modifier onlyDivis {
        require(myDividends(true) > 0);
        _;
    }

    event onDistribute(
        address indexed customerAddress,
        uint256 price
    );

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingVIDYA,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 VIDYAEarned,
        uint timestamp
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 VIDYAReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 VIDYAWithdrawn
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    string public name = "VidyaFLUX";
    string public symbol = "FLUX";
    uint8 constant public decimals = 18;
    uint256 internal entryFee_ = 5;
    uint256 internal transferFee_ = 1;
    uint256 internal exitFee_ = 5;
    uint256 internal referralFee_ = 20; // 20% of the 5% buy or sell fees makes it 1%
    uint256 internal maintenanceFee_ = 10; // 10% of the 5% buy or sell fees makes it 0.5%
    address internal maintenanceAddress;
    uint256 constant internal magnitude = 2 ** 64;
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal invested_;
    mapping(address => uint256) public allTimeRefEarnings_;
    mapping(address => uint256) public totalInvested_;
    mapping(address => uint256) public totalWithdrawn_;
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public stakingRequirement = 0;
    uint256 public totalHolder = 0;
    uint256 public totalDonation = 0;
    TOKEN erc20;

    constructor() public {
        maintenanceAddress = address(0x9680223F7069203E361f55fEFC89B7c1A952CDcc); // Inventory contract  
        erc20 = TOKEN(address(0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30)); // VIDYA token
    }

    function checkAndTransferVIDYA(uint256 _amount) private {
        require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function buy(uint256 _amount, address _referredBy) public returns (uint256) {
        checkAndTransferVIDYA(_amount);
        return purchaseTokens(_referredBy, msg.sender, _amount);
    }

    function() payable external {
        revert();
    }

    function reinvest() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        uint256 _tokens = purchaseTokens(address(0x0), _customerAddress, _dividends);
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function exit() external {
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens, address(0x0));
        withdraw();
    }

    function withdraw() onlyDivis public {
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false);
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        totalWithdrawn_[_customerAddress] = SafeMath.add(totalWithdrawn_[_customerAddress], _dividends);
        erc20.transfer(_customerAddress, _dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

    function sell(uint256 _amountOfTokens,address _referredBy) onlyTokenHolders public {
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_amountOfTokens, exitFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus,_maintenance));

        uint256 _taxedVIDYA = SafeMath.sub(_amountOfTokens, _undividedDividends);

        uint256 _fee = _dividends * magnitude;

        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], (_maintenance));

        tokenSupply_ = SafeMath.sub(tokenSupply_, _amountOfTokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens + (_taxedVIDYA * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        emit Transfer(_customerAddress, address(0), _amountOfTokens);
        emit onTokenSell(_customerAddress, _amountOfTokens, _taxedVIDYA, now);

    }

    function transfer(address _toAddress, uint256 _amountOfTokens) onlyTokenHolders external returns (bool){
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        if (myDividends(true) > 0) {
            withdraw();
        }

        uint256 _tokenFee = SafeMath.div(SafeMath.mul(_amountOfTokens, transferFee_), 100);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = _tokenFee;

        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _taxedTokens);

        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _taxedTokens);

        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        emit Transfer(_customerAddress, _toAddress, _taxedTokens);

        return true;
    }

    function totalVIDYABalance() public view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns (uint256) {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
    
    function myReferrals() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return referralBalance_[_customerAddress];
    }

    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    function sellPrice() public view returns (uint256) {
        uint256 _VIDYA = 1e18;
        return SafeMath.div(_VIDYA * SafeMath.sub(100, exitFee_), 100);
    }

    function buyPrice() public view returns (uint256) {
        uint256 _VIDYA = 1e18;
        return SafeMath.div(_VIDYA * 100, SafeMath.sub(100, entryFee_));
    }

    function calculateTokensReceived(uint256 _VIDYAToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_VIDYAToSpend, entryFee_), 100);
        uint256 _amountOfTokens = SafeMath.sub(_VIDYAToSpend, _dividends);

        return _amountOfTokens;
    }

    function calculateVIDYAReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_tokensToSell, exitFee_), 100);
        uint256 _taxedVIDYA = SafeMath.sub(_tokensToSell, _dividends);

        return _taxedVIDYA;
    }

    function getInvested() public view returns (uint256) {
        return invested_[msg.sender];
    }

    function purchaseTokens(address _referredBy, address _customerAddress, uint256 _incomingVIDYA) internal antiEarlyWhale(_incomingVIDYA, _customerAddress) returns (uint256) {
        if (getInvested() == 0) {
          totalHolder++;
        }

        invested_[msg.sender] += _incomingVIDYA;

        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingVIDYA, entryFee_), 100);

        uint256 _maintenance = SafeMath.div(SafeMath.mul(_undividedDividends, maintenanceFee_), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, referralFee_), 100);

        uint256 _dividends = SafeMath.sub(_undividedDividends, SafeMath.add(_referralBonus, _maintenance));
        uint256 _amountOfTokens = SafeMath.sub(_incomingVIDYA, _undividedDividends);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        referralBalance_[maintenanceAddress] = SafeMath.add(referralBalance_[maintenanceAddress], (_maintenance));

        if (_referredBy != address(0) && _referredBy != _customerAddress && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
            allTimeRefEarnings_[_referredBy] = SafeMath.add(allTimeRefEarnings_[_referredBy], _referralBonus);
            totalInvested_[_customerAddress] = SafeMath.add(totalInvested_[_customerAddress], _incomingVIDYA);
        } else {
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            tokenSupply_ = _amountOfTokens;
        }

        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        emit Transfer(address(0), msg.sender, _amountOfTokens);
        emit onTokenPurchase(_customerAddress, _incomingVIDYA, _amountOfTokens, _referredBy, now);

        return _amountOfTokens;
    }
    
    /*  Withdraw maintenance balance to Inventory contract 
        Caller (msg.sender) gets 1% of the amount as bonus */
    function feedInventory() public returns(uint256, uint256) {
        
        // Maintenance balance 
        uint256 amount = referralBalance_[maintenanceAddress];
        
        // 1% from amount (amount * 1 / 100)
        uint256 bonus = SafeMath.div(SafeMath.mul(amount, 1), 100);

        // This amount goes to Inventory 
        uint256 toInventory = SafeMath.sub(amount, bonus);
        
        // Set maintenance balance to 0
        referralBalance_[maintenanceAddress] = 0;
        
        // Send to Inventory 
        erc20.transfer(maintenanceAddress, toInventory);
        
        // Send to caller 
        erc20.transfer(msg.sender, bonus);
        
        // Returns the amounts for UI or w/e 
        return (toInventory, bonus);
        
    }
    
    function inventoryFund() public view returns(uint256) {
        return referralBalance_[maintenanceAddress];
    }

    function getOneTimeData() public view returns(uint256, uint256, uint256, string memory, string memory) {
        return (entryFee_, exitFee_, decimals, name, symbol);
    }

    function multiData() public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
  return (
        // [0] Total VIDYA in contract
        totalVIDYABalance(),

        // [1] Total FLUX supply
        totalSupply(),

        // [2] User FLUX balance
        balanceOf(msg.sender),

        // [3] User VIDYA balance
        erc20.balanceOf(msg.sender),

        // [4] User divs
        dividendsOf(msg.sender),

        // [5] Buy price
        buyPrice(),

        // [6] Sell price
        sellPrice(),

        // [7] All time ref earnings
        allTimeRefEarnings_[msg.sender],

        // [8] Ref earnings
        referralBalance_[msg.sender],

        // [9] Total invested
        totalInvested_[msg.sender],

        // [10] Total withdrawn
        totalWithdrawn_[msg.sender]

        );
    }
}