// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/ICollateralWrapper.sol";

/**
 * @title ERC1155 Collateral Wrapper
 * @author MetaStreet Labs
 */
contract ERC1155CollateralWrapper is ICollateralWrapper, ERC721, ERC1155Holder, ReentrancyGuard {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**
     * @notice Maximum token IDs
     */
    uint256 internal constant MAX_TOKEN_IDS = 32;

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid caller
     */
    error InvalidCaller();

    /**
     * @notice Invalid context
     */
    error InvalidContext();

    /**
     * @notice Invalid token IDs size
     */
    error InvalidSize();

    /**
     * @notice Invalid token id
     */
    error InvalidOrdering();

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Encoding nonce
     */
    uint256 private _nonce;

    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when batch is minted
     * @param tokenId Token ID of the new collateral wrapper token
     * @param account Address that created the batch
     * @param encodedBatch Encoded batch data
     */
    event BatchMinted(uint256 indexed tokenId, address indexed account, bytes encodedBatch);

    /**
     * @notice Emitted when batch is unwrapped
     * @param tokenId Token ID of the batch collateral wrapper token
     * @param account Address that unwrapped the batch
     */
    event BatchUnwrapped(uint256 indexed tokenId, address indexed account);

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice BatchCollateralWrapper constructor
     */
    constructor() ERC721("MetaStreet ERC1155 Collateral Wrapper", "MSMTCW") {}

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc ICollateralWrapper
     */
    function name() public pure override(ERC721, ICollateralWrapper) returns (string memory) {
        return "MetaStreet ERC1155 Collateral Wrapper";
    }

    /**
     * @inheritdoc ERC721
     */
    function symbol() public pure override returns (string memory) {
        return "MSMTCW";
    }

    /**
     * @notice Check if token ID exists
     * @param tokenId Token ID
     * @return True if token ID exists, otherwise false
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @inheritdoc ICollateralWrapper
     */
    function enumerate(uint256 tokenId, bytes calldata context) external view returns (address, uint256[] memory) {
        if (tokenId != uint256(_hash(context))) revert InvalidContext();

        /* Decode context */
        (address token, , , uint256[] memory tokenIds, ) = abi.decode(
            context,
            (address, uint256, uint256, uint256[], uint256[])
        );

        return (token, tokenIds);
    }

    /**
     * @inheritdoc ICollateralWrapper
     */
    function count(uint256 tokenId, bytes calldata context) external view returns (uint256) {
        if (tokenId != uint256(_hash(context))) revert InvalidContext();

        /* Decode context */
        (, , uint256 count_, , ) = abi.decode(context, (address, uint256, uint256, uint256[], uint256[]));

        return count_;
    }

    /**************************************************************************/
    /* Internal Helpers */
    /**************************************************************************/

    /**
     * @dev Compute hash of encoded batch
     * @param encodedBatch Encoded batch
     * @return batchTokenId Hash
     */
    function _hash(bytes memory encodedBatch) internal view returns (bytes32) {
        /* Take hash of chain ID (32 bytes) concatenated with encoded batch */
        return keccak256(abi.encodePacked(block.chainid, encodedBatch));
    }

    /**************************************************************************/
    /* User API */
    /**************************************************************************/

    /**
     * @notice Deposit a ERC1155 collateral into contract and mint a ERC1155CollateralWrapper token
     *
     * Emits a {BatchMinted} event
     *
     * @dev Collateral token, nonce, token ids, batch size, and quantities are encoded,
     * hashed and stored as the ERC1155CollateralWrapper token ID.
     * @param token Collateral token address
     * @param tokenIds List of token ids
     * @param quantities List of quantities
     */
    function mint(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata quantities
    ) external nonReentrant returns (uint256) {
        /* Validate token IDs and quantities */
        if (tokenIds.length == 0 || tokenIds.length > MAX_TOKEN_IDS || tokenIds.length != quantities.length)
            revert InvalidSize();

        /* Validate token ID and quantity */
        uint256 batchSize;
        for (uint256 i; i < tokenIds.length; i++) {
            /* Validate unique token ID */
            if (i != 0 && tokenIds[i] <= tokenIds[i - 1]) revert InvalidOrdering();

            /* Validate quantity is non-zero */
            if (quantities[i] == 0) revert InvalidSize();

            /* Compute batch size */
            batchSize += quantities[i];
        }

        /* Create encoded batch and increment nonce */
        bytes memory encodedBatch = abi.encode(token, _nonce++, batchSize, tokenIds, quantities);

        /* Hash encoded batch */
        uint256 tokenId = uint256(_hash(encodedBatch));

        /* Batch transfer tokens */
        IERC1155(token).safeBatchTransferFrom(msg.sender, address(this), tokenIds, quantities, "");

        /* Mint ERC1155CollateralWrapper token */
        _mint(msg.sender, tokenId);

        emit BatchMinted(tokenId, msg.sender, encodedBatch);

        return tokenId;
    }

    /**
     * Emits a {BatchUnwrapped} event
     *
     * @inheritdoc ICollateralWrapper
     */
    function unwrap(uint256 tokenId, bytes calldata context) external nonReentrant {
        if (tokenId != uint256(_hash(context))) revert InvalidContext();
        if (msg.sender != ownerOf(tokenId)) revert InvalidCaller();

        /* Decode context */
        (address token, , , uint256[] memory tokenIds, uint256[] memory quantities) = abi.decode(
            context,
            (address, uint256, uint256, uint256[], uint256[])
        );

        /* Burn ERC1155CollateralWrapper token */
        _burn(tokenId);

        /* Batch transfer tokens back to token owner */
        IERC1155(token).safeBatchTransferFrom(address(this), msg.sender, tokenIds, quantities, "");

        emit BatchUnwrapped(tokenId, msg.sender);
    }

    /******************************************************/
    /* ERC165 interface */
    /******************************************************/

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC1155Receiver) returns (bool) {
        return interfaceId == type(ICollateralWrapper).interfaceId || super.supportsInterface(interfaceId);
    }
}