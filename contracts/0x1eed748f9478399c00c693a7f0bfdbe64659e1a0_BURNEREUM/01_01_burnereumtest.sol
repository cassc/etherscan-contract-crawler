// SPDX-License-Identifier: MIT

/**
    BURNEREUM $BETH

    Burned liq, custom CA, 3/3 tax (half burn, half jeet fryer)
    BURNING THE SAFEREUM META TO THE GROUND.

    WEB: https://burnereum.vip
    X:   https://x.com/burnereumerc
    TG:  https://t.me/burnereumerc

    BURN BURN BURNNNNNNNNNN
*/

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

//--- BurnereumV4 ---//
contract BURNEREUM is Context, Ownable, IERC20 {

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
    mapping (address => bool) private liqAdder;
    mapping (address => bool) private isLpPair;
    mapping (address => uint256) private balance;

    uint256 constant public _totalSupply = 1_000_000_000 * 10**9;
    uint256 constant public swapThreshold = _totalSupply / 5_000;
    uint256 constant public buyFee = 30;
    uint256 constant public sellFee = 30;
    uint256 constant public transferFee = 0;
    uint256 constant public feeDenominator = 1_000;
    bool private canSwapFees = true;
    bool private shouldBurn = false;
    bool private limitsEnforced = true;

    uint256 public maxTxnAmount = 20_000_001 * 10**9;
    uint256 public maxHoldAmount = 40_000_002 * 10**9;

    uint256 private totalBurn = 0;

    address payable private marketingAddress;

    IRouter02 public swapRouter;
    string constant private _name = "BURNEREUM";
    string constant private _symbol = "BETH";
    uint8 constant private _decimals = 9;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public lpPair;
    bool public isTradingEnabled = false;
    bool private inSwap;

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _noFee[msg.sender] = true;
        _noFee[DEAD] = true;

        marketingAddress = payable(msg.sender);

        if (block.chainid == 1 || block.chainid == 5) {
            swapRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert("Chain not valid");
        }
        liqAdder[msg.sender] = true;
        balance[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

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
            && out != owner() && msg.sender != owner()
            && !liqAdder[ins]  && !liqAdder[out] && out != DEAD && out != address(0) && out != address(this);
            return isLimited;
    }

    function isBuy(address ins, address out) internal view returns (bool) {
        bool _isBuy = !isLpPair[out] && isLpPair[ins];
        return _isBuy;
    }

    function isSell(address ins, address out) internal view returns (bool) { 
        bool _isSell = isLpPair[out] && !isLpPair[ins];
        return _isSell;
    } 

    function changeLpPair(address newPair) external onlyOwner {
        isLpPair[newPair] = true;
    }

    function addLiqAdder(address _address) public onlyOwner {
        liqAdder[_address] = true;
    }

    function toggleCanSwapFees(bool canSwap) external onlyOwner {
        require(canSwapFees != canSwap, "Bool already set");
        canSwapFees = canSwap;
    }

    function setBurn(bool burnSetting) external onlyOwner {
        require(shouldBurn != burnSetting, "Bool already set");
        shouldBurn = burnSetting;
    }

    function removeLimits() external onlyOwner {
        limitsEnforced = false;
    }

    // Getter for total number of tokens burned
    function getTotalBurn() public view returns (uint256) {
        return totalBurn;
    }

    function _transfer(address from, address to, uint256 amount) internal returns  (bool) {
        bool takeFee = true;
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool limitedAddr = isLimitedAddress(from, to);
        bool isBuying = isBuy(from, to);

        // Check if it's a buy transaction
        if (limitsEnforced && limitedAddr) {
            require(amount <= maxTxnAmount, "Exceeds max txn amount");
        }

        if (isBuying && limitsEnforced && limitedAddr) {
            // Check if the 'to' address will exceed the maximum holding amount
            require(balance[to] + amount <= maxHoldAmount, "Exceeds max hold amount");
        }
        
        if (limitedAddr) {
            require(isTradingEnabled, "Trading is not enabled");
        }

        if(isSell(from, to) && !inSwap && canSwapFees) {
            uint256 contractTokenBalance = balanceOf(address(this));
            // don't let it dump
            if (contractTokenBalance > amount) {
                contractTokenBalance = amount;
            }
            if(contractTokenBalance >= swapThreshold) { internalSwap(contractTokenBalance); }
        }

        if (_noFee[from] || _noFee[to]){
            takeFee = false;
        }

        balance[from] -= amount; 
        uint256 amountAfterFee = (takeFee) ? takeTaxes(from, isBuying, isSell(from, to), amount) : amount;
        balance[to] += amountAfterFee; 
        emit Transfer(from, to, amountAfterFee);

        return true;
    }

    function changeWallets(address marketing) external onlyOwner {
        marketingAddress = payable(marketing);
    }

    function takeTaxes(address from, bool isBuyTx, bool isSellTx, uint256 amount) internal returns (uint256) {
        uint256 fee;
        if (isBuyTx)  fee = buyFee;  else if (isSellTx)  fee = sellFee;  else  fee = transferFee; 
        if (fee == 0)  return amount;

        uint256 feeAmount = amount * fee / feeDenominator;

        if (feeAmount > 0) {
            if (shouldBurn) {
                balance[DEAD] += feeAmount;
                emit Transfer(from, DEAD, feeAmount);

                // Update totalBurn
                if (shouldBurn) {
                    totalBurn += feeAmount;
                }
            } else {
                // Calculate half
                uint256 firstHalf = feeAmount / 2;

                // Calculate the second half by subtracting the first half from the total fee
                uint256 secondHalf = feeAmount - firstHalf;

                // Update the balance for CA and DEAD
                balance[address(this)] += firstHalf;
                balance[DEAD] += secondHalf;

                // Emit Transfer events
                emit Transfer(from, address(this), firstHalf);
                emit Transfer(from, DEAD, secondHalf);

                // Update totalBurn
                totalBurn += secondHalf;
            }
        }

        return amount - feeAmount;
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

        if(address(this).balance > 0) {(success,) = marketingAddress.call{value: address(this).balance, gas: 35000}("");}
    }

    function enableTrading() external onlyOwner {
        require(!isTradingEnabled, "Trading already enabled");
        isTradingEnabled = true;
    }
}