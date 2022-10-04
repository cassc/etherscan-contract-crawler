/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
// File: SingleSlotBitArray.sol


pragma solidity ^0.8.0;

/**
 * @dev Library for managing a uint8 to bool mapping in a compact way.
 * Essentially a modified version of OpenZeppelin's BitMaps contract.
 */
library SingleSlotBitArray {
    /**
     * @dev A single uint256 that contains all bits of storage.
     */
    struct BitArray256 {
        uint256 storedValue;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitArray256 storage bitArray, uint8 index) internal view returns (bool) {
        uint256 mask = 1 << (index & 0xff);
        return bitArray.storedValue & mask != 0;
    }
    
    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function set(BitArray256 storage bitArray, uint8 index, bool value) internal {
        uint256 mask = 1 << (index & 0xff);
        if (value) {
            // Set the bit
            bitArray.storedValue |= mask;
        } else {
            // Unset the bit
            bitArray.storedValue &= ~mask;
        }
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: CKRegistry.sol



pragma solidity ^0.8.17;



/**
 * @dev A contract that attests to proofs of complete knowledge
 */
interface ICKVerifier {
    /**
     * @dev Returns true if the address has shown a proof of complete knowledge
     * to this verifier.
     */
    function isCKVerified(address addr) external returns (bool);
}

/**
 * @dev A registry containing addresses that have provided proofs of complete
 * knowledge.
 */
contract CKRegistry is Ownable {
    /**
     * @dev Maps addresses to a value containing the verifications. Up to 256
     * verification bits can be used per address to denote different verification
     * types.
     */
    mapping (address => SingleSlotBitArray.BitArray256) public verifications;
    
    /**
     * @dev A bit array denoting which verification bits are accepted as evidence
     * of a CK proof. This value can be updated to revoke proofs if a particular
     * CK verification method is deemed to be insecure in the future.
     *
     * If this value is set to 0 by the contract owner, then the `isCK` function would
     * not accept any verification type at all.
     *
     * Note that it is possible for verifier addresses to continue to set the
     * bits that are not trusted by this variable. This might be useful if
     * external contracts have different trust settings.
     */
    SingleSlotBitArray.BitArray256 public trustedVerificationBits;
    
    /**
     * @dev A mapping of addresses to verification bits (plus one). The default storage
     * slot value, 0, remains unprivileged.
     */
    mapping (address => uint256) public verifierAddresses;
    
    /**
     * @dev Emitted when an address becomes a verifier for a specific verification bit
     */
    event VerifierAssigned(address indexed verifier, uint8 indexed bit);
    
    /**
     * @dev Emitted when an address is removed from the verifiers set
     */
    event VerifierRemoved(address indexed verifier);
    
    /**
     * @dev Emitted when an address successfully sets a verification bit
     */
    event VerificationBitSet(
        address indexed userAddress,
        ICKVerifier indexed verifierAddress,
        uint8 indexed vBit
    );
    
    /**
     * @dev Returns whether a particular address has provided a proof of complete
     * knowledge per the current state of trust given by `trustedVerificationBits`.
     */
    function isCK(address addr) public view returns (bool) {
        return verifications[addr].storedValue & trustedVerificationBits.storedValue != 0;
    }
    
    /**
     * @dev Returns whether a particular address has provided a proof of complete
     * knowledge using any verifier at any time in the past.
     */
    function isCKAny(address addr) public view returns (bool) {
        return verifications[addr].storedValue != 0;
    }
    
    /**
     * @dev Sets a verification bit as trusted or not.
     */
    function trustVerificationBit(uint8 bit, bool trusted) public onlyOwner {
        SingleSlotBitArray.set(trustedVerificationBits, bit, trusted);
    }
    
    /**
     * @dev Assigns the power of setting a verification bit to an address. Note that
     * more than one address can be assigned to a single verification bit. Addresses
     * might share the same verification bit if they are very similar, e.g. for minor
     * contract upgrades.
     */
    function assignVerifierAddress(address verifierAddress, uint8 bit) public onlyOwner {
        verifierAddresses[verifierAddress] = uint256(bit) + 1;
        emit VerifierAssigned(verifierAddress, bit);
    }
    
    /**
     * @dev Revokes verification bit setting privileges from an address.
     *
     * Note: This function might be used without also removing the bit from
     * `trustedVerificationBits` when a certain verifier was known to produce
     * true results for previous verifications but is not guaranteed to do
     * so in the future.
     */
    function removeVerifierAddress(address verifierAddress) public onlyOwner {
        verifierAddresses[verifierAddress] = 0;
        emit VerifierRemoved(verifierAddress);
    }
    
    /**
     * @dev Assigns the verification bit of an address that has provided a
     * proof of complete knowledge to a verifier.
     */
    function registerCK(address userAddress, ICKVerifier verifierAddress) public {
        uint256 vBitPlusOne = verifierAddresses[address(verifierAddress)];
        require(vBitPlusOne > 0, "CKRegistry: Verifier address is not authorized");
        bool didVerify = verifierAddress.isCKVerified(userAddress);
        require(didVerify, "CKRegistry: Verifier needs proof");
        uint8 vBit = uint8(vBitPlusOne - 1);
        SingleSlotBitArray.set(verifications[userAddress], vBit, true);
        emit VerificationBitSet(userAddress, verifierAddress, vBit);
    }
}