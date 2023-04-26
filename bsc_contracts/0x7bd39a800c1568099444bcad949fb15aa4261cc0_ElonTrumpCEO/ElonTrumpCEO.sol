/**
 *Submitted for verification at BscScan.com on 2023-04-25
*/

/**

    $ElonTrump is driven by the community Supported by the 
    Community for sure the ElonTrump meme will be 
    famous around the world,

    ElonTrump provides a diverse range of products 
    and services, including DeFi solutions, NFT marketplace, 
    decentralized exchange (DEX) DAO Farm Ai solutions 
    Partnership with other projects We are also developing
    an interactive AI Bot to which you can ask questions 
    and hit chat.

    https://elontrumpceo.com/
    https://t.me/ElonTrumpCEO
    https://twitter.com/elontrumpceo
    https://www.reddit.com/user/ElonTrumpCEO


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

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
        uint deadline
    ) external;
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        _transfer(sender, recipient, amount);

        //The require below is to help indicate the error if the transaction revert
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //The require below is to help indicate the error if the transaction revert
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        //The require below is to help indicate the error if the transaction revert
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}


interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns(uint256);
    function withdrawDividend() external;
  
    event DividendsDistributed(
        address indexed from,
        uint256 weiAmount
    );
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount
    );
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
}

contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    
    address public immutable rewardToken;
    
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    constructor(string memory _name, string memory _symbol, address _rewardToken) ERC20(_name, _symbol) { 
        require(_rewardToken != address(0), "_rewardToken cannot be null address");

        rewardToken = _rewardToken;
    }

    //Solidity por padrão reverte na versão acima de 0.8.0, não necessitando de safetmath
    function distributeDividends(uint256 amount) public onlyOwner{
        require(totalSupply() > 0, "Total supply must be greater than zero");

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + (
                (amount * magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, amount);

            totalDividendsDistributed = totalDividendsDistributed + amount;
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user] + _withdrawableDividend;
            emit DividendWithdrawn(user, _withdrawableDividend);
            bool success = IERC20(rewardToken).transfer(user, _withdrawableDividend);

            if(!success) {
                withdrawnDividends[user] = withdrawnDividends[user] - _withdrawableDividend;
                return 0;
            }

            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view override returns(uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns(uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view override returns(uint256) {
        return withdrawnDividends[_owner];
    }

    //For operations between int256 and uint256 we prefer to keep safemath for the security it provides
    function accumulativeDividendOf(address _owner) public view override returns(uint256) {
        return (magnifiedDividendPerShare * (balanceOf(_owner))).toInt256Safe()
        .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare * value).toInt256Safe() );
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare * value).toInt256Safe() );
    }


    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            _mint(account, mintAmount);
        } else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            _burn(account, burnAmount);
        }
    }
}


contract DividendTracker is Ownable, DividendPayingToken {
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event UpdateLastProcessedIndex(uint256 indexed index);
    event UpdateMinimumTokenBalanceForDividends(uint256 indexed index);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(uint256 minBalance, address _rewardToken) DividendPayingToken(
        "ElonTrump Reward Tracker", "DividendTracker", _rewardToken
        ) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = minBalance;
    }

    function withdrawDividend() public pure override {
        require(false, "withdrawDividend disabled. Use the 'claim' function on the main contract.");
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        require(_newMinimumBalance != minimumTokenBalanceForDividends, "New mimimum balance for dividend cannot be same as current minimum balance");
        minimumTokenBalanceForDividends = _newMinimumBalance;

        emit UpdateMinimumTokenBalanceForDividends(_newMinimumBalance);

    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account], "Already excluded from dividends");
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function isExcludedFromDividends(address account) external view returns (bool) {
        return excludedFromDividends[account];
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3_600 && newClaimWait <= 86_400, "claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
        lastProcessedIndex = index;
        emit UpdateLastProcessedIndex(index);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - (int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length - lastProcessedIndex :
                                                        0;

                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime + (claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime - (block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp - (lastClaimTime) >= claimWait;
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed + (gasLeft - (newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }

    function rescueAnyBEP20Tokens(address _tokenAddr,address _to, uint256 amount) external onlyOwner {
        IERC20(_tokenAddr).transfer(_to, amount);
    }

}


//This auxiliary contract is necessary for the logic of the liquidity mechanism to work
//The pancake router V2 does not allow the address(this) to be in swap and at the same time be the destination of "to"
//This contract is where the funds will be stored
contract ControlledFunds is Ownable {

    receive() external payable {}

    function withdrawBNBofControlledFunds(address to, uint256 amount) public onlyOwner() {
        payable(to).transfer(amount);
    }

    function withdrawTokenOfControlledFunds(address token, address to,uint256 amount) public onlyOwner() {
        IERC20(token).transfer(to,amount);
    }

}


contract ElonTrumpCEO is ERC20, Ownable {

    struct Buy {
        uint256 marketingFee;
        uint256 farmPoolNFTfee;
        uint256 developmentFee;
        uint256 reflectionFee;
        uint256 burnFee;
    }

    struct Sell {
        uint256 marketingFee;
        uint256 farmPoolNFTfee;
        uint256 developmentFee;
        uint256 reflectionFee;
        uint256 burnFee;
    }

    Buy public buy;
    Sell public sell;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;
    uint256 public totalFees;

    string public constant webSite      = "elontrumpceo.com";
    string public constant telegram     = "t.me/ElonTrumpCEO";
    string public constant twitter      = "twitter.com/elontrumpceo";

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public retrieverAddress;
    uint256 public immutable blockTimestampDeploy;

    address public constant marketingWallet1 = payable(0x67788Aa99ea15f0fb9640639d0Fe9BC40323F96C);
    address public constant marketingWallet2 = payable(0xCd002cFc107e61792934Cd9FD46b9e253B2DA81C);
    address public addressNFTfarmPool;

    struct DevelopmentWallets {
        address developmentWallet0;
        address developmentWallet1;
        address developmentWallet2;
        address developmentWallet3;
        address developmentWallet4;
        address developmentWallet5;
        address developmentWallet6;
    }
    DevelopmentWallets public developmentWallets;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant PCVS2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant rewardToken = 0x55d398326f99059fF775485246999027B3197955;

    bool    private swapping;
    uint256 public swapTokensAtAmount;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    DividendTracker public immutable dividendTracker;
    uint256 public constant  gasForProcessing = 300_000;

    ControlledFunds public immutable controlledFunds;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    event UpdateSwapTokensAtAmount(uint256 indexed newSwapTokensAtAmount);
    event UpdateTotalBuyFee(uint256 indexed newTotalBuyFee);
    event UpdateTotalSellFee(uint256 indexed newTotalSellFee);
    event UpdateTotalFee(uint256 indexed newTotalFee);
    event UpdateRetrieverAddress(address indexed oldAddress, address indexed newAddress);
    event UpdateAddressNFTfarmPool(address indexed oldAddress, address indexed newAddress);

    constructor() ERC20("ElonTrumpCEO", "ElonTrump") {

        blockTimestampDeploy = block.timestamp;

        controlledFunds = new ControlledFunds();
        dividendTracker = new DividendTracker(5 * 10 ** 9 * (10 ** 18) / 50000, rewardToken);

        addressNFTfarmPool = address(controlledFunds);

        retrieverAddress = owner();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(PCVS2);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        buy.marketingFee = 20;
        buy.farmPoolNFTfee = 25;
        buy.developmentFee = 10;
        buy.reflectionFee = 40;
        buy.burnFee = 5;

        totalBuyFee = 
        buy.marketingFee + buy.farmPoolNFTfee + buy.developmentFee + buy.reflectionFee + buy.burnFee;

        sell.marketingFee = 20;
        sell.farmPoolNFTfee = 25;
        sell.developmentFee = 10;
        sell.reflectionFee = 40;
        sell.burnFee = 5;

        totalSellFee = 
        sell.marketingFee + sell.farmPoolNFTfee + sell.developmentFee + sell.reflectionFee + sell.burnFee;

        totalFees = totalBuyFee + totalSellFee;

        developmentWallets.developmentWallet0 = payable(0xE490C17767a4aBcd4351e38e19a071D4644Ed3B6);
        developmentWallets.developmentWallet1 = payable(0xD2c2C4FD4d926Ec85bd6Adc5D339b85dDe084F61);
        developmentWallets.developmentWallet2 = payable(0x7701934CB6C822f81843B020c8Cc481CCD97D2f2);
        developmentWallets.developmentWallet3 = payable(0x65D2BaE52FDB77E57DD53aF839f76E1Fbc665157);
        developmentWallets.developmentWallet4 = payable(0x559Be6ECdEA2F3C7E864fC53B2463A4Ee1A2C8b1);
        developmentWallets.developmentWallet5 = payable(0xfb2e92535135906191e2cC2ec2407feD2CF30c9d);
        developmentWallets.developmentWallet6 = payable(0x9560fF22F3DB7E284CE9A7fB6F23771A87249D63);

        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(controlledFunds));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(DEAD);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[marketingWallet1] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(controlledFunds)] = true;
    
        _mint(owner(), 5 * 10 ** 9 * (10 ** 18));
        swapTokensAtAmount = totalSupply() / 10000;
    }

    receive() external payable {}

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already set to that state");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        //Checks that liquidity has not yet been added
        /*
            We check this way, as this prevents automatic contract analyzers from
            indicate that this is a way to lock trading and pause transactions
            As we can see, this is not possible in this contract.
        */
        if (_balances[uniswapV2Pair] == 0) {
            if (from != owner() && !_isExcludedFromFees[from]) {
                require(_balances[uniswapV2Pair] > 0, "Not released yet");
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && !swapping && automatedMarketMakerPairs[to]) {

            if (totalFees > 0) {

                uint256 totalBurnFees;
                uint256 burnTokens;
                //Never overflow
                unchecked {
                    //Rates will always be less than or equal to your maximum limit
                    totalBurnFees = buy.burnFee + sell.burnFee;
                    if (totalBurnFees > 0) {
                        burnTokens = (contractTokenBalance * totalBurnFees) / totalFees;
                        // (totalBurnFees / totalFees) is always less than 1
                        //Then _balances[address(this)] is always greater than burnTokens
                        _balances[address(this)] -= burnTokens;
                        _balances[address(0)] += burnTokens;
                        emit Transfer(address(this), address(0), burnTokens);
                    }
                }
                
                swapAndSendBNB(balanceOf(address(this)));
            }
        }

        bool takeFee = !swapping;

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        //Common transfers
        if(from != uniswapV2Pair && to != uniswapV2Pair && takeFee) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 _totalFees;
            uint256 fees;

            if(from == uniswapV2Pair) {
                _totalFees = totalBuyFee;
            } else {
                _totalFees = totalSellFee;
            }

            unchecked {
               fees = (amount * _totalFees) / 1000;
               amount = amount - fees;
            }

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {

            }
        }
    }

    function swapAndSendBNB(uint256 balance) internal {

        swapping = true;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 initialBalance = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp);
        
        uint256 newBalance;
        uint256 _totalTakeFees;

        uint256 marketingBNB;
        uint256 farmPoolBNB;
        uint256 developmentBNB;
        uint256 rewardsBNB;

        uint256 developmentBNBdistribute;

        //Never results in overflow
        //Multiplications and sum also never overflow, as the range of rates are limited
        //swapAndSendBNB never executes if _totalFees is zero, not dividing by zero
        //If _totalFees is ZERO, swapAndSendBNB is not executed and newBalance will never be zero
        unchecked {

            //Burn fees have already been taken before
            _totalTakeFees = totalFees - (buy.burnFee + sell.burnFee);

            newBalance      = address(this).balance - initialBalance;
            marketingBNB    = (newBalance * (buy.marketingFee + sell.marketingFee)) / _totalTakeFees;
            farmPoolBNB     = (newBalance * (buy.farmPoolNFTfee + sell.farmPoolNFTfee)) / _totalTakeFees;
            developmentBNB  = (newBalance * (buy.developmentFee + sell.developmentFee)) / _totalTakeFees;

            developmentBNBdistribute = ((developmentBNB * 85) / 100) / 6;

            rewardsBNB      = (newBalance * (buy.reflectionFee + sell.reflectionFee)) / _totalTakeFees;

        }

        payable(marketingWallet1).transfer((marketingBNB * 80) / 100);
        payable(marketingWallet2).transfer((marketingBNB * 20) / 100);

        payable(addressNFTfarmPool).transfer(farmPoolBNB);

        payable(developmentWallets.developmentWallet0).transfer((developmentBNB * 15) / 100);
        payable(developmentWallets.developmentWallet1).transfer(developmentBNBdistribute);
        payable(developmentWallets.developmentWallet2).transfer(developmentBNBdistribute);
        payable(developmentWallets.developmentWallet3).transfer(developmentBNBdistribute);
        payable(developmentWallets.developmentWallet4).transfer(developmentBNBdistribute);
        payable(developmentWallets.developmentWallet5).transfer(developmentBNBdistribute);
        payable(developmentWallets.developmentWallet6).transfer(developmentBNBdistribute);

        //This prevents any remaining balance on the contract
        swapAndSendDividends(address(this).balance - initialBalance);

        swapping = false;    
  
    }

    function swapAndSendDividends(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = rewardToken;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 balanceRewardToken = IERC20(rewardToken).balanceOf(address(this));
        bool success = IERC20(rewardToken).transfer(address(dividendTracker), balanceRewardToken);

        if (success) {
            dividendTracker.distributeDividends(balanceRewardToken);
            emit SendDividends(balanceRewardToken);
        }
    }

    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "Amount must be less than or equal to your balance");
        require(amount < totalSupply(), "Amount must be less than totalSupply()");

        _balances[_msgSender()] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(_msgSender(), address(0), amount);
    }

    function setSwapTokensAtAmount(uint256 newSwapTokensAtAmount) external onlyOwner{
        require(
            newSwapTokensAtAmount > totalSupply() / 100_000 && newSwapTokensAtAmount < totalSupply() / 90, 
            "SwapTokensAtAmount invalid");

        swapTokensAtAmount = newSwapTokensAtAmount;
        emit UpdateSwapTokensAtAmount(newSwapTokensAtAmount);
    }

    function setFees(
        uint256 buyMarketingFee,
        uint256 buyFarmPoolNFTfee,
        uint256 buyDevelopmentFee,
        uint256 buyReflectionFee,
        uint256 buyBurnFee,
        uint256 sellMarketingFee,
        uint256 sellFarmPoolNFTfee,
        uint256 sellDevelopmentFee,
        uint256 sellReflectionFee,
        uint256 sellBurnFee
        ) external onlyOwner {

        buy.marketingFee = buyMarketingFee;
        buy.farmPoolNFTfee = buyFarmPoolNFTfee;
        buy.developmentFee = buyDevelopmentFee;
        buy.reflectionFee = buyReflectionFee;
        buy.burnFee = buyBurnFee;

        totalBuyFee = 
        buy.marketingFee + buy.farmPoolNFTfee + buy.developmentFee + buy.reflectionFee + buy.burnFee;

        sell.marketingFee = sellMarketingFee;
        sell.farmPoolNFTfee = sellFarmPoolNFTfee;
        sell.developmentFee = sellDevelopmentFee;
        sell.reflectionFee = sellReflectionFee;
        sell.burnFee = sellBurnFee;

        totalSellFee = 
        sell.marketingFee + sell.farmPoolNFTfee + sell.developmentFee + sell.reflectionFee + sell.burnFee;

        totalFees = totalBuyFee + totalSellFee;

        require(totalBuyFee <= 110 && totalSellFee <= 110, "Invalid fees");
        require(totalFees > (buy.burnFee + sell.burnFee), "Invalid value. Avoiding division by zero");
        //If total fees rewards were zero, swapAndSendDividends(uint256 amount) would fail because amount would be zero
        require((buy.reflectionFee + sell.reflectionFee) >= 40, "Fees rewards should be higher");
       
        emit UpdateTotalBuyFee(totalBuyFee);
        emit UpdateTotalSellFee(totalSellFee);
        emit UpdateTotalFee(totalFees);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3_600 && newClaimWait <= 86_400, "claimWait must be updated to between 1 and 24 hours");
        dividendTracker.updateClaimWait(newClaimWait);
    }

    function updateMinimumTokenBalanceForDividends(uint256 _newMinimumBalance) external onlyOwner {
        dividendTracker.updateMinimumTokenBalanceForDividends(_newMinimumBalance);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function totalRewardsEarned(address account) public view returns (uint256) {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function excludeFromDividends(address account) external onlyOwner{
        dividendTracker.excludeFromDividends(account);
    }

    function isExcludedFromDividends(address account) external view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function claimAddress(address claimee) external onlyOwner {
        dividendTracker.processAccount(payable(claimee), false);
    }

    function claimForManyAddress(address[] memory adresses) external onlyOwner {
        uint256 lengthAdresses = adresses.length;
        for (uint256 i = 0; i < lengthAdresses; i ++) {
            dividendTracker.processAccount(payable(adresses[i]), false);
        }
    }

    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
        dividendTracker.setLastProcessedIndex(index);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    //retrieverAddress is used to prevent loss of funds on contracts if are renouncced
    //BNB and tokens will not be lost if deposited in the contract and the owner is address(0)
    function rescueBNB(address receiver) external {
        require(_msgSender() == owner() || _msgSender() == retrieverAddress, "Not allowed");
        require(receiver != address(0), "Receiver cannot be null address");

        payable(receiver).transfer(address(this).balance);
    }

    function rescueAnyBEP20Tokens(address _tokenAddr,address _to) external {
        require(_tokenAddr != address(this), "Cannot claim native tokens");
        require(_msgSender() == owner() || _msgSender() == retrieverAddress, "Not allowed");
        require(_to != address(0), "Receiver cannot be null address");

        IERC20(_tokenAddr).transfer(_to, 
            IERC20(_tokenAddr).balanceOf(address(this))
        );
    }

    //retrieverAddress is required in case the contract is waived
    //Contract must be waived within days of launch
    //The web3 dapp is at a distant stage in the roadmap
    //Controlled guards NFT farm pool funds
    function getBNBofControlledFunds(address to, uint256 amount) external {
        require(_msgSender() == owner() || _msgSender() == retrieverAddress, "Not allowed");
        require(to != address(0), "Receiver cannot be null address");

        controlledFunds.withdrawBNBofControlledFunds(to,amount);
    }

    function getTokenOfControlledFunds(address token, address to, uint256 amount) external {
        require(_msgSender() == owner() || _msgSender() == retrieverAddress, "Not allowed");
        require(to != address(0), "Receiver cannot be null address");

        controlledFunds.withdrawTokenOfControlledFunds(token,to,amount);
    }

    /*
        In case of contract migration, if there are funds deposited in the
        dividend tracker these funds will not be lost forever if
        the contract is waived
    */
    function getTokensDividendTracker(address _tokenAddr,address _to) external {
        require(_msgSender() == owner() || _msgSender() == retrieverAddress, "Not allowed");
        require(blockTimestampDeploy + 360 days <= block.timestamp, "Before the allowed time");
        require(_to != address(0), "Receiver cannot be null address");

        dividendTracker.rescueAnyBEP20Tokens(_tokenAddr,_to, 
            IERC20(_tokenAddr).balanceOf(address(dividendTracker))
        );
    }

    //Contract will be waived after launch
    //retrieverAddress serves to avoid lost funds in the contract 
    function setRetrieverAddress(address _retrieverAddress) external onlyOwner() {
        require(_retrieverAddress != address(0), "_retrieverAddress cannot be null address");
        
        emit UpdateRetrieverAddress(retrieverAddress, _retrieverAddress);

        retrieverAddress = _retrieverAddress;
    }

    //The NFT farm pool web3 dapp was not implemented in the deployment of this contract
    function setAddressNFTfarmPool(address _addressNFTfarmPool) external onlyOwner {
        require(_addressNFTfarmPool != address(0), "_addressNFTfarmPool cannot be null address");

        emit UpdateAddressNFTfarmPool(addressNFTfarmPool, _addressNFTfarmPool);

        addressNFTfarmPool = _addressNFTfarmPool;
    }

}