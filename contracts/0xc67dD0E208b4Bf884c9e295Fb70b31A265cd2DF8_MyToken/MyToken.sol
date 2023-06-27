/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function getSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function getMsgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract AssetOwner is Context {
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        assignOwnership(getSender());
    }

    modifier onlyAssetOwner() {
        checkOwnership();
        _;
    }

    function getOwner() public view virtual returns (address) {
        return owner;
    }

    function checkOwnership() internal view virtual {
        require(getOwner() == getSender(), "AssetOwner: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyAssetOwner {
        assignOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyAssetOwner {
        require(newOwner != address(0), "AssetOwner: new owner is the zero address");
        assignOwnership(newOwner);
    }

    function assignOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

contract BasicToken is Context, IERC20, IERC20Metadata {
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
        address sender = getSender();
        doTransfer(sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return accountAllowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = getSender();
        doApprove(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = getSender();
        spendAllowance(from, spender, amount);
        doTransfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = getSender();
        doApprove(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = getSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            doApprove(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function doTransfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        beforeTokenTransfer(from, to, amount);
        uint256 senderBalance = accountBalances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            accountBalances[from] = senderBalance - amount;
        }
        accountBalances[to] += amount;
        emit Transfer(from, to, amount);
        afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC20: mint to the zero address");
        beforeTokenTransfer(address(0), to, amount);
        totalTokens += amount;
        accountBalances[to] += amount;
        emit Transfer(address(0), to, amount);
        afterTokenTransfer(address(0), to, amount);
    }

    function doApprove(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        accountAllowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            doApprove(owner, spender, currentAllowance - amount);
        }
    }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    function afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.8.0;

contract MyToken is BasicToken, AssetOwner {
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) BasicToken(name_, symbol_) {
        _mint(getSender(), initialSupply);
    }

    function _mint(address to, uint256 amount) internal virtual override {
        super._mint(to, amount);
    }
}