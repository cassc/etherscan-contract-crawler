/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract SenderContext {
    function _getMsgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _getMsgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface ITokenStandard {
    event TokenTransfer(address indexed from, address indexed to, uint256 value);
    event ApprovalGranted(address indexed owner, address indexed spender, uint256 value);
    function maxSupply() external view returns (uint256);
    function getBalance(address account) external view returns (uint256);
    function sendToken(address to, uint256 amount) external returns (bool);
    function getAllowance(address owner, address spender) external view returns (uint256);
    function approveSpender(address spender, uint256 amount) external returns (bool);
    function sendFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface ITokenMeta is ITokenStandard {
    function getTokenName() external view returns (string memory);
    function getTokenSymbol() external view returns (string memory);
    function getTokenDecimals() external view returns (uint8);
}

contract TokenStandard is SenderContext, ITokenStandard, ITokenMeta {
    mapping(address => uint256) private _accountBalances;
    mapping(address => mapping(address => uint256)) private _spenderAllowances;
    uint256 private _maxSupply;
    string private _tokenName;
    string private _tokenSymbol;

    constructor(string memory name_, string memory symbol_) {
        _tokenName = name_;
        _tokenSymbol = symbol_;
    }

    function getTokenName() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function getTokenSymbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    function getTokenDecimals() public view virtual override returns (uint8) {
        return 18;
    }

    function maxSupply() public view virtual override returns (uint256) {
        return _maxSupply;
    }

    function getBalance(address account) public view virtual override returns (uint256) {
        return _accountBalances[account];
    }

    function sendToken(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _getMsgSender();
        _send(owner, to, amount);
        return true;
    }

    function getAllowance(address owner, address spender) public view virtual override returns (uint256) {
        return _spenderAllowances[owner][spender];
    }

    function approveSpender(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _getMsgSender();
        _approveSpender(owner, spender, amount);
        return true;
    }

    function sendFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _getMsgSender();
        _useAllowance(from, spender, amount);
        _send(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _getMsgSender();
        _approveSpender(owner, spender, getAllowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _getMsgSender();
        uint256 currentAllowance = getAllowance(owner, spender);
        require(currentAllowance >= subtractedValue, "TokenStandard: decreased allowance below zero");
        unchecked {
            _approveSpender(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _send(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "TokenStandard: transfer from the zero address");
        require(to != address(0), "TokenStandard: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _accountBalances[from];
        require(fromBalance >= amount, "TokenStandard: transfer amount exceeds balance");
        unchecked {
            _accountBalances[from] = fromBalance - amount;
            _accountBalances[to] += amount;
        }

        emit TokenTransfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "TokenStandard: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _maxSupply += amount;
        unchecked {
            _accountBalances[account] += amount;
        }
        emit TokenTransfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "TokenStandard: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _accountBalances[account];
        require(accountBalance >= amount, "TokenStandard: burn amount exceeds balance");
        unchecked {
            _accountBalances[account] = accountBalance - amount;
            _maxSupply -= amount;
        }

        emit TokenTransfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approveSpender(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "TokenStandard: approve from the zero address");
        require(spender != address(0), "TokenStandard: approve to the zero address");

        _spenderAllowances[owner][spender] = amount;
        emit ApprovalGranted(owner, spender, amount);
    }

    function _useAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = getAllowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "TokenStandard: insufficient allowance");
            unchecked {
                _approveSpender(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract TRIG is TokenStandard {
    constructor() TokenStandard("Trigger", "TRIG") {
        _mint(_getMsgSender(), 150000000000000 * 10 ** getTokenDecimals());
    }
}