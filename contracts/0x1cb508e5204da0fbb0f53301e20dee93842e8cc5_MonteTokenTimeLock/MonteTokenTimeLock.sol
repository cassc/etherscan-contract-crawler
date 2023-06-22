/**
 *Submitted for verification at Etherscan.io on 2023-06-18
*/

// File: vesting/Ownable.sol



pragma solidity ^0.8.16;


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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: vesting/tokenlock.sol



// Developed By www.soroosh.app 

pragma solidity ^0.8.16;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MonteTokenTimeLock is Ownable {

    // creation time of the token
    uint256 public immutable creationTime;
    
    // Number of tokens which is released after each period.
    uint256 private immutable periodicReleaseNum;
    
    //  Release period in seconds.
    uint256 public constant PERIOD = 600;
    
    // Number of tokens that has been withdrawn already.
    uint256 private _withdrawnTokens;
    
    IERC20 private immutable _token;
    
    event TokenWithdrawn(uint indexed previousAmount, uint indexed newAmount);


    /// @dev creates timelocked wallet with given info.
    /// @param token_ tokenContract address.
    /// @param periodicReleaseNum_ periodic release number.

    constructor(IERC20 token_, uint256 periodicReleaseNum_) {
        _transferOwnership(msg.sender);
        _token = token_;
        creationTime = block.timestamp;
        periodicReleaseNum = periodicReleaseNum_;
    }

    /// @dev withdraws token from wallet if it has enough balance.
    /// @param amount_ amount of withdrawal.
    /// @param beneficiary_ destination address.

    function withdraw(uint256 amount_, address beneficiary_) public onlyOwner {
        require(availableTokens() >= amount_);
        uint256 oldAmount  = _withdrawnTokens;
        _withdrawnTokens += amount_;
        emit TokenWithdrawn(oldAmount, _withdrawnTokens);
        require(token().transfer(beneficiary_, amount_));
    }
    
    /// @dev returns token.

    function token() public view returns (IERC20) {
        return _token;
    }

    /// @dev returns periodic release number.

    function getPeriodicReleaseNum() public view returns (uint256) {
        return periodicReleaseNum;
    }

    /// @dev returns amount of withdrawan tokens.

    function withdrawnTokens() public view returns (uint256) {
        return _withdrawnTokens;
    }
    
    /// @dev returns available balance to withdraw.

    function availableTokens() public view returns (uint256) {
        uint256 passedTime = block.timestamp - creationTime;
        return (passedTime * periodicReleaseNum / PERIOD) - _withdrawnTokens;
    }

    /// @dev returns total locked balance of token.

    function lockedTokens() public view returns (uint256) {
        uint256 balance = timeLockWalletBalance();
        return balance - availableTokens();
    }

    /// @dev returns total balance of the token.
    
    function timeLockWalletBalance() public view returns (uint256) {
        uint256 balance = token().balanceOf(address(this));
        return balance;
    }
}