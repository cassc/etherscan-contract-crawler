/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

/**
 *Submitted for verification at Etherscan.io on 2023-09-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;
 
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
        require(_owner == _msgSender(), "E0");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "E1");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
 
}
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "E2");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "E3");
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
        require(c / a == b, "E4");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "E5");
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
 
contract SailBot is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    string private constant _name = "STEST";
    string private constant _symbol = "STEST";
    uint8 private constant _decimals = 18;
 

    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant _totalSupply = 10000000 * 10**18;
    uint256 private _feeTotal;
    uint256 private _feeOnBuy = 5;  
    uint256 private _feeOnSell = 5;
 
    //Original Fee
    uint256 private _fee = _feeOnSell;
 
    uint256 private _previousFee = _fee;
 
    mapping(address => bool) public bots; 
    mapping (address => uint256) public _buyMap;
    
    address payable private _marketingAddress = payable(0xf1898720c0718b63D4feB452355Ee0E3EE82c4cE);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 public _maxTxAmount = 150000 * 10**18; 
    uint256 public _maxWalletSize = 150000 * 10**18; 
    uint256 public _swapTokensAtAmount = 100 * 10**18;
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() {
        _balances[owner()] = _totalSupply;
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // uniswapV2Router = _uniswapV2Router;
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingAddress] = true;
 
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function initUniSwap() public onlyOwner {
        if (uniswapV2Pair != address(0)) {
            return;
        }
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        address tmp = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        if (tmp != address(0)) {
            uniswapV2Pair = tmp;
        } else {
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        }
        
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
                "E6"
            )
        );
        return true;
    }
 

 
    function removeAllFee() private {
        if (_fee == 0) return;
 
        _previousFee = _fee;
 
        _fee = 0;
    }
 
    function restoreAllFee() private {
        _fee = _previousFee;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "E7");
        require(spender != address(0), "E8");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "E9");
        require(to != address(0), "E10");
        require(amount > 0, "E11");
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "E12");
            }
            require(amount <= _maxTxAmount, "E13");
            require(!bots[from] && !bots[to], "E14");
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "E15");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee();
                }
            }
        }
 
        bool takeFee = true;
 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
 
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _fee = _feeOnBuy;
            }
 
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _fee = _feeOnSell;
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
    }
 
    function sendETHToFee() private {
        bool success;
        (success, ) = address(_marketingAddress).call{
            value: address(this).balance
        }("");
    }
 
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
 
    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee();
        }
    }
 
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
 
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function isBot(address addr) public view returns (bool) {
        return bots[addr];
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
        uint256 amount
    ) private {

        uint256 fee = amount.mul(_fee).div(100);
        uint256 transferAmount = amount.sub(fee);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        if (fee > 0) {
            _feeTotal = _feeTotal.add(fee);
            _balances[address(this)] =  _balances[address(this)].add(fee);
        }
       
        
        emit Transfer(sender, recipient, transferAmount);
    }
 
 
    receive() external payable {}
 
    function setFee(uint256 feeOnBuy, uint256 feeOnSell) public onlyOwner {
        require(feeOnBuy >= 0 && feeOnBuy <= 20, "E16");
        require(feeOnSell >= 0 && feeOnSell <= 20, "E17");

        _feeOnBuy = feeOnBuy;
        _feeOnSell = feeOnSell;
    }
 
    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 

    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
           _maxTxAmount = maxTxAmount;
        
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }

    function isExcludedFromFee(address addr) public view returns (bool) {
        return _isExcludedFromFee[addr];
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint i = 0; i < addresses.length; i++) {
            _transfer(from, addresses[i], amounts[i] * (10**18));
        }
    }

    function getInfo() public view returns(bool[2] memory, uint256[8] memory, address) {
        bool[2] memory bargs;
        uint256[8] memory uargs;
        bargs[0] = tradingOpen;
        bargs[1] = swapEnabled;
        uargs[0] = _feeOnBuy;
        uargs[1] = _feeOnSell;
        uargs[2] = _maxTxAmount;
        uargs[3] = _maxWalletSize;
        uargs[4] = _feeTotal;
        uargs[5] = _swapTokensAtAmount;

        uint256 ethBalance = address(this).balance;
        uargs[6] = ethBalance;
        uint256 contractTokenBalance = balanceOf(address(this));
        uargs[7] = contractTokenBalance;

        
        return (bargs,uargs,_marketingAddress);
    }

     function setMarketAddr(address payable addr) public onlyOwner {
        if (_marketingAddress == addr) {
            return;
        }

        _marketingAddress = addr;
        _isExcludedFromFee[_marketingAddress] = true;
    }

}