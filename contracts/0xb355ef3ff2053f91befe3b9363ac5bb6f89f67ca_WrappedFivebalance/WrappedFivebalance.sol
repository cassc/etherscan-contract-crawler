/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: MIT

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {

    mapping(address => bool) _isExcluded;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 _charityFee;
    uint256 _devFee;
    uint256 _walletFee;
    uint256 _feeDivider;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address _charityAddress;
    address _devAddress;
    address _walletAddress;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        {
            _balances[from] = fromBalance - amount;

            if(!_isExcluded[from] && !_isExcluded[to]) {

                uint _cAmount = (amount * _charityFee) / _feeDivider;
                uint _dAmount = (amount * _devFee) / _feeDivider;
                uint _wAmount = (amount * _walletFee) / _feeDivider;

                _balances[_charityAddress] += _cAmount;
                _balances[_devAddress] += _dAmount;
                _balances[_walletAddress] += _wAmount;

                amount -= (_cAmount + _dAmount + _wAmount);
            }

            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _excludeAddress(address _address) internal {
        _isExcluded[_address] = true;
    }

    function _removeFromExcludeAddress(address _address) internal {
        _isExcluded[_address] = false;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract WrappedFivebalance is ERC20, Ownable {
    constructor() ERC20("Wrapped Fivebalance", "WFBN") {
        _charityAddress = 0x66B216e10ae3acb676986D0E29e79f60dc8f81f8;
        _devAddress = 0x9a942d97dAdbfC88f9C7Edc8DcAc80FB61265598;
        _walletAddress = 0xdbA77b4477a4d61D6dA41a8eeFB8E0ee7EA08c20;
        _charityFee = 10;
        _devFee = 5;
        _walletFee = 10;
        _feeDivider = 1000;
        _mint(0x908D537870c088E9Ae99f8bE080f6A95f603866e, 3_000_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function excludeAddress(address _address) external onlyOwner {
        _excludeAddress(_address);
    }

    function removeFromExcludeAddress(address _address) external onlyOwner {
        _removeFromExcludeAddress(_address);
    }

    function isAddressExcluded(address _address) external view returns (bool) {
        return _isExcluded[_address];
    }

    function getCharityFees() external view returns (uint) {
        return _charityFee;
    }

    function getDevFees() external view returns (uint) {
        return _devFee;
    }

    function getWalletFees() external view returns (uint) {
        return _walletFee;
    }

    function getFeeDivider() external view returns (uint) {
        return _feeDivider;
    }

    function getCharityAddress() external view returns (address) {
        return _charityAddress;
    }

    function getDevAddress() external view returns (address) {
        return _devAddress;
    }

    function getWalletAddress() external view returns (address) {
        return _walletAddress;
    }
}