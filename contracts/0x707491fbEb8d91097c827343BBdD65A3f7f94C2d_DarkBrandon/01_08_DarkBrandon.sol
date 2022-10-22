// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;         

import "@openzeppelin/contracts/access/Ownable.sol";         
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";         
import "@openzeppelin/contracts/utils/math/SafeMath.sol";         
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";         
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";         

interface IUSDCReceiver {
    function initialize(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
}

contract USDCReceiver is IUSDCReceiver, Ownable {
    address public usdc;
    address public token;

    constructor() Ownable() {
        token = msg.sender;
    }

    function initialize(address _usdc) public onlyOwner {
        require(usdc == address(0x0), "Already initialized");
        usdc = _usdc;
    }

    function withdraw() public {
        require(msg.sender == token, "Caller is not token");
        IERC20(usdc).transfer(token, IERC20(usdc).balanceOf(address(this)));
    }

    function withdrawUnsupportedAsset(address _token, uint256 _amount) public onlyOwner {
        if(_token == address(0x0))
            payable(owner()).transfer(_amount);
        else
            IERC20(_token).transfer(owner(), _amount);
    }
}

contract DarkBrandon is Context, IERC20, Ownable {         
    using SafeMath for uint256;         

    IUniswapV2Router02 private _uniswapV2Router;

    USDCReceiver private _receiver;         

    mapping (address => uint) private _antiMEV;         

    mapping (address => uint256) private _balances;         

    mapping (address => mapping (address => uint256)) private _allowances;         

    mapping (address => bool) private _isExcludedFromFees;         
    mapping (address => bool) private _isExcludedMaxTransactionAmount;         

    bool public tradingOpen;         
    bool private _swapping;         
    bool public swapEnabled;         
    bool public antiMEVEnabled;         

    string private constant _name = "Dark Brandon";         
    string private constant _symbol = "BRANDON";         

    uint8 private constant _decimals = 18;         

    uint256 private constant _totalSupply = 75_757_757_757_757 * (10**_decimals);         

    uint256 public buyThreshold = _totalSupply.mul(15).div(1000);         
    uint256 public sellThreshold = _totalSupply.mul(15).div(1000);         
    uint256 public walletThreshold = _totalSupply.mul(15).div(1000);         

    uint256 public fee = 50; // 5%         
    uint256 private _previousFee = fee;         

    uint256 private _tokensForFee;         
    uint256 private _swapTokensAtAmount = _totalSupply.mul(7).div(10000);                  

    address payable private feeCollector;         
    address private _uniswapV2Pair;         
    address private DEAD = 0x000000000000000000000000000000000000dEaD;         
    address private ZERO = 0x0000000000000000000000000000000000000000;         
    address private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    constructor () {         
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);         
        _approve(address(this), address(_uniswapV2Router), _totalSupply);         
        IERC20(USDC).approve(address(_uniswapV2Router), IERC20(USDC).balanceOf(address(this)));         
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), USDC);         
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);         

        _receiver = new USDCReceiver();
        _receiver.initialize(USDC);
        _receiver.transferOwnership(msg.sender);

        feeCollector = payable(_msgSender());         
        _balances[_msgSender()] = _totalSupply;         

        _isExcludedFromFees[owner()] = true;         
        _isExcludedFromFees[address(this)] = true;         
        _isExcludedFromFees[address(_receiver)] = true;         
        _isExcludedFromFees[DEAD] = true;         

        _isExcludedMaxTransactionAmount[owner()] = true;         
        _isExcludedMaxTransactionAmount[address(this)] = true;         
        _isExcludedMaxTransactionAmount[address(_receiver)] = true;         
        _isExcludedMaxTransactionAmount[DEAD] = true;         

        emit Transfer(ZERO, _msgSender(), _totalSupply);         
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

    function balanceOf(address account) public view override returns (uint256) {         
        return _balances[account];         
    }         

    function transfer(address to, uint256 amount) public override returns (bool) {         
        _transfer(_msgSender(), to, amount);         
        return true;         
    }         

    function allowance(address owner, address spender) public view override returns (uint256) {         
        return _allowances[owner][spender];         
    }         

    function approve(address spender, uint256 amount) public override returns (bool) {         
        address owner = _msgSender();         
        _approve(owner, spender, amount);         
        return true;         
    }         

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {         
        address spender = _msgSender();         
        _spendAllowance(from, spender, amount);         
        _transfer(from, to, amount);         
        return true;         
    }         

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {         
        address owner = _msgSender();         
        _approve(owner, spender, allowance(owner, spender) + addedValue);         
        return true;         
    }         

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {         
        address owner = _msgSender();         
        uint256 currentAllowance = allowance(owner, spender);         
        require(currentAllowance >= subtractedValue, "BRANDON: decreased allowance below zero");         
        unchecked {         
            _approve(owner, spender, currentAllowance - subtractedValue);         
        }         

        return true;         
    }         

    function _transfer(address from, address to, uint256 amount) internal {         
        require(from != ZERO, "BRANDON: transfer from the zero address");         
        require(to != ZERO, "BRANDON: transfer to the zero address");         
        require(amount > 0, "BRANDON: Transfer amount must be greater than zero");         

        bool takeFee = true;         
        bool shouldSwap = false;         
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {         
            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "BRANDON: Trading is not allowed yet.");         

            if (antiMEVEnabled) {         
                if (to != address(_uniswapV2Router) && to != address(_uniswapV2Pair)) {         
                    require(_antiMEV[tx.origin] < block.number - 1 && _antiMEV[to] < block.number - 1, "BRANDON: Transfer delay enabled. Try again later.");         
                    _antiMEV[tx.origin] = block.number;         
                    _antiMEV[to] = block.number;         
                }         
            }         

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[to]) {         
                require(amount <= buyThreshold, "BRANDON: Transfer amount exceeds the buyThreshold.");         
                require(balanceOf(to) + amount <= walletThreshold, "BRANDON: Exceeds maximum wallet token amount.");         
            }         
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_isExcludedMaxTransactionAmount[from]) {         
                require(amount <= sellThreshold, "BRANDON: Transfer amount exceeds the sellThreshold.");         
                
                shouldSwap = true;         
            }         
        }         

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;         

        uint256 contractBalance = balanceOf(address(this));         
        bool canSwap = (contractBalance > _swapTokensAtAmount) && shouldSwap;         

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {         
            _swapping = true;         
            _swapBack(contractBalance);         
            _swapping = false;         
        }         

        _tokenTransfer(from, to, amount, takeFee);         
    }         

    function _approve(address owner, address spender, uint256 amount) internal {         
        require(owner != ZERO, "BRANDON: approve from the zero address");         
        require(spender != ZERO, "BRANDON: approve to the zero address");         

        _allowances[owner][spender] = amount;         
        emit Approval(owner, spender, amount);         
    }         

    function _spendAllowance(address owner, address spender, uint256 amount) internal {         
        uint256 currentAllowance = allowance(owner, spender);         
        if (currentAllowance != type(uint256).max) {         
            require(currentAllowance >= amount, "BRANDON: insufficient allowance");         
            unchecked {         
                _approve(owner, spender, currentAllowance - amount);         
            }         
        }         
    }         

    function _swapBack(uint256 contractBalance) internal {         
        if (contractBalance == 0 || _tokensForFee == 0) return;         

        if (contractBalance > _swapTokensAtAmount * 5) contractBalance = _swapTokensAtAmount * 5;         

        _swapTokensForTokens(contractBalance);          

        _receiver.withdraw();
        
        _tokensForFee = 0;         

        IERC20(USDC).transfer(feeCollector, IERC20(USDC).balanceOf(address(this)));
    }         

    function _swapTokensForTokens(uint256 tokenAmount) internal {         
        address[] memory path = new address[](2);         
        path[0] = address(this);         
        path[1] = USDC;         
        _approve(address(this), address(_uniswapV2Router), tokenAmount);         
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_receiver),
            block.timestamp
        );         
    }         

    function _removeFee() internal {         
        if (fee == 0) return;         
        _previousFee = fee;         
        fee = 0;         
    }         
    
    function _restoreFee() internal {         
        fee = _previousFee;         
    }         
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal {         
        if (!takeFee) _removeFee();         
        else amount = _takeFees(sender, amount);         

        _transferStandard(sender, recipient, amount);         
        
        if (!takeFee) _restoreFee();         
    }         

    function _transferStandard(address sender, address recipient, uint256 tAmount) internal {         
        _balances[sender] = _balances[sender].sub(tAmount);         
        _balances[recipient] = _balances[recipient].add(tAmount);         
        emit Transfer(sender, recipient, tAmount);         
    }         

    function _takeFees(address sender, uint256 amount) internal returns (uint256) {         
        if (fee > 0) {         
            uint256 fees = amount.mul(fee).div(1000);         
            _tokensForFee += fees * fee / fee;         

            if (fees > 0) _transferStandard(sender, address(this), fees);         

            amount -= fees;         
        }         

        return amount;         
    }         

    function usdcReceiverAddress() external view returns (address) {
        return address(_receiver);
    }
    
    function openTrading() public onlyOwner {         
        require(!tradingOpen,"BRANDON: Trading is already open");         
        IERC20(USDC).approve(address(_uniswapV2Router), IERC20(USDC).balanceOf(address(this)));         
        _uniswapV2Router.addLiquidity(address(this), USDC, balanceOf(address(this)), IERC20(USDC).balanceOf(address(this)), 0, 0, owner(), block.timestamp);         
        swapEnabled = true;               
        antiMEVEnabled = true;               
        tradingOpen = true;         
    }         

    function setBuyThreshold(uint256 _buyTreshold) public onlyOwner {         
        require(_buyTreshold >= (totalSupply().mul(1).div(1000)), "BRANDON: Max buy amount cannot be lower than 0.1% total supply.");         
        buyThreshold = _buyTreshold;         
    }         

    function setSellThreshold(uint256 _sellThreshold) public onlyOwner {         
        require(_sellThreshold >= (totalSupply().mul(1).div(1000)), "BRANDON: Max sell amount cannot be lower than 0.1% total supply.");         
        sellThreshold = _sellThreshold;         
    }         
    
    function setWalletThreshold(uint256 _walletThreshold) public onlyOwner {         
        require(_walletThreshold >= (totalSupply().mul(1).div(100)), "BRANDON: Max wallet amount cannot be lower than 1% total supply.");         
        walletThreshold = _walletThreshold;         
    }         
    
    function setSwapTokensAtAmount(uint256 _swapAmountThreshold) public onlyOwner {         
        require(_swapAmountThreshold >= (totalSupply().mul(1).div(100000)), "BRANDON: Swap amount cannot be lower than 0.001% total supply.");         
        require(_swapAmountThreshold <= (totalSupply().mul(5).div(1000)), "BRANDON: Swap amount cannot be higher than 0.5% total supply.");         
        _swapTokensAtAmount = _swapAmountThreshold;         
    }         

    function setSwapEnabled(bool onoff) public onlyOwner {         
        swapEnabled = onoff;         
    }         

    function setAntiMEVEnabled(bool onoff) public onlyOwner {         
        antiMEVEnabled = onoff;         
    }         

    function setFeeCollector(address feeCollectorAddy) public onlyOwner {         
        require(feeCollectorAddy != ZERO, "BRANDON: feeCollector address cannot be 0");         
        feeCollector = payable(feeCollectorAddy);         
        _isExcludedFromFees[feeCollectorAddy] = true;         
        _isExcludedMaxTransactionAmount[feeCollectorAddy] = true;         
    }         

    function excludeFromFees(address[] memory accounts, bool isEx) public onlyOwner {         
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;         
    }         
    
    function excludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {         
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;         
    }         

    function rescueETH() public onlyOwner {         
        bool success;         
        (success,) = address(msg.sender).call{value: address(this).balance}("");         
    }         

    function rescueTokens(address tokenAddy) public onlyOwner {         
        require(tokenAddy != address(this), "Cannot withdraw this token");         
        require(IERC20(tokenAddy).balanceOf(address(this)) > 0, "No tokens");         
        uint amount = IERC20(tokenAddy).balanceOf(address(this));         
        IERC20(tokenAddy).transfer(msg.sender, amount);         
    }         

    function removeThresholds() public onlyOwner {         
        buyThreshold = _totalSupply;         
        sellThreshold = _totalSupply;         
        walletThreshold = _totalSupply;         
    }         

    receive() external payable {
    }         
    fallback() external payable {
    }         

}