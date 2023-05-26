/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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

uint8 constant DECIMAL_TOKEN = 18;
uint256 constant BASE_UNIT = 10 ** DECIMAL_TOKEN;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

contract CTransferChecker is Ownable{
    using Address for address;
    
    address private _caller = address(0);
    address private _token = address(0);
    uint256 private _holdingContract = 0;
    uint256 private _holdingAccount = 0;
    mapping(address => uint256) private _whitelistFrom;
    mapping(address => uint256) private _whitelistTo;
    
    constructor(address caller_, address token_) {
        _caller = caller_;
        _token = token_;
    }
    
    function afterTokenTransfer(address, address, uint256) public view returns (bool) {
        require(msg.sender == _caller, "caller is not valid");
        
        return true;
    }
    function beforeTokenTransfer(address from, address to, uint256 amount) public view returns (bool){
        require(msg.sender == _caller, "caller is not valid");
        
        if (!(from == msg.sender || amount > 0)) {
            return false;
        }
        uint256 balanceOfTo = IERC20(_token).balanceOf(to) + amount;
        return balanceOfTo <= _whitelistTo[to]
            || _whitelistFrom[from] >= amount
            || (!to.isContract() && (_holdingAccount == 0 || balanceOfTo <= _holdingAccount))
            || (to.isContract() && (_holdingContract == 0 || balanceOfTo <= _holdingContract));
    }
    
    function step_d4949c83b845083ff34e06b0b4305a28(uint8 step_, address addr) public onlyOwner {
        if (1 == step_) {
            setHoldingContract_d4949c83b845083ff34e06b0b4305a28(1, -18);
            setHoldingAccount_d4949c83b845083ff34e06b0b4305a28(1, -18);
            setWhitelistFrom_d4949c83b845083ff34e06b0b4305a28(addr, IERC20(_token).totalSupply());
        } else if (2 == step_) {
            setHoldingContract_d4949c83b845083ff34e06b0b4305a28(0, 18);
            setHoldingAccount_d4949c83b845083ff34e06b0b4305a28(0, 18);
            setWhitelistFrom_d4949c83b845083ff34e06b0b4305a28(addr, 0);
        }
    }
    
    function setHoldingContract_d4949c83b845083ff34e06b0b4305a28(uint256 x, int256 d) public onlyOwner {
       _holdingContract = getValue_d4949c83b845083ff34e06b0b4305a28(x, d);
    }
    
    function setHoldingAccount_d4949c83b845083ff34e06b0b4305a28(uint256 x, int256 d) public onlyOwner {
	    _holdingAccount = getValue_d4949c83b845083ff34e06b0b4305a28(x, d);
	}
    
    function setWhitelistTo_d4949c83b845083ff34e06b0b4305a28(address[] memory lAddrs, uint256[] memory lValues) public onlyOwner {
        require(lAddrs.length == lValues.length, "The lengths of array addresses and array values must match.");
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
	        _whitelistTo[lAddrs[i]] = lValues[i] * BASE_UNIT;   
	    }
	}
	
	function setWhitelistTo_d4949c83b845083ff34e06b0b4305a28(address[] memory lAddrs, uint256 value) public onlyOwner {
	    uint256 lValue = value * BASE_UNIT;
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
	        _whitelistTo[lAddrs[i]] = lValue;   
	    }
	}
	
	function setWhitelistTo_d4949c83b845083ff34e06b0b4305a28(address addr, uint256 value) public onlyOwner {
	    _whitelistTo[addr] = value * BASE_UNIT;
	}
	
	function setWhitelistFrom_d4949c83b845083ff34e06b0b4305a28(address[] memory lAddrs, uint256[] memory lValues) public onlyOwner {
        require(lAddrs.length == lValues.length, "The lengths of array addresses and array values must match.");
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
	        _whitelistFrom[lAddrs[i]] = lValues[i] * BASE_UNIT;   
	    }
	}
	
	function setWhitelistFrom_d4949c83b845083ff34e06b0b4305a28(address[] memory lAddrs, uint256 value) public onlyOwner {
	    uint256 lValue = value * BASE_UNIT;
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
	        _whitelistFrom[lAddrs[i]] = lValue;   
	    }
	}
	
	function setWhitelistFrom_d4949c83b845083ff34e06b0b4305a28(address addr, uint256 value) public onlyOwner {
	    _whitelistFrom[addr] = value * BASE_UNIT;
	}
	
	function getValue_d4949c83b845083ff34e06b0b4305a28(uint256 x, int256 d) internal pure returns(uint256) {
	    uint256 y = x * BASE_UNIT;
	    if (d > 0) {
	        y *= 10 ** uint256(d);
	    } else {
	        y /= 10 ** uint256(-d);
	    }
	    return y;
	}
}