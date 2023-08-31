/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

/**
 *Submitted for verification at Optimistic.Etherscan.io on 2023-06-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// Sources flattened with hardhat v2.16.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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


// File contracts/utils/PerformanceTokenManagerGamma.sol

pragma solidity 0.8.11;


interface PerformanceToken {
    function updatePerformanceFee(uint256 _perfFee) external;
    function withdrawFee() external;
    function transferOwnership(address newOwner) external;
    function token() external returns (address);
}

/**
 * @title PerformanceTokenManagerGamma
 * @dev Contract to manage Performance Tokens and act as a 1 out of 2 multisig.
 */
contract PerformanceTokenManagerGamma is Ownable {
    mapping(address => bool) public performanceTokenWhitelist; // Whitelist of Performance Tokens
    mapping(address => uint256) public tokenBalances; // Balances of Performance Tokens
    address public transferAddress; // Address to transfer tokens

    event TokenAddedToWhitelist(address indexed perfToken);
    event TokenRemovedFromWhitelist(address indexed perfToken);
    event FeeWithdrawn(address indexed perfToken, address indexed recipient, uint256 amount);
    event TokensEarned(address indexed perfToken, address indexed recipient, uint256 amount);
    event TransferAddressUpdated(address indexed previousAddress, address indexed newAddress);

    /**
     * @dev Adds a Performance Token to the whitelist.
     * @param perfToken The address of the Performance Token contract.
     */
    function addToWhitelist(address perfToken) external onlyOwner {
        performanceTokenWhitelist[perfToken] = true;
        emit TokenAddedToWhitelist(perfToken);
    }

    /**
     * @dev Removes a Performance Token from the whitelist.
     * @param perfToken The address of the Performance Token contract.
     */
    function removeFromWhitelist(address perfToken) external onlyOwner {
        performanceTokenWhitelist[perfToken] = false;
        emit TokenRemovedFromWhitelist(perfToken);
    }

    /**
     * @dev Checks if a Performance Token is whitelisted.
     * @param perfToken The address of the Performance Token contract.
     * @return A boolean indicating if the Performance Token is whitelisted.
     */
    function isWhitelisted(address perfToken) external view returns (bool) {
        return performanceTokenWhitelist[perfToken];
    }

    /**
     * @dev Sets the address to transfer tokens.
     * @param newAddress The new address to transfer tokens.
     */
    function setTransferAddress(address newAddress) external onlyOwner {
        emit TransferAddressUpdated(transferAddress, newAddress);
        transferAddress = newAddress;
    }

    /**
     * @dev Withdraws the performance fee from a Performance Token contract.
     * @param perfToken The address of the Performance Token contract.
     */
    function withdrawFee(address perfToken) external {
        require(performanceTokenWhitelist[perfToken], "Token not whitelisted");
        PerformanceToken(perfToken).withdrawFee();
        emit FeeWithdrawn(perfToken, msg.sender, 0);
    }

    /**
     * @dev Transfers the entire balance of ERC20 tokens held by the contract to the transfer address.
     * @param perfToken The address of the ERC20 token contract.
     * @return The amount of tokens transferred.
     */
    function transferUnderlying(address perfToken) external returns (uint256) {
        require(performanceTokenWhitelist[perfToken], "Token not whitelisted");
        IERC20 token = IERC20(PerformanceToken(perfToken).token());
        uint256 balance = token.balanceOf(address(this));
        token.transfer(transferAddress, balance);
        tokenBalances[perfToken] += balance;
        emit TokensEarned(perfToken, transferAddress, balance);
        return balance;
    }

    /**
     * @dev Allows the owner to call a target contract with specific data.
     * @param target The address of the target contract to call.
     * @param data The data to be sent to the target contract.
     * @return The result of the target contract call.
     */
    function ownerCall(address target, bytes memory data) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = target.call(data);
        require(success, "CallFailed");
        return result;
    }

    /**
     * @dev Updates the performance fee of a Performance Token contract.
     * @param perfToken The address of the Performance Token contract.
     * @param newFee The new performance fee to be set.
     */
    function updatePerformanceFee(address perfToken, uint256 newFee) external onlyOwner {
        require(performanceTokenWhitelist[perfToken], "Token not whitelisted");
        PerformanceToken(perfToken).updatePerformanceFee(newFee);
    }

    /**
     * @dev Transfers ownership of a Performance Token contract.
     * @param perfToken The address of the Performance Token contract.
     * @param newOwner The address of the new owner.
     */
    function transferTokenOwnership(address perfToken, address newOwner) external onlyOwner {
        require(performanceTokenWhitelist[perfToken], "Token not whitelisted");
        PerformanceToken(perfToken).transferOwnership(newOwner);
    }

    /**
     * @dev Allows the owner to remove any ETH stored in the contract.
     */
    function removeEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Transfers any ERC20 token held by the contract to a specified address.
     * @param _token The address of the Performance Token contract.
     * @return The amount of tokens transferred.
     */
    function transferAnyERC20(address _token) external onlyOwner returns (uint256) {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
        return balance;
    }
}