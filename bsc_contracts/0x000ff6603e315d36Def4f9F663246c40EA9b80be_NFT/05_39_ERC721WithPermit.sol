//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "./IERC721WithPermit.sol";

/// @dev Following code was taken from https://github.com/dievardump/erc721-with-permits and adapted to the Upgradeable pattern
/// @title ERC721WithPermit
/// @author Simon Fremaux (@dievardump) & William Schwab (@wschwab)
/// @notice This implementation of Permits links the nonce to the tokenId instead of the owner
///         This way, it is possible for a same account to create several usable permits at the same time,
///         for different ids
///
///         This implementation overrides _transfer and increments the nonce linked to a tokenId
///         every time it is transfered

// solhint-disable ordering
abstract contract ERC721WithPermit is IERC721WithPermit, ERC721Upgradeable {
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    mapping(uint256 => uint256) internal _nonces;

    // this are saved as immutable for cheap access
    // the chainId is also saved to be able to recompute domainSeparator
    // in the case of a fork
    bytes32 private _domainSeparator;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 private immutable _domainChainId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _domainChainId = block.chainid;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ERC721WithPermit_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
        __ERC721WithPermit_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ERC721WithPermit_init_unchained() internal onlyInitializing {
        _domainSeparator = _calculateDomainSeparator();
    }

    /// @notice Builds the DOMAIN_SEPARATOR (eip712) at time of use
    /// @dev This is not set as a constant, to ensure that the chainId will change in the event of a chain fork
    /// @return the DOMAIN_SEPARATOR of eip712
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return (block.chainid == _domainChainId) ? _domainSeparator : _calculateDomainSeparator();
    }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current token nonce
    function nonces(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "!UNKNOWN_TOKEN!");
        return _nonces[tokenId];
    }

    /// @notice function to be called by anyone to approve `spender` using a Permit signature
    /// @dev Anyone can call this to approve `spender`, even a third-party
    /* /// @param owner the owner of the token */
    /// @param spender the actor to approve
    /// @param tokenId the token id
    /// @param deadline the deadline for the permit to be used
    /// @param signature permit
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external {
        _permit(spender, tokenId, deadline, signature);
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Overriden from ERC721 here in order to include the interface of this EIP
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721WithPermit).interfaceId || // 0x5604e225
            super.supportsInterface(interfaceId);
    }

    function _permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) internal {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "!PERMIT_DEADLINE_EXPIRED!");

        bytes32 digest = _buildDigest(
            // owner,
            spender,
            tokenId,
            _nonces[tokenId],
            deadline
        );

        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signature);
        require(
            // verify if the recovered address is owner or approved on tokenId
            // and make sure recoveredAddress is not address(0), else getApproved(tokenId) might match
            (recoveredAddress != address(0) && _isApprovedOrOwner(recoveredAddress, tokenId)) ||
                // else try to recover signature using SignatureChecker, which also allows to recover signature made by contracts
                SignatureCheckerUpgradeable.isValidSignatureNow(ownerOf(tokenId), digest, signature),
            "!INVALID_PERMIT_SIGNATURE!"
        );

        _approve(spender, tokenId);
    }

    /// @notice Builds the permit digest to sign
    /// @param spender the token spender
    /// @param tokenId the tokenId
    /// @param nonce the nonce to make a permit for
    /// @param deadline the deadline before when the permit can be used
    /// @return the digest (following eip712) to sign
    function _buildDigest(
        address spender,
        uint256 tokenId,
        uint256 nonce,
        uint256 deadline
    ) private view returns (bytes32) {
        return
            ECDSAUpgradeable.toTypedDataHash(
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, nonce, deadline))
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
        // increment the nonce to be sure it can't be reused
        _incrementNonce(tokenId);

        // do normal transfer
        super._transfer(from, to, tokenId);
    }

    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}