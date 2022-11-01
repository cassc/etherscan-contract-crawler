// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./internal-upgradeable/SignableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/ProxyCheckerUpgradeable.sol";
import "./internal-upgradeable/WithdrawableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./interfaces/ITreasury.sol";

contract Treasury is
    ITreasury,
    BaseUpgradeable,
    SignableUpgradeable,
    ProxyCheckerUpgradeable,
    WithdrawableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Bytes32Address for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev value is equal to keccak256("Treasury_v1")
    bytes32 public constant VERSION =
        0xea88ed743f2d0583b98ad2b145c450d84d46c8e4d6425d9e0c7cd0e4930fce2f;

    /// @dev value is equal to keccak256("Permit(address token,address to,uint256 amount,uint256 deadline,uint256 nonce)")
    bytes32 private constant __PERMIT_TYPE_HASH =
        0x984451e1880855a56058ebd6b0f6c8dd534f21c83a8dedad93ab0e57c6c84c7a;

    EnumerableSetUpgradeable.AddressSet private _payments;
    EnumerableSetUpgradeable.AddressSet private __payments;

    function initialize(IAuthority authority_) external initializer {
        /// @dev support native payment
        __addPayment(address(0));

        __ReentrancyGuard_init();
        __Base_init(authority_, 0);
        __EIP712_init(type(Treasury).name, "2");
    }

    function withdraw(
        IERC20Upgradeable token_,
        address to_,
        uint256 amount_
    )
        external
        override(IWithdrawableUpgradeable, WithdrawableUpgradeable)
        onlyRole(Roles.TREASURER_ROLE)
    {
        _safeTransfer(token_, to_, amount_);
        emit Withdrawn(token_, to_, amount_);
    }

    function withdraw(
        IERC20Upgradeable token_,
        address to_,
        uint256 amount_,
        uint256 deadline_,
        bytes calldata signature_
    ) external nonReentrant whenNotPaused {
        _onlyEOA(to_);
        _checkBlacklist(to_);

        require(block.timestamp <= deadline_, "TREASURY: EXPIRED");
        require(
            _hasRole(
                Roles.SIGNER_ROLE,
                _recoverSigner(
                    keccak256(
                        abi.encode(
                            __PERMIT_TYPE_HASH,
                            token_,
                            to_,
                            amount_,
                            deadline_,
                            _useNonce(to_)
                        )
                    ),
                    signature_
                )
            ),
            "TREASURY: INVALID_SIGNATURE"
        );

        _safeTransfer(token_, to_, amount_);

        emit Withdrawn(token_, to_, amount_);
    }

    function addPayments(IERC20Upgradeable[] calldata tokens_)
        external
        onlyRole(Roles.TREASURER_ROLE)
    {
        address[] memory tokens;
        {
            IERC20Upgradeable[] memory _token = tokens_;
            assembly {
                tokens := _token
            }
        }
        uint256 length = tokens.length;
        for (uint256 i; i < length; ) {
            __addPayment(tokens[i]);
            unchecked {
                ++i;
            }
        }

        emit PaymentsAdded(tokens_);
    }

    function addPayment(IERC20Upgradeable token_)
        external
        onlyRole(Roles.TREASURER_ROLE)
    {
        __addPayment(address(token_));

        emit PaymentAdded(token_);
    }

    function __addPayment(address token_) private {
        __payments.add(token_);
    }

    function removePayment(IERC20Upgradeable token_)
        external
        whenPaused
        onlyRole(Roles.TREASURER_ROLE)
    {
        if (__payments.remove(address(token_))) emit PaymentRemoved(token_);
    }

    function payments() external view returns (address[] memory) {
        return __payments.values();
    }

    function supportedPayment(address token_) public view returns (bool) {
        return __payments.contains(token_);
    }
}