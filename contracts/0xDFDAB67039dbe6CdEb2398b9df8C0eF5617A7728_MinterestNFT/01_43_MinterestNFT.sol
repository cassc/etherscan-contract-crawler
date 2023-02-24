// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IMinterestNFT.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

/**
 * @title MinterestNFT
 * @dev Contract module which provides functionality to mint new ERC1155 tokens
 *      Each token connected with image and metadata. The image and metadata saved
 *      on IPFS and this contract stores the CID of the folder where lying metadata.
 *      Also each token belongs one of the Minterest tiers, and give some emission
 *      boost for Minterest distribution system.
 */
contract MinterestNFT is IMinterestNFT, ERC1155, AccessControl, InterconnectorLeaf {
    using Counters for Counters.Counter;
    using Strings for string;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    /// Name for Minterst NFT Token
    string public constant name = "Minterest NFT";
    /// Symbol for Minterst NFT Token
    string public constant symbol = "MNFT";

    /// Address of opensea proxy registry, for opensea integration
    ProxyRegistry public immutable proxyRegistry;
    /// @dev ERC1155 id, Indicates a specific token or token type
    Counters.Counter private idCounter;

    /**
     * @notice Initialize contract
     * @param _baseURI Base of URI where stores images
     * @param _admin The address of the Admin
     */
    constructor(
        string memory _baseURI,
        ProxyRegistry _proxyRegistry,
        address _admin
    ) ERC1155(_baseURI) {
        require(address(_proxyRegistry) != address(0), ErrorCodes.ZERO_ADDRESS);
        require(_admin != address(0), ErrorCodes.ZERO_ADDRESS);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        proxyRegistry = _proxyRegistry;
    }

    /*** External user-defined functions ***/

    /// @inheritdoc IMinterestNFT
    function mint(
        address account_,
        uint256 amount_,
        bytes memory data_,
        uint256 tier_
    ) external onlyRole(GATEKEEPER) {
        idCounter.increment();
        uint256 id = idCounter.current();

        _mint(account_, id, amount_, data_);

        if (tier_ > 0) {
            emissionBooster().onMintToken(
                account_,
                _asSingletonArray2(id),
                _asSingletonArray2(amount_),
                _asSingletonArray2(tier_)
            );
        }
    }

    /// @inheritdoc IMinterestNFT
    function mintBatch(
        address account_,
        uint256[] memory amounts_,
        bytes memory data_,
        uint256[] memory tiers_
    ) external onlyRole(GATEKEEPER) {
        require(tiers_.length == amounts_.length, ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL);

        uint256[] memory ids = new uint256[](amounts_.length);
        for (uint256 i = 0; i < amounts_.length; i++) {
            idCounter.increment();
            uint256 id = idCounter.current();

            ids[i] = id;
        }

        _mintBatch(account_, ids, amounts_, data_);

        emissionBooster().onMintToken(account_, ids, amounts_, tiers_);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     */
    function _beforeTokenTransfer(
        address,
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory
    ) internal virtual override {
        // Ignore mint transfers
        if (from_ != address(0)) emissionBooster().onTransferToken(from_, to_, ids_, amounts_);
    }

    /// @inheritdoc IMinterestNFT
    function safeTransfer(
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external {
        safeTransferFrom(msg.sender, to_, id_, amount_, data_);
    }

    /// @inheritdoc IMinterestNFT
    function safeBatchTransfer(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external {
        safeBatchTransferFrom(msg.sender, to_, ids_, amounts_, data_);
    }

    /*** Admin Functions ***/

    /// @inheritdoc IMinterestNFT
    function setURI(string memory newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newBaseUri);
        emit NewBaseUri(newBaseUri);
    }

    /*** Helper special functions ***/

    /// @inheritdoc IMinterestNFT
    function uri(uint256 tokenId_) public view override(ERC1155, IMinterestNFT) returns (string memory) {
        return
            _exists(tokenId_)
                ? string(abi.encodePacked(super.uri(tokenId_), Strings.toString(tokenId_), ".json"))
                : super.uri(tokenId_);
    }

    /// @inheritdoc IMinterestNFT
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC1155, IMinterestNFT)
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(_owner) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /// @inheritdoc IMinterestNFT
    function nextIdToBeMinted() external view returns (uint256) {
        return idCounter.current() + 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(AccessControl, ERC1155, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC1155).interfaceId;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) private view returns (bool) {
        return _id > 0 && _id <= idCounter.current();
    }

    function _asSingletonArray2(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }

    function emissionBooster() internal view returns (IEmissionBooster) {
        return getInterconnector().emissionBooster();
    }
}