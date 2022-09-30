// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

abstract contract IMintGateway {
    /// @dev For backwards compatiblity reasons, the sigHash is cast to a
    /// uint256.
    event LogMint(address indexed to, uint256 amount, uint256 indexed sigHash, bytes32 indexed nHash);

    /// @dev Once `LogBurnToChain` is enabled on mainnet, LogBurn may be
    /// replaced by LogBurnToChain with empty payload and chain fields.
    /// @dev For backwards compatibility, `to` is bytes instead of a string.
    event LogBurn(
        bytes to,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        bytes indexed indexedTo
    );
    event LogBurnToChain(
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        string indexed recipientAddressIndexed,
        string indexed recipientChainIndexed
    );

    function mint(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external virtual returns (uint256);

    function burnWithPayload(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external virtual returns (uint256);

    function burn(string calldata recipient, uint256 amount) external virtual returns (uint256);

    function burn(bytes calldata recipient, uint256 amount) external virtual returns (uint256);
}