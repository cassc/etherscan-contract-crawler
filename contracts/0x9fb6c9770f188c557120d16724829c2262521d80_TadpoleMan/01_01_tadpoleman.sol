// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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



abstract contract Context {
    
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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




contract TadpoleMan is Ownable, IERC20 {
    

    address WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    

    string constant private _name = "TadPole Man";
    string constant private _symbol = "TPM";
    uint256 _totalSupply;
    uint8 constant _decimals = 9; 


    uint public maxBuyPercent = 1;
    function setMaxBuyPercent(uint Percent) public onlyOwner{
        require(Percent <= 100,"can't exceed 100");
        maxBuyPercent = Percent;
    }
    
  
         

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;  
    

    address public marketingWallet;
    
    bool public swapEnabled;
    function setSwapEnable(bool _swapEnabled) public onlyOwner{
        swapEnabled = _swapEnabled;
        _updateSwapThreshold();
    }
    function _random(uint number) internal view returns(uint) {
        // emit log_difficulty(block.difficulty);
        return uint(keccak256(abi.encodePacked(block.timestamp,block.coinbase,block.difficulty,  
        msg.sender))) % number;
    }
    uint private  _swapThreshold;
    function _updateSwapThreshold() internal {
        _swapThreshold = _totalSupply * (70 + _random(430)) / 100  / 100;
    }

    

    IDEXRouter public router;
    address public pair;
    
    
    uint public tradeStartTime;
    bool public tradeStart;
    function setTradeStart(bool start) public onlyOwner{
        tradeStart = start;
        tradeStartTime = block.timestamp;
    }
    function getBuyTax() public view returns(uint buyTax){
        require(tradeStart,"trade not start");        
        uint deltaTime = block.timestamp - tradeStartTime;
        if (deltaTime >= 600){
            buyTax = 1;
        }else if(deltaTime >= 300){
            buyTax = 5;
        }else if(deltaTime >= 180){
            buyTax = 10;
        }else if(deltaTime >= 30){
            buyTax = 20;
        }else{
            buyTax = 30;
        }
    }
    function getSellTax() public view returns(uint sellTax){
        require(tradeStart,"trade not start");        
        uint deltaTime = block.timestamp - tradeStartTime;
        if (deltaTime >= 600){
            sellTax = 1;
        }else if(deltaTime >= 300){
            sellTax = 5;
        }else if(deltaTime >= 180){
            sellTax = 10;
        }else if(deltaTime >= 30){
            sellTax = 20;
        }else{
            sellTax = 50;
        }
    }
    uint private _buyTax;
    function _updateBuyTax() internal{
        if (_buyTax != 1){
            _buyTax = getBuyTax();
        }        

    }
    uint private _sellTax;
    function _updateSellTax() internal{
        if (_sellTax != 1){
            _sellTax = getSellTax();
        }       

    }
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }   
    uint public liquitdyShare;
    
    
    constructor () {
        address router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IDEXRouter(router_address);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        
        
        uint totalAmount = 420000000000000 * (10**(_decimals));       
        liquitdyShare = totalAmount * 90 / 100;
        uint lottery = totalAmount * 9 /100;
        uint treasury = totalAmount / 100; 
        
        
        marketingWallet = 0x7a1cDb0C07A394F924CAC9810fF703187B70baA9;
        _mint(address(this),liquitdyShare);
        _mint(0x05354F415F4F2F284e21231b65f988D9FebE20b8,lottery);
        _mint(0x7a1cDb0C07A394F924CAC9810fF703187B70baA9,treasury);
        
        _updateSwapThreshold();

    }

    // receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) {return owner();}
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
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function addLiquidity() public payable  onlyOwner{
        address tmp = pair;
        pair = ZERO;
        router.addLiquidityETH{value:msg.value}(address(this),liquitdyShare, 0, 0, marketingWallet, block.timestamp + 300);
        pair = tmp;
    }
    

      
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns(bool) {
        if (inSwap){
            _basicTransfer(from,to,amount);
            return true;
        }
        
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (shouldSwap()){
            swapToMarketingWallet();
        }
        
        uint amountToTransfer = amount;
        uint amountToMarketingWallet = 0;
        //buy
        if (from == pair && to != marketingWallet)
        {
            require(amount <= _totalSupply * maxBuyPercent/100,"exceed the max buy volume" );
            _updateBuyTax();
            amountToMarketingWallet = amount * _buyTax / 100;
            amountToTransfer = amount - amountToMarketingWallet;
        //sell
        }else if(to == pair && from != marketingWallet){
            _updateSellTax();
            amountToMarketingWallet = amount * _sellTax / 100;
            amountToTransfer = amount - amountToMarketingWallet;
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[from] = fromBalance - amount;
            _balances[to] += amountToTransfer;
            _balances[address(this)] += amountToMarketingWallet;
        }
        

        emit Transfer(from, to, amountToTransfer);
        if (amountToMarketingWallet > 0){
            emit Transfer(from,address(this),amountToMarketingWallet);
        }
        return true;
    }
    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

    }

    function shouldSwap() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= _swapThreshold;
    }
    function swapToMarketingWallet() internal swapping {
        require(marketingWallet != address(0), "please set marketing wallet");
        uint feeBalance = _swapThreshold;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            feeBalance,
            0,
            path,
            marketingWallet,
            block.timestamp + 300
        );
        _updateSwapThreshold();
    }

    function manulSwapToETH() public {
        require(msg.sender == marketingWallet,"not marketingWallet");
        swapToMarketingWallet();
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

    }

      
   
}