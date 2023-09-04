/**
 *Submitted for verification at Etherscan.io on 2023-07-07
*/

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// This contract allows 0xencrypt rug victims to claim Free Katana

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

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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

pragma solidity ^0.8.0;

interface OxEncrypt {
    function balanceOf(address account) external view returns (uint256);
}

interface Katana {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract ClaimKatana2 {
    OxEncrypt public Oxencrypt;
    Katana public Katana_;
    uint256 public claimRate;
    bool public claimWindowOpen;
    address public owner;

    mapping(address => bool) public hasClaimedTokens;
    mapping(address => bool) public holders;

    event ClaimWindowOpened();
    event ClaimWindowClosed();
    event TokensClaimed(address indexed recipient, uint256 amount);

    constructor(address oxencryptAddress, address katanaAddress, uint256 _claimRate) {
        Oxencrypt = OxEncrypt(oxencryptAddress);
        Katana_ = Katana(katanaAddress);
        claimRate = _claimRate;
        claimWindowOpen = false;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyHolder() {
        require(holders[msg.sender], "Only holders can claim tokens");
        _;
    }

    function addHolders(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address holder = addresses[i];
            if (Oxencrypt.balanceOf(holder) > 0) {
                holders[holder] = true;
            }
        }
    }

    function oxencryptClaim() external onlyHolder {
        require(claimWindowOpen, "Claim window is closed");
        require(!hasClaimedTokens[msg.sender], "Tokens already claimed");

        uint256 OxencryptBalance = Oxencrypt.balanceOf(msg.sender);
        require(OxencryptBalance > 0, "Must hold Token A to claim Token B");

        uint256 KatanaAmount = (OxencryptBalance * claimRate) / 100;
        Katana_.transfer(msg.sender, KatanaAmount);

        hasClaimedTokens[msg.sender] = true;

        emit TokensClaimed(msg.sender, KatanaAmount);
    }

    function startClaims() external onlyOwner {
        require(!claimWindowOpen, "Claim window is already open");

        claimWindowOpen = true;

        emit ClaimWindowOpened();
    }

    function stopClaims() external onlyOwner {
        require(claimWindowOpen, "Claim window is already closed");

        claimWindowOpen = false;

        emit ClaimWindowClosed();
    }
    }