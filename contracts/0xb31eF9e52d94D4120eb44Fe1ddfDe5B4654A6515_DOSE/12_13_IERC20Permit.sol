// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, ERC2612 optional extension: permit – 712-signed approvals
 * @dev Interface for allowing ERC20 approvals to be made via ECDSA `secp256k1` signatures.
 * See https://eips.ethereum.org/EIPS/eip-2612
 * Note: the ERC-165 identifier for this interface is 0x9d8ff7da.
 */
interface IERC20Permit {
    /**
     * Sets `value` as the allowance of `spender` over the tokens of `owner`, given `owner` account's signed permit.
     * @dev WARNING: The standard ERC-20 race condition for approvals applies to `permit()` as well: https://swcregistry.io/docs/SWC-114
     * @dev Reverts if `owner` is the zero address.
     * @dev Reverts if the current blocktime is > `deadline`.
     * @dev Reverts if `r`, `s`, and `v` is not a valid `secp256k1` signature from `owner`.
     * @dev Emits an {IERC20-Approval} event.
     * @param owner The token owner granting the allowance to `spender`.
     * @param spender The token spender being granted the allowance by `owner`.
     * @param value The token amount of the allowance.
     * @param deadline The deadline from which the permit signature is no longer valid.
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter.
     * @param s Permis signature s parameter.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * Returns the current permit nonce of `owner`.
     * @param owner the address to check the nonce of.
     * @return the current permit nonce of `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * Returns the EIP-712 encoded hash struct of the domain-specific information for permits.
     *
     * @dev A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:
     *
     *  keccak256(
     *      abi.encode(
     *          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
     *          keccak256(bytes(name)),
     *          keccak256(bytes(version)),
     *          chainId,
     *          address(this)))
     *
     *  where
     *   - `name` (string) is the ERC-20 token name.
     *   - `version` (string) refers to the ERC-20 token contract version.
     *   - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.
     *   - `verifyingContract` (address) is the ERC-20 token contract address.
     *
     * @return the EIP-712 encoded hash struct of the domain-specific information for permits.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}