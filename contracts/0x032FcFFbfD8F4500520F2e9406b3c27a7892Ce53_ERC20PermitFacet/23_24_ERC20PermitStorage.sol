// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Permit} from "./../interfaces/IERC20Permit.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ERC20Storage} from "./ERC20Storage.sol";
import {ERC20DetailedStorage} from "./ERC20DetailedStorage.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20PermitStorage {
    using ERC20Storage for ERC20Storage.Layout;
    using ERC20DetailedStorage for ERC20DetailedStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(address => uint256) accountNonces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20Permit.storage")) - 1);

    // 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
    bytes32 internal constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Permit.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Permit).interfaceId, true);
    }

    /// @notice Sets the allowance to an account from another account using a signed permit.
    /// @dev Reverts if `owner` is the zero address.
    /// @dev Reverts if the current blocktime is greather than `deadline`.
    /// @dev Reverts if `r`, `s`, and `v` do not represent a valid `secp256k1` signature from `owner`.
    /// @dev Emits an {IERC20-Approval} event.
    /// @param owner The token owner granting the allowance to `spender`.
    /// @param spender The token spender being granted the allowance by `owner`.
    /// @param value The allowance amount to grant.
    /// @param deadline The deadline from which the permit signature is no longer valid.
    /// @param v Permit signature v parameter
    /// @param r Permit signature r parameter.
    /// @param s Permit signature s parameter.
    function permit(Layout storage st, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal {
        require(owner != address(0), "ERC20: permit from address(0)");
        require(block.timestamp <= deadline, "ERC20: expired permit");
        unchecked {
            bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, st.accountNonces[owner]++, deadline));
            bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));
            address signer = ecrecover(hash, v, r, s);
            require(signer == owner, "ERC20: invalid permit");
        }
        ERC20Storage.layout().approve(owner, spender, value);
    }

    /// @notice Gets the current permit nonce of an account.
    /// @param owner The account to check the nonce of.
    /// @return nonce The current permit nonce of `owner`.
    function nonces(Layout storage s, address owner) internal view returns (uint256 nonce) {
        return s.accountNonces[owner];
    }

    /// @notice Returns the EIP-712 encoded hash struct of the domain-specific information for permits.
    /// @dev A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:
    ///  keccak256(
    ///      abi.encode(
    ///          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    ///          keccak256(bytes(name)),
    ///          keccak256(bytes(version)),
    ///          chainId,
    ///          address(this)))
    ///
    ///  where
    ///   - `name` (string) is the ERC-20 token name.
    ///   - `version` (string) refers to the ERC-20 token contract version.
    ///   - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.
    ///   - `verifyingContract` (address) is the ERC-20 token contract address.
    ///
    /// @return domainSeparator The EIP-712 encoded hash struct of the domain-specific information for permits.
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(ERC20DetailedStorage.layout().name())),
                    keccak256("1"),
                    chainId,
                    address(this)
                )
            );
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}