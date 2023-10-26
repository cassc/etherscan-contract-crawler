// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITOS {
    function balanceOf(address account) external view returns (uint256);

    /// @dev Issue a token.
    /// @param to  who takes the issue
    /// @param amount the amount to issue
    function mint(address to, uint256 amount) external returns (bool);

    // @dev burn a token.
    /// @param from Whose tokens are burned
    /// @param amount the amount to burn
    function burn(address from, uint256 amount) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    /// @dev Authorizes the owner's token to be used by the spender as much as the value.
    /// @dev The signature must have the owner's signature.
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @dev verify the signature
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param _nounce the _nounce
    /// @param sigR the owner's signature - r
    /// @param sigS the owner's signature - s
    /// @param sigV the owner's signature - v
    function verify(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 _nounce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external view returns (bool);

    /// @dev the hash of Permit
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param _nounce the _nounce
    function hashPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 _nounce
    ) external view returns (bytes32);
}