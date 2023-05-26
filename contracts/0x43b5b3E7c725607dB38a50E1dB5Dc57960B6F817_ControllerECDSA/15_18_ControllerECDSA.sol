// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/IController.sol";
import "./interfaces/ILoreMembershipCardToken.sol";

    error NotAuthorized();
    error InvalidSignature();
    error EmptySigner();
    error DuplicateNonce();
    error MsgExpired();

/// @notice ControllerECDSA allows authorized addresses to mint and transfer NFTs on behalf of users.
contract ControllerECDSA is IController, AccessControlEnumerable, EIP712 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant SAFE_MINT_EIP712_HASH = keccak256("Mint(address squad,address to,address minterOwner,uint256 nonce,uint256 deadline)");
    bytes32 public constant SAFE_MINT_BATCH_EIP712_HASH = keccak256("MintBatch(address[] squads,address[] toAddresses,address minterOwner,uint256 nonce,uint256 deadline)");
    bytes32 public constant ADMIN_TRANSFER_EIP712_HASH = keccak256("AdminTransfer(address from,address to,uint256 tokenId,address transferOwner,uint256 nonce,uint256 deadline)");
    string public constant VERSION = "1";

    ILoreMembershipCardToken public loreMembershipCard;

    mapping(uint256 => address) private _nonces;

    constructor(
        string memory domainName,
        address contractOwner,
        address loreMembershipPass
    ) EIP712(domainName, VERSION) {
        _setupRole(DEFAULT_ADMIN_ROLE, contractOwner);
        loreMembershipCard = ILoreMembershipCardToken(loreMembershipPass);
    }

    function setMembershipCard(address _membershipCard) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        loreMembershipCard = ILoreMembershipCardToken(_membershipCard);
    }

    function signerOfSafeMintBatch(
        address[] memory _squadsIn,
        address[] memory toAddresses,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    override
    view
    returns (address)
    {
        return _signerOfSafeMintBatch(_squadsIn, toAddresses, minterOwner, signature, deadline, _nonce);
    }

    function _signerOfSafeMintBatch(
        address[] memory _squadsIn,
        address[] memory toAddresses,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    internal
    view
    returns (address)
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                SAFE_MINT_BATCH_EIP712_HASH,
                keccak256(abi.encodePacked(_squadsIn)),
                keccak256(abi.encodePacked(toAddresses)),
                minterOwner,
                _nonce,
                deadline
            )));
        return _signerForHashTypedData(digest, signature);
    }

    function signerOfSafeMint(
        address _squad,
        address to,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    override
    view
    returns (address)
    {
        return _signerOfSafeMint(_squad, to, minterOwner, signature, deadline, _nonce);
    }

    function _signerOfSafeMint(
        address _squad,
        address to,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    public
    view
    returns (address)
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                SAFE_MINT_EIP712_HASH,
                _squad,
                to,
                minterOwner,
                _nonce,
                deadline
            )));
        return _signerForHashTypedData(digest, signature);
    }

    function signerOfAdminTransfer(
        address from,
        address to,
        uint256 tokenId,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    override
    view
    returns (address)
    {
        return _signerOfAdminTransfer(from, to, tokenId, minterOwner, signature, deadline, _nonce);
    }

    function _signerOfAdminTransfer(
        address from,
        address to,
        uint256 tokenId,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    internal
    view
    returns (address)
    {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                ADMIN_TRANSFER_EIP712_HASH,
                from,
                to,
                tokenId,
                minterOwner,
                _nonce,
                deadline
            )));
        return _signerForHashTypedData(digest, signature);
    }

    function _signerForHashTypedData(
        bytes32 digest,
        bytes memory signature)
    internal
    pure
    returns (address)
    {
        return ECDSA.recover(digest, signature);
    }

    /// @dev Check if the signature is valid for the digest and has the expected role set.
    /// @param resolvedSigner the signer of the digest. This is the recovered address from the signature.
    /// @param expectedSigner the expected signer of the signature. Fails if it does not match.
    /// @param deadline the seconds since epoch deadline compared against `block.timestamp`.
    /// @param _nonce random nonce that can only be used once. Fails if it has already be used.
    /// @param role the recovered signer address must have this role to execute the meta transaction.
    function _checkSignerNonceDeadline(
        address resolvedSigner,
        address expectedSigner,
        uint256 deadline,
        uint256 _nonce, bytes32 role)
    internal
    {
        if (resolvedSigner != expectedSigner) {
            revert InvalidSignature();
        }
        if (resolvedSigner == address(0)) {
            revert EmptySigner();
        }
        if (_nonces[_nonce] != address(0)) {
            revert DuplicateNonce();
        }
        if (!hasRole(role, resolvedSigner)) {
            revert NotAuthorized();
        }
        if (block.timestamp > deadline) {
            revert MsgExpired();
        }
        _nonces[_nonce] = resolvedSigner;
    }

    /// @notice Execute the mintBatch function in a meta transaction context.
    /// @param squads list of squad addresses to mint for
    /// @param toAddresses list of users addresses to mint to. Must be equal length to _squadsIn.
    /// @param minterOwner the address of the account that generated the signature
    /// @param signature the eip712 signature for `SafeMintBatch`
    /// @param deadline deadline for this message to be executed. Seconds in epoch time. Must match the deadline in the signature.
    /// @param _nonce the random nonce included in the signature.
    function executeMintBatchFromSignature(
        address[] memory squads,
        address[] memory toAddresses,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    {
        _checkSignerNonceDeadline(
            _signerOfSafeMintBatch(squads, toAddresses, minterOwner, signature, deadline, _nonce),
            minterOwner,
            deadline,
            _nonce,
            MINTER_ROLE
        );
        loreMembershipCard.mintBatch(squads, toAddresses);
    }

    /// @notice Execute the mint function with a presigned message.
    /// @param squad squad address to mint for.
    /// @param to account to mint to.
    /// @param minterOwner the address of the account that generated the signature
    /// @param signature the eip712 signature for `SafeMintBatch`
    /// @param deadline deadline for this message to be executed. Seconds in epoch time. Must match the deadline in the signature.
    /// @param _nonce the random nonce included in the signature.
    function executeMintFromSignature(
        address squad,
        address to,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    {
        _checkSignerNonceDeadline(
            _signerOfSafeMint(squad, to, minterOwner, signature, deadline, _nonce),
            minterOwner,
            deadline,
            _nonce,
            MINTER_ROLE
        );
        loreMembershipCard.mint(squad, to);
    }

    /// @notice Execute the adminTransfer function with a presigned message.
    /// @param from token current owner
    /// @param to token new owner
    /// @param tokenId token id to transfer
    /// @param transferOwner the address of the account that generated the signature
    /// @param signature the eip712 signature for `AdminTransfer`
    /// @param deadline deadline for this message to be executed. Seconds in epoch time. Must match the deadline in the signature.
    /// @param _nonce the random nonce included in the signature.
    function executeAdminTransferFromSignature(
        address from,
        address to,
        uint256 tokenId,
        address transferOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    )
    external
    {
        _checkSignerNonceDeadline(
            _signerOfAdminTransfer(from, to, tokenId, transferOwner, signature, deadline, _nonce),
            transferOwner,
            deadline,
            _nonce,
            TRANSFER_ROLE
        );
        loreMembershipCard.adminTransfer(from, to, tokenId);
    }
}