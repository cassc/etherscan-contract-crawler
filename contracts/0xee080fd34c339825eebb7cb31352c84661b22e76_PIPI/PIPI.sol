/**
 *Submitted for verification at Etherscan.io on 2023-07-11
*/

// SPDX-License-Identifier: Unlicensed

/**
 *  Twitter: https://twitter.com/thePipicoineth
 */

pragma solidity 0.8.20;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        emit OwnershipTransferred(owner, adr);
        owner = adr;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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


contract PIPI is IERC20, Auth {
    using SafeMath for uint256;

    address private WETH;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    string private constant  _name = "PIPI";
    string private constant _symbol = "PIPI";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public maxWallet = ( _totalSupply * 2 ) / 100;
    uint256 public maxTransactionAmount = ( _totalSupply * 2 ) / 100;
    uint256 public numTokensSellToAddToLiquidity = _totalSupply * 5 / 10000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private cooldown;

    mapping (address => bool) private isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isTimelockExempt;
            
    uint256 public buyFeeRate = 20;
    uint256 public sellFeeRate = 20;

    uint256 private feeDenominator = 100;

    address payable public devWallet = payable(0xeb9A7070478962424b38a9464bFaE0F74386B3E9);
    address payable public marketingWallet = payable(0x484fF85dc7E03464782647e1961ac575013C4f1b);

    IDEXRouter public router;
    address public pair;

    bool private tradingOpen;
    bool private limitEffect = true;

    bool public maxWalletEnabled = true;
    bool private inSwap;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = false;
    uint8 public cooldownTimerInterval = 15;

    mapping (address => uint) private cooldownTimer;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isTxLimitExempt[msg.sender] = true;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingWallet] = true;   
        isFeeExempt[devWallet] = true;               

        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
    
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(limitEffect){
            if (
                sender != owner &&
                recipient != owner &&
                recipient != address(0) &&
                recipient != address(0xdead)
            ){
                if(!isFeeExempt[sender] && !isFeeExempt[recipient]){ 
                    require(tradingOpen, "Trading not yet enabled.");
                }
            }

            // Checks max transaction limit
            require(amount <= maxTransactionAmount || isTxLimitExempt[sender], "TX Limit Exceeded");

            // max wallet code
            if (maxWalletEnabled && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != marketingWallet && recipient != devWallet){
                uint256 heldTokens = balanceOf(recipient);
                require((heldTokens + amount) <= maxWallet,"Total Holding is currently limited, you can not buy that much.");
            }

            // cooldown timer, so a bot doesnt do quick trades! 1min gap between 2 trades.
            if (sender == pair &&
                buyCooldownEnabled &&
                !isTimelockExempt[recipient]) {
                require(cooldownTimer[recipient] < block.timestamp,"Please wait for 1min between two buys");
                cooldownTimer[recipient] = block.timestamp + cooldownTimerInterval;
            }
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }      

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    
        bool shouldSwapBack = (overMinTokenBalance && recipient==pair && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ 
            swapBack(numTokensSellToAddToLiquidity); 

            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
            
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

	function _distributeTaxEth(uint256 _amount) private {
		marketingWallet.transfer(_amount.div(2));
		devWallet.transfer(_amount.div(2));
	}
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return ( !(isFeeExempt[sender] || isFeeExempt[recipient]) &&  (sender == pair || recipient == pair) );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 transferFeeRate = recipient == pair ? sellFeeRate : buyFeeRate;
        uint256 feeAmount;
        feeAmount = amount.mul(transferFeeRate).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);   

        return amount.sub(feeAmount);
    }

    function swapBack(uint256 amount) internal swapping {
        swapTokensForEth(amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapToken() public onlyOwner {

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    
        bool shouldSwapBack = (overMinTokenBalance && balanceOf(address(this)) > 0);
        if(shouldSwapBack){ 
            swapTokensForEth(numTokensSellToAddToLiquidity);
         }
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }    
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFee (uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
        require (_buyFeeRate <= 20, "Fee can't exceed 20%");
        require (_sellFeeRate <= 20, "Fee can't exceed 20%");
        buyFeeRate = _buyFeeRate;
        sellFeeRate = _sellFeeRate;
    }

    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setWallets(address _marketingWallet, address _devWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
        devWallet = payable(_devWallet);
    } 

    function removeLimitEffect() external onlyOwner {
        limitEffect = false;
    }

    function setMaxWalletEnabled(bool value) external onlyOwner {
        maxWalletEnabled = value;
    }

    function setSwapThresholdAmount (uint256 amount) external onlyOwner {
        require (amount <= _totalSupply.div(100), "can't exceed 1%");
        numTokensSellToAddToLiquidity = amount * 10 ** 9;
    } 

    function setMaxBuyAmount (uint256 maxBuyPercent) external onlyOwner {
        maxTransactionAmount = (_totalSupply * maxBuyPercent ) / 1000;
    } 

    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner {
        maxWallet = (_totalSupply * maxWallPercent ) / 1000;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }
    
    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

}