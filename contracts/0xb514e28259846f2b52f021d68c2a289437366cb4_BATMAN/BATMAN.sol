/**
 *Submitted for verification at Etherscan.io on 2023-06-17
*/

// SPDX-License-Identifier: No

pragma solidity = 0.8.19;

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

//--- Contract v3 ---//
contract BATMAN is Context, Ownable, IERC20 {

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
    mapping (address => bool) private liquidityAdd;
    mapping (address => bool) private isLpPair;
   
    mapping (address => uint256) private balance;

    uint256 constant public _totalSupply = 100_000_000_000_000 * 10**9;
    uint256 constant public swapThreshold = _totalSupply / 7_000;
    uint256 private buyfee = 300;
    uint256 private sellfee = 300;
    uint256 constant private transferfee = 0;
    uint256 constant public fee_denominator = 1_000;

    function viewTaxes() external view returns(uint256 buy, uint256 sell, uint256 transferf) {
        return(100 * buyfee / fee_denominator, 100 * sellfee / fee_denominator, 100 * transferfee / fee_denominator);
    }
    
    bool private canSwapFees = true;
    address payable private marketingAddress = payable(0x207d2b73d0cf3678dcCb9944A55298Eb64562e12); 


//--- v3 Allocations  ---//
    uint256 private buyAllocation = 100;
    uint256 private sellAllocation = 0;
    uint256 private liquidityAllocation = 0;


    IRouter02 public swapRouter;
    string constant private _name = "BATMAN";
    string constant private _symbol = "BATMAN";
    uint8 constant private _decimals = 9;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
 
    bool private inSwap;

        modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    event _toggleCanSwapFees(bool enabled);
    event _changePair(address newLpPair);
    event _changeThreshold(uint256 newThreshold);
    event _changeWallets(address newBuy);
    event _changeFees(uint256 buy, uint256 sell);
    event SwapAndLiquify();


    constructor () {
        _noFee[msg.sender] = true;

        if (block.chainid == 56) {
            swapRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            swapRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (block.chainid == 42161) {
            swapRouter = IRouter02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        } else if (block.chainid == 5) {
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert("Chain not valid");
        }
        liquidityAdd[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        require(buyAllocation + sellAllocation + liquidityAllocation == 100,"Freddy: Must equals to 100%");

        lpPair = IFactoryV2(swapRouter.factory()).createPair(swapRouter.WETH(), address(this));
        isLpPair[lpPair] = true;
        _approve(msg.sender, address(swapRouter), type(uint256).max);
        _approve(address(this), address(swapRouter), type(uint256).max);


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

    function setNoFeeWallet(address account, bool enabled) public onlyOwner {
        _noFee[account] = enabled;
    }

    function isLimitedAddress(address ins, address out) internal view returns (bool) {

        bool isLimited = ins != owner()
            && out != owner() && tx.origin != owner() // any transaction with no direct interaction from owner will be accepted
            && msg.sender != owner()
            && !liquidityAdd[ins]  && !liquidityAdd[out] && out != DEAD && out != address(0) && out != address(this);
            return isLimited;
    }

    function is_buy(address ins, address out) internal view returns (bool) {
        bool _is_buy = !isLpPair[out] && isLpPair[ins];
        return _is_buy;
    }

    function is_sell(address ins, address out) internal view returns (bool) { 
        bool _is_sell = isLpPair[out] && !isLpPair[ins];
        return _is_sell;
    }

    function is_transfer(address ins, address out) internal view returns (bool) { 
        bool _is_transfer = !isLpPair[out] && !isLpPair[ins];
        return _is_transfer;
    }

    function canSwap() internal view returns (bool) {
        bool canswap = canSwapFees;
        return canswap;
    }


    function changeLpPair(address newPair) external onlyOwner {
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

        if(is_sell(from, to) &&  !inSwap && canSwap()) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >= swapThreshold) { 
                if(buyAllocation > 0 || sellAllocation > 0) internalSwap((contractTokenBalance * (buyAllocation + sellAllocation)) / 100);
                if(liquidityAllocation > 0) {swapAndLiquify(contractTokenBalance * liquidityAllocation / 100);}
            }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }
        balance[from] -= amount; 
        uint256 amountAfterFee = (takeFee) ? takeTaxes(from, is_buy(from, to), is_sell(from, to), amount) : amount;
        balance[to] += amountAfterFee; 
        emit Transfer(from, to, amountAfterFee);

        return true;
    }


    function changeWallets(address newBuy) external onlyOwner {
        require(newBuy != address(0),"batman: Address Zero");
        marketingAddress = payable(newBuy);
        emit _changeWallets(newBuy);
    }

    function setBuyFee(uint256 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= fee_denominator, "Invalid fee");
        buyfee = newFee;
        emit _changeFees(buyfee, sellfee);
    }

    function setSellFee(uint256 newFee) external onlyOwner {
        require(newFee >= 0 && newFee <= fee_denominator, "Invalid fee");
        sellfee = newFee;
        emit _changeFees(buyfee, sellfee);
    }

    function takeTaxes(address from, bool isbuy, bool issell, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isbuy)  fee = buyfee;  else if (issell)  fee = sellfee;  else  fee = transferfee; 
        if (fee == 0)  return amount; 
        uint256 feeAmount = amount * fee / fee_denominator;
        if (feeAmount > 0) {

            balance[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
            
        }
        return amount - feeAmount;
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal inSwapFlag {
        uint256 firstmath = contractTokenBalance / 2;
        uint256 secondMath = contractTokenBalance - firstmath;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        if (_allowances[address(this)][address(swapRouter)] != type(uint256).max) {
            _allowances[address(this)][address(swapRouter)] = type(uint256).max;
        }

        try swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            firstmath,
            0, 
            path,
            address(this),
            block.timestamp) {} catch {return;}
        
        uint256 newBalance = address(this).balance - initialBalance;

        try swapRouter.addLiquidityETH{value: newBalance}(
            address(this),
            secondMath,
            0,
            0,
            DEAD,
            block.timestamp
        ){} catch {return;}

        emit SwapAndLiquify();
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

        if(address(this).balance > 0) (success,) = marketingAddress.call{value: address(this).balance, gas: 35000}("");
    }

 
}