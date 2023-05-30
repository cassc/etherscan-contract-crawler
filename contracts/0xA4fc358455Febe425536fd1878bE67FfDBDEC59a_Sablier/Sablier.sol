/**
 *Submitted for verification at Etherscan.io on 2019-11-12
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.2;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard is Initializable {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    function initialize() public initializer {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }

    uint256[50] private ______gap;
}

// File: @sablier/shared-contracts/compound/CarefulMath.sol

pragma solidity ^0.5.8;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// File: @sablier/shared-contracts/compound/Exponential.sol

pragma solidity ^0.5.8;


/**
 * @title Exponential module for storing fixed-decision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa; //TODO: Add some simple tests and this in another PR yo.
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
}

// File: @sablier/shared-contracts/interfaces/ICERC20.sol

pragma solidity 0.5.11;

/**
 * @title CERC20 interface
 * @author Sablier
 * @dev See https://compound.finance/developers
 */
interface ICERC20 {
    function balanceOf(address who) external view returns (uint256);

    function isCToken() external view returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOfUnderlying(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they not should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, with should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @sablier/shared-contracts/lifecycle/OwnableWithoutRenounce.sol

pragma solidity 0.5.11;



/**
 * @title OwnableWithoutRenounce
 * @author Sablier
 * @dev Fork of OpenZeppelin's Ownable contract, which provides basic authorization control, but with
 *  the `renounceOwnership` function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/ownership/Ownable.sol
 * See https://forum.openzeppelin.com/t/contract-request-ownable-without-renounceownership/1400
 * See https://docs.openzeppelin.com/contracts/2.x/gsn#_msg_sender_and_msg_data
 */
contract OwnableWithoutRenounce is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: @sablier/shared-contracts/lifecycle/PauserRoleWithoutRenounce.sol

pragma solidity ^0.5.0;




/**
 * @title PauserRoleWithoutRenounce
 * @author Sablier
 * @notice Fork of OpenZeppelin's PauserRole, but with the `renouncePauser` function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/access/roles/PauserRole.sol
 */

contract PauserRoleWithoutRenounce is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}

// File: @sablier/shared-contracts/lifecycle/PausableWithoutRenounce.sol

pragma solidity 0.5.11;




/**
 * @title PausableWithoutRenounce
 * @author Sablier
 * @notice Fork of OpenZeppelin's Pausable, a contract module which allows children to implement an
 *  emergency stop mechanism that can be triggered by an authorized account, but with the `renouncePauser`
 *  function removed to avoid fat-finger errors.
 *  We inherit from `Context` to keep this contract compatible with the Gas Station Network.
 * See https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/lifecycle/Pausable.sol
 * See https://docs.openzeppelin.com/contracts/2.x/gsn#_msg_sender_and_msg_data
 */
contract PausableWithoutRenounce is Initializable, Context, PauserRoleWithoutRenounce {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    function initialize(address sender) public initializer {
        PauserRoleWithoutRenounce.initialize(sender);
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/interfaces/ICTokenManager.sol

pragma solidity 0.5.11;

/**
 * @title CTokenManager Interface
 * @author Sablier
 */
interface ICTokenManager {
    /**
     * @notice Emits when the owner discards a cToken.
     */
    event DiscardCToken(address indexed tokenAddress);

    /**
     * @notice Emits when the owner whitelists a cToken.
     */
    event WhitelistCToken(address indexed tokenAddress);

    function whitelistCToken(address tokenAddress) external;

    function discardCToken(address tokenAddress) external;

    function isCToken(address tokenAddress) external view returns (bool);
}

// File: contracts/interfaces/IERC1620.sol

pragma solidity 0.5.11;

/**
 * @title ERC-1620 Money Streaming Standard
 * @author Paul Razvan Berg - <[email protected]>
 * @dev See https://eips.ethereum.org/EIPS/eip-1620
 */
interface IERC1620 {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address token,
            uint256 startTime,
            uint256 stopTime,
            uint256 balance,
            uint256 rate
        );

    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId);

    function withdrawFromStream(uint256 streamId, uint256 funds) external returns (bool);

    function cancelStream(uint256 streamId) external returns (bool);
}

// File: contracts/Types.sol

pragma solidity 0.5.11;


/**
 * @title Sablier Types
 * @author Sablier
 */
library Types {
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        bool isEntity;
    }

    struct CompoundingStreamVars {
        Exponential.Exp exchangeRateInitial;
        Exponential.Exp senderShare;
        Exponential.Exp recipientShare;
        bool isEntity;
    }
}

// File: contracts/Sablier.sol

pragma solidity 0.5.11;










/**
 * @title Sablier's Money Streaming
 * @author Sablier
 */
contract Sablier is IERC1620, OwnableWithoutRenounce, PausableWithoutRenounce, Exponential, ReentrancyGuard {
    /*** Storage Properties ***/

    /**
     * @notice In Exp terms, 1e18 is 1, or 100%
     */
    uint256 constant hundredPercent = 1e18;

    /**
     * @notice In Exp terms, 1e16 is 0.01, or 1%
     */
    uint256 constant onePercent = 1e16;

    /**
     * @notice Stores information about the initial state of the underlying of the cToken.
     */
    mapping(uint256 => Types.CompoundingStreamVars) private compoundingStreamsVars;

    /**
     * @notice An instance of CTokenManager, responsible for whitelisting and discarding cTokens.
     */
    ICTokenManager public cTokenManager;

    /**
     * @notice The amount of interest has been accrued per token address.
     */
    mapping(address => uint256) private earnings;

    /**
     * @notice The percentage fee charged by the contract on the accrued interest.
     */
    Exp public fee;

    /**
     * @notice Counter for new stream ids.
     */
    uint256 public nextStreamId;

    /**
     * @notice The stream objects identifiable by their unsigned integer ids.
     */
    mapping(uint256 => Types.Stream) private streams;

    /*** Events ***/

    /**
     * @notice Emits when a compounding stream is successfully created.
     */
    event CreateCompoundingStream(
        uint256 indexed streamId,
        uint256 exchangeRate,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    );

    /**
     * @notice Emits when the owner discards a cToken.
     */
    event PayInterest(
        uint256 indexed streamId,
        uint256 senderInterest,
        uint256 recipientInterest,
        uint256 sablierInterest
    );

    /**
     * @notice Emits when the owner takes the earnings.
     */
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);

    /**
     * @notice Emits when the owner updates the percentage fee.
     */
    event UpdateFee(uint256 indexed fee);

    /*** Modifiers ***/

    /**
     * @dev Throws if the caller is not the sender of the recipient of the stream.
     */
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

    /**
     * @dev Throws if the id does not point to a valid stream.
     */
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }

    /**
     * @dev Throws if the id does not point to a valid compounding stream.
     */
    modifier compoundingStreamExists(uint256 streamId) {
        require(compoundingStreamsVars[streamId].isEntity, "compounding stream does not exist");
        _;
    }

    /*** Contract Logic Starts Here */

    constructor(address cTokenManagerAddress) public {
        require(cTokenManagerAddress != address(0x00), "cTokenManager contract is the zero address");
        OwnableWithoutRenounce.initialize(msg.sender);
        PausableWithoutRenounce.initialize(msg.sender);
        cTokenManager = ICTokenManager(cTokenManagerAddress);
        nextStreamId = 1;
    }

    /*** Owner Functions ***/

    struct UpdateFeeLocalVars {
        MathError mathErr;
        uint256 feeMantissa;
    }

    /**
     * @notice Updates the Sablier fee.
     * @dev Throws if the caller is not the owner of the contract.
     *  Throws if `feePercentage` is not lower or equal to 100.
     * @param feePercentage The new fee as a percentage.
     */
    function updateFee(uint256 feePercentage) external onlyOwner {
        require(feePercentage <= 100, "fee percentage higher than 100%");
        UpdateFeeLocalVars memory vars;

        /* `feePercentage` will be stored as a mantissa, so we scale it up by one percent in Exp terms. */
        (vars.mathErr, vars.feeMantissa) = mulUInt(feePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent`
         * and we know `feePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        fee = Exp({ mantissa: vars.feeMantissa });
        emit UpdateFee(feePercentage);
    }

    struct TakeEarningsLocalVars {
        MathError mathErr;
    }

    /**
     * @notice Withdraws the earnings for the given token address.
     * @dev Throws if `amount` exceeds the available balance.
     * @param tokenAddress The address of the token to withdraw earnings for.
     * @param amount The amount of tokens to withdraw.
     */
    function takeEarnings(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        require(amount > 0, "amount is zero");
        require(earnings[tokenAddress] >= amount, "amount exceeds the available balance");

        TakeEarningsLocalVars memory vars;
        (vars.mathErr, earnings[tokenAddress]) = subUInt(earnings[tokenAddress], amount);
        /*
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `earnings[tokenAddress]`
         * is at least as big as `amount`.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        emit TakeEarnings(tokenAddress, amount);
        require(IERC20(tokenAddress).transfer(msg.sender, amount), "token transfer failure");
    }

    /*** View Functions ***/

    /**
     * @notice Returns the compounding stream with all its properties.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream to query.
     * @return The stream object.
     */
    function getStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
    }

    /**
     * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
     *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
     *  `startTime`, it returns 0.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for whom to query the delta.
     * @return The time delta in seconds.
     */
    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    /**
     * @notice Returns the available funds for the given stream id and address.
     * @dev Throws if the id does not point to a valid stream.
     * @param streamId The id of the stream for whom to query the balance.
     * @param who The address for whom to query the balance.
     * @return The total funds allocated to `who` as uint256.
     */
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.recipientBalance) = mulUInt(delta, stream.ratePerSecond);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance calculation error");

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(stream.deposit, stream.remainingBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);
            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);
            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    /**
     * @notice Checks if the given id points to a compounding stream.
     * @param streamId The id of the compounding stream to check.
     * @return bool true=it is compounding stream, otherwise false.
     */
    function isCompoundingStream(uint256 streamId) public view returns (bool) {
        return compoundingStreamsVars[streamId].isEntity;
    }

    /**
     * @notice Returns the compounding stream object with all its properties.
     * @dev Throws if the id does not point to a valid compounding stream.
     * @param streamId The id of the compounding stream to query.
     * @return The compounding stream object.
     */
    function getCompoundingStream(uint256 streamId)
        external
        view
        streamExists(streamId)
        compoundingStreamExists(streamId)
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 exchangeRateInitial,
            uint256 senderSharePercentage,
            uint256 recipientSharePercentage
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        exchangeRateInitial = compoundingStreamsVars[streamId].exchangeRateInitial.mantissa;
        senderSharePercentage = compoundingStreamsVars[streamId].senderShare.mantissa;
        recipientSharePercentage = compoundingStreamsVars[streamId].recipientShare.mantissa;
    }

    struct InterestOfLocalVars {
        MathError mathErr;
        Exp exchangeRateDelta;
        Exp underlyingInterest;
        Exp netUnderlyingInterest;
        Exp senderUnderlyingInterest;
        Exp recipientUnderlyingInterest;
        Exp sablierUnderlyingInterest;
        Exp senderInterest;
        Exp recipientInterest;
        Exp sablierInterest;
    }

    /**
     * @notice Computes the interest accrued by keeping the amount of tokens in the contract. Returns (0, 0, 0) if
     *  the stream is not a compounding stream.
     * @dev Throws if there is a math error. We do not assert the calculations which involve the current
     *  exchange rate, because we can't know what value we'll get back from the cToken contract.
     * @return The interest accrued by the sender, the recipient and sablier, respectively, as uint256s.
     */
    function interestOf(uint256 streamId, uint256 amount)
        public
        streamExists(streamId)
        returns (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            return (0, 0, 0);
        }
        Types.Stream memory stream = streams[streamId];
        Types.CompoundingStreamVars memory compoundingStreamVars = compoundingStreamsVars[streamId];
        InterestOfLocalVars memory vars;

        /*
         * The exchange rate delta is a key variable, since it leads us to how much interest has been earned
         * since the compounding stream was created.
         */
        Exp memory exchangeRateCurrent = Exp({ mantissa: ICERC20(stream.tokenAddress).exchangeRateCurrent() });
        if (exchangeRateCurrent.mantissa <= compoundingStreamVars.exchangeRateInitial.mantissa) {
            return (0, 0, 0);
        }
        (vars.mathErr, vars.exchangeRateDelta) = subExp(exchangeRateCurrent, compoundingStreamVars.exchangeRateInitial);
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Calculate how much interest has been earned by holding `amount` in the smart contract. */
        (vars.mathErr, vars.underlyingInterest) = mulScalar(vars.exchangeRateDelta, amount);
        require(vars.mathErr == MathError.NO_ERROR, "interest calculation error");

        /* Calculate our share from that interest. */
        if (fee.mantissa == hundredPercent) {
            (vars.mathErr, vars.sablierInterest) = divExp(vars.underlyingInterest, exchangeRateCurrent);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");
            return (0, 0, truncate(vars.sablierInterest));
        } else if (fee.mantissa == 0) {
            vars.sablierUnderlyingInterest = Exp({ mantissa: 0 });
            vars.netUnderlyingInterest = vars.underlyingInterest;
        } else {
            (vars.mathErr, vars.sablierUnderlyingInterest) = mulExp(vars.underlyingInterest, fee);
            require(vars.mathErr == MathError.NO_ERROR, "sablier interest calculation error");

            /* Calculate how much interest is left for the sender and the recipient. */
            (vars.mathErr, vars.netUnderlyingInterest) = subExp(
                vars.underlyingInterest,
                vars.sablierUnderlyingInterest
            );
            /*
             * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `sablierUnderlyingInterest`
             * is less or equal than `underlyingInterest`, because we control the value of `fee`.
             */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        /* Calculate the sender's share of the interest. */
        (vars.mathErr, vars.senderUnderlyingInterest) = mulExp(
            vars.netUnderlyingInterest,
            compoundingStreamVars.senderShare
        );
        require(vars.mathErr == MathError.NO_ERROR, "sender interest calculation error");

        /* Calculate the recipient's share of the interest. */
        (vars.mathErr, vars.recipientUnderlyingInterest) = subExp(
            vars.netUnderlyingInterest,
            vars.senderUnderlyingInterest
        );
        /*
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `senderUnderlyingInterest`
         * is less or equal than `netUnderlyingInterest`, because `senderShare` is bounded between 1e16 and 1e18.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Convert the interest to the equivalent cToken denomination. */
        (vars.mathErr, vars.senderInterest) = divExp(vars.senderUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sender interest conversion error");

        (vars.mathErr, vars.recipientInterest) = divExp(vars.recipientUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "recipient interest conversion error");

        (vars.mathErr, vars.sablierInterest) = divExp(vars.sablierUnderlyingInterest, exchangeRateCurrent);
        require(vars.mathErr == MathError.NO_ERROR, "sablier interest conversion error");

        /* Truncating the results means losing everything on the last 1e18 positions of the mantissa */
        return (truncate(vars.senderInterest), truncate(vars.recipientInterest), truncate(vars.sablierInterest));
    }

    /**
     * @notice Returns the amount of interest that has been accrued for the given token address.
     * @param tokenAddress The address of the token to get the earnings for.
     * @return The amount of interest as uint256.
     */
    function getEarnings(address tokenAddress) external view returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "token is not cToken");
        return earnings[tokenAddress];
    }

    /*** Public Effects & Interactions Functions ***/

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 ratePerSecond;
    }

    /**
     * @notice Creates a new stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Throws if paused.
     *  Throws if the recipient is the zero address, the contract itself or the caller.
     *  Throws if the deposit is 0.
     *  Throws if the start time is before `block.timestamp`.
     *  Throws if the stop time is before the start time.
     *  Throws if the duration calculation has a math error.
     *  Throws if the deposit is smaller than the duration.
     *  Throws if the deposit is not a multiple of the duration.
     *  Throws if the rate calculation has a math error.
     *  Throws if the next stream id calculation has a math error.
     *  Throws if the contract is not allowed to transfer enough tokens.
     *  Throws if there is a token transfer failure.
     * @param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @return The uint256 id of the newly created stream.
     */
    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime)
        public
        whenNotPaused
        returns (uint256)
    {
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");

        CreateStreamLocalVars memory vars;
        (vars.mathErr, vars.duration) = subUInt(stopTime, startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        require(deposit % vars.duration == 0, "deposit not multiple of time delta");

        (vars.mathErr, vars.ratePerSecond) = divUInt(deposit, vars.duration);
        /* `divUInt` can only return MathError.DIVISION_BY_ZERO but we know `duration` is not zero. */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Types.Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress
        });

        /* Increment the next stream id. */
        (vars.mathErr, nextStreamId) = addUInt(nextStreamId, uint256(1));
        require(vars.mathErr == MathError.NO_ERROR, "next stream id calculation error");

        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), deposit), "token transfer failure");
        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime);
        return streamId;
    }

    struct CreateCompoundingStreamLocalVars {
        MathError mathErr;
        uint256 shareSum;
        uint256 underlyingBalance;
        uint256 senderShareMantissa;
        uint256 recipientShareMantissa;
    }

    /**
     * @notice Creates a new compounding stream funded by `msg.sender` and paid towards `recipient`.
     * @dev Inherits all security checks from `createStream`.
     *  Throws if the cToken is not whitelisted.
     *  Throws if the sender share percentage and the recipient share percentage do not sum up to 100.
     *  Throws if the the sender share mantissa calculation has a math error.
     *  Throws if the the recipient share mantissa calculation has a math error.
     * @param recipient The address towards which the money is streamed.
     * @param deposit The amount of money to be streamed.
     * @param tokenAddress The ERC20 token to use as streaming currency.
     * @param startTime The unix timestamp for when the stream starts.
     * @param stopTime The unix timestamp for when the stream stops.
     * @param senderSharePercentage The sender's share of the interest, as a percentage.
     * @param recipientSharePercentage The recipient's share of the interest, as a percentage.
     * @return The uint256 id of the newly created compounding stream.
     */
    function createCompoundingStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external whenNotPaused returns (uint256) {
        require(cTokenManager.isCToken(tokenAddress), "cToken is not whitelisted");
        CreateCompoundingStreamLocalVars memory vars;

        /* Ensure that the interest shares sum up to 100%. */
        (vars.mathErr, vars.shareSum) = addUInt(senderSharePercentage, recipientSharePercentage);
        require(vars.mathErr == MathError.NO_ERROR, "share sum calculation error");
        require(vars.shareSum == 100, "shares do not sum up to 100");

        uint256 streamId = createStream(recipient, deposit, tokenAddress, startTime, stopTime);

        /*
         * `senderSharePercentage` and `recipientSharePercentage` will be stored as mantissas, so we scale them up
         * by one percent in Exp terms.
         */
        (vars.mathErr, vars.senderShareMantissa) = mulUInt(senderSharePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent` and
         * we know `senderSharePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        (vars.mathErr, vars.recipientShareMantissa) = mulUInt(recipientSharePercentage, onePercent);
        /*
         * `mulUInt` can only return MathError.INTEGER_OVERFLOW but we control `onePercent` and
         * we know `recipientSharePercentage` is maximum 100.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        /* Create and store the compounding stream vars. */
        uint256 exchangeRateCurrent = ICERC20(tokenAddress).exchangeRateCurrent();
        compoundingStreamsVars[streamId] = Types.CompoundingStreamVars({
            exchangeRateInitial: Exp({ mantissa: exchangeRateCurrent }),
            isEntity: true,
            recipientShare: Exp({ mantissa: vars.recipientShareMantissa }),
            senderShare: Exp({ mantissa: vars.senderShareMantissa })
        });

        emit CreateCompoundingStream(streamId, exchangeRateCurrent, senderSharePercentage, recipientSharePercentage);
        return streamId;
    }

    /**
     * @notice Withdraws from the contract to the recipient's account.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if the amount exceeds the available balance.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to withdraw tokens from.
     * @param amount The amount of tokens to withdraw.
     * @return bool true=success, otherwise false.
     */
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Types.Stream memory stream = streams[streamId];
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "amount exceeds the available balance");

        if (!compoundingStreamsVars[streamId].isEntity) {
            withdrawFromStreamInternal(streamId, amount);
        } else {
            withdrawFromCompoundingStreamInternal(streamId, amount);
        }
        return true;
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev Throws if the id does not point to a valid stream.
     *  Throws if the caller is not the sender or the recipient of the stream.
     *  Throws if there is a token transfer failure.
     * @param streamId The id of the stream to cancel.
     * @return bool true=success, otherwise false.
     */
    function cancelStream(uint256 streamId)
        external
        nonReentrant
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        if (!compoundingStreamsVars[streamId].isEntity) {
            cancelStreamInternal(streamId);
        } else {
            cancelCompoundingStreamInternal(streamId);
        }
        return true;
    }

    /*** Internal Effects & Interactions Functions ***/

    struct WithdrawFromStreamInternalLocalVars {
        MathError mathErr;
    }

    /**
     * @notice Makes the withdrawal to the recipient of the stream.
     * @dev If the stream balance has been depleted to 0, the stream object is deleted
     *  to save gas and optimise contract storage.
     *  Throws if the stream balance calculation has a math error.
     *  Throws if there is a token transfer failure.
     */
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromStreamInternalLocalVars memory vars;
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        /**
         * `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know that `remainingBalance` is at least
         * as big as `amount`. See the `require` check in `withdrawFromInternal`.
         */
        assert(vars.mathErr == MathError.NO_ERROR);

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];

        require(IERC20(stream.tokenAddress).transfer(stream.recipient, amount), "token transfer failure");
        emit WithdrawFromStream(streamId, stream.recipient, amount);
    }

    struct WithdrawFromCompoundingStreamInternalLocalVars {
        MathError mathErr;
        uint256 amountWithoutSenderInterest;
        uint256 netWithdrawalAmount;
    }

    /**
     * @notice Withdraws to the recipient's account and pays the accrued interest to all parties.
     * @dev If the stream balance has been depleted to 0, the stream object to save gas and optimise
     *  contract storage.
     *  Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     */
    function withdrawFromCompoundingStreamInternal(uint256 streamId, uint256 amount) internal {
        Types.Stream memory stream = streams[streamId];
        WithdrawFromCompoundingStreamInternalLocalVars memory vars;

        /* Calculate the interest earned by each party for keeping `stream.balance` in the smart contract. */
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(streamId, amount);

        /*
         * Calculate the net withdrawal amount by subtracting `senderInterest` and `sablierInterest`.
         * Because the decimal points are lost when we truncate Exponentials, the recipient will implicitly earn
         * `recipientInterest` plus a tiny-weeny amount of interest, max 2e-8 in cToken denomination.
         */
        (vars.mathErr, vars.amountWithoutSenderInterest) = subUInt(amount, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "amount without sender interest calculation error");
        (vars.mathErr, vars.netWithdrawalAmount) = subUInt(vars.amountWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net withdrawal amount calculation error");

        /* Subtract `amount` from the remaining balance of the stream. */
        (vars.mathErr, streams[streamId].remainingBalance) = subUInt(stream.remainingBalance, amount);
        require(vars.mathErr == MathError.NO_ERROR, "balance subtraction calculation error");

        /* Delete the objects from storage if the remaining balance has been depleted to 0. */
        if (streams[streamId].remainingBalance == 0) {
            delete streams[streamId];
            delete compoundingStreamsVars[streamId];
        }

        /* Add the sablier interest to the earnings for this cToken. */
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

        /* Transfer the tokens to the sender and the recipient. */
        ICERC20 cToken = ICERC20(stream.tokenAddress);
        if (senderInterest > 0)
            require(cToken.transfer(stream.sender, senderInterest), "sender token transfer failure");
        require(cToken.transfer(stream.recipient, vars.netWithdrawalAmount), "recipient token transfer failure");

        emit WithdrawFromStream(streamId, stream.recipient, vars.netWithdrawalAmount);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }

    /**
     * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
     * @dev The stream and compounding stream vars objects get deleted to save gas
     *  and optimise contract storage.
     *  Throws if there is a token transfer failure.
     */
    function cancelStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        delete streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
        if (recipientBalance > 0)
            require(token.transfer(stream.recipient, recipientBalance), "recipient token transfer failure");
        if (senderBalance > 0) require(token.transfer(stream.sender, senderBalance), "sender token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    struct CancelCompoundingStreamInternal {
        MathError mathErr;
        uint256 netSenderBalance;
        uint256 recipientBalanceWithoutSenderInterest;
        uint256 netRecipientBalance;
    }

    /**
     * @notice Cancels the stream, transfers the tokens back on a pro rata basis and pays the accrued
     * interest to all parties.
     * @dev Importantly, the money that has not been streamed yet is not considered chargeable.
     *  All the interest generated by that underlying will be returned to the sender.
     *  Throws if there is a math error.
     *  Throws if there is a token transfer failure.
     */
    function cancelCompoundingStreamInternal(uint256 streamId) internal {
        Types.Stream memory stream = streams[streamId];
        CancelCompoundingStreamInternal memory vars;

        /*
         * The sender gets back all the money that has not been streamed so far. By that, we mean both
         * the underlying amount and the interest generated by it.
         */
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        /* Calculate the interest earned by each party for keeping `recipientBalance` in the smart contract. */
        (uint256 senderInterest, uint256 recipientInterest, uint256 sablierInterest) = interestOf(
            streamId,
            recipientBalance
        );

        /*
         * We add `senderInterest` to `senderBalance` to compute the net balance for the sender.
         * After this, the rest of the function is similar to `withdrawFromCompoundingStreamInternal`, except
         * we add the sender's share of the interest generated by `recipientBalance` to `senderBalance`.
         */
        (vars.mathErr, vars.netSenderBalance) = addUInt(senderBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net sender balance calculation error");

        /*
         * Calculate the net withdrawal amount by subtracting `senderInterest` and `sablierInterest`.
         * Because the decimal points are lost when we truncate Exponentials, the recipient will implicitly earn
         * `recipientInterest` plus a tiny-weeny amount of interest, max 2e-8 in cToken denomination.
         */
        (vars.mathErr, vars.recipientBalanceWithoutSenderInterest) = subUInt(recipientBalance, senderInterest);
        require(vars.mathErr == MathError.NO_ERROR, "recipient balance without sender interest calculation error");
        (vars.mathErr, vars.netRecipientBalance) = subUInt(vars.recipientBalanceWithoutSenderInterest, sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "net recipient balance calculation error");

        /* Add the sablier interest to the earnings attributed to this cToken. */
        (vars.mathErr, earnings[stream.tokenAddress]) = addUInt(earnings[stream.tokenAddress], sablierInterest);
        require(vars.mathErr == MathError.NO_ERROR, "earnings addition calculation error");

        /* Delete the objects from storage. */
        delete streams[streamId];
        delete compoundingStreamsVars[streamId];

        /* Transfer the tokens to the sender and the recipient. */
        IERC20 token = IERC20(stream.tokenAddress);
        if (vars.netSenderBalance > 0)
            require(token.transfer(stream.sender, vars.netSenderBalance), "sender token transfer failure");
        if (vars.netRecipientBalance > 0)
            require(token.transfer(stream.recipient, vars.netRecipientBalance), "recipient token transfer failure");

        emit CancelStream(streamId, stream.sender, stream.recipient, vars.netSenderBalance, vars.netRecipientBalance);
        emit PayInterest(streamId, senderInterest, recipientInterest, sablierInterest);
    }
}