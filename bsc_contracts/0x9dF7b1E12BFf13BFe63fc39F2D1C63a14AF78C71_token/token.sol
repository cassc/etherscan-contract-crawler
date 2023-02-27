/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable is Context {
    address _owner;

    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
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

    function balanceOf(address account)public view virtual override returns (uint256){
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
		
		_transferToken(sender,recipient,amount);
    }
    
    function _transferToken(address sender, address recipient, uint256 amount) internal virtual {
        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface Itoken {
    function marketAddress() external view returns (address);
    function owner() external view returns (address);
}

contract Pool {
    IUniswapV2Router02 private router;
    address private usdt;
    address private tokenAddr;
    
    constructor(address _router, address _usdt) {
        tokenAddr = msg.sender;
        router = IUniswapV2Router02(_router);
        usdt = _usdt; 
    }

    modifier onlyadmin() {
        require(tokenAddr == msg.sender);
        _;
    }

    function process() onlyadmin external{
        address marketAddress = Itoken(tokenAddr).marketAddress();
        uint256 amount = IERC20(usdt).balanceOf(address(this));  
        IERC20(usdt).transfer(marketAddress, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdtAmount) onlyadmin external {
        address liquidAddress = Itoken(tokenAddr).owner();
        IERC20(tokenAddr).approve(address(router), tokenAmount);
        IERC20(usdt).approve(address(router), usdtAmount);

        router.addLiquidity(
            tokenAddr,
            usdt,
            tokenAmount,
            usdtAmount,
            0, 
            0, 
            address(liquidAddress),
            block.timestamp
        );
    }
}

contract token is ERC20 {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router;
    address private  uniswapV2Pair;
    address private _tokenOwner;
    Pool pool;
    uint256 private liquidIntervalTime = 10 * 60;
    uint256 private marketIntervalTime = 30 * 60;
    address private swapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    IERC20 private RewardToken = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address private pairToken = address(0x55d398326f99059fF775485246999027B3197955);
    uint256 private LcurrentTime;
    uint256 private McurrentTime;
    bool private swapping;
    uint256 private swapTokensAtAmount;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isblack;
    bool private swapAndLiquifyEnabled = true;
    uint256 public liquidCount;
    uint256 public marketCount;

    uint256 public bmarketFee = 40;
    uint256 public bliquidFee = 10;
    uint256 public smarketFee = 40;
    uint256 public sliquidFee = 10;
    address public marketAddress = 0x93e0fb5F6CbA098204466F7791465994f4a2461A;
    uint256 public maxBuyAmount = 10 * 10**18;
    
    string private tokenName = "Ladyboy";
    string private tokenSymbol = "Ladyboy";
    uint256 constant total  =  100000000000 * 10**18;
  
    constructor(address tokenOwner) ERC20(tokenName, tokenSymbol) { 
    
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapRouter);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), pairToken);
        _approve(address(this), swapRouter, 2**256 - 1);

        pool = new Pool(swapRouter, pairToken);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _tokenOwner = tokenOwner;
        excludeFromFees(tokenOwner);
        excludeFromFees(_owner);
        excludeFromFees(address(pool));
        excludeFromFees(address(this));
        swapTokensAtAmount = total / 100000;
        _mint(tokenOwner, total);
        LcurrentTime = block.timestamp;
        McurrentTime = block.timestamp;   
    }

    receive() external payable {}
 
    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }

    function includeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function setBuyFee(uint256 _marketFee, uint256 _liquidFee) public onlyOwner {
        bliquidFee = _liquidFee;
        bmarketFee = _marketFee;
    }

    function setSellFee(uint256 _marketFee,uint256 _liquidFee) public onlyOwner {
        sliquidFee = _liquidFee;
        smarketFee = _marketFee;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function setMaxBuyAmount(uint256 amount) public onlyOwner {
        maxBuyAmount = amount;
    }

    function Black(address account, bool enable) public onlyOwner {
        _isblack[account] = enable;
    }

    function batchBlack(address[] calldata accounts, bool enable) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isblack[accounts[i]] = enable;
        }
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount>=0);
        require(!_isblack[from]);
    
		if(from == address(this) || to == address(this) || from == address(pool) || to == address(pool)){
            super._transfer(from, to, amount);
            return;
        }

       if(marketCount > swapTokensAtAmount && block.timestamp >= (McurrentTime.add(marketIntervalTime))){
            if (
                    !swapping &&
                    _tokenOwner != from &&
                    _tokenOwner != to &&
                    from != uniswapV2Pair &&
                    swapAndLiquifyEnabled
                ) {
                    swapping = true;
                    swapAndProcess(marketCount);
                    marketCount = 0;
                    McurrentTime = block.timestamp;
                    swapping = false;
                }
        }else{
                
            if(liquidCount > swapTokensAtAmount && block.timestamp >= (LcurrentTime.add(liquidIntervalTime))){
                if (
                    !swapping &&
                    _tokenOwner != from &&
                    _tokenOwner != to &&
                    from != uniswapV2Pair &&
                    swapAndLiquifyEnabled
                ) {
                    swapping = true;       
                    swapAndLiquidity(liquidCount);
                    LcurrentTime = block.timestamp;
                    liquidCount = 0;
                    swapping = false;
                }
            }
        }

        bool takeFee = !swapping;     
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }else{
			if(from == uniswapV2Pair){
               
            }else if(to == uniswapV2Pair){     
            }else{}
        }

        if (takeFee) {
            if(from == uniswapV2Pair ){
                require(balanceOf(to) + amount <= maxBuyAmount,"exceed max buy Amount");
                uint256 allFee = amount.div(1000).mul(bliquidFee + bmarketFee);
                uint256 cmarketCount = amount.div(1000).mul(bmarketFee);
                super._transfer(from, address(this), allFee);
                marketCount =marketCount.add(cmarketCount);
                liquidCount =liquidCount.add(allFee.sub(cmarketCount));

                amount = amount.div(1000).mul(1000 - (bliquidFee + bmarketFee));
                
            }else if(to == uniswapV2Pair){
                uint256 allFee = amount.div(1000).mul(sliquidFee + smarketFee);
                uint256 cmarketCount = amount.div(1000).mul(smarketFee);
                super._transfer(from, address(this), allFee);
                marketCount =marketCount.add(cmarketCount);
                liquidCount =liquidCount.add(allFee.sub(cmarketCount));
                amount = amount.div(1000).mul(1000 - (sliquidFee + smarketFee));

            }else{
               super._transfer(from, to, amount);
            }
        }
        super._transfer(from, to, amount);
        
    }

    function swapAndLiquidity(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);
        uint256 initialBalance = IERC20(RewardToken).balanceOf(address(pool));

        swapTokensForOther(half);
        uint256 newBalance = IERC20(RewardToken).balanceOf(address(pool)).sub(initialBalance);
        super._transfer(address(this), address(pool), otherHalf);
        pool.addLiquidity(otherHalf,newBalance);
    }

    function swapAndProcess(uint256 contractTokenBalance) private {
        swapTokensForOther(contractTokenBalance);
        pool.process();
    }
    
    function swapTokensForOther(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(RewardToken);
        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(pool),
            block.timestamp
        );
    }
}