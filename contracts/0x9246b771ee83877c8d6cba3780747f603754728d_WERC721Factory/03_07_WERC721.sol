// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Clone} from "solady/utils/Clone.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {SignatureCheckerLib} from "solady/utils/SignatureCheckerLib.sol";

/**
 * @title ERC721 wrapper contract.
 * @notice Wrap your ERC721 tokens for redeemable tokens with:
 *         - Significantly less gas usage when transferring tokens;
 *         - Built-in call-batching (with multicall); and
 *         - Meta-transactions using EIP3009-inspired authorized transfers (ERC1271-compatible, thanks to Solady).
 * @author kp (ppmoon69.eth)
 * @custom:contributor vectorized (vectorized.eth)
 * @custom:contributor pashov (pashov.eth)
 */
contract WERC721 is Clone, Multicallable {
    // Immutable `collection` arg. Offset by 0 bytes since it's first.
    uint256 private constant _IMMUTABLE_ARG_OFFSET_COLLECTION = 0;

    // EIP712 domain typehash: keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)").
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    // EIP712 domain name (the user readable name of the signing domain): keccak256("WERC721").
    bytes32 private constant _EIP712_DOMAIN_NAME =
        0x59b335d161aba1eac6f297a3046e2f74e6d4f8b1bc20b3766e382ce7e7b4369c;

    // EIP712 domain version (the current major version of the signing domain): keccak256("1").
    bytes32 private constant _EIP712_DOMAIN_VERSION =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // Authorized transfer typehash: keccak256("TransferFromWithAuthorization(address relayer,address from,address to,uint256 tokenId,uint256 validAfter,uint256 validBefore,bytes32 nonce)").
    bytes32 private constant _TRANSFER_FROM_WITH_AUTHORIZATION_TYPEHASH =
        0x0e3210998bc7d4519a993d9c986d16a1be38c22a169884883d35e6a2e9bff24d;

    // ERC165 interface identifier: bytes4(keccak256("supportsInterface(bytes4)")).
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;

    // ERC165 ERC721TokenReceiver interface identifier: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
    bytes4 private constant _ERC165_INTERFACE_ID_ERC721_TOKEN_RECEIVER =
        0x150b7a02;

    // ERC165 ERC721Metadata interface identifier: bytes4(keccak256("name()"))^bytes4(keccak256("symbol()"))^bytes4(keccak256("tokenURI(uint256)")).
    bytes4 private constant _ERC165_INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // WERC721 tokens mapped to their owners.
    mapping(uint256 id => address owner) private _ownerOf;

    // WERC721 owners mapped to operators and their approval status.
    mapping(address owner => mapping(address operator => bool approved))
        public isApprovedForAll;

    // Transfer authorizers mapped to nonces and their usage status.
    mapping(address authorizer => mapping(bytes32 nonce => bool state))
        public authorizationState;

    // This emits when ownership of any NFT changes by any mechanism.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    // This emits when an operator is enabled or disabled for an owner.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // This emits when an authorization is used.
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

    // This emits when an authorization is canceled.
    event AuthorizationCanceled(
        address indexed authorizer,
        bytes32 indexed nonce
    );

    error NotTokenOwner();
    error NotApprovedOperator();
    error NotAuthorizedCaller();
    error UnsafeTokenRecipient();
    error NotWrappedToken();
    error InvalidTransferAuthorization();
    error TransferAuthorizationUsed();

    /**
     * @notice Get the EIP712 domain separator.
     * @return bytes32  The EIP712 domain separator.
     */
    function domainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP712_DOMAIN_TYPEHASH,
                    _EIP712_DOMAIN_NAME,
                    _EIP712_DOMAIN_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice The underlying ERC721 collection contract.
     * @return ERC721  The underlying ERC721 collection contract.
     */
    function collection() public pure returns (ERC721) {
        return ERC721(_getArgAddress(_IMMUTABLE_ARG_OFFSET_COLLECTION));
    }

    /**
     * @notice The descriptive name for a collection of NFTs in this contract.
     * @dev    We are returning the value of `name()` on the underlying ERC721
     *         contract for parity between the derivatives and the actual assets.
     * @return string  The descriptive name for a collection of NFTs in this contract.
     */
    function name() external view returns (string memory) {
        return collection().name();
    }

    /**
     * @notice An abbreviated name for NFTs in this contract.
     * @dev    We are returning the value of `symbol()` on the underlying ERC721
     *         contract for parity between the derivatives and the actual assets.
     * @return string  An abbreviated name for NFTs in this contract.
     */
    function symbol() external view returns (string memory) {
        return collection().symbol();
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev    To maintain clear separation between WERC721 and ERC721 contracts,
     *         we are only returning a URI for wrapped tokens (throws otherwise).
     * @dev    We are returning the value of `tokenURI(id)` on the underlying ERC721
     *         contract for parity between the derivatives and the actual assets.
     * @param  id  uint256  The identifier for an NFT.
     * @return     string   A valid URI for the asset.
     */
    function tokenURI(uint256 id) external view returns (string memory) {
        // Throws if the token ID is not a wrapped ERC721.
        if (_ownerOf[id] == address(0)) revert NotWrappedToken();

        return collection().tokenURI(id);
    }

    /**
     * @notice Find the owner of an NFT.
     * @dev    NFTs assigned to zero address are considered invalid, and queries about them do throw.
     * @param  id     uint256  The identifier for an NFT.
     * @return owner  address  The address of the owner of the NFT.
     */
    function ownerOf(uint256 id) external view returns (address owner) {
        // Throw if `owner` is the zero address.
        if ((owner = _ownerOf[id]) == address(0)) revert NotWrappedToken();
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets.
     * @param  operator  address  Address to add to the set of authorized operators.
     * @param  approved  bool     True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Transfer ownership of an NFT.
     * @param  from  address  The current owner of the NFT.
     * @param  to    address  The new owner.
     * @param  id    uint256  The NFT to transfer.
     */
    function transferFrom(address from, address to, uint256 id) external {
        if (from != _ownerOf[id]) revert NotTokenOwner();
        if (to == address(0)) revert UnsafeTokenRecipient();
        if (msg.sender != from && !isApprovedForAll[from][msg.sender])
            revert NotApprovedOperator();

        _ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    /**
     * @notice Transfer ownership of an NFT with an authorization.
     * @dev    Based on: https://eips.ethereum.org/EIPS/eip-3009.
     * @param  from         address  The current owner of the NFT and authorizer.
     * @param  to           address  The new owner.
     * @param  id           uint256  The NFT to transfer.
     * @param  validAfter   uint256  The time after which this is valid (unix time).
     * @param  validBefore  uint256  The time before which this is valid (unix time).
     * @param  nonce        bytes32  Unique nonce.
     * @param  v            uint8    Signature param.
     * @param  r            bytes32  Signature param.
     * @param  s            bytes32  Signature param.
     */
    function transferFromWithAuthorization(
        address from,
        address to,
        uint256 id,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (from != _ownerOf[id]) revert NotTokenOwner();
        if (to == address(0)) revert UnsafeTokenRecipient();
        if (block.timestamp <= validAfter || block.timestamp >= validBefore)
            revert InvalidTransferAuthorization();
        if (authorizationState[from][nonce]) revert TransferAuthorizationUsed();

        // This is called before the signature is verified due to `isValidSignatureNow`
        // resulting in an external call if the signer is a contract account (staticcall
        // but erring on the overly-safe side and for the sake of consistency @ applying
        // the CEI pattern).
        authorizationState[from][nonce] = true;

        emit AuthorizationUsed(from, nonce);

        _ownerOf[id] = to;

        emit Transfer(from, to, id);

        if (
            !SignatureCheckerLib.isValidSignatureNow(
                from,
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        // Prevents collision with other contracts that may use the same structured data (the unique element is this contract's address).
                        domainSeparator(),
                        keccak256(
                            abi.encode(
                                _TRANSFER_FROM_WITH_AUTHORIZATION_TYPEHASH,
                                // `msg.sender` must match `relayer` (i.e. account allowed to perform authorized transfers on behalf of `from`).
                                msg.sender,
                                from,
                                to,
                                id,
                                validAfter,
                                validBefore,
                                nonce
                            )
                        )
                    )
                ),
                v,
                r,
                s
            )
        ) revert InvalidTransferAuthorization();
    }

    /**
     * @notice Cancel an authorization.
     * @param  nonce  bytes32  Unique nonce.
     */
    function cancelTransferFromAuthorization(bytes32 nonce) external {
        if (authorizationState[msg.sender][nonce])
            revert TransferAuthorizationUsed();

        // Prevents future usage.
        authorizationState[msg.sender][nonce] = true;

        emit AuthorizationCanceled(msg.sender, nonce);
    }

    /**
     * @notice Wrap an ERC721 NFT.
     * @param  to  address  The recipient of the wrapped ERC721 NFT.
     * @param  id  uint256  The NFT to deposit and wrap.
     */
    function wrap(address to, uint256 id) external {
        if (to == address(0)) revert UnsafeTokenRecipient();

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);

        collection().transferFrom(msg.sender, address(this), id);
    }

    /**
     * @notice Unwrap an ERC721 NFT.
     * @param  to  address  The recipient of the unwrapped ERC721 NFT.
     * @param  id  uint256  The NFT to unwrap and withdraw.
     */
    function unwrap(address to, uint256 id) external {
        if (_ownerOf[id] != msg.sender) revert NotTokenOwner();
        if (to == address(0)) revert UnsafeTokenRecipient();

        delete _ownerOf[id];

        emit Transfer(msg.sender, address(0), id);

        collection().transferFrom(address(this), to, id);
    }

    /**
     * @notice Wrap an ERC721 NFT using a "safe" ERC721 transfer method (e.g. `safeTransferFrom` or `safeMint`).
     * @dev    It is the responsibility of the ERC721 contract creator to implement `onERC721Received` calls correctly!
     * @param  id    uint256  The NFT to deposit and wrap.
     * @param  data  bytes    Encoded recipient address.
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4) {
        // Prevents minting WERC721s via this method outside of the collection's safe transfer call flow.
        if (msg.sender != address(collection())) revert NotAuthorizedCaller();

        // Will throw if `data` is an empty byte array.
        address to = abi.decode(data, (address));

        if (to == address(0)) revert UnsafeTokenRecipient();

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Query if a contract implements an interface
     * @param  interfaceID  bytes4  The interface identifier, as specified in ERC165.
     * @return              bool    Returns `true` if the contract implements `interfaceID`.
     */
    function supportsInterface(
        bytes4 interfaceID
    ) external pure returns (bool) {
        return (interfaceID == _ERC165_INTERFACE_ID ||
            interfaceID == _ERC165_INTERFACE_ID_ERC721_TOKEN_RECEIVER ||
            interfaceID == _ERC165_INTERFACE_ID_ERC721_METADATA);
    }
}