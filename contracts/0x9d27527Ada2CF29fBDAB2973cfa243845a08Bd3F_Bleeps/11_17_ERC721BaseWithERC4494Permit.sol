// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Base.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./IERC4494.sol";

abstract contract ERC721BaseWithERC4494Permit is ERC721Base {
    using Address for address;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256("PermitForAll(address spender,uint256 nonce,uint256 deadline)");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    uint256 private immutable _deploymentChainId;
    bytes32 private immutable _deploymentDomainSeparator;

    mapping(address => uint256) internal _userNonces;

    constructor() {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        _deploymentChainId = chainId;
        _deploymentDomainSeparator = _calculateDomainSeparator(chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR();
    }

    /// @notice return the account nonce, used for approvalForAll permit or other account related matter
    /// @param account the account to query
    /// @return nonce
    function nonces(address account) external view virtual returns (uint256 nonce) {
        return _userNonces[account];
    }

    /// @notice return the token nonce, used for individual approve permit or other token related matter
    /// @param id token id to query
    /// @return nonce
    function nonces(uint256 id) public view virtual returns (uint256 nonce) {
        (address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        return blockNumber;
    }

    /// @notice return the token nonce, used for individual approve permit or other token related matter
    /// @param id token id to query
    /// @return nonce
    function tokenNonces(uint256 id) external view returns (uint256 nonce) {
        return nonces(id);
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        (address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(tokenId);
        require(owner != address(0), "NONEXISTENT_TOKEN");

        // We use blockNumber as nonce as we already store it per tokens. It can thus act as an increasing transfer counter.
        // while technically multiple transfer could happen in the same block, the signed message would be using a previous block.
        // And the transfer would use then a more recent blockNumber, invalidating that message when transfer is executed.
        _requireValidPermit(owner, spender, tokenId, deadline, blockNumber, sig);

        _approveFor(owner, blockNumber, spender, tokenId);
    }

    function permitForAll(
        address signer,
        address spender,
        uint256 deadline,
        bytes memory sig
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        _requireValidPermitForAll(signer, spender, deadline, _userNonces[signer]++, sig);

        _setApprovalForAll(signer, spender, true);
    }

    /// @notice Check if the contract supports an interface.
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return
            super.supportsInterface(id) ||
            id == type(IERC4494).interfaceId ||
            id == type(IERC4494Alternative).interfaceId;
    }

    // -------------------------------------------------------- INTERNAL --------------------------------------------------------------------

    function _requireValidPermit(
        address signer,
        address spender,
        uint256 id,
        uint256 deadline,
        uint256 nonce,
        bytes memory sig
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonce, deadline))
            )
        );
        require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
    }

    function _requireValidPermitForAll(
        address signer,
        address spender,
        uint256 deadline,
        uint256 nonce,
        bytes memory sig
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR(),
                keccak256(abi.encode(PERMIT_FOR_ALL_TYPEHASH, spender, nonce, deadline))
            )
        );
        require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
    }

    /// @dev Return the DOMAIN_SEPARATOR.
    function _DOMAIN_SEPARATOR() internal view returns (bytes32) {
        uint256 chainId;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        // in case a fork happen, to support the chain that had to change its chainId,, we compute the domain operator
        return chainId == _deploymentChainId ? _deploymentDomainSeparator : _calculateDomainSeparator(chainId);
    }

    /// @dev Calculate the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), chainId, address(this)));
    }
}