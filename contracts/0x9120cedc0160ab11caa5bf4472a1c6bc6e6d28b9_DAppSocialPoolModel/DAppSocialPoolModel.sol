/**
 *Submitted for verification at Etherscan.io on 2023-07-05
*/

// SPDX-License-Identifier: MIT

// File: dappsocial_contracts/src/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.19;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        if (_status == _ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// File: dappsocial_contracts/src/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// File: dappsocial_contracts/src/Ownable.sol


pragma solidity ^0.8.19;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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

// File: dappsocial_contracts/src/IERC20.sol



pragma solidity ^0.8.19;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromWithPermit(address sender, address recipient, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
// File: dappsocial_contracts/src/DappSocialPoolModel.sol


pragma solidity ^0.8.19;




/**
 * @title  DAppSocial Pool Model contract, which holds balances of native and ERC20 token assets for users
 * @author Suresh Maddineni (https://twitter.com/TitanEverRise)
 * @notice This contract holds the user's assets, their balances and facilitates them in the transactions of 
 *         #CrossX and #Trade+ features of #DAppSocial platform
 */
contract DAppSocialPoolModel is Ownable, ReentrancyGuard {

    //Balances
    mapping (address => uint256) _nativeBalances; // Native Coin Balances. Address => Value
    mapping (address => uint256) _pendingNativeBalances; // Pending Native Coin Balances. Address => Value
    mapping (address => mapping(address => uint256)) _tokenBalances; // Token Balances. Token => Address => Value
    mapping (address => mapping(address => uint256)) _pendingTokenBalances; // Token Balances. Token => Address => Value

    //Locking
    mapping (address => uint48) internal _lockTimestamps;
    mapping (address => address) private _userUnlocks;
   
    mapping (address => bool) _supportedTokens;
    mapping (address => bool) _adminList;
    address private exchangeAddress;
    address private feeAddress;


    event TokenSupportAdded(address indexed, bool);
    event TokenSupportRemoved(address indexed, bool);
    event Deposit(address indexed, uint256);
    event Withdrawn(address indexed, uint256);
    event NativeTransferred(address indexed from , address indexed to, uint256 amount);

    event TokenDeposited(address indexed, address indexed, uint256);
    event TokenWithdrawn(address indexed, address indexed, uint256);
    event TokenTransferred(address indexed, address indexed, uint256);
    event AdminAddressAdded(address indexed oldAdderess, bool flag);
    event AdminAddressRemoved(address indexed oldAdderess, bool flag);
    event ControllerUpdated(address indexed oldAddress, address indexed newAddress);
    event LockTokens(address indexed account, address indexed altAccount, uint256 length);
    event LockTokensExtend(address indexed account, uint256 length);
    event UpdatedFeeAddress(address indexed oldAddress, address indexed newAddress);
    event UpdatedExchangeAddress(address indexed oldAddress, address indexed newAddress);


    error FailedETHSend();
    error TokensLocked();                 
    error LockTimeTooLong();              
    error LockTimeTooShort();             
    error Unlocked();
    error NotZeroAddress();
    error CallerNotApproved();
    error TokenNotSupported();
    error NotEnoughBalance();                


    constructor() {
        _adminList[msg.sender] = true;
    }

    function name() public pure returns (string memory) {
        return "DAppSocialPoolModel";
    }

    /**
     * @dev If the assets are locked for the given address, then it throws an error
     *
     * @param fromAddress Address on which the check happens
     */
    function _tokensLock(address fromAddress) internal view {
        if (isWalletLocked(fromAddress)) revert TokensLocked();
    }

    /**
     * @dev Modifier to check whether the assets are locked or not
     *
     * @param fromAddress Address on which the check happens
     */
    modifier tokensLock(address fromAddress) {
        _tokensLock(fromAddress);
        _;
    }

    /**
     * @dev Modifier to check whether the given amount is greater than Zero or not
     *
     * @param amount Amount to check
     */
    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount should be greater than 0");
        _;
    }

    /**
     * @dev Modifier to check whether the given amount is greater than the balance or not
     *      and throws error if true
     *
     * @param amount Amount to check
     * @param balance on which the check happens
     */
    modifier enoughBalance(uint256 amount, uint256 balance) {
        if (amount > balance) revert NotEnoughBalance();
        _;
    }

    /**
     * @dev Checks whether the locktimestamp is greter than current time or not
     *
     * @param fromAddress Address on which the check happens
     */
    function isWalletLocked(address fromAddress) public view returns(bool) {
        return _lockTimestamps[fromAddress] > block.timestamp;
    }

    /**
     * @dev It locks the sender account's assets from withdrawl until the time specified
     *
     * @param altAccount Alternate account whcih can unlock anytime before the lock expires
     * @param length Time in seconds to lock the assets
     */
    function lockTokens(address altAccount, uint48 length) external tokensLock(_msgSender()) {
        if (altAccount == address(0)) revert NotZeroAddress();
        if (length / 1 days > 10 * 365 days) revert LockTimeTooLong();

        _lockTimestamps[_msgSender()] = uint48(block.timestamp) + length;
        _userUnlocks[_msgSender()] = altAccount;

        emit LockTokens(_msgSender(), altAccount, length);
    }

    /**
     * @dev It extends the lock by the given time, when it is already in locked state
     *
     * @param length Time in seconds to lock the assets
     */
    function extendLockTokens(uint48 length) external {
        if (length / 1 days > 10 * 365 days) revert LockTimeTooLong();
        uint48 currentLock = _lockTimestamps[_msgSender()];

        if (currentLock < block.timestamp) revert Unlocked();

        uint48 newLock = uint48(block.timestamp) + length;
        if (currentLock > newLock) revert LockTimeTooShort();
        _lockTimestamps[_msgSender()] = newLock;

        emit LockTokensExtend(_msgSender(), length);
    }

    /**
     * @dev It unlocks the given account. 
     * @notice This has to be called from the alternate account which was used in locking the assets
     * 
     * @param accountToUnlock The main account which needs to be unlocked 
     */
    function unlockTokens(address accountToUnlock) external {
        if (_userUnlocks[accountToUnlock] != _msgSender()) revert CallerNotApproved();
        uint48 currentLock = _lockTimestamps[accountToUnlock];
        if (currentLock < block.timestamp) revert Unlocked();
        _lockTimestamps[accountToUnlock] = 1;
    }

    /**
     * @dev Add a new admin account
     *
     * @param newAddress New Admin account
     */
    function addAdmin(address newAddress) external onlyOwner{
        require(!_adminList[newAddress], "Address is already Admin");
        _adminList[newAddress] = true;
        emit AdminAddressAdded(newAddress, true);
    }

    /**
     * @dev Removes an address from the admin list
     *
     * @param oldAddress The address which needs to be removed
     */
    function removeAdmin(address oldAddress) external onlyOwner {
        require(_adminList[oldAddress], "The Address is not admin");
        _adminList[oldAddress] = false;
        emit AdminAddressRemoved(oldAddress, false);
    }

    /**
     * @dev adminOnly modifier
     */
    modifier adminOnly() {
        require(_adminList[msg.sender], "only Admin action");
        _;
    }

    /**
     * @dev exchangeOnly modifier
     */
    modifier exchangeOnly() {
        require(exchangeAddress == msg.sender, "only Exchange action");
        _;
    }

    /**
     * @dev Adds a new ERC20 token to the supported tokens list
     *
     * @param tokenAddress ERC20 token which needs to be added
     */
    function addSupportedToken(address tokenAddress) external adminOnly {
        _supportedTokens[tokenAddress] = true;
        emit TokenSupportAdded(tokenAddress, true);
    }

    /**
     * @dev Removes an ERC20 token from the supported tokens list
     *
     * @param tokenAddress ERC20 token which needs to be removed
     */
    function removeSupportedToken(address tokenAddress) external adminOnly {
        _supportedTokens[tokenAddress] = false;
        emit TokenSupportRemoved(tokenAddress, false);
    }

    /**
     * @dev Set fee address, which collects the fees for transactions
     *
     * @param newAddress Address which collects the fee
     */
    function setFeeAddress(address newAddress) external onlyOwner {
        emit UpdatedFeeAddress(feeAddress, newAddress);
        feeAddress = newAddress;
    }

    /**
     * @dev Update the Exchange address, which can have access to some operations
     *
     * @param newAddress New Exchange address 
     */
    function updateExchange(address newAddress) external onlyOwner {
        emit UpdatedExchangeAddress(exchangeAddress, newAddress);
        exchangeAddress = newAddress;
    }

    /**
     * @dev Deposit Natives
     * NOTE: This is the only method to call the deposit for Natives. Sending Native directly to the contract will not register them and will be lost
     */
    function depositNative() external payable validAmount(msg.value) {
        _nativeBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Deposit ERC20 tokens
     *
     * @param tokenAddress ERC20 token address
     * @param amount Amount to deposit 
     * NOTE: This is the only method to call the deposit for Tokens. Sending tokens directly to the contract will not register them and will be lost
     */
    function depositTokens(address tokenAddress, uint256 amount) external validAmount(amount) {
        if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _tokenBalances[tokenAddress][msg.sender] += amount;
        emit TokenDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Withdraw Natives when the assets are not in locked state
     *
     * @param amount Amount to withdraw
     */
    function withdrawNative(uint256 amount) external tokensLock(msg.sender) nonReentrant validAmount(amount) enoughBalance(amount, _nativeBalances[msg.sender]) {
        unchecked {
            _nativeBalances[msg.sender] -= amount;
        }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(msg.sender, amount);
        } else {
            revert FailedETHSend();
        }
    }

    /**
     * @dev Withdraw tokens when the assets are not in locked state
     *
     * @param tokenAddress ERC20 token address
     * @param amount Amount to withdraw
     */
    function withdrawTokens(address tokenAddress, uint256 amount) external tokensLock(msg.sender) validAmount(amount) enoughBalance(amount, _tokenBalances[tokenAddress][msg.sender]) {
        if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
        unchecked {
            _tokenBalances[tokenAddress][msg.sender] -= amount;
        }
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Withdraw Natives with alt account when the assets are in locked state for the main account

     * @param from From address
     * @param amount Amount to withdraw
     */
    function withdrawNativeWithAlt(address from, uint256 amount) external nonReentrant validAmount(amount) enoughBalance(amount, _nativeBalances[msg.sender]) {
        if (_userUnlocks[from] != _msgSender()) revert CallerNotApproved();
        unchecked {
            _nativeBalances[from] -= amount;
        }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (success) {
            emit Withdrawn(msg.sender, amount);
        } else {
            revert FailedETHSend();
        }
    }

    /**
     * @dev Withdraw Tokens with alt account when the assets are in locked state for the main account
     *
     * @param tokenAddress ERC20 token address
     * @param from From address
     * @param amount Amount to withdraw
     */
    function withdrawTokensWithAlt(address tokenAddress, address from, uint256 amount) external validAmount(amount) enoughBalance(amount, _tokenBalances[tokenAddress][msg.sender]) {
        if (!_supportedTokens[tokenAddress]) revert TokenNotSupported();
        if (_userUnlocks[from] != _msgSender()) revert CallerNotApproved();
        unchecked {
            _tokenBalances[tokenAddress][from] -= amount;
        }
        IERC20(tokenAddress).transfer(msg.sender, amount);
        emit TokenWithdrawn(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Transfers natives from one account to another with in the pool
     *
     * @param from From address
     * @param to To address
     * @param amount Amount to transfer
     */
    function transferNative(address from, address to, uint256 amount) external adminOnly validAmount(amount) enoughBalance(amount, _nativeBalances[msg.sender]) {
        unchecked {
            _nativeBalances[from] -= amount;
        }
        _nativeBalances[to] += amount;
    }

    /**
     * @dev Transfers tokens from one account to another with in the pool or to wallet, if the isWalletTransfer flag is true
     *
     * @param tokenAddress ERC20 token address
     * @param from From Address
     * @param to To Address
     * @param amount Pending amount to transfer
     * @param isWalletTransfer flag specifies walleter transfer or not
     */
    function transferTokens(address tokenAddress, address from, address to, uint256 amount, bool isWalletTransfer) external adminOnly validAmount(amount) enoughBalance(amount, _tokenBalances[tokenAddress][from]) {
        unchecked {
            _tokenBalances[tokenAddress][from] -= amount;
        }
        if (isWalletTransfer) {
            IERC20(tokenAddress).transfer(to, amount);
        } else {
            _tokenBalances[tokenAddress][to] += amount;
        }
    }

    /**
     * @dev Transfer pending tokens of from account to another with in the pool
     *
     * @param tokenAddress ERC20 token address
     * @param from From Address
     * @param to To Address
     * @param amount Pending amount to transfer
     */
    function transferPendingTokens(address tokenAddress, address from, address to, uint256 amount) external adminOnly validAmount(amount) enoughBalance(amount, _pendingTokenBalances[tokenAddress][from]) {
        unchecked {
            _pendingTokenBalances[tokenAddress][from] -= amount;
        }
        _tokenBalances[tokenAddress][to] += amount;
    }

    /**
     * @dev Transfers Natives from one account to another
     *
     * @param from From address
     * @param to To address
     * @param amount Amount to send
     */
    function transferETH(address from, address to, uint256 amount, uint256 feeAmount) external exchangeOnly validAmount(amount) enoughBalance(amount, _nativeBalances[from]) {
        unchecked {
            _nativeBalances[from] -= (amount + feeAmount);
        }
        _nativeBalances[feeAddress] += feeAmount;
        (bool success, ) = payable(to).call{value: amount}("");
        if (success) {
            emit NativeTransferred(from, to, amount);
        } else {
            revert FailedETHSend();
        }
    }

    /**
     * @dev Transfers pending natives of from account to another account
     *
     * @param from From address
     * @param to To address
     * @param amount Pending amount to send
     */
    function transferPendingETH(address from, address to, uint256 amount, uint256 feeAmount) external exchangeOnly validAmount(amount) enoughBalance(amount, _pendingNativeBalances[from]) {
        unchecked {
            _pendingNativeBalances[from] -= (amount + feeAmount);
        }
        _nativeBalances[feeAddress] += feeAmount;
        (bool success, ) = payable(to).call{value: amount}("");
        if (success) {
            emit NativeTransferred(from, to, amount);
        } else {
            revert FailedETHSend();
        }
    }

    /**
     * @dev Withhold the natives from an account
     *
     * @param from Account address
     * @param amount Amount to hold
     */
    function holdNative(address from, uint256 amount) external exchangeOnly validAmount(amount) enoughBalance(amount, _nativeBalances[from]) {
        unchecked {
            _nativeBalances[from] -= amount;
        }
        _pendingNativeBalances[from] += amount;
    }

    /**
     * @dev Withhold the natives from an account after collecting fee
     *
     * @param from Account address
     * @param amount Amount to hold
     * @param feeAmount The fee amount
     */
    function holdNativeWithFee(address from, uint256 amount, uint256 feeAmount) external exchangeOnly validAmount(amount) enoughBalance(amount, _nativeBalances[from]) {
        require(amount > feeAmount, "Fee is greater than the amount");
        unchecked {
            _nativeBalances[from] -= amount;
        }
        _pendingNativeBalances[from] += (amount - feeAmount);
        _nativeBalances[feeAddress] += feeAmount;
    }

    /**
     * @dev Release the natives from an account
     *
     * @param from Account address
     * @param amount Amount to release
     */
    function releaseNative(address from, uint256 amount) external exchangeOnly validAmount(amount) enoughBalance(amount, _pendingNativeBalances[from]) {
        unchecked {
            _pendingNativeBalances[from] -= amount;
        }
        _nativeBalances[from] += amount;
    }

    /**
     * @dev Withhold the tokens from an account
     *
     * @param tokenAddress ERC20 token address
     * @param from From Address
     * @param amount Amount to hold
     */
    function holdTokens(address tokenAddress, address from, uint256 amount) external adminOnly validAmount(amount) enoughBalance(amount, _tokenBalances[tokenAddress][from]) {
        unchecked {
            _tokenBalances[tokenAddress][from] -= amount;
        }
        _pendingTokenBalances[tokenAddress][from] += amount;
    }

    /**
     * @dev Withhold the tokens from an account after collecting fee amount
     *
     * @param tokenAddress ERC20 token address
     * @param from From Address
     * @param amount Amount to hold
     * @param feeAmount Fee amount to be collected
     */
    function holdTokensWithFee(address tokenAddress, address from, uint256 amount, uint256 feeAmount) external adminOnly validAmount(amount) enoughBalance(amount, _tokenBalances[tokenAddress][from]) {
        require(amount > feeAmount, "Fee is greater than the amount");
        unchecked {
            _tokenBalances[tokenAddress][from] -= amount;
        }
        _pendingTokenBalances[tokenAddress][from] += (amount - feeAmount);
        _tokenBalances[tokenAddress][feeAddress] += feeAmount;
    }

    /**
     * @dev Relese the pending tokens of an account
     *
     * @param tokenAddress ERC20 token address
     * @param from From address
     * @param amount Amount to release
     */
    function releaseTokens(address tokenAddress, address from, uint256 amount) external adminOnly validAmount(amount) enoughBalance(amount, _pendingTokenBalances[tokenAddress][from]) {
        unchecked {
            _pendingTokenBalances[tokenAddress][from] -= amount;
        }
        _tokenBalances[tokenAddress][from] += amount;
    }

    /**
     * @dev Get Token balances of given token address and an account
     *
     * @param tokenAddress ERC20 token address
     * @param account Account address
     * @return Available balance and Pending balance
     */
    function getTokenBalances(address tokenAddress, address account) external view returns (uint256, uint256) {
        return (_tokenBalances[tokenAddress][account], _pendingTokenBalances[tokenAddress][account]);
    }

    /**
     * @dev Get Native balances of given token address and an account
     *
     * @param account Account address
     * @return Available balance and Pending balance
     */
    function getNativeBalances(address account) external view returns (uint256, uint256) {
        return (_nativeBalances[account], _pendingNativeBalances[account]);
    }

}