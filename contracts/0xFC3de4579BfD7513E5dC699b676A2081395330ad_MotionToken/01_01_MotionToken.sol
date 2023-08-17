// SPDX-License-Identifier: No

pragma solidity ^0.8.0;

//--- Context ---//
abstract contract Context {
    constructor() {
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

//--- Ownable ---//
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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

//--- Interface for ERC20 ---//
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

//--- Contract v2 ---//
contract MotionToken is Context, Ownable, IERC20 {

    function totalSupply() external pure override returns (uint256) { if (_totalSupply == 0) { revert(); } return _totalSupply; }
    function decimals() external pure override returns (uint8) { if (_totalSupply == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return balance[account];
    }

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFee;
    mapping (address => bool) private isLpPair;
    mapping (address => uint256) private balance;
    mapping(address => bool) private _isBot; 

    uint256 constant public _totalSupply = 5e9 * 10**18;
    uint256 public swapThreshold = 1000000 * 10 ** 18; 
    uint256 public maxTxAmount = 50000000 * 10**18; // 1% of the supply
    uint256 public buyfee = 0;
    uint256 public sellfee = 50;
    uint256 public transferfee = 0;
    uint256 constant public fee_denominator = 1000;
    bool private canSwapFees = false;
    address payable private marketingAddress;
    address public circulatingSupplyWallet = 0xb7A681D261EeDB90c41664c0d3dA49402Ec57fCB; // add Liquidty and circulating supply wallet address
    address public rewardWallet = 0x71D05c1Dfb4F1AF5E6cCe4C4865a8cCe34EA2914; // add reward wallet address
    address public devTeamWallet = 0x81ea96678cAd9fd9476A093455C30D3655627c1a; // add Dev teams wallet address
    uint256 public first72HourRestriction = block.timestamp + 86400;
    uint256 public first72hoursFee = 75;

    IRouter02 public swapRouter;
    string constant private _name = "Motion";
    string constant private _symbol = "MOTN";
    uint8 constant private _decimals = 18;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool public isTradingEnabled = false;
    bool private inSwap;

        modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    event _enableTrading();
    event _toggleCanSwapFees(bool enabled);
    event _changePair(address newLpPair);
    event _changeWallets(address marketing);
    event _changeMaxTransactionLimit(uint256 maxTxAmount);

    constructor (address _swapRouter, address _marketingAddress) {
        
        swapRouter = IRouter02(_swapRouter);
        marketingAddress = payable(_marketingAddress);
        balance[circulatingSupplyWallet] = (_totalSupply * 60) / 100;
        balance[rewardWallet] = (_totalSupply * 30) / 100;
        balance[devTeamWallet] = (_totalSupply * 10) / 100;

        lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);


        _noFee[address(this)] = true;
        _noFee[marketingAddress] = true;
        _noFee[msg.sender] = true;
        _noFee[circulatingSupplyWallet] = true;
        _noFee[rewardWallet] = true;
        _noFee[devTeamWallet] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function openTrading() external onlyOwner() {
        require(!isTradingEnabled,"trading is already open");
        isTradingEnabled = true;
        first72HourRestriction = block.timestamp + 259200;
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

	function approve(address spender, uint256 amount) external override returns (bool) {
	_approve(msg.sender, spender, amount);
	return true;
    }

	function _approve(address sender, address spender, uint256 amount) internal {
	require(sender != address(0), "ERC20: Zero Address");
	require(spender != address(0), "ERC20: Zero Address");

	_allowances[sender][spender] = amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }
    function isNoFeeWallet(address account) external view returns(bool) {
        return _noFee[account];
    }

    function setNoFeeWallet(address account, bool enabled) external onlyOwner {
        _noFee[account] = enabled;
    }

    function set72hourfee(uint256 _fee) external onlyOwner{
        require(first72HourRestriction >=block.timestamp, "Time expired to set this value");
        first72hoursFee = _fee;
    }

    function remove72hourRestriction() external onlyOwner{
        first72HourRestriction = block.timestamp;
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {
        bool isLimited = ins != owner()
            && out != owner() && msg.sender != owner()
            && out != DEAD && out != address(0) && out != address(this);
            return isLimited;
    }

    function is_buy(address _from, address _to) internal view returns (bool) {
        bool _is_buy = !isLpPair[_to] && isLpPair[_from];
        return _is_buy;
    }

    function is_sell(address _from, address _to) internal view returns (bool) {
        bool _is_sell = isLpPair[_to] && !isLpPair[_from];
        return _is_sell;
    }

    function canSwap() internal view returns (bool) {
        bool canswap = canSwapFees;
        return canswap;
    }

    function changeSwapThreshold(uint256 _amount) external onlyOwner {
        require(_amount >= 10000, "Threshold is too loo");
        swapThreshold = _amount * 10**18;
    }

    function changeLpPair(address newPair) external onlyOwner {
        lpPair = newPair;
        isLpPair[newPair] = true;
        emit _changePair(newPair);
    }

    function toggleCanSwapFees(bool yesno) external onlyOwner {
        require(canSwapFees != yesno,"Bool is the same");
        canSwapFees = yesno;
        emit _toggleCanSwapFees(yesno);
    }

    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
        require(isTradingEnabled || _noFee[from] || _noFee[to], "Trading not yet enabled!");

        if(is_sell(from, to) &&  !inSwap && canSwap()) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapThreshold) { internalSwap(contractTokenBalance); }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }

        balance[from] -= amount; uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee; emit Transfer(from, to, amountAfterFee);
        return true;

    }


    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
        if (isbuy){
            fee = buyfee;
        } else if (issell) { 
            fee = (block.timestamp >= first72HourRestriction) ? sellfee : first72hoursFee;
        }  
        else  fee = transferfee;  
        if (fee == 0)  return amount;
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }

    function internalSwap(uint256 contractTokenBalance) internal inSwapFlag {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }
        bool success;

        if(address(this).balance > 0) {(success,) = marketingAddress.call{value: address(this).balance, gas: 35000}("");}

    }

    function changeTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferFee) external onlyOwner {
        require(_buyTax <= 100, "Buy tax cannot exceed 10%"); // 100 represents 10%
        require(_sellTax <= 100, "Sell tax cannot exceed 10%"); // 100 represents 10%
        require(_transferFee <= 100, "Transfer tax cannot exceed 10%"); // 100 represents 10%
        transferfee = _transferFee;
        sellfee = _sellTax;
        buyfee = _buyTax;
    }

    function changeTaxWallets(address marketing) external onlyOwner {
        marketingAddress = payable(marketing);
        emit _changeWallets(marketing);
    }

    function changeMaxTransactionLimit(uint256 _maxTransaction) external onlyOwner {
    require(_maxTransaction >= 10000000, "Max transaction limit is too loo");
    maxTxAmount = _maxTransaction;
    emit _changeMaxTransactionLimit(maxTxAmount);
    }

	function bulkAntiBot(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        require(accounts.length <= 100, "Address: Invalid");
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_isBot[accounts[i]] != state) _isBot[accounts[i]] = state;
        }
    }

    function airdropTokens(
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner returns (bool) {
        require(recipients.length == amounts.length, "Invalid size");
        for (uint256 i; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
        return true;
    }
	
	function rescueETH(uint256 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Owner cannot transfer _to catecoin from this smart contract
    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint _amount
    ) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }      
    
}