// SPDX-License-Identifier: MIT
// UBDNDistributor ERC20 Token Distributor
pragma solidity 0.8.19;


import "SafeERC20.sol";
import "Ownable.sol";
import "IERC20Mint.sol";


contract UBDNLockerDistributor is Ownable {
    using SafeERC20 for IERC20Mint;
    
    struct Lock {
        uint256 amount;
        uint256 lockedUntil;
    }

    uint256 constant public START_PRICE = 1;         // 1 stable coin unit, not decimal. 
    uint256 constant public PRICE_INCREASE_STEP = 1; // 1 stable coin unit, not decimal. 
    uint256 constant public INCREASE_FROM_ROUND = 1;
    uint256 constant public ROUND_VOLUME = 1_000_000e18; // in wei
    uint256 constant public ADD_NEW_PAYMENT_TOKEN_TIMELOCK = 48 hours;
    uint256 constant public EMERGENCY_PAYMENT_PAUSE = 1 hours;

    
    uint256 public LOCK_PERIOD = 90 days;
    uint256 public distributedAmount;

    IERC20Mint public distributionToken;
    mapping (address => uint256) public paymentTokens;
    mapping (address => Lock[]) public userLocks;
    mapping (address => bool) public isGuardian;

    event DistributionTokenSet(address indexed Token);
    event PaymentTokenStatus(address indexed Token, bool Status);
    event Purchase(
        address indexed User,
        uint256 indexed PurchaseAmount, 
        address indexed PaymentToken, 
        uint256 PaymentAmount
    );
    event Claimed(address User, uint256 Amount, uint256 Timestamp);
    event PaymentTokenPaused(address indexed Token, uint256 Until);

    constructor (uint256 _lockPeriod) {
        if (_lockPeriod > 0) {
           LOCK_PERIOD = _lockPeriod;
        }
    }

    /// @notice Buy distibuting token with stable coins
    /// @dev _inAmount in wei. Don't forget approve
    /// @param _paymentToken stable coin address
    /// @param _inAmount amount of stable to spent
    /// @param _outNotLess minimal desired amount of distributed tokens (anti slippage)
    function buyTokensForExactStableWithSlippage(
        address _paymentToken, 
        uint256 _inAmount, 
        uint256 _outNotLess
    ) 
        external 
    {
        require(
            _calcTokensForExactStable(_paymentToken,_inAmount) >= _outNotLess, 
            "Slippage occur"
        );
        buyTokensForExactStable(_paymentToken, _inAmount); 

    }     

    /// @notice Buy distibuting token with stable coins
    /// @dev _inAmount in wei. Don't forget approve
    /// @param _paymentToken stable coin address
    /// @param _inAmount amount of stable to spent
    function buyTokensForExactStable(address _paymentToken, uint256 _inAmount) 
        public 
    {
        require(address(distributionToken) != address(0), 'Distribution not Define');

        require(_isValidForPayment(_paymentToken), 'This payment token not supported');
        
        // 1. Calc distribution tokens
        uint256 outAmount = _calcTokensForExactStable(_paymentToken,_inAmount);
        require(outAmount > 0, 'Cant buy zero');
        
        // 2. Save lockInfo
        _newLock(msg.sender, outAmount);
        distributedAmount += outAmount;
        
        // 3. Mint distribution token
        distributionToken.mint(address(this), outAmount);
        emit Purchase(msg.sender, outAmount, _paymentToken, _inAmount);

        // 4. Receive payment
        IERC20Mint(_paymentToken).safeTransferFrom(msg.sender, owner(),_inAmount);
    }

    /// @notice Claim available for now tokens
    function claimTokens() external {
        uint256 claimAmount;
        // calc and mark as claimed
        for (uint256 i = 0; i < userLocks[msg.sender].length; ++i){
            if (block.timestamp >= userLocks[msg.sender][i].lockedUntil){
                claimAmount += userLocks[msg.sender][i].amount;
                userLocks[msg.sender][i].amount = 0;
            }
        }
        require(claimAmount > 0, 'Nothing to claim');
        distributionToken.safeTransfer(msg.sender, claimAmount);
        emit Claimed(msg.sender, claimAmount, block.timestamp);
    }

    /// @notice Temprory disable payments with token
    /// @param _paymentToken stable coin address
    function emergencyPause(address _paymentToken) external {
        require(isGuardian[msg.sender], "Only for approved guardians");
        if (
                paymentTokens[_paymentToken] > 0 // token enabled 
                && paymentTokens[_paymentToken] <= block.timestamp // no timelock 
            ) 
        {
            paymentTokens[_paymentToken] = block.timestamp + EMERGENCY_PAYMENT_PAUSE;
            emit PaymentTokenPaused(_paymentToken, paymentTokens[_paymentToken]);
        }
    }

    ///////////////////////////////////////////////////////////
    ///////    Admin Functions        /////////////////////////
    ///////////////////////////////////////////////////////////
    function setPaymentTokenStatus(address _token, bool _state) 
        external 
        onlyOwner 
    {
        if (_state ) {
            paymentTokens[_token] = block.timestamp + ADD_NEW_PAYMENT_TOKEN_TIMELOCK;    
        } else {
            paymentTokens[_token] = 0;
        }
        
        emit PaymentTokenStatus(_token, _state);
    }

    function setDistributionToken(address _token) 
        external 
        onlyOwner 
    {
        require(address(distributionToken) == address(0), "Can call only once");
        distributionToken = IERC20Mint(_token);
        emit DistributionTokenSet(_token);
    }

    function setGuardianStatus(address _guardian, bool _state)
        external
        onlyOwner
    {
        isGuardian[_guardian] = _state;
    }

    ///////////////////////////////////////////////////////////

    /// @notice Returns amount of distributing tokens that will be
    /// get by user if he(she) pay given stable coin amount
    /// @dev _inAmount must be with given in wei (eg 1 USDT =1000000)
    /// @param _paymentToken stable coin address
    /// @param _inAmount stable coin amount that user want to spend
    function calcTokensForExactStable(address _paymentToken, uint256 _inAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcTokensForExactStable(_paymentToken, _inAmount);
    }

    /// @notice Returns amount of stable coins that must be spent
    /// for user get given  amount of distributing token
    /// @dev _outAmount must be with given in wei (eg 1 UBDN =1e18)
    /// @param _paymentToken stable coin address
    /// @param _outAmount distributing token amount that user want to get
    function calcStableForExactTokens(address _paymentToken, uint256 _outAmount) 
        external 
        view 
        returns(uint256) 
    {
        return _calcStableForExactTokens(_paymentToken, _outAmount);
    }

    /// @notice Returns price without decimals and distributing token rest
    /// for given round
    /// @dev returns tuple  (price, rest)
    /// @param _round round number
    function priceInUnitsAndRemainByRound(uint256 _round) 
        external 
        view 
        returns(uint256, uint256) 
    {
        return _priceInUnitsAndRemainByRound(_round);
    }

    /// @notice Returns array of user's locks
    /// @dev returns tuple  array of (amount, unlock timestamp)
    /// @param _user user address 
    function getUserLocks(address _user) 
        public 
        view 
        returns(Lock[] memory)
    {
        return userLocks[_user];
    }

    /// @notice Returns array of user's locks
    /// @dev returns tuple  array of (total locked amount, available now)
    /// @param _user user address 
    function getUserAvailableAmount(address _user)
        public
        view
        returns(uint256 total, uint256 availableNow)
    {
        for (uint256 i = 0; i < userLocks[_user].length; ++i){
            total += userLocks[_user][i].amount;
            if (block.timestamp >= userLocks[_user][i].lockedUntil){
                availableNow += userLocks[_user][i].amount;
            }
        }
    }

    /// @notice Returns current round number
    function getCurrentRound() external view returns(uint256){
        return _currenRound();   
    }

    /////////////////////////////////////////////////////////////////////
    function _newLock(address _user, uint256 _lockAmount) internal {
        userLocks[_user].push(
            Lock(_lockAmount, block.timestamp + LOCK_PERIOD)
        );
    }

    function _calcStableForExactTokens(address _paymentToken, uint256 _outAmount) 
        internal
        virtual 
        view 
        returns(uint256 inAmount) 
    {
        uint256 outA = _outAmount;
        uint256 curR = _currenRound();
        uint256 curPrice; 
        uint256 curRest;
        uint8 payTokenDecimals = IERC20Mint(_paymentToken).decimals();
        uint8 dstTokenDecimals = distributionToken.decimals();
        while (outA > 0) {
            (curPrice, curRest) = _priceInUnitsAndRemainByRound(curR); 
            if (outA > curRest) {
                inAmount += curRest 
                    * curPrice * 10**payTokenDecimals
                    / (10**dstTokenDecimals);
                outA -= curRest;
                ++ curR;
            } else {
                inAmount += outA 
                    * curPrice * 10**payTokenDecimals
                    / (10**dstTokenDecimals);
                return inAmount;
            }
        }
    }

    function _calcTokensForExactStable(address _paymentToken, uint256 _inAmount) 
        internal
        virtual 
        view 
        returns(uint256 outAmount) 
    {
        uint256 inA = _inAmount;
        uint256 curR = _currenRound();
        uint256 curPrice; 
        uint256 curRest;
        uint8 payTokenDecimals = IERC20Mint(_paymentToken).decimals();
        uint8 dstTokenDecimals = distributionToken.decimals();
        while (inA > 0) {
            (curPrice, curRest) = _priceInUnitsAndRemainByRound(curR); 
            if (
                // calc out amount
                inA 
                * (10**dstTokenDecimals)
                / (curPrice * 10**payTokenDecimals)
                   > curRest
                ) 
            {
                // Case when inAmount more then price of all tokens 
                // in current round
                outAmount += curRest;
                inA -= curRest 
                       * curPrice * 10**payTokenDecimals
                       / (10**dstTokenDecimals);
                ++ curR;
            } else {
                // Case when inAmount less or eqal then price of all tokens 
                // in current round
                outAmount += inA 
                  * 10**dstTokenDecimals
                  / (curPrice * 10**payTokenDecimals);
                return outAmount;
            }
        }
    }

    function _priceInUnitsAndRemainByRound(uint256 _round) 
        internal 
        view 
        virtual 
        returns(uint256 price, uint256 rest) 
    {
        if (_round < INCREASE_FROM_ROUND){
            price = START_PRICE;
        } else {
            price = START_PRICE + PRICE_INCREASE_STEP * (_round - INCREASE_FROM_ROUND + 1); 
        }
        
        // in finished rounds rest always zero
        if (_round < _currenRound()){
            rest = 0;
        
        // in current round need calc 
        } else if (_round == _currenRound()){
            if (_round == 1){
                // first round
                rest = ROUND_VOLUME - distributedAmount; 
            } else {
                rest = ROUND_VOLUME - (distributedAmount % ROUND_VOLUME); 
            } 
        
        // in future rounds rest always ROUND_VOLUME
        } else {
            rest = ROUND_VOLUME;
        }
    }

    function _currenRound() internal view virtual returns(uint256){
        return distributedAmount / ROUND_VOLUME + 1;
    }

    function _isValidForPayment(address _paymentToken) internal view returns(bool){
        if (paymentTokens[_paymentToken] == 0) {
            return false;
        }
        require(
            paymentTokens[_paymentToken] < block.timestamp,
            "Token paused or timelocked"
        );
        return true; 
    }
}