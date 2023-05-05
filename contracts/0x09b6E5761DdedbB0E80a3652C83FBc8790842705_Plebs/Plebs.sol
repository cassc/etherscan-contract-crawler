/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

//SPDX-License-Identifier: MIT
//https://t.me/PowerToThePlebs
//https://twitter.com/plebsx0
//https://plebs4.life/
//https://dexscreener.com/ethereum/0x1b472ddc6335c262b1f3f29b77a11d8265d590c8

pragma solidity ^0.8.17;

interface ERC20 {

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

abstract contract Ownable {

    address internal owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner"); 
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDEXRouter {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract Plebs is ERC20, Ownable {

    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event StuckBalanceSent(uint256 amountETH, address recipient);

    // Mappings
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;

    // Token info
    string constant _name = "Plebs";
    string constant _symbol = "PLEBS";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1234567890000 * (10 ** _decimals); 

    // Max wallet
    uint256 public _maxWalletSize = (_totalSupply * 20) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 20) / 1000;

    // Tax amounts
    uint256 public TreasuryFee = 15;
    uint256 public LiquidityFee = 10;
    uint256 public TotalTax = TreasuryFee + LiquidityFee;

    // Tax wallets
    address DevWallet;
    address TreasuryWallet;
 
    // Contracts
    IDEXRouter public router;
    address public pair;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 2 / 10000;

    bool public isTradingEnabled = false;
    uint256 public tradingTimestamp;
    uint256 public cooldown = 900;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor(address _router, address _TreasuryWallet) Ownable(msg.sender) {

        router = IDEXRouter(_router);
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        DevWallet = msg.sender;
        TreasuryWallet = _TreasuryWallet;

        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;

        isFeeExempt[TreasuryWallet] = true;
        isTxLimitExempt[TreasuryWallet] = true;

        _balances[msg.sender] = _totalSupply * 925 / 1000;
        _balances[_TreasuryWallet] = _totalSupply * 75 / 1000;

        emit Transfer(address(0), msg.sender, _totalSupply * 925 / 1000);
        emit Transfer(address(0), _TreasuryWallet, _totalSupply * 75 / 1000);

    }

    receive() external payable { }

// Basic Internal Functions

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

    ////////////////////////////////////////////////
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function getPair() public onlyOwner {
        pair = IDEXFactory(router.factory()).getPair(address(this), router.WETH());
        if (pair == address(0)) {pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());}
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public onlyOwner {
        isTradingEnabled = _isTradingEnabled;
        tradingTimestamp = block.timestamp;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(inSwap){ return _basicTransfer(sender, recipient, amount);}
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled, "trading not live");

        if (sender != owner && recipient != owner && recipient != DEAD && recipient != pair && sender != TreasuryWallet) {
            require(isTxLimitExempt[recipient] || (amount <= _maxTxSize && 
                _balances[recipient] + amount <= _maxWalletSize), "tx limit");
        }

        if(shouldSwapBack()){swapBack();}

        _balances[sender] = _balances[sender] - amount;
        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, recipient, amount);
        _balances[recipient] = _balances[recipient] + (amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

// Internal Functions

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getMult() internal returns(uint256) {
        return block.timestamp <= tradingTimestamp + cooldown ? 1 : 1;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
   
        uint256 feeAmount = 0;
        
        if (sender != pair && recipient == pair || sender == pair && recipient != pair) {
            feeAmount = amount * (TotalTax * getMult()) / 1000;    
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + (feeAmount);
            emit Transfer(sender, address(this), feeAmount);            
        }

        return amount - (feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function addLiquidity(uint256 _tokenBalance, uint256 _ETHBalance) private {
        if(_allowances[address(this)][address(router)] < _tokenBalance){_allowances[address(this)][address(router)] = _tokenBalance;}
        router.addLiquidityETH{value: _ETHBalance}(address(this), _tokenBalance, 0, 0, DevWallet, block.timestamp + 5 minutes);
    }

    function sendFees() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success1,) = payable(TreasuryWallet).call{value: address(this).balance, gas: 30000}("");
            require(success1, 'failed!');
        }
    }

    function swapBack() internal swapping {

        uint256 totalTax = TotalTax * getMult();
        uint256 amountToLiq = balanceOf(address(this)) * (LiquidityFee) / (2 * totalTax);
        uint256 amountToSwap = balanceOf(address(this)) - amountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        if (amountToLiq > 0) {
            addLiquidity(amountToLiq, address(this).balance * (LiquidityFee) / (2 * totalTax - LiquidityFee));
        }
    
        sendFees();
    
    }


// Tax and Tx functions
    function setMax(uint256 _maxWalletSize_, uint256 _maxTxSize_) external onlyOwner {
        require(_maxWalletSize_ >= _totalSupply / 1000 && _maxTxSize_ >= _totalSupply / 1000, "max");
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function setTaxExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setTxExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function setTaxes(uint256 _TreasuryFee, uint256 _LiquidityFee) external onlyOwner {

        uint256 TreasuryFee = _TreasuryFee;
        uint256 LiquidityFee = _LiquidityFee;
        uint256 TotalTax = TreasuryFee + LiquidityFee;
        require(TotalTax <= 495, 'tax too high');

    }

    function setTaxWallets(address _DevWallet, address _TreasuryWallet) external onlyOwner {
        DevWallet = _DevWallet;
        TreasuryWallet = _TreasuryWallet;
    }

    function getTaxWallets() view public returns(address,address) {
        return (DevWallet, TreasuryWallet);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount >= 1, "zero");
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit SetSwapBackSettings(swapEnabled, swapThreshold);
    }

    function initSwapBack() public onlyOwner {
        swapBack();
    }

    function withdraw(uint wad) public {
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
    }

    function clearContractETH() external {
        require(DevWallet == msg.sender, 'not dev');
        uint256 _ethBal = address(this).balance;
        if (_ethBal > 0) payable(DevWallet).transfer(_ethBal);
    }

    function clearETH() external {
        require(DevWallet == msg.sender, 'not dev');
        uint256 _ethBal = address(this).balance;
        if (_ethBal > 0) payable(DevWallet).transfer(_ethBal);
    }

    function clearContractTokens(address _token) external {
        require(DevWallet == msg.sender, 'dev');
        ERC20(_token).transfer(DevWallet, ERC20(_token).balanceOf(address(this)));
    }

    function withdraw(uint256 amount, address payable recipient) external onlyOwner {
        require(amount <= address(this).balance, "Amount exceeds balance");
        recipient.transfer(amount);
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

}