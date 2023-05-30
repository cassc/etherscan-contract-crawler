/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

// SPDX-License-Identifier: Unlicensed

    pragma solidity ^0.8.0;

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
        function add(uint256 a, uint256 b) internal pure returns (uint256) 
        {    return a + b; }
        function sub(uint256 a, uint256 b) internal pure returns (uint256) 
        {    return a - b; }
        function mul(uint256 a, uint256 b) internal pure returns (uint256) 
        {    return a * b; }
        function div(uint256 a, uint256 b) internal pure returns (uint256) 
        {    return a / b; }
        function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            unchecked {
                require(b <= a, errorMessage);
                return a - b;
            }
        }
        function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            unchecked {
                require(b > 0, errorMessage);
                return a / b;
            }
        }  
    }

    abstract contract Context {
        function _msgSender() internal view virtual returns (address) 
        {    return msg.sender; }

        function _msgData() internal view virtual returns (bytes calldata) 
        {  
             this; 
            return msg.data;
        }
    }

    abstract contract Ownable is Context {
        address internal _owner;
        address private _previousOwner;

        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
        constructor () {
            _owner = _msgSender();
            emit OwnershipTransferred(address(0), _owner);
        }
        function owner() public view virtual returns (address) {
            return _owner;
        }
        modifier onlyOwner() {
            require(owner() == _msgSender(), "Ownable: caller is not the owner");
            _;
        }
        function renounceOwnership() public virtual onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }

    interface IERC20Metadata is IERC20 
    {
         function name() external view returns (string memory);
         function symbol() external view returns (string memory);
         function decimals() external view returns (uint8);
    }

    contract ERC20 is Context,Ownable, IERC20, IERC20Metadata {
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
            return 9;
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
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            return true;
        }
        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
            return true;
        }
        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) internal virtual {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");

            _beforeTokenTransfer(sender, recipient, amount);

            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

            _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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


    interface IUniswapV2Factory {
        function createPair(address tokenA, address tokenB) external returns (address pair);
    }

    interface IUniswapV2Pair {
        function factory() external view returns (address);
    }

    interface IUniswapV2Router01 {
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

    interface IUniswapV2Router02 is IUniswapV2Router01 {     
       function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

    contract TOKEN is ERC20 {
        
        using SafeMath for uint256;

        mapping (address => bool) private _isExcludedFromFee;

        address constant burnAddress = 0xdEAD000000000000000042069420694206942069;

        uint256 public buyBurnFee = 5;  
        uint256 public sellBurnFee = 5; 

        IUniswapV2Router02 public uniswapV2Router;
        address public uniswapV2Pair;
        
        constructor () ERC20("Mallow", "MLC"){
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            uniswapV2Router = _uniswapV2Router;
            _isExcludedFromFee[_msgSender()] = true;
            _isExcludedFromFee[address(this)] = true;
            _mint(owner(), 1000000000000000  * 10 ** decimals());
        }

        function excludeFromFee(address account) public onlyOwner 
        { _isExcludedFromFee[account] = true;}
        
        function includeInFee(address account) public onlyOwner 
        {_isExcludedFromFee[account] = false;}

        function setFee(
            uint256 buyFee,
            uint256 sellFee
        ) external onlyOwner 
        {   
            buyBurnFee = buyFee;
            sellBurnFee = sellFee;
        }
        
        function isExcludedFromFee(address account) public view returns(bool) {
            return _isExcludedFromFee[account];
        }

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) internal override {
            require(from != address(0), "ERC20: transfer from the zero address");
            require(to != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");

          
            bool takeFee = true;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                super._transfer(from, to, amount);
                takeFee = false;
            } else {
            if (from == uniswapV2Pair) {
                // Buy
                uint256 burnTokens = amount.mul(buyBurnFee).div(100);
                amount= amount.sub(burnTokens);
                super._transfer(from, burnAddress, burnTokens);
                super._transfer(from, to, amount);

            } else if (to == uniswapV2Pair) {
                // Sell
                uint256 burnTokens = amount.mul(sellBurnFee).div(100);
                amount= amount.sub(burnTokens);
                super._transfer(from, burnAddress, burnTokens);
                super._transfer(from, to, amount);
            } else {
                // Transfer
                super._transfer(from, to, amount);
            }       
        }
        }
    }