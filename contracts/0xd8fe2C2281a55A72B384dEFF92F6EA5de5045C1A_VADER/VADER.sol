/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

// Let's help Lord Vader finish his Death Star project
// Death Star funding wallet address (our burn address): 0x0000000000000000000000000000000DeAtHsTaR
// 0 tax after 60000 block
// 6.9% is reserved for providing liquidity for CEX listings, seeding other DEXs, or bridges.
// twitter: @vader_pr

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    )
        external payable;
}

interface IUniswapV2Pair {
    function sync() external;
}

contract VADER is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxWallet;

    string private constant _name = "VADER";
    string private constant _symbol = "VADER";
    uint256 private _feeRateVADER = 50;
    uint8 private constant _decimals = 18;
    uint256 private _tTotalVADER =  10000000  * 10**_decimals;
    uint256 private _mWalletVADER = 200000  * 10**_decimals;

    address payable public marketingAddress = payable(0x78E7BcE7a5946FE719906848dd55c19Dedac8e1c);

    struct BuyFees{
        uint256 marketing;
    }

    struct SellFees{
        uint256 marketing;
    }

    BuyFees public buyFee;
    SellFees public sellFee;

    uint256 private marketingFee;

    bool private swapping;

    bool _warmUp;
    mapping(address => bool) public _warmuplist;

    uint256 private _taxTill;

    constructor () {
        buyFee.marketing = 30;

        sellFee.marketing = 30;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0x00)] = true;
        _isExcludedFromFee[address(0xdead)] = true;

        _isExcludedFromMaxWallet[msg.sender] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;
        _isExcludedFromMaxWallet[marketingAddress] = true;

        _warmUp = true;

        _taxTill = block.number + 60000;

        balances[_msgSender()] = _tTotalVADER;
        emit Transfer(address(0), _msgSender(), _tTotalVADER);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotalVADER;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[address(account)] = excluded;
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxWallet[address(account)] = excluded;
    }

    function setMarketingFee(uint256 amountBuy, uint256 amountSell) public onlyOwner {
        buyFee.marketing = amountBuy;
        sellFee.marketing = amountSell;
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner {
        marketingAddress = newMarketingAddress;
    }

    function getMarketingBuyFee() public view returns (uint256) {
        return buyFee.marketing;
    }

    function getMarketingSellFee() public view returns (uint256) {
        return sellFee.marketing;
    }

    receive() external payable {}

    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 marketingFeeTokens = amount * buyFee.marketing / 100;

        balances[address(this)] += marketingFeeTokens;
        emit Transfer (from, address(this), marketingFeeTokens);
        return (amount -marketingFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 marketingFeeTokens = amount * sellFee.marketing / 100;

        balances[address(this)] += marketingFeeTokens;
        emit Transfer (from, address(this), marketingFeeTokens );
        return (amount -marketingFeeTokens);
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxWallet(address account) public view returns(bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function setFeeRate(uint256 maxFee) external onlyOwner() {
        _feeRateVADER = maxFee;
    }

    function disableWarmUp() external onlyOwner() {
        require(_warmUp == true, "warmUp function already disabled");
        _warmUp = false;
        _taxTill = block.number + 60000;
    }

    function setZeroFees() external {
        uint256 currentBlock = block.number;
        require(_taxTill < currentBlock, "please try again later");
        buyFee.marketing = 0;
        sellFee.marketing = 0;
    }

    function getTaxTill() public view returns(uint256) {
        return _taxTill;
    }

    function setWarmuplist(address account, bool value) external onlyOwner() {
        _warmuplist[account] = value;
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
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner() && !_isExcludedFromMaxWallet[to]){
            require(balanceOf(to).add(amount) <= _mWalletVADER, "Max Balance is reached.");
        }

        balances[from] -= amount;
        uint256 transferAmount = amount;

        bool takeFee;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && buyFee.marketing > 0 && sellFee.marketing > 0){
            takeFee = true;
        }

        if(_warmUp == true && from != owner()){
            require(_warmuplist[to], "not allowed yet");
            takeFee = false;
        }

        if(takeFee){
            if(to != uniswapV2Pair){
                transferAmount = takeBuyFees(amount, to);
            } else {
                transferAmount = takeSellFees(amount, from);
                uint256 swapTokenAtAmount = balanceOf(uniswapV2Pair).mul(_feeRateVADER).div(1000);

                if (balanceOf(address(this)) >= swapTokenAtAmount && !swapping) {
                    swapping = true;
                    swapBack(swapTokenAtAmount);
                    swapping = false;
                }

                if (!swapping) {
                    swapping = true;
                    swapBack(balanceOf(address(this)));
                    swapping = false;
                }
            }
        }

        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function manualSwapBack() external onlyOwner() {
      uint256 amount = balanceOf(address(this));
      swapTokensForEth(amount);
      payable(marketingAddress).transfer(address(this).balance);
    }

    function swapBack(uint256 amount) private {
        swapTokensForEth(amount);
        payable(marketingAddress).transfer(address(this).balance);
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
}