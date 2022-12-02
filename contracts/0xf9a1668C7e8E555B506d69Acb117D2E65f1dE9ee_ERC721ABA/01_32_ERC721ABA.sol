// SPDX-License-Identifier: BUSL-1.1
// Creator: JCBDEV (Quantum Art)
pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../ERC2981V3.sol";
import "../../TokenId.sol";
import "../../ManageableUpgradeable.sol";
import "./ERC721ABAStorage.sol";
import "../interfaces/IMintByUri.sol";
import "../libs/Errors.sol";

error VariantAndMintAmountMismatch();
error InvalidVariantForDrop();
error MintExceedsDropSupply();
error NonceAlreadyUsed();
error DropPaused();
error ContractLocked();
error MetadataLocked();
error IncorrectFees(uint256 expectedFee, uint256 suppliedMsgValue);

// Keyholders
// Public mint -

contract ERC721ABA is
    ERC2981,
    OwnableUpgradeable,
    ManageableUpgradeable,
    ERC721AUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IMintByUri
{
    using ERC721ABAStorage for ERC721ABAStorage.Layout;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using StringsUpgradeable for uint256;
    using TokenId for uint256;

    /// >>>>>>>>>>>>>>>>>>>>>>>  CUSTOM EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(address admin, bytes memory data)
        public
        virtual
        initializer
    {
        __ERC721ABA_init(admin, data);
    }

    function __ERC721ABA_init(address admin, bytes memory data)
        internal
        onlyInitializing
    {
        __ERC721A_init("ERC721ABA", "QBCBA");
        __Ownable_init();
        __Manageable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ERC721ABA_init_unchained(admin, data);
    }

    function __ERC721ABA_init_unchained(address admin, bytes memory data)
        internal
        onlyInitializing
    {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        es.baseURI = "https://core-api.quantum.art/v1/drop/metadata/studio/";
        es.ipfsURI = "ipfs://";
        es.isContractLocked = false;
        es.isMetadataLocked = false;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        if (es.isContractLocked) {
            revert ContractLocked();
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI()
        internal
        view
        override(ERC721AUpgradeable)
        returns (string memory)
    {
        // revert(ERC721ABAStorage.layout().baseURI);
        return ERC721ABAStorage.layout().baseURI;
    }

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(MINTER_ROLE, minter);
        grantRole(MINTER_ROLE, minter);
    }

    /// @notice remove address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function unsetMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, minter);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice Locks contract upgrades
    function setContractLocked() public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC721ABAStorage.layout().isContractLocked = true;
    }

    /// @notice Locks metadata upgrades
    function setMetadataLocked() public onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC721ABAStorage.layout().isMetadataLocked = true;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        if (es.isMetadataLocked) {
            revert MetadataLocked();
        }
        ERC721ABAStorage.layout().baseURI = baseURI;
    }

    /// @notice set the base ipfs URI
    /// @param ipfsURI new base
    function setIpfsURI(string calldata ipfsURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        if (es.isMetadataLocked) {
            revert MetadataLocked();
        }
        ERC721ABAStorage.layout().ipfsURI = ipfsURI;
    }

    /// @notice Pause contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice set the IPFS CID
    /// @param cid cid
    function setCID(string calldata cid) public onlyRole(MANAGER_ROLE) {
        ERC721ABAStorage.layout().CID = cid;
    }

    /// @notice configure drop
    /// @param maxSupply maximum items in the drop
    function setSupply(uint128 maxSupply) public onlyRole(MANAGER_ROLE) {
        ERC721ABAStorage.layout().maxSupply = maxSupply;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient)
        public
        onlyRole(MANAGER_ROLE)
    {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public onlyRole(MANAGER_ROLE) {
        _royaltyFee = fee;
    }

    /// @notice Mints new ERC721ABA
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param amount amount of tokens to mint
    function mintBatch(address to, uint128 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        if (es.maxSupply == 0 || totalSupply() + amount > es.maxSupply)
            revert MintExceedsDropSupply();
        _safeMint(to, amount);
    }

    /// @notice Mints new ERC721ABA
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();
        if (es.maxSupply == 0 || totalSupply() + 1 > es.maxSupply)
            revert MintExceedsDropSupply();
        if (bytes(uri).length > 0) es.tokenURIs[totalSupply() + 1] = uri;
        _safeMint(to, 1);
    }

    /// @notice Burns token that has been redeemed for something else
    /// @dev Relay Only
    /// @param tokenId id of the tokens
    function redeemBurn(uint256 tokenId)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _burn(tokenId, false);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        ERC721ABAStorage.Layout storage es = ERC721ABAStorage.layout();

        if (bytes(es.tokenURIs[tokenId]).length > 0)
            return es.tokenURIs[tokenId];

        if (bytes(es.CID).length > 0) {
            return
                string(
                    abi.encodePacked(
                        es.ipfsURI,
                        es.CID,
                        "/",
                        tokenId.toString()
                    )
                );
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function maxSupply() public view returns (uint256) {
        return ERC721ABAStorage.layout().maxSupply;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Burns token
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public whenNotPaused {
        _burn(tokenId, true);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721AUpgradeable,
            ERC2981,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  HOOKS  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}