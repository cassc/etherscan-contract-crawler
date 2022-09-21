//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import './interfaces/IERC4494.sol';

/// @dev OpenZeppelin's ERC721Upgradeable extended with EIP-4494-compliant permits
/// @notice Based on the reference implementation of the EIP-4494
/// @notice See https://github.com/dievardump/erc721-with-permits and https://eips.ethereum.org/EIPS/eip-4494
/// @author Simon Fremaux (@dievardump) & William SchwabSchwab (@wschwab)
abstract contract ERC721WithPermitUpgradable is ERC721Upgradeable, IERC4494 {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            'Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)'
        );

    mapping(uint256 => uint256) private _nonces;

    // the chainId is also saved to be able to recompute domainSeparator in the case of a fork
    bytes32 private _domainSeparator;
    uint256 private _domainChainId;

    function __ERC721WithPermitUpgradable_init(string memory name_, string memory symbol_) internal initializer {
        __ERC721_init(name_, symbol_);
        __ERC721WithPermitUpgradable_init_unchained();
    }

    function __ERC721WithPermitUpgradable_init_unchained() internal initializer {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        _domainChainId = chainId;
        _domainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @notice Builds the DOMAIN_SEPARATOR (eip712) at time of use
    /// @dev This is not set as a constant, to ensure that the chainId will change in the event of a chain fork
    /// @return the DOMAIN_SEPARATOR of eip712
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        return
            (chainId == _domainChainId)
                ? _domainSeparator
                : _calculateDomainSeparator(chainId);
    }

    function _calculateDomainSeparator(uint256 chainId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                    ),
                    keccak256(bytes(name())),
                    keccak256(bytes('1')),
                    chainId,
                    address(this)
                )
            );
    }

    /// @notice Allows to retrieve current nonce for token
    /// @param tokenId token id
    /// @return current token nonce
    function nonces(uint256 tokenId) public view override returns (uint256) {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');
        return _nonces[tokenId];
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
    ) external override {
        require(deadline >= block.timestamp, 'permit expired');

        bytes32 digest = _buildDigest(
            spender,
            tokenId,
            _nonces[tokenId],
            deadline
        );

        (address recoveredAddress, ) = ECDSA.tryRecover(digest, signature);
        require(
            // verify if the recovered address is owner or approved on tokenId
            // and make sure recoveredAddress is not address(0), else getApproved(tokenId) might match
            (recoveredAddress != address(0) &&
                _isApprovedOrOwner(recoveredAddress, tokenId)) ||
                // else try to recover signature using SignatureChecker, which also allows to recover signature made by contracts
                SignatureChecker.isValidSignatureNow(
                    ownerOf(tokenId),
                    digest,
                    signature
                ),
            'permit is invalid'
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
    ) public view returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonce,
                        deadline
                    )
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
        // increment the nonce to be sure it can't be reused
        _incrementNonce(tokenId);

        // do normal transfer
        super._transfer(from, to, tokenId);
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Overridden from ERC721 here in order to include the interface of this EIP
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4494).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}