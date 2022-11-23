pragma solidity 0.8.16;
// SPDX-License-Identifier: Unlicensed
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";
import "./Social.sol";
import "./InfoToken.sol";
import "./Blacklistable.sol";
import "./Fee.sol";

contract DeflaxToken is Context, IERC20, Ownable, Blacklistable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    
    uint256 public _taxFee = 10;
    uint256 private _previousTaxFee = _taxFee;
    address public _feeWallet;
    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _burnFee = 10;
    uint256 private _previousBurnFee = _burnFee;
    uint256 public _charityFee = 70;
    address public charityWallet;
    uint256 private _previouscharityFee = _charityFee;

    IPancakeRouter02 public  uniswapV2Router;
    address public  uniswapV2Pair;
    address private _tokenLiquidity;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private numTokensSellToAddToLiquidity = 1000 * 10**_decimals;

    Social private social;
    mapping (address => bool) internal _blacklist;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (InfoToken memory _infoToken, Social memory _social, Fee memory _devFee, Fee memory _marketingFee, 
        uint256 burnAmount_, address pancakeRouterAddress_, address tokenToLiquidity_, 
         uint256 liquidityFee_, uint256 burnFee_, 
        address _creator) {
        _name = _infoToken.name;
        _symbol = _infoToken.symbol;
        social = _social;
        _taxFee = _devFee.percentage;
        _liquidityFee = liquidityFee_;
        _burnFee = burnFee_;
        _charityFee = _marketingFee.percentage;
        _feeWallet = _devFee.wallet;
        charityWallet = _marketingFee.wallet;
        uint256 _burnWithDecimals = burnAmount_.mul(10**_decimals);
        uint256 _totalWithDecimals = _infoToken.totalSupply.mul(10**_decimals);
        _totalSupply = _totalWithDecimals;
        _balances[_creator] = _totalWithDecimals.sub(_burnWithDecimals);
        _balances[address(0)] = _burnWithDecimals;
        _tokenLiquidity = tokenToLiquidity_;
        IPancakeRouter02 _uniswapV2Router = IPancakeRouter02(pancakeRouterAddress_);
        uniswapV2Pair = IPancakeFactory(_uniswapV2Router.factory())
            .createPair(address(this), tokenToLiquidity_);
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[_creator] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), address(0), _burnWithDecimals);
        emit Transfer(address(0), _creator, _totalWithDecimals.sub(_burnWithDecimals));
    }
    function addRobotToBlacklist(address _robotAddress) external onlyOwner() {
        _blacklist[_robotAddress] = true;
    }
    function removeRobotFromBlacklist(address _robotAddress) external onlyOwner() {
        _blacklist[_robotAddress] = false;
    }
    function inRobotBlacklist(address _addressToVerify) external view returns (bool) {
        return _blacklist[_addressToVerify];
    }
    function site() public view returns (string memory) {
        return social.site;
    }
    function telegram() public view returns (string memory) {
        return social.telegram;
    }
    function twitter() public view returns (string memory) {
        return social.twitter;
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
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    function _getValues(uint256 amount) private view returns (uint256, uint256, uint256) {
        uint256 fee = calculateTaxFee(amount);
        uint256 liquidityFee = calculateLiquidityFee(amount);
        uint256 transferAmount = amount.sub(fee).sub(liquidityFee);
        return (transferAmount, fee, liquidityFee);
    }
    function _takeLiquidity(uint256 amountToAdd) private {
        _balances[address(this)] = _balances[address(this)] + amountToAdd;
    }
    function _takeFee(uint256 amountToAdd) private {
        _balances[_feeWallet] = _balances[_feeWallet] + amountToAdd;
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**3
        );
    }
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _charityFee==0 && _burnFee==0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        _previouscharityFee = _charityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
        _burnFee = 0;
    }
    function restoreAllFee() private {
       _taxFee = _previousTaxFee;
       _liquidityFee = _previousLiquidityFee;
       _burnFee = _previousBurnFee;
       _charityFee = _previouscharityFee;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_blacklist[from], "BEP20: Sender is blacklisted");
        require(!_blacklist[to], "BEP20: Recipient is blacklisted");
        uint256 contractTokenBalance = balanceOf(address(this));        
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }
        _tokenTransfer(from,to,amount);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        if(_tokenLiquidity == uniswapV2Router.WETH()) {
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half);
            uint256 newBalance = address(this).balance.sub(initialBalance);
            addLiquidityEth(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        } else {
            uint256 initialBalance = IERC20(_tokenLiquidity).balanceOf(address(this));
            swapTokensForTokens(half);
            uint256 newBalance = IERC20(_tokenLiquidity).balanceOf(address(this)).sub(initialBalance);
            addLiquidityToken(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        } 
    }
    function swapTokensForTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _tokenLiquidity;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function swapTokensForEth(uint256 tokenAmount) private {
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
    function addLiquidityToken(uint256 tokenAmount, uint256 liquidityAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidity(
            address(this),
            _tokenLiquidity,
            tokenAmount,
            liquidityAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function addLiquidityEth(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function burn(uint256 amount) public {
        removeAllFee();
        _transferStandard(_msgSender(),address(0), amount);
        restoreAllFee();
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            removeAllFee();
        }
        uint256 burnAmt = amount.mul(_burnFee).div(1000);
        uint256 charityAmt = amount.mul(_charityFee).div(1000);
        uint256 devAmt = amount.mul(_taxFee).div(1000);
        uint256 liquidityAmt = amount.mul(_liquidityFee).div(1000);
        uint256 _amountFinal = amount.sub(burnAmt).sub(charityAmt).sub(devAmt).sub(liquidityAmt);
        _transferStandard(sender, recipient, _amountFinal);
        _taxFee = 0;
        _liquidityFee = 0;
        if(burnAmt > 0)
            _transferStandard(sender, address(0), burnAmt);
        if(charityAmt > 0)
            _transferStandard(sender, charityWallet, charityAmt);
        if(liquidityAmt > 0)
            _takeLiquidity(liquidityAmt);
        if(devAmt > 0)
            _takeFee(devAmt);
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }
    function _transferStandard(address sender, address recipient, uint256 amount) private {
        //(uint256 transferAmount, uint256 fee, uint256 liquidityFee) = _getValues(amount);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function disableAllFees() external onlyOwner() {
        _taxFee = 0;
        _previousTaxFee = _taxFee;
        _liquidityFee = 0;
        _previousLiquidityFee = _liquidityFee;
        _burnFee = 0;
        _previousBurnFee = _taxFee;
        _charityFee = 0;
        _previouscharityFee = _charityFee;
        inSwapAndLiquify = false;
        emit SwapAndLiquifyEnabledUpdated(false);
    }
    function setCharityWallet(address newWallet) external onlyOwner() {
        charityWallet = newWallet;
    }
    function setTaxWallet(address newWallet) external onlyOwner() {
        _feeWallet = newWallet;
    }
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    function setChartityFeePercent(uint256 charityFee) external onlyOwner() {
        _charityFee = charityFee;
    }
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        _burnFee = burnFee;
    }
    function setRouterAddress(address newRouter) public onlyOwner() {
        IPancakeRouter02 _newPancakeRouter = IPancakeRouter02(newRouter);
        uniswapV2Pair = IPancakeFactory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function setAmountMinToTransferLiquidity(uint256 amount) public onlyOwner{
        numTokensSellToAddToLiquidity = amount * 10**decimals();
    }
}