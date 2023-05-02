/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

pragma solidity ^0.5.17;

/******************************
*******************************
* https://link.nexus-dapp.com *
*******************************
******************************/

contract LinkInterface {
	function transfer(address _toAddress, uint256 _amountOfTokens) public returns (bool);
	function balanceOf(address _Address) public view returns (uint256);
}

contract GemsHr {

    /*=================================
    =            MODIFIERS            =
    =================================*/

    /// @dev Only people with tokens
    modifier onlyBagholders {
        require(myTokens(msg.sender) > 0);
        _;
    }

    /// @dev Only people with profits
    modifier onlySlinkghands {
        require(myDividends(true, msg.sender) > 0);
        _;
    }


    /// @dev isControlled
    modifier isControlled() {
      require(isStarted());
      _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/

    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingLink,
        uint256 tokensMinted,
        address indexed referredBy,
        uint timestamp,
        uint256 price
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 linkEarned,
        uint timestamp,
        uint256 price
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 linkReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 linkWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	
    event Approval(
		address indexed admin, 
		address indexed spender, 
		uint256 value
	);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/

    string public name = "Gem token";
    string public symbol = "GEM";
    uint8 constant public decimals = 18;

    /// @dev 5% dividends for token selling
    uint8 constant internal exitFee_ = 5;

    /// @dev 33% masternode
    uint8 constant internal refferalFee_ = 30;

    /// @dev P3D pricing
    uint256 constant internal tokenPriceInitial_ = 100000000000; //0.0000001 link;
    uint256 constant internal tokenPriceIncremental_ = 10000000000; //0.00000001 link;

    uint256 constant internal magnitude = 2 ** 64;

    /// @dev 100 needed for masternode activation
    uint256 public stakingRequirement = 100e18;

    /// @dev light the marketing
    address public marketing;
	
	// @dev ERC20 allowances
	mapping (address => mapping (address => uint256)) private _allowances;


   /*=================================
    =            DATASETS            =
    ================================*/

    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) public payoutsTo_;
    mapping(address => uint256) public referralBalance_;
	
	// referrers
	mapping(address => address) public referrers_;	
    
	uint256 public jackPot_;
	address public jackPotPretender_;	
	uint256 public jackPotStartTime_;
	
    uint256 internal tokenSupply_;
    uint256 internal profitPerShare_;
    uint256 public depositCount_;

    // ChainLink interface 
	
    address internal constant tokenAddress = address(
        0x759Bd4ed07A34b9ea761F8F2ED9f0e102675a29C  // chainlink token address
    );
    LinkInterface public linkContract = LinkInterface(tokenAddress);	

    /*=======================================
    =            CONSTRUCTOR                =
    =======================================*/

   constructor (address _marketing) public {
		marketing = _marketing;
		jackPotStartTime_ = now;
		jackPot_ = 1000e18;
   }

    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    /**
     * @dev Fallback function to handle linkeum that was send straight to the contract
     *  Unfortunately we cannot use a referral address this way.
     */
    
	function() external isControlled  {	
        revert();
    }

    /// @dev Converts all incoming link to tokens for the caller, and passes down the referral addy (if any)
    /**
     * ERC677 transferandcall support
     */
    function onTokenTransfer(address _sender, uint _value, bytes calldata _data) external {
        // make sure that only chainlink transferandcalls are supported
        require(msg.sender == tokenAddress);

        // convert _data to address
        bytes memory x = _data;
        address _referredBy;

        assembly {
            _referredBy := mload(add(x,20))
        }

        purchaseTokens(_value, _referredBy, _sender);
    }	

    /// @dev Converts to tokens on behalf of the customer - this allows gifting and integration with other systems
    //function purchaseFor(uint256 tokensValue, address _referredBy, address _customerAddress) isControlled public returns (uint256) {
    //   purchaseTokens(tokensValue, _referredBy , _customerAddress);
    //}

    /// @dev Converts all of caller's dividends to tokens.
    function reinvest() onlySlinkghands public {
        // fetch dividends
        uint256 _dividends = myDividends(false, msg.sender); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, address(0x0) , _customerAddress);

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
	
	/// @dev The new user welcome function
    function reg() public returns(bool) {	
		return true;
	}
	
    /// @dev Alias of sell() and withdraw().
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);

        // capitulation
        withdraw();
    }

    /// @dev Withdraws all of the callers earnings.
    function withdraw() onlySlinkghands public {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false, msg.sender); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        linkContract.transfer(_customerAddress, _dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /// @dev Liquifies tokens to link.
    function sell(uint256 _amountOfTokens) onlyBagholders public {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _link = tokensToLink_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_link, exitFee_), 100);
        uint256 _taxedLink = SafeMath.sub(_link, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedLink * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
		emit Transfer(_customerAddress, address(0x0), _tokens);
        emit onTokenSell(_customerAddress, _tokens, _taxedLink, now, buyPrice());
    }
	
    /**
     * @dev ERC20 functions.
     */
    function allowance(address _admin, address _spender) public view returns (uint256) {
        return _allowances[_admin][_spender];
    }

    function approve(address _spender, uint256 _amountOfTokens) public returns (bool) {
        approveInternal(msg.sender, _spender, _amountOfTokens);
        return true;
    }

    function approveInternal(address _admin, address _spender, uint256 _amountOfTokens) internal {
        require(_admin != address(0x0), "ERC20: approve from the zero address");
        require(_spender != address(0x0), "ERC20: approve to the zero address");

        _allowances[_admin][_spender] = _amountOfTokens;
        emit Approval(_admin, _spender, _amountOfTokens);
    }
	
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        approveInternal(msg.sender, spender, SafeMath.add(_allowances[msg.sender][spender], addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        approveInternal(msg.sender, spender, SafeMath.sub(_allowances[msg.sender][spender], subtractedValue));
        return true;
    }	
	
    /**
     * @dev Transfer tokens from the caller to a new holder.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyBagholders public returns (bool) {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if (myDividends(true, msg.sender) > 0) {
            withdraw();
        }

        return transferInternal(_toAddress,_amountOfTokens,_customerAddress);
    }
	
    function transferFrom(address _fromAddress, address _toAddress, uint256 _amountOfTokens) public returns (bool) {
        transferInternal(_toAddress, _amountOfTokens, _fromAddress);
        approveInternal(_fromAddress, msg.sender, SafeMath.sub(_allowances[_fromAddress][msg.sender], _amountOfTokens));
        return true;
    }	

    function transferInternal(address _toAddress, uint256 _amountOfTokens , address _fromAddress) internal returns (bool) {
        // setup
        address _customerAddress = _fromAddress;

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // ERC20
        return true;
    }
	

    /*=====================================
    =      HELPERS AND CALCULATORS        =
    =====================================*/

    /**
     * @dev Mlnkod to view the current Link stored in the contract
     *  Example: totalLinkBalance()
     */
    function totalLinkBalance() public view returns (uint256) {
        return linkContract.balanceOf(address(this));
    }

    /// @dev Retrieve the total token supply.
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /// @dev Retrieve the tokens balance.
    function myTokens(address _customerAddress) public view returns (uint256) {
        return balanceOf(_customerAddress);
    }

    /**
     * @dev Retrieve the dividends owned by the caller.
     *  If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     *  The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     *  But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus, address _customerAddress) public view returns (uint256) {
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /// @dev Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /// @dev Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress) public view returns (uint256) {
        return (uint256) ((int256) (profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

    /// @dev Return the sell price of 1 individual token.
    function sellPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _link = tokensToLink_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_link, exitFee_), 100);
            uint256 _taxedLink = SafeMath.sub(_link, _dividends);

            return _taxedLink;
        }
    }

    /// @dev Return the buy price of 1 individual token.
    function buyPrice() public view returns (uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _link = tokensToLink_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_link, entryFee()), 100);
            uint256 _taxedLink = SafeMath.add(_link, _dividends);

            return _taxedLink;
        }
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _linkToSpend) public view returns (uint256) {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_linkToSpend, entryFee()), 100);
        uint256 _taxedLink = SafeMath.sub(_linkToSpend, _dividends);
        uint256 _amountOfTokens = linkToTokens_(_taxedLink);
        return _amountOfTokens;
    }

    /// @dev Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateLinkReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _link = tokensToLink_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_link, exitFee_), 100);
        uint256 _taxedLink = SafeMath.sub(_link, _dividends);
        return _taxedLink;
    }

    /// @dev Function for the frontend to get untaxed receivable link.
    function calculateUntaxedLinkReceived(uint256 _tokensToSell) public view returns (uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _link = tokensToLink_(_tokensToSell);
        //uint256 _dividends = SafeMath.div(SafeMath.mul(_link, exitFee()), 100);
        //uint256 _taxedLink = SafeMath.sub(_link, _dividends);
        return _link;
    }

    function entryFee() private view returns (uint8){
      uint256 volume = totalLinkBalance()  - msg.value;

      if (volume<=50e18){
        return 22;
      }
      if (volume<=100e18){
        return 21;
      }
      if (volume<=25e22){
        return 20;
      }
      if (volume<=30e22){
        return 19;
      }
      if (volume<=35e22){
        return 18;
      }

      return 17;
	  
    }

     // @dev Function for find if premine
    function jackPotInfo() public view returns (uint256 jackPot, uint256 timer, address jackPotPretender) {
		jackPot = jackPot_;
		if (jackPot > totalLinkBalance()) {
			jackPot = totalLinkBalance();
		}
		jackPot = SafeMath.div(jackPot,2);
		
		timer = now - jackPotStartTime_;
		jackPotPretender = jackPotPretender_;
    }
	
	// @dev Function for find if premine
    function isPremine() public view returns (bool) {
      return depositCount_<=5;
    }

    // @dev Function for find if premine
    function isStarted() public pure returns (bool) {
      return true; //startTime!=0 && now > startTime;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    /// @dev Internal function to actually purchase the tokens.
    function purchaseTokens(uint256 _incomingLink, address _referredBy , address _customerAddress) internal returns (uint256) {
        // data setup
		require (_incomingLink > 0);
		
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingLink, entryFee()), 100);
        uint256 _referralBonus = SafeMath.div(SafeMath.mul(_undividedDividends, refferalFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedLink = SafeMath.sub(_incomingLink, _undividedDividends);
        uint256 _amountOfTokens = linkToTokens_(_taxedLink);
        uint256 _fee = _dividends * magnitude;
		uint256 _marketing = SafeMath.div(SafeMath.mul(_incomingLink, 4), 100); //4%
		
        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_);

        // is the user referred by a masternode?
        if (
            // is this a referred purchase?
            _referredBy != address(0x0) &&

            // no cheating!
            _referredBy != _customerAddress &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
			if (referrers_[_customerAddress] == address(0x0)) {
				referrers_[_customerAddress] = _referredBy;
			}
			calculateReferrers(_customerAddress, _referralBonus, 1);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        // we can't give people infinite link
        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
			
			// fire event
			emit Transfer(address(0x0), _customerAddress, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / tokenSupply_);

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee - (_amountOfTokens * (_dividends * magnitude / tokenSupply_)));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
		
		// JackPot calculate
		calculateJackPot(_incomingLink, _customerAddress);
		
		// 4% for marketing 
		linkContract.transfer(marketing, _marketing);

        // fire event
        emit onTokenPurchase(_customerAddress, _incomingLink, _amountOfTokens, _referredBy, now, buyPrice());

        // Keep track
        depositCount_++;
        return _amountOfTokens;
    }

    /**
     * @dev Calculate Referrers reward 
     * Level 1: 35%, Level 2: 20%, Level 3: 15%, Level 4: 10%, Level 5: 10%, Level 6: 5%, Level 7: 5%
     */	
	function calculateReferrers(address _customerAddress, uint256 _referralBonus, uint8 _level) internal {
		address _referredBy = referrers_[_customerAddress];
		uint256 _percent = 35;
		if (_referredBy != address(0x0)) {
			if (_level == 2) _percent = 20;
			if (_level == 3) _percent = 15;
			if (_level == 4 || _level == 5) _percent = 10;
			if (_level == 6 || _level == 7) _percent = 5;
			uint256 _newReferralBonus = SafeMath.div(SafeMath.mul(_referralBonus, _percent), 100);
			referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _newReferralBonus);
			if (_level < 7) {
				calculateReferrers(_referredBy, _referralBonus, _level+1);
			}
		}
	}

    /**
     * @dev Calculate JackPot 
     * 40% from entryFee is going to JackPot 
     * The last investor (with 0.2 link) will receive the jackpot in 12 hours 
     */	
	function calculateJackPot(uint256 _incomingLink, address _customerAddress) internal {
		uint256 timer = SafeMath.div(SafeMath.sub(now, jackPotStartTime_), 12 hours);
		if (timer > 0 && jackPotPretender_ != address(0x0) && jackPot_ > 0) {
			//pay jackPot
			if (totalLinkBalance() < jackPot_) {
				jackPot_ = totalLinkBalance();
			}
				
			linkContract.transfer(jackPotPretender_, SafeMath.div(jackPot_,2));
			jackPot_ = SafeMath.div(jackPot_,2);
			jackPotStartTime_ = now;
			jackPotPretender_ = address(0x0);
		}
		
		uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingLink, entryFee()), 100);
		jackPot_ += SafeMath.div(SafeMath.mul(_undividedDividends, 40), 100);
		
		if (_incomingLink >= 10e18) { 
			jackPotPretender_ = _customerAddress;
			jackPotStartTime_ = now;
		}
	}	
	
    /**
     * @dev Calculate Token price based on an amount of incoming link
     *  It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function linkToTokens_(uint256 _link) internal view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial ** 2)
                            +
                            (2 * (tokenPriceIncremental_ * 1e18) * (_link * 1e18))
                            +
                            ((tokenPriceIncremental_ ** 2) * (tokenSupply_ ** 2))
                            +
                            (2 * tokenPriceIncremental_ * _tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)
        ) - (tokenSupply_);

        return _tokensReceived;
    }

    /**
     * @dev Calculate token sell value.
     *  It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     *  Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToLink_(uint256 _tokens) internal view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _linkReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ + (tokenPriceIncremental_ * (_tokenSupply / 1e18))
                        ) - tokenPriceIncremental_
                    ) * (tokens_ - 1e18)
                ), (tokenPriceIncremental_ * ((tokens_ ** 2 - tokens_) / 1e18)) / 2
            )
        / 1e18);

        return _linkReceived;
    }

    /// @dev This is where all your gas goes.
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}