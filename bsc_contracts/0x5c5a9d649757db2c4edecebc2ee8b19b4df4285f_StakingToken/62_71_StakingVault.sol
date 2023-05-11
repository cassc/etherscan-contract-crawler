// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {        
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IOwned {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
    function claimOwnership() external;
}

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IBuddySystem {
    function myUpline() external view returns (address);
    function myMembers() external view returns (address);
    function getTeamOf(address _addr) external view returns (address[] memory team);
    function uplineOf(address player) external view returns (address);
    function membersOf(address player) external view returns (uint256);
    function getDownlineById(address player, uint256 _pos) external view returns (address);

    function setUpline(address _newUpline) external returns (uint256);
}

interface ITokenVault {
    function withdraw(address _token, uint256 _amount) external;
}

interface ITokensRecoverable {
    function recoverTokens(IERC20 token, address _to) external;
    function lockToken(IERC20 token, bool _locked) external;
}

abstract contract Owned is IOwned {
    address public override owner = msg.sender;
    address internal pendingOwner;

    modifier ownerOnly() {
        require (msg.sender == owner, "Owner only");
        _;
    }

    function transferOwnership(address newOwner) public override ownerOnly() {
        pendingOwner = newOwner;
    }

    function claimOwnership() public override {
        require (pendingOwner == msg.sender);
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
    }
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    
    uint8 public override decimals = 18;

    uint256 public override totalSupply;

    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address a) public virtual override view returns (uint256) { return _balanceOf[a]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 oldAllowance = allowance[sender][msg.sender];
        if (oldAllowance != uint256(-1)) {
            _approve(sender, msg.sender, oldAllowance.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply = totalSupply.add(amount);
        _balanceOf[account] = _balanceOf[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balanceOf[account] = _balanceOf[account].sub(amount, "ERC20: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 _decimals) internal {
        decimals = _decimals;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract Whitelist is Owned {

    modifier onlyWhitelisted() {
        if(active){
            require(whitelist[msg.sender], 'not whitelisted');
        }
        _;
    }

    bool active = true;

    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    function activateDeactivateWhitelist() public ownerOnly() {
        active = !active;
    }

    function addAddressToWhitelist(address addr) public ownerOnly() returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] calldata addrs) public ownerOnly() returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function removeAddressFromWhitelist(address addr) ownerOnly() public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function removeAddressesFromWhitelist(address[] calldata addrs) ownerOnly() public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract TokensRecoverable is Owned, ITokensRecoverable {
    using SafeERC20 for IERC20;

    mapping (address => bool) internal locked_;

    function recoverTokens(IERC20 token, address _to) public override ownerOnly() {
        require (canRecoverTokens(token));
        uint256 amountOut = token.balanceOf(address(this));
        token.safeTransfer(_to, amountOut);
    }

    function lockToken(IERC20 token, bool _locked) public override ownerOnly() {
        locked_[address(token)] = _locked;
    }

    function canRecoverTokens(IERC20 token) internal virtual view returns (bool) { 
        return locked_[address(token)];
    }
}

/*
|||||||||||||||||||||||||||||||||||||||||||||||
|| ExtremisVault - Based on 'Bankroll Stack' ||
|| V1.0 by Don Function | The Degen Protocol ||
|||||||||||||||||||||||||||||||||||||||||||||||

 - Added ERC20 tokenomics
 - Dividends handling on transfer

 - Added referral scheme
 - Merged compound + withdraw into one action
 - On-chain storage for action percentages

 - Whitelisted addresses can do action for any address
 - Whitelisted addresses can set amounts for any address
*/

contract StakingVault is ERC20, Whitelist, ReentrancyGuard, TokensRecoverable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;
    IBuddySystem public buddies;
    
    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////

    uint public users;
    uint public totalTxs;
    uint public totalClaims;
    uint public totalAirdrops;
    uint public totalDeposits;
    uint public dripPoolBalance;
    uint public lastPayoutTimestamp;
    uint public lastDistributionTime;

    uint256 internal profitPerShare_;

    uint16 constant internal dripRate = 300;
    uint16 constant internal refsFee = 300;
    uint16 constant internal divsFee = 1000;
    uint16 constant internal oneHundred = 10000;

    uint256 constant internal magnitude = 2 ** 64;
    uint256 constant internal payoutFrequency = 2 seconds;
    uint256 constant internal distributionFrequency = 6 hours;

    ////////////////////////////////////
    // DATA STRUCTS & MAPPINGS        //
    ////////////////////////////////////

    struct Airdrop {
        uint256 ready;
        uint256 pending;
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop;
    }

    struct ActionConfig {
        uint16 compound;
        uint16 withdraw;
        uint16 airdrop;
    }

    struct AddressStats {
        uint deposited;
        uint withdrawn;
        uint compounded;
        uint rewarded;
        uint contributed;
        uint transferredShares;
        uint receivedShares;
        
        uint xInvested;
        uint xCompounded;
        uint xRewarded;
        uint xContributed;
        uint xWithdrawn;
        uint xTransferredShares;
        uint xReceivedShares;
    }

    mapping(address => Airdrop) internal airdrops;
    mapping(address =>  int256) internal payoutsOf_;
    mapping(address => ActionConfig) internal actionCfg_;
    mapping(address => AddressStats) internal accountOf_;
    
    ////////////////////////////////////
    // EVENTS                         //
    ////////////////////////////////////
    
    event onDeposit( address indexed caller, uint256 deposited,  uint256 tokensMinted, uint timestamp);
    event onWithdraw(address indexed caller, uint256 liquidated, uint256 tokensEarned, uint timestamp);

    event onSetAmounts(address indexed caller, uint16 compound, uint16 withdraw, uint16 airdrop, uint timestamp);
    event onDoActions(address indexed caller, uint256 compounded, uint256 withdrawn, uint timestamp);
    
    event onAddRewards(address indexed caller, uint256 amount, uint timestamp);
    event onAirdrop(address indexed from, uint256 totalAmount, uint256 timestamp);
    event onDistribute(address indexed caller, uint256 balance, uint256 timestamp);
    
    ////////////////////////////////////
    // CONSTRUCTOR & FALLBACK         //
    ////////////////////////////////////

    constructor(
        string memory _name, 
        string memory _symbol, 
        address _tokenAddress, 
        address _buddySystem
    ) ERC20(_name, _symbol) {
        token = IERC20(_tokenAddress);
        buddies = IBuddySystem(_buddySystem);
        lastPayoutTimestamp = (block.timestamp);
    }
    
    receive() payable external {
        Address.sendValue(payable(owner), msg.value);
    }

    ////////////////////////////////////
    // VIEW FUNCTIONS                 //
    ////////////////////////////////////

    function buyPrice() external pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = _tokens.mul(divsFee).div(oneHundred);
        uint256 _taxedTokens = _tokens.add(_dividends);
        return _taxedTokens;
    }
    
    function sellPrice() external pure returns (uint256) {
        uint256 _tokens = 1e18;
        uint256 _dividends = _tokens.mul(divsFee).div(oneHundred);
        uint256 _taxedTokens = _tokens.sub(_dividends);
        return _taxedTokens;
    }

    function totalStaked() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function payoutsOf(address _user) public view returns (int256) {
        return (payoutsOf_[_user]);
    }

    function earnRateOf(address _user) external view returns (uint256) {
        uint256 userBalance = balanceOf(_user);
        uint256 currentTotalStaked = totalStaked();

        uint256 share = dripPoolBalance.mul(dripRate).div(oneHundred);
        return (currentTotalStaked > 0) ? share.mul(userBalance).div(currentTotalStaked) : 0;
    }
    
    function dividendsOf(address _user) public view returns (uint256) {
        uint256 userBalance = balanceOf(_user);
        int256 userPayouts = payoutsOf(_user);
        return (uint256) ((int256) (profitPerShare_ * userBalance) - userPayouts) / magnitude;
    }

    function statsOf(address _user) external view returns (uint256[14] memory){
        AddressStats memory a = accountOf_[_user];
        uint256[14] memory accountArray = [
            a.deposited, 
            a.withdrawn, 
            a.rewarded, 
            a.compounded,
            a.contributed, 
            a.transferredShares, 
            a.receivedShares, 
            a.xInvested, 
            a.xRewarded, 
            a.xContributed, 
            a.xWithdrawn, 
            a.xTransferredShares, 
            a.xReceivedShares, 
            a.xCompounded
        ];
        return accountArray;
    }

    function airdropBalanceOf(address _user) public view returns (uint256) {
        return airdrops[_user].ready;
    }

    function getActionAmounts(address _user) public view returns (uint16 _compound, uint16 _withdraw, uint16 _airdrop) {
        ActionConfig storage actionCfg = actionCfg_[_user];
        return (actionCfg.compound, actionCfg.withdraw, actionCfg.airdrop);
    }

    function calculateSharesReceived(uint256 _amount) external pure returns (uint256) {
        uint256 _divies = _amount.mul(divsFee).div(oneHundred);
        uint256 _remains = _amount.sub(_divies);
        uint256 _result = _remains;
        return  _result;
    }

    function calculateTokensReceived(uint256 _amount) external view returns (uint256) {
        uint256 currentTotalStaked = totalStaked();
        require(_amount <= currentTotalStaked);
        uint256 _tokens  = _amount;
        uint256 _divies  = _tokens.mul(divsFee).div(oneHundred);
        uint256 _remains = _tokens.sub(_divies);
        return _remains;
    }
    
    ////////////////////////////////////
    // WRITE FUNCTIONS                //
    ////////////////////////////////////

    // Add tokens to drip pool
    function addToRewards(uint _amount) external returns (bool success) {
        require(token.transferFrom(msg.sender, address(this), _amount));

        dripPoolBalance += _amount;

        emit onAddRewards(msg.sender, _amount, block.timestamp);
        return true;
    }

    // Deposit tokens
    function deposit(uint _amount) external returns (bool success)  {
        success = depositTo(msg.sender, _amount);
        require(success, "DEPOSIT_FAILED");
        return true;
    }

    // Deposit tokens, giving vault tokens to an address
    function depositTo(address _user, uint _amount) public returns (bool success)  {
        
        require(token.transferFrom(msg.sender, address(this), _amount));

        totalDeposits += _amount;

        address _upline = buddies.uplineOf(msg.sender);
        require(_upline != address(0), "SET_UPLINE_FIRST");

        uint256 airdropsPending = airdrops[_user].pending;
        uint256 userShare = oneHundred - refsFee;

        uint256 playerDepositAmount = _amount.mul(userShare).div(oneHundred);
        uint256 uplineDepositAmount = _amount.mul(refsFee).div(oneHundred);

        if (airdropsPending > 0) {
            playerDepositAmount += airdropsPending;
            receiveAirdrops(_user, airdropsPending);
        }

        _depositTokens(_user, playerDepositAmount);
        _depositTokens(_upline, uplineDepositAmount);

        distribute();

        return true;
    }

    // Withdraw tokens from vault
    function withdraw(uint256 _amount) external {
        address _user = msg.sender;
        require(_amount <= balanceOf(_user));
        
        // Calculate dividends and 'shares' (tokens)
        uint256 _undividedDividends = _amount.mul(divsFee) / oneHundred;
        uint256 _taxedTokens = _amount.sub(_undividedDividends);

        // Subtract amounts from user and totals...
        _burn(_user, _amount);

        // Update the payment ratios for the user and everyone else...
        int256 _updatedPayouts = (int256) (profitPerShare_ * _amount + (_taxedTokens * magnitude));
        payoutsOf_[_user] -= _updatedPayouts;

        // Serve dividends between the drip and instant divs (4:1)...
        addToDripPool(_undividedDividends);
        
        // Tell the network, and trigger a distribution
        emit onWithdraw( _user, _amount, _taxedTokens, block.timestamp);
        
        // Trigger a distribution for everyone, kind soul!
        distribute();
    }

    // Set action percentages
    function setActionAmounts(uint16 _compound, uint16 _withdraw, uint16 _airdrop) public returns (bool success) {
        address _user = msg.sender;

        require(_compound + _withdraw + _airdrop == oneHundred, "SET_CORRECT_RATIO");

        _setAmounts(_user, _compound, _withdraw, _airdrop);

        return true;
    }

    // Compound + Withdraw in one function. Forces users to take profits.
    function doAction() external returns (bool success) {
        address _user = msg.sender;
        
        success = _doActions(_user);
        require(success, "DO_ACTIONS_FAILED");

        return true;
    }

    // Send airdrop to an array of addresses
    function airdrop(address[] memory _recipients, uint256 _amount) external returns (bool success) {

        address _addr = msg.sender;
        uint256 airdropBalance = airdropBalanceOf(_addr);
        require(airdropBalance >= _amount, "INSUFFICIENT_FUNDS");
        uint256 airdropPerUser = _amount.div(_recipients.length);

        for (uint i = 0; i < _recipients.length; i++) {
            airdrops[_recipients[i]].pending += airdropPerUser;
        }

        airdrops[_addr].airdrops += _amount;
        airdrops[_addr].last_airdrop = block.timestamp;
        airdrops[_addr].ready -= _amount;

        emit onAirdrop(_addr, _amount, block.timestamp);
        return true;
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    // Do action for another address, according to its preferences
    function doActionFor(address _user) external onlyWhitelisted() returns (bool success) {
        success = _doActions(_user);
        require(success, "DO_ACTIONS_FAILED");
    }

    // Set amounts for another address, defining its preferences
    function setAmountsFor(address _user, uint16 _compound, uint16 _withdraw, uint16 _airdrop) external onlyWhitelisted() returns (bool success) {
        success = _setAmounts(_user, _compound, _withdraw, _airdrop);
        require(success, "SET_AMOUNTS_FAILED");
    }

    ////////////////////////////////////
    // PRIVATE / INTERNAL FUNCTIONS   //
    ////////////////////////////////////

    // Distribute rewards to all holders
    function distribute() internal {
        uint256 currentTotalStaked = totalStaked();
        uint256 _currentTimestamp = (block.timestamp);
        
        // Log the event, if it's time to do so...
        if (_currentTimestamp.sub(lastDistributionTime) > distributionFrequency) {
            
            // Tell the network...
            emit onDistribute(msg.sender, totalStaked(), _currentTimestamp);
            
            // Update the time this was last updated...
            lastDistributionTime = _currentTimestamp;
        }

        // If there's any time difference...
        if (_currentTimestamp.sub(lastPayoutTimestamp) > payoutFrequency && currentTotalStaked > 0) {
            
            // Calculate shares and profits...
            uint256 share = dripPoolBalance.mul(dripRate).div(oneHundred).div(24 hours);
            uint256 profit = share * _currentTimestamp.sub(lastPayoutTimestamp);
            
            // Subtract from drip pool balance and add to all user earnings
            dripPoolBalance = dripPoolBalance.sub(profit);
            profitPerShare_ = profitPerShare_.add((profit * magnitude) / currentTotalStaked);
            
            // Update the last payout timestamp
            lastPayoutTimestamp = _currentTimestamp;
        }
    }

    // Allocate fees to the drip pool
    function addToDripPool(uint amount) internal {
        dripPoolBalance = dripPoolBalance.add(amount);
    }

    // Do actions (compound & withdraw)
    function _doActions(address _user) internal returns (bool) {
        uint256 _dividends = dividendsOf(_user);

        (uint16 _compound, uint16 _withdraw, uint16 _airdrop) = getActionAmounts(_user);

        if (_compound == 0 && _withdraw == 0) {
            _compound == 6000;
            _withdraw == 4000;
            _airdrop == 0;
        }

        uint256 toCompound = _dividends.mul(_compound).div(oneHundred);
        uint256 toWithdraw = _dividends.mul(_withdraw).div(oneHundred);
        uint256 toAirdrop = _dividends.mul(_airdrop).div(oneHundred);

        if (toCompound > 0) {
            _compoundFor(_user, toCompound);
        }

        if (toWithdraw > 0) {
            _harvestFor(_user, toWithdraw);
        }

        if (toAirdrop > 0) {
            _addToAirdrops(_user, toAirdrop);
        }

        distribute();

        emit onDoActions(msg.sender, toCompound, toWithdraw, block.timestamp);
        return true;
    }

    // Send specified token amount supplying an upline referral
    function receiveAirdrops(address _to, uint256 _amount) internal {

        //User stats
        airdrops[_to].pending = 0;
        airdrops[_to].airdrops_received += _amount;

        //Keep track of overall stats
        totalAirdrops += _amount;
    }

    // Set amounts (compound & withdraw ratio)
    function _setAmounts(address _user, uint16 _compound, uint16 _withdraw, uint16 _airdrop) internal returns (bool) {
        ActionConfig storage actionCfg = actionCfg_[_user];

        actionCfg.compound = _compound;
        actionCfg.withdraw = _withdraw;
        actionCfg.airdrop = _airdrop;

        emit onSetAmounts(msg.sender, _compound, _withdraw, _airdrop, block.timestamp);
        return true;
    }
    
    // Deposit Tokens to an address
    function _depositTokens(address _recipient, uint256 _amount) internal returns (uint256) {

        uint256 currentTotalStaked = totalStaked();
        uint256 _undividedDividends = _amount.mul(divsFee).div(oneHundred);
        uint256 _tokens = _amount.sub(_undividedDividends);

        // There needs to be something being added in this call...
        require(_tokens > 0 && _tokens.add(currentTotalStaked) > currentTotalStaked);
        
        // Allocate fees, and balance to the recipient
        addToDripPool(_undividedDividends);

        _mint(_recipient, _tokens);
        
        // Updated payouts...
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens);
        
        // Update stats...
        payoutsOf_[_recipient] += _updatedPayouts;
        accountOf_[_recipient].deposited += _amount;
        accountOf_[_recipient].xInvested += 1;

        // Successful function - how many "shares" generated?
        emit onDeposit(_recipient, _amount, _tokens, block.timestamp);
        return _tokens;
    }

    // Compound earnings for an address
    function _compoundFor(address _user, uint256 _dividends) internal {
        payoutsOf_[_user] += (int256) (_dividends * magnitude);
        
        _depositTokens(msg.sender, _dividends);
        
        // Then update the stats...
        accountOf_[_user].compounded = accountOf_[_user].compounded.add(_dividends);
        accountOf_[_user].xCompounded += 1;
    }

    // Harvest earnings for an address
    function _harvestFor(address _user, uint256 _dividends) internal {
        
        // Calculate the payout, add it to the user's total paid out accounting...
        payoutsOf_[_user] += (int256) (_dividends * magnitude);
        
        // Pay the user their tokens to their wallet
        token.transfer(_user, _dividends);

        // Update accounting for user/total withdrawal stats...
        accountOf_[_user].withdrawn = accountOf_[_user].withdrawn.add(_dividends);
        accountOf_[_user].xWithdrawn += 1;
        
        // Update total Tx's and claims stats
        totalTxs += 1;
        totalClaims += _dividends;
    }

    // Add amount to airdroppable balance for an address
    function _addToAirdrops(address _user, uint256 _amount) internal {
        // Add _amount to _user's airdroppable balance
        airdrops[_user].ready += _amount;
    }

    // Before transfer override
    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        uint256 senderDividends = dividendsOf(from);
        uint256 receiverDividends = dividendsOf(to);

        if (senderDividends > 0) {
            _harvestFor(from, senderDividends);
        }

        if (receiverDividends > 0) {
            _harvestFor(to, receiverDividends);
        }

        // Count user if they're new...
        if (accountOf_[to].deposited == 0 && accountOf_[to].receivedShares == 0) {
            users += 1;
        }
    }

    // After transfer override
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        // Adjust payout ratios to match the new balances...
        payoutsOf_[from] -= (int256) (profitPerShare_ * amount);
        payoutsOf_[to] += (int256) (profitPerShare_ * amount);
        
        // Update stats...
        accountOf_[from].xTransferredShares += 1;
        accountOf_[from].transferredShares += amount;
        accountOf_[to].receivedShares += amount;
        accountOf_[to].xReceivedShares += 1;
        
        // Add this to the Tx counter...
        totalTxs += 1;
    }

    // Can recover any token except the staked token
    function canRecoverTokens(IERC20 _token) internal override view returns (bool) { 
        return address(_token) != address(token); 
    }
}