// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";
import "../token/T.sol";

/// @title T token vending machine
/// @notice Contract implements a special update protocol to enable KEEP/NU
///         token holders to wrap their tokens and obtain T tokens according
///         to a fixed ratio. This will go on indefinitely and enable NU and
///         KEEP token holders to join T network without needing to buy or
///         sell any assets. Logistically, anyone holding NU or KEEP can wrap
///         those assets in order to upgrade to T. They can also unwrap T in
///         order to downgrade back to the underlying asset. There is a separate
///         instance of this contract deployed for KEEP holders and a separate
///         instance of this contract deployed for NU holders.
contract VendingMachine is IReceiveApproval {
    using SafeERC20 for IERC20;
    using SafeERC20 for T;

    /// @notice Number of decimal places of precision in conversion to/from
    ///         wrapped tokens (assuming typical ERC20 token with 18 decimals).
    ///         This implies that amounts of wrapped tokens below this precision
    ///         won't take part in the conversion. E.g., for a value of 3, then
    ///         for a conversion of 1.123456789 wrapped tokens, only 1.123 is
    ///         convertible (i.e., 3 decimal places), and 0.000456789 is left.
    uint256 public constant WRAPPED_TOKEN_CONVERSION_PRECISION = 3;

    /// @notice Divisor for precision purposes, used to represent fractions.
    uint256 public constant FLOATING_POINT_DIVISOR =
        10**(18 - WRAPPED_TOKEN_CONVERSION_PRECISION);

    /// @notice The token being wrapped to T (KEEP/NU).
    IERC20 public immutable wrappedToken;

    /// @notice T token contract.
    T public immutable tToken;

    /// @notice The ratio with which T token is converted based on the provided
    ///         token being wrapped (KEEP/NU), expressed in 1e18 precision.
    ///
    ///         When wrapping:
    ///           x [T] = amount [KEEP/NU] * ratio / FLOATING_POINT_DIVISOR
    ///
    ///         When unwrapping:
    ///           x [KEEP/NU] = amount [T] * FLOATING_POINT_DIVISOR / ratio
    uint256 public immutable ratio;

    /// @notice The total balance of wrapped tokens for the given holder
    ///         account. Only holders that have previously wrapped KEEP/NU to T
    ///         can unwrap, up to the amount previously wrapped.
    mapping(address => uint256) public wrappedBalance;

    event Wrapped(
        address indexed recipient,
        uint256 wrappedTokenAmount,
        uint256 tTokenAmount
    );
    event Unwrapped(
        address indexed recipient,
        uint256 tTokenAmount,
        uint256 wrappedTokenAmount
    );

    /// @notice Sets the reference to `wrappedToken` and `tToken`. Initializes
    ///         conversion `ratio` between wrapped token and T based on the
    ///         provided `_tTokenAllocation` and `_wrappedTokenAllocation`.
    /// @param _wrappedToken Address to ERC20 token that will be wrapped to T
    /// @param _tToken Address of T token
    /// @param _wrappedTokenAllocation The total supply of the token that will be
    ///       wrapped to T
    /// @param _tTokenAllocation The allocation of T this instance of Vending
    ///        Machine will receive
    /// @dev Multiplications in this contract can't overflow uint256 as we
    ///     restrict `_wrappedTokenAllocation` and `_tTokenAllocation` to
    ///     96 bits and FLOATING_POINT_DIVISOR fits in less than 60 bits.
    constructor(
        IERC20 _wrappedToken,
        T _tToken,
        uint96 _wrappedTokenAllocation,
        uint96 _tTokenAllocation
    ) {
        wrappedToken = _wrappedToken;
        tToken = _tToken;
        ratio =
            (FLOATING_POINT_DIVISOR * _tTokenAllocation) /
            _wrappedTokenAllocation;
    }

    /// @notice Wraps up to the the given `amount` of the token (KEEP/NU) and
    ///         releases T token proportionally to the amount being wrapped with
    ///         respect to the wrap ratio. The token holder needs to have at
    ///         least the given amount of the wrapped token (KEEP/NU) approved
    ///         to transfer to the Vending Machine before calling this function.
    /// @param amount The amount of KEEP/NU to be wrapped
    function wrap(uint256 amount) external {
        _wrap(msg.sender, amount);
    }

    /// @notice Wraps up to the given amount of the token (KEEP/NU) and releases
    ///         T token proportionally to the amount being wrapped with respect
    ///         to the wrap ratio. This is a shortcut to `wrap` function that
    ///         avoids a separate approval transaction. Only KEEP/NU token
    ///         is allowed as a caller, so please call this function via
    ///         token's `approveAndCall`.
    /// @param from Caller's address, must be the same as `wrappedToken` field
    /// @param amount The amount of KEEP/NU to be wrapped
    /// @param token Token's address, must be the same as `wrappedToken` field
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata
    ) external override {
        require(
            token == address(wrappedToken),
            "Token is not the wrapped token"
        );
        require(
            msg.sender == address(wrappedToken),
            "Only wrapped token caller allowed"
        );
        _wrap(from, amount);
    }

    /// @notice Unwraps up to the given `amount` of T back to the legacy token
    ///         (KEEP/NU) according to the wrap ratio. It can only be called by
    ///         a token holder who previously wrapped their tokens in this
    ///         vending machine contract. The token holder can't unwrap more
    ///         tokens than they originally wrapped. The token holder needs to
    ///         have at least the given amount of T tokens approved to transfer
    ///         to the Vending Machine before calling this function.
    /// @param amount The amount of T to unwrap back to the collateral (KEEP/NU)
    function unwrap(uint256 amount) external {
        _unwrap(msg.sender, amount);
    }

    /// @notice Returns the T token amount that's obtained from `amount` wrapped
    ///         tokens (KEEP/NU), and the remainder that can't be upgraded.
    function conversionToT(uint256 amount)
        public
        view
        returns (uint256 tAmount, uint256 wrappedRemainder)
    {
        wrappedRemainder = amount % FLOATING_POINT_DIVISOR;
        uint256 convertibleAmount = amount - wrappedRemainder;
        tAmount = (convertibleAmount * ratio) / FLOATING_POINT_DIVISOR;
    }

    /// @notice The amount of wrapped tokens (KEEP/NU) that's obtained from
    ///         `amount` T tokens, and the remainder that can't be downgraded.
    function conversionFromT(uint256 amount)
        public
        view
        returns (uint256 wrappedAmount, uint256 tRemainder)
    {
        tRemainder = amount % ratio;
        uint256 convertibleAmount = amount - tRemainder;
        wrappedAmount = (convertibleAmount * FLOATING_POINT_DIVISOR) / ratio;
    }

    function _wrap(address tokenHolder, uint256 wrappedTokenAmount) internal {
        (uint256 tTokenAmount, uint256 remainder) = conversionToT(
            wrappedTokenAmount
        );
        wrappedTokenAmount -= remainder;
        require(wrappedTokenAmount > 0, "Disallow conversions of zero value");
        emit Wrapped(tokenHolder, wrappedTokenAmount, tTokenAmount);

        wrappedBalance[tokenHolder] += wrappedTokenAmount;
        wrappedToken.safeTransferFrom(
            tokenHolder,
            address(this),
            wrappedTokenAmount
        );
        tToken.safeTransfer(tokenHolder, tTokenAmount);
    }

    function _unwrap(address tokenHolder, uint256 tTokenAmount) internal {
        (uint256 wrappedTokenAmount, uint256 remainder) = conversionFromT(
            tTokenAmount
        );
        tTokenAmount -= remainder;
        require(tTokenAmount > 0, "Disallow conversions of zero value");
        require(
            wrappedBalance[tokenHolder] >= wrappedTokenAmount,
            "Can not unwrap more than previously wrapped"
        );

        emit Unwrapped(tokenHolder, tTokenAmount, wrappedTokenAmount);
        wrappedBalance[tokenHolder] -= wrappedTokenAmount;
        tToken.safeTransferFrom(tokenHolder, address(this), tTokenAmount);
        wrappedToken.safeTransfer(tokenHolder, wrappedTokenAmount);
    }
}