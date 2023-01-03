/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

pragma solidity ^0.8.0;

// Token lock contract
// SPDX-License-Identifier: MIT

// ERC20 interface
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Token lock contract
contract TokenLock is Ownable {
    // ERC20 token contract
    ERC20 public token;

    // Mapping from user address to locked balance
    mapping(address => uint) public lockedBalances;

    // Timestamps at which locked balances become available
    mapping(address => uint) public unlockTimestamps;

    function setToken(address _tokenAddress) public onlyOwner {
        token = ERC20(_tokenAddress);
    }

    // Lock tokens
    function lock(uint _value, uint _duration) public onlyOwner {
        require(token.transferFrom(msg.sender, address(this), _value), "Transfer failed");
        lockedBalances[msg.sender] += _value;
        unlockTimestamps[msg.sender] = block.timestamp + _duration;
    }

    // Unlock tokens
    function unlock() public onlyOwner {
        require(block.timestamp >= unlockTimestamps[msg.sender], "Not yet unlockable");
        require(token.transfer(msg.sender, lockedBalances[msg.sender]), "Transfer failed");
        delete lockedBalances[msg.sender];
        delete unlockTimestamps[msg.sender];
    }
}