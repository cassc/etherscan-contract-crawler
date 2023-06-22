/**
 *Submitted for verification at Etherscan.io on 2019-10-31
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * (.note) This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * (.warning) `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise)
     * be too long), and then calling `toEthSignedMessageHash` on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * [`eth_sign`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign)
     * JSON-RPC method.
     *
     * See `recover`.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: contracts/token/SRC20Detailed.sol

pragma solidity ^0.5.0;

/**
 * @title SRC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract SRC20Detailed {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

// File: contracts/interfaces/ISRC20.sol

pragma solidity ^0.5.0;

/**
 * @title SRC20 public interface
 */
interface ISRC20 {

    event RestrictionsAndRulesUpdated(address restrictions, address rules);

    function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
        bytes32 msgHash, bytes calldata signature) external returns (bool);
    function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
        uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
    function getTransferNonce() external view returns (uint256);
    function getTransferNonce(address account) external view returns (uint256);
    function executeTransfer(address from, address to, uint256 value) external returns (bool);
    function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

    // ERC20 part-like interface
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}

// File: contracts/interfaces/ISRC20Managed.sol

pragma solidity ^0.5.0;

/**
    @title SRC20 interface for managers
 */
interface ISRC20Managed {
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    function burn(address account, uint256 value) external returns (bool);
    function mint(address account, uint256 value) external returns (bool);
}

// File: contracts/interfaces/ITransferRules.sol

pragma solidity ^0.5.0;

/**
 * @title ITransferRules interface
 * @dev Represents interface for any on-chain SRC20 transfer rules
 * implementation. Transfer Rules are expected to follow
 * same interface, managing multiply transfer rule implementations with
 * capabilities of managing what happens with tokens.
 *
 * This interface is working with ERC20 transfer() function
 */
interface ITransferRules {
    function setSRC(address src20) external returns (bool);
    function doTransfer(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/interfaces/IFreezable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available events
 * `AccountFrozen` and `AccountUnfroze` and it will make sure that any child
 * that implements all necessary functionality.
 */
contract IFreezable {
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    function _freezeAccount(address account) internal;
    function _unfreezeAccount(address account) internal;
    function _isAccountFrozen(address account) internal view returns (bool);
}

// File: contracts/interfaces/IPausable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the functions are implemented.
 */
contract IPausable{
    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool);

    function _pause() internal;
    function _unpause() internal;
}

// File: contracts/interfaces/IFeatured.sol

pragma solidity ^0.5.0;



/**
 * @dev Support for "SRC20 feature" modifier.
 */
contract IFeatured is IPausable, IFreezable {
    
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event TokenFrozen();
    event TokenUnfrozen();
    
    uint8 public constant ForceTransfer = 0x01;
    uint8 public constant Pausable = 0x02;
    uint8 public constant AccountBurning = 0x04;
    uint8 public constant AccountFreezing = 0x08;

    function _enable(uint8 features) internal;
    function isEnabled(uint8 feature) public view returns (bool);

    function checkTransfer(address from, address to) external view returns (bool);
    function isAccountFrozen(address account) external view returns (bool);
    function freezeAccount(address account) external;
    function unfreezeAccount(address account) external;
    function isTokenPaused() external view returns (bool);
    function pauseToken() external;
    function unPauseToken() external;
}

// File: contracts/interfaces/ISRC20Roles.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which allows children to implement access managements
 * with multiple roles.
 *
 * `Authority` the one how is authorized by token owner/issuer to authorize transfers
 * either on-chain or off-chain.
 *
 * `Delegate` the person who person responsible for updating KYA document
 *
 * `Manager` the person who is responsible for minting and burning the tokens. It should be
 * be registry contract where staking->minting is executed.
 */
contract ISRC20Roles {
    function isAuthority(address account) external view returns (bool);
    function removeAuthority(address account) external returns (bool);
    function addAuthority(address account) external returns (bool);

    function isDelegate(address account) external view returns (bool);
    function addDelegate(address account) external returns (bool);
    function removeDelegate(address account) external returns (bool);

    function manager() external view returns (address);
    function isManager(address account) external view returns (bool);
    function transferManagement(address newManager) external returns (bool);
    function renounceManagement() external returns (bool);
}

// File: contracts/interfaces/ITransferRestrictions.sol

pragma solidity ^0.5.0;

/**
 * @title ITransferRestrictions interface
 * @dev Represents interface for any on-chain SRC20 transfer restriction
 * implementation. Transfer Restriction registries are expected to follow
 * same interface, managing multiply transfer restriction implementations.
 *
 * It is intended to implementation of this interface be used for transferToken()
 */
interface ITransferRestrictions {
    function authorize(address from, address to, uint256 value) external returns (bool);
}

// File: contracts/interfaces/IAssetRegistry.sol

pragma solidity ^0.5.0;

/**
 * AssetRegistry holds the real-world/offchain properties of the various Assets being tokenized.
 * It provides functions for getting/setting these properties.
 */
interface IAssetRegistry {

    event AssetAdded(address indexed src20, bytes32 kyaHash, string kyaUrl, uint256 AssetValueUSD);
    event AssetNVAUSDUpdated(address indexed src20, uint256 AssetValueUSD);
    event AssetKYAUpdated(address indexed src20, bytes32 kyaHash, string kyaUrl);

    function addAsset(address src20, bytes32 kyaHash, string calldata kyaUrl, uint256 netAssetValueUSD) external returns (bool);

    function getNetAssetValueUSD(address src20) external view returns (uint256);
    function updateNetAssetValueUSD(address src20, uint256 netAssetValueUSD) external returns (bool);

    function getKYA(address src20) external view returns (bytes32 kyaHash, string memory kyaUrl);
    function updateKYA(address src20, bytes32 kyaHash, string calldata kyaUrl) external returns (bool);

}

// File: contracts/token/SRC20.sol

pragma solidity ^0.5.0;














/**
 * @title SRC20 contract
 * @dev Base SRC20 contract.
 */
contract SRC20 is ISRC20, ISRC20Managed, SRC20Detailed, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    uint256 public _totalSupply;
    uint256 public _maxTotalSupply;

    mapping(address => uint256) private _nonce;

    ISRC20Roles public _roles;
    IFeatured public _features;

    IAssetRegistry public _assetRegistry;

    /**
     * @description Configured contract implementing token restriction(s).
     * If set, transferToken will consult this contract should transfer
     * be allowed after successful authorization signature check.
     */
    ITransferRestrictions public _restrictions;

    /**
     * @description Configured contract implementing token rule(s).
     * If set, transfer will consult this contract should transfer
     * be allowed after successful authorization signature check.
     * And call doTransfer() in order for rules to decide where fund
     * should end up.
     */
    ITransferRules public _rules;

    modifier onlyAuthority() {
        require(_roles.isAuthority(msg.sender), "Caller not authority");
        _;
    }

    modifier onlyDelegate() {
        require(_roles.isDelegate(msg.sender), "Caller not delegate");
        _;
    }

    modifier onlyManager() {
        require(_roles.isManager(msg.sender), "Caller not manager");
        _;
    }

    modifier enabled(uint8 feature) {
        require(_features.isEnabled(feature), "Token feature is not enabled");
        _;
    }

    // Constructors
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 maxTotalSupply,
        address[] memory addressList
                    //  addressList[0] tokenOwner,
                    //  addressList[1] restrictions,
                    //  addressList[2] rules,
                    //  addressList[3] roles,
                    //  addressList[4] featured,
                    //  addressList[5] assetRegistry
    )
    SRC20Detailed(name, symbol, decimals)
    public
    {
        _assetRegistry = IAssetRegistry(addressList[5]);
        _transferOwnership(addressList[0]);

        _maxTotalSupply = maxTotalSupply;
        _updateRestrictionsAndRules(addressList[1], addressList[2]);

        _roles = ISRC20Roles(addressList[3]);
        _features = IFeatured(addressList[4]);
    }

    /**
     * @dev This method is intended to be executed by TransferRules contract when doTransfer is called in transfer
     * and transferFrom methods to check where funds should go.
     *
     * @param from The address to transfer from.
     * @param to The address to send tokens to.
     * @param value The amount of tokens to send.
     */
    function executeTransfer(address from, address to, uint256 value) external onlyAuthority returns (bool) {
        _transfer(from, to, value);
        return true;
    }

    /**
     * Update the rules and restrictions settings for transfers.
     * Only a Delegate can call this role
     * 
     * @param restrictions address implementing on-chain restriction checks
     * or address(0) if no rules should be checked on chain.
     * @param rules address implementing on-chain restriction checks
     * @return True on success.
     */
    function updateRestrictionsAndRules(address restrictions, address rules) external onlyDelegate returns (bool) {
        return _updateRestrictionsAndRules(restrictions, rules);
    }

    /**
     * @dev Internal function to update the restrictions and rules contracts.
     * Emits RestrictionsAndRulesUpdated event.
     *
     * @param restrictions address implementing on-chain restriction checks
     *                     or address(0) if no rules should be checked on chain.
     * @param rules address implementing on-chain restriction checks
     * @return True on success.
     */
    function _updateRestrictionsAndRules(address restrictions, address rules) internal returns (bool) {

        _restrictions = ITransferRestrictions(restrictions);
        _rules = ITransferRules(rules);

        if (rules != address(0)) {
            require(_rules.setSRC(address(this)), "SRC20 contract already set in transfer rules");
        }

        emit RestrictionsAndRulesUpdated(restrictions, rules);
        return true;
    }

    /**
     * @dev Transfer token to specified address. Caller needs to provide authorization
     * signature obtained from MAP API, signed by authority accepted by token issuer.
     * Emits Transfer event.
     *
     * @param to The address to send tokens to.
     * @param value The amount of tokens to send.
     * @param nonce Token transfer nonce, can not repeat nonce for subsequent
     * token transfers.
     * @param expirationTime Timestamp until transfer request is valid.
     * @param hash Hash of transfer params (kyaHash, from, to, value, nonce, expirationTime).
     * @param signature Ethereum ECDSA signature of msgHash signed by one of authorities.
     * @return True on success.
     */
    function transferToken(
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes calldata signature
    )
        external returns (bool)
    {
        return _transferToken(msg.sender, to, value, nonce, expirationTime, hash, signature);
    }

    /**
     * @dev Transfer token to specified address. Caller needs to provide authorization
     * signature obtained from MAP API, signed by authority accepted by token issuer.
     * Whole allowance needs to be transferred.
     * Emits Transfer event.
     * Emits Approval event.
     *
     * @param from The address to transfer from.
     * @param to The address to send tokens to.
     * @param value The amount of tokens to send.
     * @param nonce Token transfer nonce, can not repeat nance for subsequent
     * token transfers.
     * @param expirationTime Timestamp until transfer request is valid.
     * @param hash Hash of transfer params (kyaHash, from, to, value, nonce, expirationTime).
     * @param signature Ethereum ECDSA signature of msgHash signed by one of authorities.
     * @return True on success.
     */
    function transferTokenFrom(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes calldata signature
    )
        external returns (bool)
    {
        _transferToken(from, to, value, nonce, expirationTime, hash, signature);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another, used by token issuer. This
    * call requires only that from address has enough tokens, all other checks are
    * skipped.
    * Emits Transfer event.
    * Allowed only to token owners. Require 'ForceTransfer' feature enabled.
    *
    * @param from The address which you want to send tokens from.
    * @param to The address to send tokens to.
    * @param value The amount of tokens to send.
    * @return True on success.
    */
    function transferTokenForced(address from, address to, uint256 value)
        external
        enabled(_features.ForceTransfer())
        onlyOwner
        returns (bool)
    {
        _transfer(from, to, value);
        return true;
    }

    // Nonce management
    /**
     * @dev Returns next nonce expected by transfer functions that require it.
     * After any successful transfer, nonce will be incremented.
     *
     * @return Nonce for next transfer function.
     */
    function getTransferNonce() external view returns (uint256) {
        return _nonce[msg.sender];
    }

    /**
     * @dev Returns nonce for account.
     *
     * @return Nonce for next transfer function.
     */
    function getTransferNonce(address account) external view returns (uint256) {
        return _nonce[account];
    }

    // Account token burning management
    /**
     * @dev Function that burns an amount of the token of a given
     * account.
     * Emits Transfer event, with to address set to zero.
     *
     * @return True on success.
     */
    function burnAccount(address account, uint256 value)
        external
        enabled(_features.AccountBurning())
        onlyOwner
        returns (bool)
    {
        _burn(account, value);
        return true;
    }

    // Token managed burning/minting
    /**
     * @dev Function that burns an amount of the token of a given
     * account.
     * Emits Transfer event, with to address set to zero.
     * Allowed only to manager.
     *
     * @return True on success.
     */
    function burn(address account, uint256 value) external onlyManager returns (bool) {
        _burn(account, value);
        return true;
    }

    /**
     * @dev Function that mints an amount of the token to a given
     * account.
     * Emits Transfer event, with from address set to zero.
     * Allowed only to manager.
     *
     * @return True on success.
     */
    function mint(address account, uint256 value) external onlyManager returns (bool) {
        _mint(account, value);
        return true;
    }

    // ERC20 part-like interface methods
    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * NOTE: Clients SHOULD make sure to create user interfaces in such a way that
     * they set the allowance first to 0 before setting it to another value for
     * the same spender. THOUGH The contract itself shouldn’t enforce it, to allow
     * backwards compatibility with contracts deployed before
     * Emit Approval event.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(_features.checkTransfer(msg.sender, to), "Feature transfer check");

        if (_rules != ITransferRules(0)) {
            require(_rules.doTransfer(msg.sender, to, value), "Transfer failed");
        } else {
            _transfer(msg.sender, to, value);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(_features.checkTransfer(from, to), "Feature transfer check");

        if (_rules != ITransferRules(0)) {
            _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
            require(_rules.doTransfer(from, to, value), "Transfer failed");
        } else {
            _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
            _transfer(from, to, value);
        }

        return true;
    }

    /**
     * @dev Atomically increase approved tokens to the spender on behalf of msg.sender.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens that allowance will be increase for.
     */
    function increaseAllowance(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(value));
        return true;
    }

    /**
     * @dev Atomically decrease approved tokens to the spender on behalf of msg.sender.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens that allowance will be reduced for.
     */
    function decreaseAllowance(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(value));
        return true;
    }

    // Privates
    /**
     * @dev Internal transfer token to specified address. Caller needs to provide authorization
     * signature obtained from MAP API, signed by authority accepted by token issuer.
     * Emits Transfer event.
     *
     * @param from The address to transfer from.
     * @param to The address to send tokens to.
     * @param value The amount of tokens to send.
     * @param nonce Token transfer nonce, can not repeat nance for subsequent
     * token transfers.
     * @param expirationTime Timestamp until transfer request is valid.
     * @param hash Hash of transfer params (kyaHash, from, to, value, nonce, expirationTime).
     * @param signature Ethereum ECDSA signature of msgHash signed by one of authorities.
     * @return True on success.
     */
    function _transferToken(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes memory signature
    )
        internal returns (bool)
    {
        if (address(_restrictions) != address(0)) {
            require(_restrictions.authorize(from, to, value), "transferToken restrictions failed");
        }

        require(now <= expirationTime, "transferToken params expired");
        require(nonce == _nonce[from], "transferToken params wrong nonce");

        (bytes32 kyaHash, string memory kyaUrl) = _assetRegistry.getKYA(address(this));

        require(
            keccak256(abi.encodePacked(kyaHash, from, to, value, nonce, expirationTime)) == hash,
            "transferToken params bad hash"
        );
        require(_roles.isAuthority(hash.toEthSignedMessageHash().recover(signature)), "transferToken params not authority");

        require(_features.checkTransfer(from, to), "Feature transfer check");
        _transfer(from, to, value);

        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Recipient is zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        _nonce[from]++;

        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * Emit Transfer event.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), 'burning from zero address');

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that mints an amount of the token on given
     * account.
     * Emit Transfer event.
     *
     * @param account The account where tokens will be minted.
     * @param value The amount that will be minted.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0), 'minting to zero address');

        _totalSupply = _totalSupply.add(value);
        require(_totalSupply <= _maxTotalSupply || _maxTotalSupply == 0, 'trying to mint too many tokens!');

        _balances[account] = _balances[account].add(value);

        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * NOTE: Clients SHOULD make sure to create user interfaces in such a way that
     * they set the allowance first to 0 before setting it to another value for
     * the same spender. THOUGH The contract itself shouldn’t enforce it, to allow
     * backwards compatibility with contracts deployed before
     * Emit Approval event.
     *
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), 'approve from the zero address');
        require(spender != address(0), 'approve to the zero address');

        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    /**
     * Perform multiple token transfers from the token owner's address.
     * The tokens should already be minted. If this function is to be called by
     * an actor other than the owner (a delegate), the owner has to call approve()
     * first to set up the delegate's allowance.
     *
     * @param _addresses an array of addresses to transfer to
     * @param _values an array of values
     * @return True on success
     */
    function bulkTransfer (
        address[] calldata _addresses, uint256[] calldata _values) external onlyDelegate returns (bool) {
        require(_addresses.length == _values.length, "Input dataset length mismatch");

        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            address to = _addresses[i];
            uint256 value = _values[i];
            _approve(owner(), msg.sender, _allowances[owner()][msg.sender].sub(value));
            _transfer(owner(), to, value);
        }

        return true;
    }

    /**
     * Perform multiple token transfers from the token owner's address.
     * The tokens should already be minted. If this function is to be called by
     * an actor other than the owner (a delegate), the owner has to call approve()
     * first to set up the delegate's allowance.
     *
     * Data needs to be packed correctly before calling this function.
     *
     * @param _lotSize number of tokens in the lot
     * @param _transfers an array or encoded transfers to perform
     * @return True on success
     */
    function encodedBulkTransfer (
        uint160 _lotSize, uint256[] calldata _transfers) external onlyDelegate returns (bool) {

        uint256 count = _transfers.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 tr = _transfers[i];
            uint256 value = (tr >> 160) * _lotSize;
            address to = address (tr & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            _approve(owner(), msg.sender, _allowances[owner()][msg.sender].sub(value));
            _transfer(owner(), to, value);
        }

        return true;
    }
}