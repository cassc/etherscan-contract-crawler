/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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
        return c;
    }
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

contract Token is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    Middleman public _middleman;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _blockList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;

    uint256 public _buyMiddlemanFee = 20; //购买CRC
    uint256 public _buyLPDividendFee = 30;//LP分红

    uint256 public _sellMiddlemanFee = 20;//购买CRC
    uint256 public _sellLPDividendFee = 30;//LP分红

    uint256 public startTradeBlock;
    uint256 public swapAt;
    uint256 public _maxWalletToken;

    address public _mainPair;
    address public _lastSeller = address(0);


    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (){
        _name = "Angel";
        _symbol = "Angel";
        _decimals = 18;

        _usdt = 0x55d398326f99059fF775485246999027B3197955; 

        ISwapRouter swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        IERC20(_usdt).approve(address(swapRouter), MAX);

 
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), _usdt);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        _tTotal = 1980 * 10 ** _decimals;
        _maxWalletToken = _tTotal * 10**_decimals;

        swapAt = 10000000000000000000;

        _middleman = new Middleman();

        
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        _feeWhiteList[address(_middleman)] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[address(0x000000000000000000000000000000000000dEaD)] = true;

        _tokenDistributor = new TokenDistributor(_usdt);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(to != address(0), "Cannot transfer to the zero address");
        require(balanceOf(from) >= amount, "balanceNotEnough");
        require(!_blockList[from] && !_blockList[to], "bot address");

        if (_swapPairList[to]){
            tryAddHolder(from);
        }

        if (_feeWhiteList[from] || _feeWhiteList[to] || inSwap){
            _basicTransfer(from, to, amount);
            return;
        }

        require(0 < startTradeBlock, "!Trading");
        if (!_swapPairList[to]){ //todo:需要验证
            require((balanceOf(to) + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        // if (block.number < startTradeBlock + 3) {
        //     _basicTransfer(from, treasuryAddress, amount * 99 / 100);
        //     _basicTransfer(from, to, amount * 1 / 100);
        //     return;
        // }

        //sell trigger swap
        if (_swapPairList[to]){
            swapTokenForFund();
        }

        _feeTransfer(from,to,amount);

        if (from != address(this)) {
            processReward(500000);
        }
    }

    // function _funTransfer(
    //     address sender,
    //     address recipient,
    //     uint256 tAmount
    // ) private {
    //     _balances[sender] = _balances[sender] - tAmount;
    //     uint256 feeAmount = tAmount * 99 / 100;
    //     _basicTransfer(sender, recipient, feeAmount);
    //     _basicTransfer(sender, recipient, tAmount - feeAmount);
    // }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _feeTransfer(address from, address to, uint256 amount) private {
        uint fee = 0;
        uint destoryFee = 0;
        //if buy
        if (_swapPairList[from]){
            fee = _buyLPDividendFee + _buyMiddlemanFee;

        }else{  //sell or transfer
            fee = _sellLPDividendFee + _sellMiddlemanFee;
        }

        if (destoryFee > 0){
            _basicTransfer(from, address(0xdead), amount * destoryFee / 1000);
        }

        if (fee > 0){
            _basicTransfer(from, address(this), amount * fee / 1000);
        }
        
        _basicTransfer(from, to, amount * (1000 - fee - destoryFee) / 1000);
    }

    function swapTokenForFund() private lockTheSwap {
        uint256 totalFee = _buyLPDividendFee + _buyMiddlemanFee + _sellLPDividendFee  + _sellMiddlemanFee;
        uint256 swapAmount = balanceOf(address(this));
        if (swapAmount > swapAt) {
            swapAmount = swapAt;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );

        IERC20 USDT = IERC20(_usdt);
        uint256 fistBalance = USDT.balanceOf(address(_tokenDistributor));
        uint256 middlemanAmount = fistBalance * (_buyMiddlemanFee + _sellMiddlemanFee) / totalFee;


        USDT.transferFrom(address(_tokenDistributor), address(_middleman), middlemanAmount);
        USDT.transferFrom(address(_tokenDistributor), address(this), fistBalance - middlemanAmount);

        _middleman.Swap();
    }


    function setBuyLPDividendFee(uint256 dividendFee) external onlyOwner {
        _buyLPDividendFee = dividendFee;
    }

    function setSellLPDividendFee(uint256 dividendFee) external onlyOwner {
        _sellLPDividendFee = dividendFee;
    }

    function setSellMiddlemanFee(uint256 newFee) external onlyOwner {
        _sellMiddlemanFee = newFee;
    }
    function setBuyMiddlemanFee(uint256 lpFee) external onlyOwner {
        _buyMiddlemanFee = lpFee;
    }

    function startTrade() external onlyOwner {
        if(0 == startTradeBlock){
            startTradeBlock = block.number;
        }
    }

    function setFeeWhiteList(address[] calldata addList, bool enable) external onlyOwner {
        for(uint256 i = 0; i < addList.length; i++) {
            _feeWhiteList[addList[i]] = enable;
        }
    }
    
    function setBlockList(address[] calldata addList, bool enable) public onlyOwner {
        for(uint256 i = 0; i < addList.length; i++) {
            _blockList[addList[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function tryAddHolder(address _currentSeller) internal {
        if ( _lastSeller!=address(0) && IERC20(_mainPair).balanceOf(_lastSeller) > 0 ){
            addHolder(_lastSeller);
        }
        _lastSeller = _currentSeller;
    }

    receive() external payable {}

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    function addHolder(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 private currentIndex;
    uint256 private progressRewardBlock;
    function processReward(uint256 gas) internal {
        if (progressRewardBlock + 30 > block.number) {
            return;
        }

        if (IERC20(_usdt).balanceOf(address(this)) < 1 * 10 ** IERC20(_usdt).decimals()) {
            return;
        }

        _processReward(gas);

        progressRewardBlock = block.number;
    }

    function processRewardWithoutCondition(uint256 gas) public {
        _processReward(gas);
    }

    function _processReward(uint256 gas) internal {
        IERC20 USDT = IERC20(_usdt);

        uint256 balance = USDT.balanceOf(address(this));
        if (balance == 0) {
            return;
        }

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    USDT.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }
    function setMaxWallet(uint256 amount) external onlyOwner() {
        _maxWalletToken = amount*10**_decimals;
    }
    function setMiddleman(address payable addr) external onlyOwner(){
        _middleman = Middleman(addr);
    }
}

//中间商 用于购买guiwang
contract Middleman {
    using SafeMath for uint256;

    uint256 public swapAt =  1 * 10 ** 18; //10 usdt
    address public _usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public outToken=0x13AF7Bd0304954894a72876fBA0005272EA4Eb9b; //guiwang
    address public tokenReciever = 0x000000000000000000000000000000000000dEaD; //guiwang 接收人

    ISwapRouter public swapRouter=ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    receive()external payable{}

    fallback() external payable {}

    constructor(){
        IERC20(_usdt).approve(address(swapRouter),2**256 - 1);
    }

    function Swap() public{
        uint256 swapAmount =IERC20(_usdt).balanceOf(address(this));
        if (swapAmount <= swapAt) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = outToken;

        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount,0,path,tokenReciever,block.timestamp);
        //try swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount,0,path,tokenReciever,block.timestamp) {} catch {}
    }    
}