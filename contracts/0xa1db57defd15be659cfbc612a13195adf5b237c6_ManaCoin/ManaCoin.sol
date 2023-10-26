/**
 *Submitted for verification at Etherscan.io on 2023-09-20
*/

/**
 * Website :  https://www.manacoin.io/
 * DApp :     https://app.manacoin.io/
 * Twitter :  https://twitter.com/ManaCoinETH
 * Medium :   https://medium.com/@ManaCoinETH
 * Telegram : https://t.me/ManaCoinETH
**/

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract ManaCoin is Ownable, IERC20{
    string  private _name;
    string  private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;

    uint256 public  maxTxLimit;
    uint256 public  maxWalletLimit;
    uint256 public minTokenSwapAmount;
    address payable public treasuryWallet;
    uint256 public  swapableRefection;
    uint256 public  swapableTreasuryTax;
    bool private _swapping;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public sellTax;
    uint256 public buyTax;
    uint256 public taxSharePercentage;
    uint256 public totalBurned;
    uint256 public totalReflected;
    uint256 public totalLP;

    IUniswapV2Router02 public dexRouter;
    address public  lpPair;
    bool    public  tradingActive;
    bool    public  isLimit;
    uint256 public  ethReflectionBasis;
    uint256 public  reflectionLockPeriod;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool)    private _reflectionExcluded;
    mapping(address => uint256) public  lastReflectionBasis;
    mapping(address => uint256) public  lastReflectionTimeStamp;
    mapping(address => uint256) public  totalClaimedReflection;
    mapping(address => uint256) private _claimableReflection;

    mapping(address => bool)    public  lpPairs;
    mapping(address => bool)    private _isExcludedFromTax;

    event functionType (uint Type, address sender, uint256 amount);
    event reflectionClaimed (address indexed recipient, uint256 amount);
    event recoverAllEths(uint256 amount);
    event excludedFromTaxes (address account);
    event includeInTaxes(address account);
    event buyTaxUpdated(uint256 tax);
    event sellTaxUpdated(uint256 tax);
    event taxSharePercentageUpdated(uint256 percentage);
    event reflectionExcluded(address account);
    event recoverERC20Tokens(address token, uint256 amount);

    constructor(){
        _name              = "ManaCoin";
        _symbol            = "MNC";
        _decimals          = 18;
        _totalSupply       = 100000000 * (10 ** _decimals);
        _balances[owner()] = _balances[owner()] + _totalSupply;

        treasuryWallet     = payable(0x0aDEAE6683eFB0408542350E89B7B8311C4b6CE2);
        sellTax            = 20;
        buyTax             = 15;
        maxTxLimit         = 2000000000000000000000000;
        maxWalletLimit     = 2000000000000000000000000;
        minTokenSwapAmount = (_totalSupply * 21) / 10000;
        taxSharePercentage   = 50;
        reflectionLockPeriod = 60; 
        isLimit = true;

        dexRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lpPair    = IUniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        lpPairs[lpPair] = true;

        _approve(owner(), address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromTax[owner()]        = true;
        _isExcludedFromTax[treasuryWallet] = true;
        _isExcludedFromTax[address(this)]  = true;
        _isExcludedFromTax[lpPair]         = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address sender, address spender) public view override returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender  != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(_balances[msg.sender] >= amount, "ERC20: Amount exceeds account balance");

        _transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Zero Address");
        require(recipient != address(0), "ERC20: Zero Address");
        require(recipient != DEAD, "ERC20: Dead Address");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: Insufficient allowance.");
        require(_balances[sender] >= amount, "ERC20: Amount exceeds sender's account balance");

        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender]  = _allowances[sender][msg.sender] + (amount);
        }
        _transfer(sender, recipient, amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {

        if (sender == owner() && lpPairs[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        }
        else if (lpPairs[sender] || lpPairs[recipient]){
            require(tradingActive == true, "ERC20: Trading is not active.");
            
            if (_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient]){
                if (_checkWalletLimit(recipient, amount) && _checkTxLimit(amount)) {
                    _transferBuy(sender, recipient, amount); //user buy process
                } 
            }   
            else if (!_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]){
                if (_checkTxLimit(amount)) {
                    _transferSell(sender, recipient, amount); //user sell process
                }
            }
            else if (_isExcludedFromTax[sender] && _isExcludedFromTax[recipient]) {
                if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
                } else if (lpPairs[recipient]) {
                    if (_checkTxLimit(amount)) {
                        _transferBothExcluded(sender, recipient, amount);
                    }
                } else if (_checkWalletLimit(recipient, amount) && _checkTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
                }
            } 
        } else {
            if (sender == owner() || recipient == owner() || sender == address(this) || recipient == address(this)) {
                    _transferBothExcluded(sender, recipient, amount);
            } else if(_checkWalletLimit(recipient, amount) && _checkTxLimit(amount)){
                    _transferBothExcluded(sender, recipient, amount);
            }
        }
    }

    function _transferBuy(address sender, address recipient, uint256 amount) private { 
        /// users buy process
        uint256 randomTaxType  = _generateRandomTaxType();
        uint256 taxAmount     = amount * (buyTax)/100;
        uint256 receiveAmount = amount - (taxAmount);
        // get tax details
        ( uint256 treasuryAmount, uint256 burnAmount, uint256 lpAmount, uint256 reflectionAmount ) = _getTaxAmount(taxAmount);
        
        _claimableReflection[recipient] = _claimableReflection[recipient] + unclaimedReflection(recipient); 
        lastReflectionBasis[recipient]  = ethReflectionBasis;

        _balances[sender]        = _balances[sender] - (amount);
        _balances[recipient]     = _balances[recipient] + (receiveAmount);
        _balances[address(this)] = _balances[address(this)] + (treasuryAmount);
        swapableTreasuryTax      = swapableTreasuryTax + (treasuryAmount);

        if (randomTaxType == 1) {
            // true burn
            _burn(sender, burnAmount);
            emit functionType(randomTaxType, sender, burnAmount);
        } else if (randomTaxType == 2) {
            // smart lp
            _takeLP(sender, lpAmount);
            emit functionType(randomTaxType, sender, lpAmount);
        } else if (randomTaxType == 3) {
            // reflection adding
            _balances[address(this)] = _balances[address(this)] + (reflectionAmount);
            swapableRefection        = swapableRefection + (reflectionAmount);
            totalReflected           = totalReflected + (reflectionAmount);
            emit functionType(randomTaxType, sender, reflectionAmount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _transferSell(address sender, address recipient, uint256 amount) private { 
        /// users sell process
        uint256 randomTaxType = _generateRandomTaxType();
        uint256 taxAmount    = amount * sellTax/100;
        uint256 sentAmount   = amount - taxAmount;
        // get sell tax details
        ( uint256 treasuryAmount, uint256 burnAmount, uint256 lpAmount, uint256 reflectionAmount ) = _getTaxAmount(taxAmount);
        bool canSwap = swapableTreasuryTax >= minTokenSwapAmount;

        if(canSwap && !_swapping ) {
            _swapping = true;
            _swap(treasuryWallet, minTokenSwapAmount); // treasury swap function
            _swapping = false;
            swapableTreasuryTax = swapableTreasuryTax - (minTokenSwapAmount);
        }

        _balances[sender]        = _balances[sender] - (amount);
        _balances[recipient]     = _balances[recipient] + (sentAmount);
        _balances[address(this)] = _balances[address(this)] + (treasuryAmount);
        swapableTreasuryTax      = swapableTreasuryTax + (treasuryAmount);
        
        if(_balances[sender] == 0) {
            _claimableReflection[recipient] = 0; // claimable reflection amount initilize
        }
        
        if (randomTaxType == 1) {
            // true burn
            _burn(sender, burnAmount); 
            emit functionType(randomTaxType, sender, burnAmount);
        } else if (randomTaxType == 2) {
            // smart lp
            _takeLP(sender, lpAmount); 
            emit functionType(randomTaxType, sender, lpAmount);
        } else if (randomTaxType == 3) {
            // reflection adding
            _balances[address(this)] = _balances[address(this)] + (reflectionAmount);
            swapableRefection        = swapableRefection + (reflectionAmount);
            totalReflected           = totalReflected + (reflectionAmount);
            emit functionType(randomTaxType, sender, reflectionAmount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 amount) private {
        if(recipient == owner() || recipient == address(this)){
            _balances[sender]    = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
        } else {
            _claimableReflection[recipient] = _claimableReflection[recipient] + unclaimedReflection(recipient); 
            lastReflectionBasis[recipient]  = ethReflectionBasis;

            _balances[sender]    = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 amountTokens) public {
        address sender = msg.sender;
        require(_balances[sender] >= amountTokens, "ERC20: Burn Amount exceeds account balance");
        require(amountTokens > 0, "ERC20: Enter some amount to burn");

        if (amountTokens > 0) {
            _balances[sender] = _balances[sender] - amountTokens;
            _burn(sender, amountTokens);
        }
    }

    function _burn(address from, uint256 amount) private {
        _totalSupply = _totalSupply - amount;
        totalBurned  = totalBurned + amount;
        
        emit Transfer(from, address(0), amount);
    }

    function _takeLP(address from, uint256 tax) private {
        if (tax > 0) {
            (, , uint256 lp, ) = _getTaxAmount(tax);
            _balances[lpPair]  = _balances[lpPair] + lp;
            totalLP = totalLP + lp;

            emit Transfer(from, lpPair, lp);
        }
    }

    function addReflection() external payable {
        require (msg.value > 0);
        ethReflectionBasis = ethReflectionBasis + (msg.value);
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) external onlyOwner {
        require(isReflectionExcluded(account), "ERC20: Account must be excluded");

        _reflectionExcluded[account] = false;
    }

    function addReflectionExcluded(address account) external onlyOwner {
        _addReflectionExcluded(account);
        emit reflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "ERC20: Account must not be excluded");
        _reflectionExcluded[account] = true;
    }

    function unclaimedReflection(address addr) public view returns (uint256) {
        if (addr == lpPair || addr == address(dexRouter)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[addr];
        return ((basisDifference * balanceOf(addr)) / _totalSupply) + _claimableReflection[addr];
    }

    function _claimReflection(address payable addr) internal {
        uint256 unclaimed = unclaimedReflection(addr);
        require(unclaimed > 0, "ERC20: Claim amount should be more then 0");
        require(isReflectionExcluded(addr) == false, "ERC20: Address is excluded to claim reflection");
        
        lastReflectionBasis[addr] = ethReflectionBasis;
        lastReflectionTimeStamp[addr] = block.timestamp; // adding last claim Timestamp
        _claimableReflection[addr] = 0;
        addr.transfer(unclaimed);
        totalClaimedReflection[addr] = totalClaimedReflection[addr] + unclaimed;
        emit reflectionClaimed(addr, unclaimed);
    }

    function claimReflection() external returns (bool) {
        address _sender = _msgSender();
        require(!_isContract(_sender), "ERC20: Sender can't be a contract"); 
        require(lastReflectionTimeStamp[_sender] + reflectionLockPeriod <= block.timestamp, "ERC20: Reflection lock period exists,  try again later");
        _claimReflection(payable(_sender));
        return true;
    }

    function swapReflection(uint256 amount) public returns (bool) {
        // everyone can call this function to generate eth reflection
        require(swapableRefection > 0, "ERC20: Insufficient token to swap");
        require(swapableRefection >= amount);
        uint256 currentBalance = address(this).balance;
        _swap(address(this), amount);
        swapableRefection = swapableRefection - amount;
        uint256 ethTransfer = (address(this).balance) - currentBalance;
        ethReflectionBasis  = ethReflectionBasis + ethTransfer;
        return true;
    }

    function setMinTokensSwapAmount(uint256 newValue) external onlyOwner {
        require(
            newValue != minTokenSwapAmount,
            "Cannot update minTokenSwapAmount to same value"
        );
        minTokenSwapAmount = newValue;
    }

    function setsellTax(uint256 tax) public onlyOwner {
        require(tax <= 6, "ERC20: The percentage can't more 6%.");
        sellTax = tax;
        emit sellTaxUpdated(tax);
    }

    function setbuyTax(uint256 tax) public onlyOwner {
        require(tax <= 6, "ERC20: The percentage can't more 6%.");
        buyTax = tax;
        emit buyTaxUpdated(tax);
    }

    function setTaxSharePercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 100, "ERC20: The percentage can't more then 100");
        taxSharePercentage = percentage;
        emit taxSharePercentageUpdated(percentage);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function addLpPair(address pair, bool status) public onlyOwner{
        lpPairs[pair] = status;
        _isExcludedFromTax[pair] = status;
    }

    function returnNormalTax() public onlyOwner {
        sellTax = 5;
        buyTax  = 5;
        taxSharePercentage = 50;
    }

    function removeAllTax() public onlyOwner {
        sellTax = 0;
        buyTax  = 0;
        taxSharePercentage = 0;
    }

    function removeAllLimits() public onlyOwner {
        isLimit = false;
    }

    function excludeFromTax(address account) public onlyOwner {
        require(!_isExcludedFromTax[account], "ERC20: Account is already excluded.");
        _isExcludedFromTax[account] = true;
        emit excludedFromTaxes(account);
    }

    function includeInTax(address _account) public onlyOwner {
        require(_isExcludedFromTax[_account], "ERC20: Account is already included.");
        _isExcludedFromTax[_account] = false;
        emit includeInTaxes(_account);
    }
    
    function recoverAllEth() public {
        (bool success, ) = address(treasuryWallet).call{value: address(this).balance}("");
        if (success) {
            emit recoverAllEths(address(this).balance);
        }
    }

    function recoverErc20token(address token, uint256 amount) public onlyOwner {
        require(token != address(this),"can't claim own tokens");
        IERC20(token).transfer(owner(), amount);
        emit recoverERC20Tokens(token, amount);
    }

    function checkExludedFromTax(address _account) public view returns (bool) {
        return _isExcludedFromTax[_account];
    }

    function _generateRandomTaxType() private view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.gaslimit, tx.origin, block.number, tx.gasprice))) % 3) + 1;
    }

    function _getTaxAmount(uint256 _tax) private view returns (uint256 _treasuryAmount, uint256 Burn, uint256 LP, uint256 Reflection) {
        uint256 treasuryAmount;
        uint256 burnAmount;
        uint256 lpAmount;
        uint256 reflectionAmount;

        if (_tax > 0) {
            treasuryAmount = _tax * ((100 - taxSharePercentage))/100;
            burnAmount = _tax * (taxSharePercentage)/100;
            lpAmount = _tax * (taxSharePercentage)/100;
            reflectionAmount = _tax * (taxSharePercentage)/100;
        }
        return (treasuryAmount, burnAmount, lpAmount, reflectionAmount);
    }

    function _checkWalletLimit(address recipient, uint256 amount) private view returns(bool){
        if (isLimit) {
        require(maxWalletLimit >= balanceOf(recipient) + amount, "ERC20: Wallet limit exceeds");
        }
        return true;
    }

    function _checkTxLimit(uint256 amount) private view returns(bool){
        if (isLimit) {
        require(amount <= maxTxLimit, "ERC20: Transaction limit exceeds");
        }
        return true;
    }

    function _isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function _swap(address recipient, uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETH(
            amount,
            0,
            path,
            recipient,
            block.timestamp
        );
    }
}