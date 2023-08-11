// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct SignedMintAuthorization {
    uint256 reservationId;
    string tokenUri;
    /// eth_sign(keccak256(abi.encodePacked(minter, to, reservationId, tokenUri)))
    bytes authorization;
}

/// @title IAuthorizeMints
/// @author molecule.to
/// @notice a flexible interface to gate token mint calls on another contract, built for IP-NFTs
interface IAuthorizeMints {
    /// @notice checks whether `minter` is allowed to mint a token for `to`. MAY safely revert if this is not the case.
    /// @param data bytes implementation specific data
    function authorizeMint(address minter, address to, bytes memory data) external view returns (bool);

    /// @notice checks whether `reserver` is allowed to reserve a token id on the target contract
    function authorizeReservation(address reserver) external view returns (bool);

    /// @notice called by the gated token contract to signal that a token has been minted and an authorization can be invalidated
    /// @param data implementation specific data
    function redeem(bytes memory data) external;
}