/**
 *Submitted for verification at Etherscan.io on 2023-07-20
*/

/**
 * Pepe Five-O $PEPE5O
 * https://pepe5o.vip
 * https://t.me/pepe5o
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;


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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PEPE5O is Ownable, IERC20 {
    string constant _name    = "Pepe Five-O";
    string constant _symbol  = "PEPE5O";
    uint8 constant _decimals = 18;

    event MaxHoldingSet(uint256 amount);
    event SwapBackSet(uint256 amount, bool enabled);
    event ExemptFromFee(address account, bool exempt);

    uint256 _totalSupply = 420_690_000_000_000 * 10**_decimals;

    uint256 public maxHolding = _totalSupply / 100;
    uint256 public maxTxAmount = _totalSupply / 100;
    uint256 public swapThreshold = _totalSupply * 5 / 10000; // 0.05%s

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) isExemptFromFee;
    mapping (address => bool) isExemptFromMaxTX;

    address public pair;
    address private feeReceiver;

    IUniswapRouter public router;

    bool inSwap;
    bool public swapEnabled = true;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address routerAddress, address feeAddress) {
        router = IUniswapRouter(routerAddress);
        pair = IUniswapFactory(router.factory()).createPair(router.WETH(), address(this));
 
        _allowances[address(this)][address(router)] = type(uint256).max;

        feeReceiver = feeAddress;

        isExemptFromFee[msg.sender] = true;
        isExemptFromMaxTX[msg.sender] = true;
        isExemptFromMaxTX[pair] = true;
        isExemptFromMaxTX[feeReceiver] = true;
        isExemptFromMaxTX[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    /**
     * View functions
     */

    function decimals() external pure override returns (uint8) { return _decimals; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    /**
     * ERC20 functions
     */

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            require(_allowances[sender][msg.sender] >= amount, "PEPE5O: insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    /**
     * Clear tokens function (needed after renounce)
     */
    function clearTokens(uint256 amount) external returns (bool success) {
        if(amount == 0){
            amount = balanceOf(address(this));
        }

        return _transfer(address(this), feeReceiver, amount);
    }

    /**
     * Owner functions
     */

    function removeLimits () external onlyOwner {
        maxHolding = _totalSupply;
        maxTxAmount = _totalSupply;
    }

    function setMaxHolding(uint percent) external onlyOwner {
        require(percent >= 1 && percent <= 100, "PEPE5O: percentage can only be between 1 and 100"); 
        require((_totalSupply * percent) / 100 > maxHolding, "PEPE5O: max holding cannot be lowered");

        maxHolding = (_totalSupply * percent) / 100;

        emit MaxHoldingSet(maxHolding);                
    }

    function setFeeExempt(address account, bool exempt) public onlyOwner {
        isExemptFromFee[account] = exempt;
        emit ExemptFromFee(account, exempt);
    }

   function setSwapBackSettings(bool enabled, uint256 threshold) external onlyOwner {
        swapEnabled = enabled;
        swapThreshold = threshold;
        emit SwapBackSet(swapThreshold, swapEnabled);
    }

    /**
     * Internal functions
     */

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "PEPE5O: transfer amount exceeds balance");

        if(inSwap){ return _transfer(from, to, amount); }

        if (from != owner() 
            && to != pair
            && to != feeReceiver 
            && to != address(this)
            && !isExemptFromMaxTX[to]
        ) {
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= maxHolding,"PEPE5O: exceeds max holding");
        }

        _checkTxLimit(from, amount);

        if(_shouldSwapBack()){ _swapBack(); }

        uint256 amountReceived = (isExemptFromFee[from] || isExemptFromFee[to]) ? amount : _takeFee(from, to, amount);

        unchecked {
            _balances[from] -= amount;
            _balances[to] += amountReceived;
        }

        emit Transfer(from, to, amountReceived);
        return true;
    }
 
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
        return true;
    }

    function _checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= maxTxAmount || isExemptFromMaxTX[sender], "PEPE5O: exceeds tx limit");
    }

    function _takeFee(address from, address to, uint256 amount) internal returns (uint256) {
        if(from != pair && to != pair) return amount;

        uint256 feeAmount = amount / 100;
        unchecked{
            _balances[address(this)] += feeAmount;
        }
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold;
    }

    function _swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapThreshold,
            0,
            path,
            feeReceiver,
            block.timestamp
        );
    }
}