/**
 *Submitted for verification at Etherscan.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT

// spookyskeletons.xyz

// https://t.me/SpookySkeletonsPortal

// https://twitter.com/Spooky5keletons

// SPOOKY SZN ☠️💀☠️💀☠️

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract SpookySZN is Ownable {
    string public name = '_SpookySZN';
    string public symbol = '_SpookySkeletons';
    uint8 public decimals = 9;
    uint256 public totalSupply = 1000000000 * 10 ** decimals;
    address public uniswapV2Pair;
    bool public isPaused = false;
    uint256 public buyFee = 5;
    uint256 public sellFee = 10;
    address public feeAddress;
    uint256 public transferLimit = totalSupply;
    uint256 public walletLimit = totalSupply;

    mapping(address => bool) public feeExcluded;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        feeAddress = msg.sender;
        feeExcluded[msg.sender] = true;
        feeExcluded[address(this)] = true;
        feeExcluded[feeAddress] = true;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function togglePause() external onlyOwner {
        isPaused = !isPaused;
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
    }

    function setLimits(uint256 _transferLimit, uint256 _walletLimit) external onlyOwner {
        transferLimit = _transferLimit;
        walletLimit = _walletLimit;
    }

    function setFeeAddress(address _address) external onlyOwner {
        feeExcluded[feeAddress] = false;
        feeAddress = _address;
        feeExcluded[feeAddress] = true;
    }

    function excludeFromFee(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            feeExcluded[addresses[i]] = true;
        }
    }

    function includeInFee(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            feeExcluded[addresses[i]] = false;
        }
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        require(!isPaused, 'Transfer paused');
        require(_value <= transferLimit, 'Transfer limit exceeded');
        uint256 fee = _to == uniswapV2Pair ? sellFee : buyFee;
        if (feeExcluded[_from] || feeExcluded[_to]) fee = 0;
        uint256 feeAmount = (_value * fee) / 100;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value - feeAmount;
        balanceOf[feeAddress] += feeAmount;
        require(_to == uniswapV2Pair || balanceOf[_to] <= walletLimit, 'Wallet limit exceeded');
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}