/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract MM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    address payable private _devWallet;
    address payable private _lpWallet;

    uint8 private constant _buyTax = 5;
    uint8 private constant _sellTax = 5;

    string private constant _name = unicode"Magic Mushroom";
    string private constant _symbol = unicode"MM";

    uint8 private constant _decimals = 8;
    uint256 private constant _totalSupply = 1_000_000_000_000 * 10**_decimals;
    uint256 private _currentSupply = 0;

    uint256 private constant _mintWalletMax = 5_000_000_000 * 10**_decimals;    
    uint256 private constant _mintPriceByToken = 5_000_000_000 * 10**_decimals;
    uint256 private constant _mintPriceByEther = 0.1 ether;

    bool public isTrade = false;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    event CurrentSupplyUpdated(uint256 _currentSupply);
    event AutoLiquify(uint256 amountETH, uint256 amountTokens);
    event EnableTrade();

    bool private locked = false;
    modifier lockTheAddLiquidity {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    constructor (address lpWallet) {
        _lpWallet = payable(lpWallet);
        _devWallet = payable(_msgSender());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[_lpWallet] = true;
        _isExcludedFromFee[_devWallet] = true;

        renounceOwnership();
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function currentSupply() public view  returns (uint256) {
        return _currentSupply;
    }

    function buyTax() public pure returns (uint8) {
        return _buyTax;
    }

    function sellTax() public pure returns (uint8) {
        return _sellTax;
    }

    function mintPriceByToken() public pure returns (uint256) {
        return _mintPriceByToken;
    }

    function mintPriceByEther() public pure returns (uint256) {
        return _mintPriceByEther;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        uint256 taxAmount=0;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if((from == uniswapV2Pair || to == uniswapV2Pair ) && !(from == uniswapV2Pair && to == address(uniswapV2Router))){
                require(isTrade,"Haven't opened the transaction yet");

                if(from == uniswapV2Pair)                  
                    taxAmount = amount.mul(_buyTax).div(100);  

                if(to == uniswapV2Pair)                   
                    taxAmount = amount.mul(_sellTax).div(100);
                    
                _balances[_lpWallet]=_balances[_lpWallet].add(taxAmount);
                emit Transfer(from, _lpWallet,taxAmount);
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function enableTrade() external{
        require(_msgSender()==_devWallet,"Only devWallet call");
        require(!isTrade,"Swap opened");
        isTrade = true;
        emit EnableTrade();
    }

    function createPair() external payable {
        require(_msgSender()==_devWallet,"Only devWallet call");
        require(uniswapV2Pair == address(0),"Trading pair created");

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        
        uint256 amount = msg.value.mul(_mintPriceByToken).div(0.1 ether);

         _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        emit Transfer(address(0), _msgSender(), amount);

        _balances[address(this)] = _balances[address(this)].add(amount);
        payable(address(this)).transfer(msg.value);

        _currentSupply = _currentSupply.add(amount.mul(2));
        emit CurrentSupplyUpdated(_currentSupply);

        if (address(this).balance > 0 && _balances[address(this)] > 0){
            triggerAutoLiquify(address(this).balance,_balances[address(this)],address(0)); 
        }
    }
   
    function mint() external payable {
        require(msg.value == 0.1 ether, "Mint range 0.1ETH");
        uint256 amount = msg.value.mul(_mintPriceByToken).div(0.1 ether);
        require(balanceOf(_msgSender()).add(amount) <= _mintWalletMax, "Wallet mint out of range");
        require(_currentSupply.add(amount.mul(2)) <= _totalSupply, "Mint has exceeded the maximum number");
        
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        emit Transfer(address(0), _msgSender(), amount);

        _balances[address(this)] = _balances[address(this)].add(amount);
        payable(address(this)).transfer(msg.value);

        _currentSupply = _currentSupply.add(amount.mul(2));
        emit CurrentSupplyUpdated(_currentSupply);

        if (address(this).balance > 0 && _balances[address(this)] > 0){
            triggerAutoLiquify(address(this).balance,_balances[address(this)],_lpWallet); 
        }
        
    }  

    function triggerAutoLiquify(uint256 amountETHLiquidity,uint256 amountToLiquify,address addr) private lockTheAddLiquidity{
        uniswapV2Router.addLiquidityETH{value: amountETHLiquidity}(
            address(this),
            amountToLiquify,
            0,
            0,
            addr,
            block.timestamp
        );
        emit AutoLiquify(amountETHLiquidity, amountToLiquify);
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i]* 10**_decimals;

            require(recipient != address(0), "Invalid recipient address");
            require(amount > 0, "Invalid amount");

            _transfer(_msgSender(), recipient, amount);
        }
    }

    receive() external payable {}
}