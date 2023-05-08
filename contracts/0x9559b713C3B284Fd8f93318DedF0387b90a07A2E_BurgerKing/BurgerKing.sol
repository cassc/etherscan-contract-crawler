/**
 *Submitted for verification at Etherscan.io on 2023-05-07
*/

// https://t.me/Burgerkingcommunity - There is only 1 king, and he ain't from england. 
// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;
 
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
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
 
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    constructor() {
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
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 
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
 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
 
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
 
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
 
    function factory() external pure returns (address);
 
    function WETH() external pure returns (address);
 
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
 
contract BurgerKing is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string constant private _name = "Burger King";
    string constant private _symbol = "BK";   
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_000_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;  
    uint256 private _taxFeeOnBuy = 5;  
    uint256 private _redisFeeOnSell = 0;  
    uint256 private _taxFeeOnSell = 15;
 
    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
 
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
 
    mapping(address => bool) public bots; 
    mapping(uint256 => uint256) swapBlock;
    address payable private _developmentAddress = payable(_msgSender()); 
    address payable private _marketingAddress;
 
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
 
    uint256 public _maxTxAmount = 25 * _tTotal / 1e3; 
    uint256 public _maxWalletSize = 25 * _tTotal / 1e3;
    uint256 _swapTokensAtAmount = 1 * _tTotal / 1e3;
    uint256 constant _maxSwapTokenAmount = 1 * _tTotal / 1e2;
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    event MaxWalletAmountUpdated(uint256 _maxWalletAmount);

    event SwapTokensAtAmountUpdated(uint256 _swapTokensAtAmount);

    event SwapEnabledUpdated(bool _swapEnabled);

    event MarketingWalletUpdated(address _marketingAddress);

    event DevelopmentWalletUpdated(address _developmentAddress);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() {
 
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        _isExcludedFromFee[address(this)] = true;

        bots[0x00003c85bF903e179f1224bc8aB2EA4Ed8000001] = true;
        bots[0x7E41300B7c78a805F225447823446A1A29bBF1e2] = true;
        bots[0xFAdEd000Cc97f8707E3A5598e5E1F7DA5DBD8186] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
    receive() external payable {}
 
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
        return _tTotal;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "TOKEN: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
 
    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
 
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
 
        _redisFee = 0;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
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
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero"); 

        if (from != _developmentAddress && to != _developmentAddress) {
            require(!bots[from] && !bots[to], "TOKEN: No bots allowed");
            require(tradingOpen, "TOKEN: Cannot send tokens until trading is enabled");
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
    
            uint256 contractTokenBalance = balanceOf(address(this));

            if(contractTokenBalance >= _maxSwapTokenAmount)
            {
                contractTokenBalance = _maxSwapTokenAmount;
            }

            if (from != uniswapV2Pair && canSwap(contractTokenBalance, amount) &&  !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;
 
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } 
        else {
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }           
        } 
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
        swapBlock[block.number]++;
    }

    function canSwap(uint256 contractTokenBalance, uint256 amount) internal view returns (bool) {
        return contractTokenBalance >= _swapTokensAtAmount && !inSwap && swapEnabled && 
            swapBlock[block.number] < 2 && amount >= _swapTokensAtAmount / 2;
    }
 
    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }
 
    function openTrading() public onlyOwner {
        require(!tradingOpen, "TOKEN: trading already open");
        tradingOpen = true;
    }
 
    function manualSwapback(uint256 percentToSwap) external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress, "TOKEN: Team restricted");
        uint256 tokensToSwap = percentToSwap * balanceOf(address(this)) / 100;
        swapTokensForEth(tokensToSwap);
    }
 
    function manualSend() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress, "TOKEN: Team restricted");
        require(address(this).balance > 0, "TOKEN: No eth to transfer");
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }
 
    function _transferStandard(
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
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    function _getValues(uint256 tAmount)
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
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }
 
    function _getRValues(
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
 
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
 
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    function setFees(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    function setBots(address[] calldata _bots, bool areBots) external onlyOwner {
        for(uint256 i = 0;i<_bots.length;i++){
            bots[_bots[i]] = areBots;
        }
    }
 
    //Set minimum tokens required to swap.
    function setSwapThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        require(swapTokensAtAmount <= _maxSwapTokenAmount && swapTokensAtAmount >= _tTotal / 1e3, "TOKEN: swapTokensAtAmount must be higher or equal to 0.1% totalSupply");
        _swapTokensAtAmount = swapTokensAtAmount;
        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }
 
    function toggleSwaps(bool _swapEnabled) public onlyOwner {
        require(swapEnabled != _swapEnabled, "TOKEN: swapEnabled assigned old value");
        swapEnabled = _swapEnabled;
        emit SwapEnabledUpdated(_swapEnabled);
    }

    function setMarketingWallet(address payable marketingAddress) external onlyOwner {
        require(marketingAddress != address(0), "TOKEN: cannot assign zero address as marketingAddress");
        _marketingAddress = marketingAddress;
        _isExcludedFromFee[_marketingAddress] = true;
        toggleSwaps(true);
        emit MarketingWalletUpdated(marketingAddress);
    }

    function setDevelopmentWallet(address payable developmentAddress) external onlyOwner {
        require(developmentAddress != address(0), "TOKEN: cannot assign zero address as developmentAddress");
        _developmentAddress = developmentAddress;
        _isExcludedFromFee[developmentAddress] = true;
        emit DevelopmentWalletUpdated(developmentAddress);
    }

    function removeLimits() external onlyOwner {
        setMaxTxnAmount(totalSupply());
        setMaxWalletSize(totalSupply());
    }
 
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        require(maxTxAmount >= ((totalSupply() * 1) / 100),"TOKEN: Cannot set maxTransactionAmount lower than 1%");
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(maxTxAmount);
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        require(maxWalletSize >= ((totalSupply() * 1) / 100),"TOKEN: Cannot set maxWalletAmount lower than 1%");
        _maxWalletSize = maxWalletSize;
        emit MaxWalletAmountUpdated(maxWalletSize);
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}