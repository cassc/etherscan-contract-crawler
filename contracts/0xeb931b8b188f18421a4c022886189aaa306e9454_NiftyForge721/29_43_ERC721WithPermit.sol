//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @title ERC721WithPermit
/// @author Simon Fremaux (@dievardump)
/// @notice This implementation differs from what I can see everywhere else
///         My take on Permits for NFTs is that the nonce should be linked to the tokens
///         and not to an owner.
///         Whenever a token is transfered, its nonce should increase.
///         This allows to emit a lot of Permit (for sales for example) but ensure they
///         will get invalidated after the token is transfered
///         This also allows an owner to emit several Permit on different tokens
///         and not have Permit to be used one after the other
///         Example:
///         An owner sign a Permit of sale on OpenSea and on Rarible at the same time
///         Only the first one that will sell the item will be able to use the permit
///         The nonce being incremented, this Permits won't be usable anymore
abstract contract ERC721WithPermit is ERC721Upgradeable {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );

    bytes32 private _deploymentDomainSeparator;
    uint256 private _deploymentChainId;

    mapping(uint256 => uint256) private _nonces;

    // function to initialize the contract
    function __ERC721WithPermit_init() internal {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        _deploymentChainId = chainId;
        _deploymentDomainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        // in case a fork happen, to support the chain that had to change its chainId,, we compute the domain operator
        return
            chainId == _deploymentChainId
                ? _deploymentDomainSeparator
                : _calculateDomainSeparator(chainId);
    }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current nonce
    function nonce(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "!UNKNOWN_TOKEN!");
        return _nonces[tokenId];
    }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current nonce
    function nonces(uint256 tokenId) public view returns (uint256) {
        return nonce(tokenId);
    }

    function makePermitDigest(
        address spender,
        uint256 tokenId,
        uint256 nonce_,
        uint256 deadline
    ) public view returns (bytes32) {
        return
            ECDSAUpgradeable.toTypedDataHash(
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonce_,
                        deadline
                    )
                )
            );
    }

    /// @notice function to be called by anyone to approve `spender` using a Permit signature
    /// @dev Anyone can call this to approve `spender`, even a third-party
    /// @param spender the actor to approve
    /// @param tokenId the token id
    /// @param deadline the deadline for the permit to be used
    /// @param signature permit
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) public {
        require(deadline >= block.timestamp, "!PERMIT_DEADLINE_EXPIRED!");

        // this will revert if token is burned
        address owner_ = ownerOf(tokenId);

        bytes32 digest = makePermitDigest(
            spender,
            tokenId,
            _nonces[tokenId],
            deadline
        );

        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(
            digest,
            signature
        );
        require(
            (
                // no need to check for recoveredAddress == 0
                // because if it's 0, it won't work
                (recoveredAddress == owner_ ||
                    isApprovedForAll(owner_, recoveredAddress))
            ) ||
                // if owner is a contract, try to recover signature using SignatureChecker
                SignatureCheckerUpgradeable.isValidSignatureNow(
                    owner_,
                    digest,
                    signature
                ),
            "!INVALID_PERMIT_SIGNATURE!"
        );

        _approve(spender, tokenId);
    }

    /// @dev returns the domain separator for `chainId`
    /// @param chainId the chain id
    function _calculateDomainSeparator(uint256 chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name())),
                    keccak256(bytes("1")),
                    chainId,
                    address(this)
                )
            );
    }

    /// @dev helper to easily increment a nonce for a given tokenId
    /// @param tokenId the tokenId to increment the nonce for
    function _incrementNonce(uint256 tokenId) internal {
        _nonces[tokenId]++;
    }

    /// @dev _transfer override to be able to increment the nonce
    /// @inheritdoc ERC721Upgradeable
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // increment the permit nonce linked to this tokenId.
        // this will ensure that a Permit can not be used on a token
        // if it were to leave the owner's hands and come back later
        // this if saves 20k on the mint, which is already expensive enough
        if (from != address(0)) {
            _incrementNonce(tokenId);
        }

        super._transfer(from, to, tokenId);
    }
}