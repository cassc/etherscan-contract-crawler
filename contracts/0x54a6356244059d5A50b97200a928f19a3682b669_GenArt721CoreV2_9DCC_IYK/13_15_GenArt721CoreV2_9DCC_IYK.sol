// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../GenArt721CoreV2_PBAB.sol";

import "@openzeppelin-4.5/contracts/utils/cryptography/ECDSA.sol";
import "./ISignVerifierRegistry.sol";

pragma solidity 0.8.9;

/**
 * @title Powered by Art Blocks ERC-721 core contract.
 * Support for IYK pull mechanism to transfer tokens based on verified signatures
 * @notice Due to the pull mechanism (claimNFT) being the only supported transfer function, these NFTs will NOT be tradeable on secondary marketplaces
 * @author Art Blocks Inc. + IYK GMI Inc.
 */
contract GenArt721CoreV2_9DCC_IYK is GenArt721CoreV2_PBAB {
    using ECDSA for bytes32;

    event SignVerifierRegistryUpdated(
        address indexed signVerifierRegistry,
        address indexed oldSignVerifierRegistry
    );
    event SignVerifierIdUpdated(
        bytes32 indexed signVerifierId,
        bytes32 indexed oldSignVerifierId
    );

    // Address of registry that resolves the signVerifier
    ISignVerifierRegistry public signVerifierRegistry;
    bytes32 public signVerifierId;

    // Nonce per user, used to prevent replay signature attacks
    mapping(address => uint256) public claimNonces;

    /**
     * @notice Initializes contract.
     * @param _tokenName Name of token.
     * @param _tokenSymbol Token symbol.
     * @param _randomizerContract Randomizer contract.
     * @param _startingProjectId The initial next project ID.
     * @param _signVerifierRegistry Address of registry that resolves the signVerifierId.
     * @param _signVerifierId ID of the signVerifier.
     * @dev _startingProjectId should be set to a value much, much less than
     * max(uint256) to avoid overflow when adding to it.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _randomizerContract,
        uint256 _startingProjectId,
        address _signVerifierRegistry,
        bytes32 _signVerifierId
    )
        GenArt721CoreV2_PBAB(
            _tokenName,
            _tokenSymbol,
            _randomizerContract,
            _startingProjectId
        )
    {
        require(
            _signVerifierRegistry != address(0),
            "_signVerifierRegistry cannot be the zero address"
        );
        require(
            _signVerifierId != bytes32(0),
            "_signVerifierId cannot be the zero ID"
        );
        require(
            IERC165(_signVerifierRegistry).supportsInterface(
                type(ISignVerifierRegistry).interfaceId
            ),
            "_signVerifierRegistry does not implement ISignVerifierRegistry"
        );

        signVerifierRegistry = ISignVerifierRegistry(_signVerifierRegistry);
        signVerifierId = _signVerifierId;

        emit SignVerifierRegistryUpdated(_signVerifierRegistry, address(0));
        emit SignVerifierIdUpdated(_signVerifierId, bytes32(0));
    }

    /**
     * @notice Transfers a token from its owner to the recipient
     * @param _sig The result of getClaimSigningHash signed by the signVerifier
     * @param _blockExpiry The block as of which the signature is no longer valid
     * @param _recipient The address that receives the token
     * @param _tokenId The tokenId being claimed
     * @dev ECDSA signatures are used to verify the permission to claim a NFT. ECDSA.recover will revert if the signer (signVerifier) is the zero address.
     */
    function claimNFT(
        bytes memory _sig,
        uint256 _blockExpiry,
        address _recipient,
        uint256 _tokenId
    ) public {
        bytes32 messageHash = getClaimSigningHash(
            _blockExpiry,
            _recipient,
            _tokenId
        ).toEthSignedMessageHash();
        require(
            ECDSA.recover(messageHash, _sig) == getSignVerifier(),
            "Permission to call this function failed"
        );
        require(block.number < _blockExpiry, "Sig expired");

        address from = ownerOf(_tokenId);
        require(from != address(0));

        claimNonces[_recipient]++;

        _safeTransfer(from, _recipient, _tokenId, "");
    }

    /**
     * @notice Returns the current claim nonce of a address
     * @param _recipient The address whose nonce is being fetched
     * @return nonce The addresses current nonce
     * @dev This view exposes the nonce as it will be required for the signature.
     * By including a nonce in the signature and updating the nonce on every claim,
     * we prevent replay signature attacks, as signatures can only be used once.
     */
    function getClaimNonce(address _recipient)
        external
        view
        virtual
        returns (uint256)
    {
        return claimNonces[_recipient];
    }

    /**
     * @notice Returns the hash that we expect was signed in claimNFT.
     * @param _blockExpiry As of which block the signature is no longer valid
     * @param _recipient The address who receives the token
     * @param _tokenId The tokenId being claimed
     * @return hash A bytes32 hash that is signed by the signVerifier
     * @dev claimNFT uses this view to get the expected hash to have been signed - hashes cannot be replayed since claimNFT verifies using the current hash and increments the hash on a successful claim.
     */
    function getClaimSigningHash(
        uint256 _blockExpiry,
        address _recipient,
        uint256 _tokenId
    ) public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _blockExpiry,
                    _recipient,
                    _tokenId,
                    address(this),
                    claimNonces[_recipient]
                )
            );
    }

    /**
     * @notice Updates the sign verifier registry address
     * @param _signVerifierRegistry The address the new registry
     * @dev Requires the DEFAULT_ADMIN_ROLE to call
     */
    function setSignVerifierRegistry(address _signVerifierRegistry)
        external
        onlyAdmin
    {
        require(
            _signVerifierRegistry != address(0),
            "_signVerifierRegistry cannot be the zero address"
        );
        require(
            IERC165(_signVerifierRegistry).supportsInterface(
                type(ISignVerifierRegistry).interfaceId
            ),
            "_signVerifierRegistry does not implement ISignVerifierRegistry"
        );

        address oldSignVerifierRegistry = address(signVerifierRegistry);
        signVerifierRegistry = ISignVerifierRegistry(_signVerifierRegistry);

        emit SignVerifierRegistryUpdated(
            _signVerifierRegistry,
            oldSignVerifierRegistry
        );
    }

    /**
     * @notice Updates the ID of the sign verifier
     * @dev Requires the DEFAULT_ADMIN_ROLE to call
     * @param _signVerifierId The ID of the new sign verifier
     */
    function setSignVerifierId(bytes32 _signVerifierId) external onlyAdmin {
        require(
            _signVerifierId != bytes32(0),
            "_signVerifierId cannot be the zero ID"
        );

        bytes32 oldSignVerifierId = signVerifierId;
        signVerifierId = _signVerifierId;

        emit SignVerifierIdUpdated(_signVerifierId, oldSignVerifierId);
    }

    /**
     * @notice Returns the address of the sign verifier
     */
    function getSignVerifier() public view returns (address) {
        address signVerifier = signVerifierRegistry.get(signVerifierId);
        require(
            signVerifier != address(0),
            "cannot use zero address as sign verifier"
        );
        return signVerifier;
    }

    /**
     * @notice transferFrom has been overriden to make it useless
     * @dev Behavior replaced by pull mechanism in claimNFT
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        revert("ERC721 public transfer functions are not allowed");
    }

    /**
     * @notice safeTransferFrom has been overriden to make it useless
     * @dev Behavior replaced by pull mechanism in claimNFT
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        revert("ERC721 public transfer functions are not allowed");
    }

    /**
     * @notice safeTransferFrom has been overriden to make it useless
     * @dev Behavior replaced by pull mechanism in claimNFT
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override {
        revert("ERC721 public transfer functions are not allowed");
    }
}