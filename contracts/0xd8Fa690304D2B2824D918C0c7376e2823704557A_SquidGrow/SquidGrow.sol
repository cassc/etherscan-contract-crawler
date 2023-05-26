/**
 *Submitted for verification at Etherscan.io on 2023-04-30
*/

/**

https://t.me/SquidGrowOfficial

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
abstract contract Auth {
    address public owner;
    mapping (address => bool) internal authorizations;
    
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true; 
    }
    
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }
    
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
    
    function transferOwnership(address payable adr) public authorized {
        require(adr != address(0), "Zero Address");
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);}
    
    function renounceOwnership() external authorized {
        emit OwnershipTransferred(address(0));
        owner = address(0);}
    
    event OwnershipTransferred(address owner);
}


interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IPair {
    function sync() external;
}

interface IWeth {
    function deposit() external payable;
}

contract SquidGrow  is IERC20, Auth {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string private constant _name = 'SquidGrow';
    string private constant _symbol = 'SquidGrow';
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 * 10**14 * (10 ** _decimals);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 30 ) / 10000;
    uint256 public _maxWalletAmount = ( _totalSupply * 500 ) / 10000;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) _isBot;
    mapping (address => bool) isWhitelisted;
    mapping (address => bool) isBlacklisted;

    IRouter public immutable router;
    address public immutable pair;
    bool tradingEnabled = false;
    uint256 startedTime;

    uint256 constant feeDenominator = 10000;

    struct Fee {
        uint256 stakingFee;
        uint256 burnFee;
        uint256 liquidFee; // marketingFee + autoLPFee + teamFee
        uint256 totalFee;
    }

    enum TransactionType {BUY, SELL, TRANSFER}

    mapping (TransactionType => Fee) public fees;

    bool swapAndLiquifyEnabled = false;
    uint256 swapTimes; 
    uint256 minTransactionsBeforeSwap = 7;
    bool swapping; 
    bool antiBotEnabled = true;

    uint256 swapThreshold = ( _totalSupply * 300 ) / 100000;
    uint256 _minTokenAmount = ( _totalSupply * 15 ) / 100000;

    uint256 marketing_divisor = 0;
    uint256 liquidity_divisor = 100;
    uint256 team_divisor = 0;
    uint256 total_divisor = 100;

    address liquidity_receiver; 
    address staking_receiver;
    address marketing_receiver;

    address team1_receiver;
    address team2_receiver;
    address team3_receiver;
    address team4_receiver;

    address public multisig = address(0x4B1AbbdEaC18EaA719C608BcCF9005711f296E87); // it will be updated to mutlisig address before deployemnt.

    event WhitelistUpdated(address indexed account, bool indexed whitelisted);
    event BotUpdated(address indexed account, bool indexed isBot);
    event BlacklistedUpdated(address indexed account, bool indexed blacklisted);
    event AntiBotStateUpdated(bool indexed enabled);
    event TradingEnabled();
    event TradingDisabled();
    event SwapBackSettingsUpdated(bool indexed enabled, uint256 threshold, uint256 minLimit, uint256 _minTransactions);
    event MaxLimitsUpdated(uint256 maxTxAmount, uint256 maxWalletAmount);
    event UnsupportedTokensRecoverd(address indexed token, address receiver, uint256 amount);
    event DivisorsUpdated(uint256 team, uint256 liquidity, uint256 marketing);
    event TeamFundsDistributed(address team1, address team2, address team3, address team4, uint256 amount);
    event FeesUpdated(TransactionType indexed transactionType, uint256 burnFee, uint256 stakingFee, uint256 swapAndLiquifyFee);
    event FeesAddressesUpdated(address marketing, address liquidity, address staking);
    event TeamAddressesUpdated(address team1, address team2, address team3, address team4);
    event ForceAdjustedLP(bool indexed squid, uint256 amount, bool indexed add);
    event TokensAirdroped(address indexed sender, uint256 length, uint256 airdropedAmount);
    event MultisigUpdated(address indexed multisig);

    modifier lockTheSwap {
        swapping = true; 
        _;
        swapping = false;
    }

    modifier onlyMultisig {
        require(msg.sender == multisig, "Not multisig");
        _;
    }

    constructor() Auth(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // eth - 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;

        // initilasing Fees
        fees[TransactionType.SELL] = Fee (0, 0, 1200, 1200);
        fees[TransactionType.BUY] = Fee (0, 0, 400, 400);
        fees[TransactionType.TRANSFER] = Fee (0, 0, 0, 0);
        
        isBlacklisted[address(0)] = true;
       
        isWhitelisted[msg.sender] = true;
        isWhitelisted[address(this)] = true;

        liquidity_receiver = address(this);
        team1_receiver = msg.sender;
        team2_receiver = msg.sender;
        team3_receiver = msg.sender;
        team4_receiver = msg.sender;
        staking_receiver = msg.sender;
        marketing_receiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public pure override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}

    function isBot(address _address) public view returns (bool) {
        return _isBot[_address];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function whitelistAddress(address _address, bool _whitelist) external authorized { 
        require(isWhitelisted[_address] != _whitelist, "Already set");
        isWhitelisted[_address] = _whitelist;

        emit WhitelistUpdated(_address, _whitelist);
    }

    function blacklistAddress(address _address, bool _blacklist) external authorized { 
        require(isBlacklisted[_address] != _blacklist, "Already set");
        isBlacklisted[_address] = _blacklist;

        emit BlacklistedUpdated(_address, _blacklist);
    }

    function updateBot(address _address, bool isBot_) external authorized {
        require(_isBot[_address] != isBot_, "Already set");
        _isBot[_address] = isBot_;

        emit BotUpdated(_address, isBot_);
    }

    function enableAntiBot(bool _enable) external authorized {
        require(antiBotEnabled != _enable, "Already set");
        antiBotEnabled = _enable;

        emit AntiBotStateUpdated(_enable);
    }

    function enableTrading(uint256 _input) external authorized {
        require(!tradingEnabled, "Already Enabled!");
        tradingEnabled = true;
        if(startedTime == 0) // initialise only once
            startedTime = block.timestamp.add(_input);
        
        emit TradingEnabled();
    }

    function disableTrading() external onlyMultisig {
        require(tradingEnabled, "Already disabled!");
        tradingEnabled = false;

        emit TradingDisabled();
    }

    function updateSwapBackSettings(bool _enabled, uint256 _threshold, uint256 _minLimit, uint256 _minTransactionsBeforeSwap) external authorized {
        swapAndLiquifyEnabled = _enabled; 
        swapThreshold = _threshold;
        _minTokenAmount = _minLimit;
        minTransactionsBeforeSwap = _minTransactionsBeforeSwap;

        emit SwapBackSettingsUpdated( _enabled, _threshold, _minLimit, _minTransactionsBeforeSwap);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);

        bool takeFee = true;
        if (isWhitelisted[sender] || isWhitelisted[recipient]) {
            takeFee = false;

        } else {
            require(tradingEnabled, "Trading is Paused");
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if (recipient != pair) {
                require(_balances[recipient] + amount <= _maxWalletAmount, "Wallet amount exceeds limit");
            }

        }

        TransactionType transactionType;

        if(sender == pair) {
            transactionType = TransactionType.BUY;
            if(recipient != address(router) && block.timestamp <= startedTime) {
                _isBot[recipient] = true;
            }
        } else if (recipient == pair) {
            transactionType = TransactionType.SELL;
        } else {
            transactionType = TransactionType.TRANSFER;
        }

        swapTimes = swapTimes.add(1);
        if(shouldSwapBack(sender, amount)){
            swapAndLiquify(swapThreshold);
            swapTimes = 0;
        }

        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = takeFee ? takeTotalFee(sender, amount, transactionType) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(!isBlacklisted[sender], "Blackisted");
        require(!isBlacklisted[recipient], "Blackisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function takeTotalFee(address sender, uint256 amount, TransactionType transactionType) internal returns (uint256) {
        Fee memory fee = fees[transactionType];
        uint256 totalFees = _isBot[sender] && antiBotEnabled? (feeDenominator - 100) : fee.totalFee; // 99% fees if bot
        if (totalFees == 0) {
            return amount;
        }
        uint256 feeAmount = (amount.mul(totalFees)).div(feeDenominator);
        uint256 burnAmount = (feeAmount.mul(fee.burnFee)).div(totalFees);
        uint256 stakingAmount = (feeAmount.mul(fee.stakingFee)).div(totalFees);

        uint256 liquidAmount = feeAmount.sub(burnAmount).sub(stakingAmount);

        if(burnAmount > 0) {
            _balances[address(DEAD)] = _balances[address(DEAD)].add(burnAmount);
            emit Transfer(sender, address(DEAD), burnAmount);
        }
        if(stakingAmount > 0) {
            _balances[address(staking_receiver)] = _balances[address(staking_receiver)].add(stakingAmount);
            emit Transfer(sender, address(staking_receiver), stakingAmount);
        }
        if(liquidAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(liquidAmount);
            emit Transfer(sender, address(this), liquidAmount);
        } 
        return amount.sub(feeAmount);

    }

    function updateMaxLimits(uint256 _transaction, uint256 _wallet) external authorized {
        require(_transaction >= 1, "Max txn limit cannot be less than 0.00001%");
        require(_wallet >= 500000, "Max Wallet limit cannot be less than 5%");
        uint256 newTxLimit = ( _totalSupply * _transaction ) / 10000000;
        uint256 newWalletLimit = ( _totalSupply * _wallet ) / 10000000;
        _maxTxAmount = newTxLimit;
        _maxWalletAmount = newWalletLimit;

        emit MaxLimitsUpdated(_maxTxAmount, _maxWalletAmount);
    }

    function recoverUnsupportedTokens(address _token, address _receiver, uint256 _percentage) external authorized {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        uint256 amountToWithdraw = amount.mul(_percentage).div(10000);
        IERC20(_token).safeTransfer(_receiver, amountToWithdraw);

        emit UnsupportedTokensRecoverd(_token, _receiver, amountToWithdraw);
    }

    function updateDivisors(uint256 _team, uint256 _liquidity, uint256 _marketing) external authorized {
        team_divisor = _team;
        liquidity_divisor = _liquidity;
        marketing_divisor = _marketing;
        total_divisor = _team.add(_liquidity).add(_marketing);

        emit DivisorsUpdated(_team, _liquidity, _marketing);
    }

    function distributeTeamFunds(uint256 _numerator, uint256 _denominator) external authorized {
        uint256 ethAmount = address(this).balance;
        uint256 distributeAmount = ethAmount.mul(_numerator).div(_denominator);
        uint256 amountToSend = distributeAmount.div(4);
        transferETH(team1_receiver, amountToSend);
        transferETH(team2_receiver, amountToSend);
        transferETH(team3_receiver, amountToSend);
        transferETH(team4_receiver, amountToSend);

        emit TeamFundsDistributed(team1_receiver, team2_receiver, team3_receiver, team4_receiver, distributeAmount);
    }

    function updateFee(TransactionType transactionType, uint256 _burnFee, uint256 _stakingFee, uint256 _swapAndLiquifyFee) external onlyMultisig {
        require(_burnFee.add(_stakingFee).add(_swapAndLiquifyFee) <= feeDenominator.mul(3).div(20), "Tax cannot be more than 15%");
        Fee storage fee = fees[transactionType];
        fee.burnFee = _burnFee;
        fee.stakingFee = _stakingFee;
        fee.liquidFee = _swapAndLiquifyFee;
        fee.totalFee = _burnFee.add(_stakingFee).add(_swapAndLiquifyFee);    

        emit FeesUpdated(transactionType, _burnFee, _stakingFee, _swapAndLiquifyFee);
    }

    function updateFeesAddresses(address _marketing, address _liquidity, address _staking) external authorized {
        require(_marketing != address(0), "Zero Address");
        require(_liquidity != address(0), "Zero Address");
        require(_staking != address(0), "Zero Address");
        marketing_receiver = _marketing;
        liquidity_receiver = _liquidity;
        staking_receiver = _staking;

        emit FeesAddressesUpdated( _marketing, _liquidity, _staking);
    }

    function updateTeamAddresses(address _team1, address _team2, address _team3, address _team4) external authorized {
        require(_team1 != address(0), "Zero Address");
        require(_team2 != address(0), "Zero Address");
        require(_team3 != address(0), "Zero Address");
        require(_team4 != address(0), "Zero Address");
        team1_receiver = _team1;
        team2_receiver = _team2;
        team3_receiver = _team3;
        team4_receiver = _team4;

        emit TeamAddressesUpdated( _team1, _team2, _team3, _team4);
    }

    function shouldSwapBack(address sender, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapAndLiquifyEnabled && aboveMin && 
             swapTimes >= minTransactionsBeforeSwap && aboveThreshold && sender != pair;
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 amountToLiquify = tokens.mul(liquidity_divisor).div(total_divisor).div(2);
        uint256 amountToSwap = tokens.sub(amountToLiquify);

        uint256 initialBalance = address(this).balance;
        swapTokensForETH(amountToSwap);

        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 totalETHFee = total_divisor.sub(liquidity_divisor.div(2));

        if(amountToLiquify > 0){
            addLiquidity(amountToLiquify, deltaBalance.mul(liquidity_divisor).div(totalETHFee).div(2)); 
        }
        // transfer ETH to marketing, teamFunds stay in contract for future distribution.
        transferETH(marketing_receiver, deltaBalance.mul(marketing_divisor).div(totalETHFee));
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function transferETH(address recipient, uint256 amount) private {
        if(amount == 0) return;
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Unable to send ETH");
    }

    function airdropTokens(address[] calldata accounts, uint256[] calldata amounts) external authorized {
        uint256 length = accounts.length;
        require (length == amounts.length, "array length mismatched");
        uint256 airdropAmount = 0;
        
        for (uint256 i = 0; i < length; i++) {
            // updating balance directly instead of calling transfer to save gas
            _balances[accounts[i]] += amounts[i];
            airdropAmount += amounts[i];
            emit Transfer(msg.sender, accounts[i], amounts[i]);
        }
        _balances[msg.sender] -= airdropAmount;

        emit TokensAirdroped(msg.sender, length, airdropAmount);
    }

    function forceAdjustLP(bool squid, uint256 amount, bool add) external payable onlyMultisig{
        if(!squid) {
            require(add, "Cant withdraw bnb from pool");
            amount = msg.value;
            IWeth(router.WETH()).deposit{value: amount}();
            IERC20(router.WETH()).safeTransfer(pair, amount);
        }else {
            if(add) {
                _balances[msg.sender] -= amount;
                _balances[pair] += amount;
                emit Transfer(msg.sender, pair, amount);

            } else {
                _balances[pair] -= amount;
                _balances[msg.sender] += amount;
                emit Transfer(pair, msg.sender, amount);
            }
        }
        IPair(pair).sync();
        emit ForceAdjustedLP(squid, amount, add);
    }

    function setMultisig(address _newMultisig) external onlyMultisig {
        require(_newMultisig != address(0), "Zero Address");
        multisig = _newMultisig;
        emit MultisigUpdated(_newMultisig);
    }
}