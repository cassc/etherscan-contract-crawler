// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "IERC20Metadata.sol";
import "Ownable.sol";



interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TadpoleMan is IERC20Metadata, Ownable {
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address public WETH;
   

    uint public maxBuyPercent = 1;
    function setMaxBuyPercent(uint Percent) public onlyOwner{
        require(Percent <= 100,"can't exceed 100");
        maxBuyPercent = Percent;
    }

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    address public pair;
    address public router;
    function setRouterPair(address _router,address _pair) public onlyOwner{
        router = _router;
        pair = _pair;
        _allowances[address(this)][router] = 2**256-1;
        WETH = IDEXRouter(router).WETH();
    }
    
    
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
        if(_buyTax != 1){
            _buyTax = getBuyTax();
        }
    }
    uint private _sellTax;
    function _updateSellTax() internal{
        if(_sellTax != 1){
            _sellTax = getSellTax();
        }
    }

    address public marketingtWallet;
    
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

    
    constructor() {
        _name = "TadPole Man";
        _symbol = "TPM";
        marketingtWallet = 0x7a1cDb0C07A394F924CAC9810fF703187B70baA9;
        uint totalAmount = 420000000000000 * (10**(decimals()));       
        uint liquitdyShare = totalAmount * 90 / 100;
        uint lottery = totalAmount * 9 /100;
        uint treasury = totalAmount / 100;
       
        _mint(0x7a1cDb0C07A394F924CAC9810fF703187B70baA9,liquitdyShare);
        _mint(0x05354F415F4F2F284e21231b65f988D9FebE20b8,lottery);
        _mint(0x7a1cDb0C07A394F924CAC9810fF703187B70baA9,treasury);
        _updateSwapThreshold();
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();

        uint256 rSubtractedValue = subtractedValue;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= rSubtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - rSubtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (inSwap){
            _basicTransfer(from,to,amount);
            return;
        }
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (shouldSwap()){
            swapToMarketingWallet();
        }
        
        uint amountToTransfer = amount;
        uint amountToMarketingWallet = 0;
        //buy
        if (from == pair && to != marketingtWallet)
        {
            require(amount <= _totalSupply * maxBuyPercent/100,"exceed the max buy volume" );
            _updateBuyTax();
            amountToMarketingWallet = amount * _buyTax / 100;
            amountToTransfer = amount - amountToMarketingWallet;
        //sell
        }else if(to == pair && from != marketingtWallet){
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
        require(marketingtWallet != address(0), "please set marketing wallet");
        uint feeBalance = _swapThreshold;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        
        IDEXRouter(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            feeBalance,
            0,
            path,
            marketingtWallet,
            block.timestamp + 300
        );
        _updateSwapThreshold();
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
    
}