/**
 *Submitted for verification at Etherscan.io on 2023-04-27
*/

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _enterNonReentrant();
        _;
        _exitNonReentrant();
    }

    function _enterNonReentrant() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        _require(_status != _ENTERED, Errors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _exitNonReentrant() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/// @notice Interface for managing list of addresses permitted to perform preferred rate
///         arbitrage swaps on Cron-Fi TWAMM V1.0.
///
interface IArbitrageurList {
  /// @param sender is the address that called the function changing list owner permissions.
  /// @param listOwner is the address to change list owner permissions on.
  /// @param permission is true if the address specified in listOwner is granted list owner
  ///        permissions. Is false otherwise.
  ///
  event ListOwnerPermissions(address indexed sender, address indexed listOwner, bool indexed permission);

  /// @param sender is the address that called the function changing arbitrageur permissions.
  /// @param arbitrageurs is a list of addresses to change arbitrage permissions on.
  /// @param permission is true if the addresses specified in arbitrageurs is granted
  ///        arbitrage permissions. Is false otherwise.
  ///
  event ArbitrageurPermissions(address indexed sender, address[] arbitrageurs, bool indexed permission);

  /// @param sender is the address that called the function changing the next list address.
  /// @param nextListAddress is the address the return value of the nextList function is set to.
  ///
  event NextList(address indexed sender, address indexed nextListAddress);

  /// @notice Returns true if the provide address is permitted the preferred
  ///         arbitrage rate in the partner swap method of a Cron-Fi TWAMM pool.
  ///         Returns false otherwise.
  /// @param _address the address to check for arbitrage rate permissions.
  ///
  function isArbitrageur(address _address) external returns (bool);

  /// @notice Returns the address of the next contract implementing the next list of arbitrageurs.
  ///         If the return value is the NULL address, address(0), then the TWAMM contract's update
  ///         list method will keep the existing address it is storing to check for arbitrage permissions.
  ///
  function nextList() external returns (address);
}

// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

address constant NULL_ADDR = address(0);

/// @notice Abstract contract for managing list of addresses permitted to perform preferred rate
///         arbitrage swaps on Cron-Fi TWAMM V1.0.
///
/// @dev    In Cron-Fi TWAMM V1.0 pools, the partner swap (preferred rate arbitrage swap) may only
///         be successfully called by an address that returns true when isArbitrageur in a contract
///         derived from this one (the caller must also specify the address of the arbitrage partner
///         to facilitate a call to isArbitrageur in the correct contract).
///
/// @dev    Two mechanisms are provided for updating the arbitrageur list, they are:
///             - The setArbitrageurs method, which allows a list of addresses to
///               be given or removed arbitrage permission.
///             - The nextList mechanism. In order to use this mechanism, a new contract deriving
///               from this contract with new arbitrage addresses specified must be deployed.
///               A listOwner then sets the nextList address to the newly deployed contract
///               address with the setNextList method.
///               Finally, the arbPartner address in the corresponding Cron-Fi TWAMM contract will
///               then call updateArbitrageList to retrieve the new arbitrageur list contract address
///               from this contract instance. Note that all previous arbitraguer contracts in the TWAMM
///               contract using the updated list are ignored.
///
/// @dev    Note that this is a bare-bones implementation without conveniences like a list to
///         inspect all current arbitraguer addresses at once (emitted events can be consulted and
///         aggregated off-chain for this purpose), however users are encouraged to modify the contract
///         as they wish as long as the following methods continue to function as specified:
///             - isArbitrageur
contract ArbitrageurListExample is IArbitrageurList, ReentrancyGuard {
  mapping(address => bool) private listOwners;
  mapping(address => bool) private permittedAddressMap;
  address public override(IArbitrageurList) nextList;

  modifier senderIsListOwner() {
    require(listOwners[msg.sender], "Sender must be listOwner");
    _;
  }

  /// @notice Constructs this contract with next contract and the specified list of addresses permitted
  ///         to arbitrage.
  /// @param _arbitrageurs is a list of addresses to give arbitrage permission to on contract instantiation.
  ///
  constructor(address[] memory _arbitrageurs) {
    bool permitted = true;

    listOwners[msg.sender] = permitted;
    emit ListOwnerPermissions(msg.sender, msg.sender, permitted);

    setArbitrageurs(_arbitrageurs, permitted);
    emit ArbitrageurPermissions(msg.sender, _arbitrageurs, permitted);

    nextList = NULL_ADDR;
  }

  /// @notice Sets whether or not a specified address is a list owner.
  /// @param _address is the address to give or remove list owner priviliges from.
  /// @param _permitted if true, gives the specified address list owner priviliges. If false
  ///        removes list owner priviliges.
  function setListOwner(address _address, bool _permitted) public nonReentrant senderIsListOwner {
    listOwners[_address] = _permitted;

    emit ListOwnerPermissions(msg.sender, _address, _permitted);
  }

  /// @notice Sets whether the specified list of addresses is permitted to arbitrage Cron-Fi TWAMM
  ///         pools at a preffered rate or not.
  /// @param _arbitrageurs is a list of addresses to add or remove arbitrage permission from.
  /// @param _permitted specifies if the list of addresses contained in _arbitrageurs will be given
  ///        arbitrage permission when set to true. When false, arbitrage permission is removed from
  ///        the specified addresses.
  function setArbitrageurs(address[] memory _arbitrageurs, bool _permitted) public nonReentrant senderIsListOwner {
    uint256 length = _arbitrageurs.length;
    for (uint256 index = 0; index < length; index++) {
      permittedAddressMap[_arbitrageurs[index]] = _permitted;
    }

    emit ArbitrageurPermissions(msg.sender, _arbitrageurs, _permitted);
  }

  /// @notice Sets the next contract address to use for arbitraguer permissions. Requires that the
  ///         contract be instantiated and that a call to updateArbitrageList is made by the
  ///         arbitrage partner list on the corresponding TWAMM pool.
  /// @param _address is the address of the instantiated contract deriving from this contract to
  ///        use for address arbitrage permissions.
  function setNextList(address _address) public nonReentrant senderIsListOwner {
    nextList = _address;

    emit NextList(msg.sender, _address);
  }

  /// @notice Returns true if specified address has list owner permissions.
  /// @param _address is the address to check for list owner permissions.
  function isListOwner(address _address) public view returns (bool) {
    return listOwners[_address];
  }

  /// @notice Returns true if the provide address is permitted the preferred
  ///         arbitrage rate in the partner swap method of a Cron-Fi TWAMM pool.
  ///         Returns false otherwise.
  /// @param _address the address to check for arbitrage rate permissions.
  ///
  function isArbitrageur(address _address) public view override(IArbitrageurList) returns (bool) {
    return permittedAddressMap[_address];
  }
}