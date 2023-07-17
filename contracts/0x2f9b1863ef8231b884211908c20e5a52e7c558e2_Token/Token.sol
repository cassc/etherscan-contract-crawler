/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract SenderContext {
    function getSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function getMsgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract AssetOwner is SenderContext {
    address private assetOwner;
    event AssetOwnershipTransferred(address indexed previousAssetOwner, address indexed newAssetOwner);
    constructor() {
        _transferAssetOwnership(getSender());
    }
    modifier onlyAssetOwner() {
        _verifyOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return assetOwner;
    }
    function _verifyOwner() internal view virtual {
        require(owner() == getSender(), "AssetOwner: caller is not the owner");
    }
    function discardOwnership() public virtual onlyAssetOwner {
        _transferAssetOwnership(address(0));
    }
    function changeOwnership(address newAssetOwner) public virtual onlyAssetOwner {
        require(newAssetOwner != address(0), "AssetOwner: new owner is the zero address");
        _transferAssetOwnership(newAssetOwner);
    }
    function _transferAssetOwnership(address newAssetOwner) internal virtual {
        address oldAssetOwner = assetOwner;
        assetOwner = newAssetOwner;
        emit AssetOwnershipTransferred(oldAssetOwner, newAssetOwner);
    }
}

pragma solidity ^0.8.0;

interface IERC20Basic {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC20BasicMeta is IERC20Basic {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract BasicToken is SenderContext, IERC20Basic, IERC20BasicMeta {
    mapping(address => uint256) private accountBalances;
    mapping(address => mapping(address => uint256)) private accountAllowances;
    uint256 private totalTokens;
    string private tokenName;
    string private tokenSymbol;
    constructor(string memory name_, string memory symbol_) {
        tokenName = name_;
        tokenSymbol = symbol_;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return totalTokens;
    }
    function name() public view virtual override returns (string memory) {
        return tokenName;
    }
    function symbol() public view virtual override returns (string memory) {
        return tokenSymbol;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return accountBalances[account];
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = getSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return accountAllowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = getSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = getSender();
        _consumeAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = getSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = getSender();
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
        uint256 fromBalance = accountBalances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            accountBalances[from] = fromBalance - amount;
            accountBalances[to] += amount;
        }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = accountBalances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            accountBalances[account] = accountBalance - amount;
            totalTokens -= amount;
        }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        totalTokens += amount;
        unchecked {
            accountBalances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        accountAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _consumeAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.8.0;

contract Token is BasicToken, AssetOwner {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) BasicToken(name_, symbol_) {
        _mint(getSender(), initialSupply);
    }
    function burn(uint256 amount) public virtual onlyAssetOwner {
        _burn(getSender(), amount);
    }
    function mint(address to, uint256 amount) public virtual onlyAssetOwner {
        _mint(to, amount);
    }
}