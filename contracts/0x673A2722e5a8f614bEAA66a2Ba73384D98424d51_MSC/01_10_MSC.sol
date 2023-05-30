/**

    /$$    /$$      /$$  /$$$$$$   /$$$$$$ 
  /$$$$$$ | $$$    /$$$ /$$__  $$ /$$__  $$
 /$$__  $$| $$$$  /$$$$| $$  \__/| $$  \__/
| $$  \__/| $$ $$/$$ $$|  $$$$$$ | $$      
|  $$$$$$ | $$  $$$| $$ \____  $$| $$      
 \____  $$| $$\  $ | $$ /$$  \ $$| $$    $$
 /$$  \ $$| $$ \/  | $$|  $$$$$$/|  $$$$$$/
|  $$$$$$/|__/     |__/ \______/  \______/ 
 \_  $$_/                                  
   \__/                                    
                                           
MultiStrategiesCapital: $MSC
The new Multi Strategies DaaS protocol on Ethereum

Website: https://multistrategies.capital
Telegram: https://t.me/MultiStrategiesCapital
Twitter: https://twitter.com/MultiSCapital
Contact us: [email protected]
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract MSC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;

    address payable public _fundWalletAddress = payable(0x958aE4d07aB18e5b87465Db3f9f89874E00D2dE1);
    address payable public _marketingWalletAddress = payable(0x86b826403877CC10dCF147fa491db187168a2bd2);
    address payable public _liquidityWalletAddress = payable(0x3699b64a6D0933722372fe1b637EFF0b652DEa4d);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL = 3000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % TOTAL));
    uint256 private _tFeeTotal;
    uint256 public _maxTxAmount = 1 * 10**6 * 10**9;
    uint256 private _minimumTokensBeforeSwap = 1 * 10**6 * 10**9;

    string private constant NAME = "MultiStrategiesCapital";
    string private constant SYMBOL = "MSC";
    uint8 private constant DECIMALS = 9;
    uint8 private _fundAllocation = 27;
    uint8 private _liquidityAllocation = 27;
    uint8 private _marketingAllocation = 45;
    uint8 public _taxFee = 1;
    uint8 public _projectFee = 11;
    uint8 private _previousTaxFee = _taxFee;
    uint8 private _previousProjectFee = _projectFee;
    bool inSwap = false;
    bool public swapEnabled = false;

    IUniswapV2Router02 public immutable _uniswapV2Router;
    mapping(address => bool) private _isUniswapPair;

    event SwapEnabled(bool enabled);
    event AddUniswapV2Pair(address pairAddress);
    event RemoveUniswapV2Pair(address pairAddress);
    event WalletAddressUpdated(string name, address walletAddress);
    event FeeUpdated(string name, uint8 value);
    event Share(address sender, uint256 amount);
    event ExcludeAccount(address account);
    event IncludeAccount(address account);
    event ExcludeAccountFromFee(address account, bool isExcluded);
    event MaxTxAmountUpdated(uint256 amount);
    event MinimumTokensBeforeSwapUpdated(uint256 amount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_fundWalletAddress] = true;
        _isExcludedFromFee[_marketingWalletAddress] = true;
        _isExcludedFromFee[_liquidityWalletAddress] = true;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludeFromFee(address account, bool excluded) external onlyOwner {
        _isExcludedFromFee[account] = excluded;
        emit ExcludeAccountFromFee(account, excluded);
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function share(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        emit Share(sender, rAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= TOTAL, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, "We can not exclude Uniswap router.");
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeAccount(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit IncludeAccount(account);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _projectFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousProjectFee = _projectFee;

        _taxFee = 0;
        _projectFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _projectFee = _previousProjectFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwap && swapEnabled && contractTokenBalance >= _minimumTokensBeforeSwap && _isUniswapPair[recipient]) {
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToTeam(contractETHBalance);
            }
        }

        bool takeFee = false;
        if (
            (_isUniswapPair[recipient] || _isUniswapPair[sender]) &&
            !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
        ) {
            takeFee = true;
        }

        tokenTransfer(sender, recipient, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToTeam(uint256 amount) private {
        _fundWalletAddress.call{value: amount.mul(_fundAllocation).div(100)}("");
        _marketingWalletAddress.call{value: amount.mul(_marketingAllocation).div(100)}("");
        _liquidityWalletAddress.call{value: amount.mul(_liquidityAllocation).div(100)}("");
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToTeam(contractETHBalance);
    }

    function setSwapEnabled(bool enabled) public onlyOwner {
        swapEnabled = enabled;
        emit SwapEnabled(enabled);
    }

    function tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            transferBothExcluded(sender, recipient, amount);
        } else {
            transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeam(tTeam);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeam(tTeam);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeam(tTeam);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeam(tTeam);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function takeTeam(uint256 tTeam) private {
        uint256 currentRate = getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
        if (_isExcluded[address(this)]) _tOwned[address(this)] = _tOwned[address(this)].add(tTeam);
    }

    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = getTValues(tAmount, _taxFee, _projectFee);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function getTValues(
        uint256 tAmount,
        uint8 taxFee,
        uint8 projectFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(projectFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = TOTAL;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, TOTAL);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(TOTAL)) return (_rTotal, TOTAL);
        return (rSupply, tSupply);
    }

    function setTaxFee(uint8 taxFee) external onlyOwner {
        require(taxFee <= 6, "taxFee should be in 0 - 6");
        _taxFee = taxFee;
        emit FeeUpdated("tax", taxFee);
    }

    function setProjectFee(uint8 projectFee) external onlyOwner {
        require(projectFee <= 12, "projectFee should be in 0 - 12");
        _projectFee = projectFee;
        emit FeeUpdated("project", projectFee);
    }

    function setFundWallet(address payable fundWalletAddress) external onlyOwner {
        require(fundWalletAddress != address(0), "address can bot be zero address");
        _fundWalletAddress = fundWalletAddress;
        emit WalletAddressUpdated("fund", fundWalletAddress);
    }

    function setMarketingWallet(address payable marketingWalletAddress) external onlyOwner {
        require(marketingWalletAddress != address(0), "address can bot be zero address");
        _marketingWalletAddress = marketingWalletAddress;
        emit WalletAddressUpdated("marketing", marketingWalletAddress);
    }

    function setLiquidityWallet(address payable liquidityWalletAddress) external onlyOwner {
        require(liquidityWalletAddress != address(0), "address can bot be zero address");
        _liquidityWalletAddress = liquidityWalletAddress;
        emit WalletAddressUpdated("liquidity", liquidityWalletAddress);
    }

    function updateAllocations(
        uint8 marketingAllocation,
        uint8 fundAllocation,
        uint8 liquidityAllocation
    ) external onlyOwner {
        require(
            marketingAllocation.add(fundAllocation).add(liquidityAllocation) <= 100,
            "Allocation could't be more than 100%"
        );
        _marketingAllocation = marketingAllocation;
        _fundAllocation = fundAllocation;
        _liquidityAllocation = liquidityAllocation;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(maxTxAmount >= 1 * 10**6 * 10**9, "maxTxAmount should be greater or equal 1 * 10**6 * 10**9");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(maxTxAmount);
    }

    function isUniswapPair(address _pair) external view returns (bool) {
        return _isUniswapPair[_pair];
    }

    function addUniswapPair(address pair) public onlyOwner {
        _isUniswapPair[pair] = true;
        emit AddUniswapV2Pair(pair);
    }

    function removeUniswapPair(address pair) public onlyOwner {
        _isUniswapPair[pair] = false;
        emit RemoveUniswapV2Pair(pair);
    }

    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function setMinimumTokensBeforeSwap(uint256 minimumTokensBeforeSwap) external onlyOwner {
        _minimumTokensBeforeSwap = minimumTokensBeforeSwap;
        emit MinimumTokensBeforeSwapUpdated(minimumTokensBeforeSwap);
    }

    function afterLiquidityAdded(address pair) external onlyOwner {
        addUniswapPair(pair);
        excludeAccount(pair);
        setSwapEnabled(true);
    }
}