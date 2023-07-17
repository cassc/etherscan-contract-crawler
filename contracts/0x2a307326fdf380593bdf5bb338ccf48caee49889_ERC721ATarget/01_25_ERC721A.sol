// SPDX-License-Identifier: BUSL-1.1
// Creator: JCBDEV (Quantum Art)
pragma solidity ^0.8.4;

import {ERC721A as ERC721ABase} from "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// WARNING: use of non-upgradable version will make it impossible to upgrade any contract without option "unsafeAllow: ['delegatecall']".
// Trying to upgrade would cause this error:
//      Error: Contract `ContractName` is not upgrade safe
//      @openzeppelin/contracts/utils/Address.sol:191: Use of delegatecall is not allowed
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/IRoyaltySplitter.sol";
import "../libs/EIP2981.sol";
import "../interfaces/ICollection.sol";
import "../interfaces/ITargetInitializer.sol";
import "../libs/Errors.sol";

error VariantAndMintAmountMismatch();
error InvalidVariantForDrop();
error MintExceedsDropSupply();
error NonceAlreadyUsed();
error DropPaused();
error ContractLocked();
error MetadataLocked();
error IncorrectFees(uint256 expectedFee, uint256 suppliedMsgValue);
error IncorrectSplitTotal(uint256 expectedTotal, uint256 total);
error RoyaltiesMismatch(uint256 splits, uint256 recipients);

// Keyholders
// Public mint -

contract ERC721ATarget is
    EIP2981,
    Ownable,
    AccessControlEnumerable,
    ERC721ABase,
    Pausable,
    Initializable,
    ITargetInitializer,
    IMintByUri,
    IRoyaltySplitter
{
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    /// >>>>>>>>>>>>>>>>>>>>>>>  CUSTOM EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string CID;
    mapping(uint256 => bool) noncesUsed;
    mapping(uint256 => string) tokenURIs;
    string ipfsURI;
    string baseURI;
    bool isMetadataLocked;

    uint16[] royaltySplits;
    address payable[] royaltyRecipients;

    bool private _initialized;
    bool private _initializing;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    constructor(
        string memory _init_name,
        string memory _init_symbol,
        TargetInit memory params,
        bytes memory data
    ) ERC721ABase(_init_name, _init_symbol) {
        _name = _init_name;
        _symbol = _init_symbol;

        baseURI = "https://core-api.quantum.art/v1/drop/metadata/studio/";
        ipfsURI = "ipfs://";
        isMetadataLocked = false;
        _royaltyRecipient = params.royaltyRecipients[0];
        _royaltyFee = params.royaltyFee;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, params.admin);

        _setupRole(MANAGER_ROLE, params.admin);
        _setupRole(MANAGER_ROLE, params.manager);

        _setupRole(MINTER_ROLE, params.admin);
        _setupRole(MINTER_ROLE, params.minter);

        _setupRole(CREATOR_ROLE, params.creator);

        // owner set to msg.sender in `Ownable`. Sertting owner with _transferOwnership
        // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2639#issuecomment-1253408868
        _transferOwnership(params.admin);

        setUpRecipients(params.royaltySplits, params.royaltyRecipients);
    }

    function initialize(
        string memory _init_name,
        string memory _init_symbol,
        TargetInit calldata params,
        bytes memory data
    ) public virtual initializer {
        _name = _init_name;
        _symbol = _init_symbol;

        baseURI = "https://core-api.quantum.art/v1/drop/metadata/studio/";
        ipfsURI = "ipfs://";
        isMetadataLocked = false;
        _royaltyRecipient = params.royaltyRecipients[0];
        _royaltyFee = params.royaltyFee;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        _setupRole(DEFAULT_ADMIN_ROLE, params.admin);

        _setupRole(MANAGER_ROLE, params.admin);
        _setupRole(MANAGER_ROLE, params.manager);

        _setupRole(MINTER_ROLE, params.admin);
        _setupRole(MINTER_ROLE, params.minter);

        _setupRole(CREATOR_ROLE, params.creator);

        // owner set to msg.sender in `Ownable`. Sertting owner with _transferOwnership
        // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2639#issuecomment-1253408868
        _transferOwnership(params.admin);

        setUpRecipients(params.royaltySplits, params.royaltyRecipients);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI()
        internal
        view
        override(ERC721ABase)
        returns (string memory)
    {
        return baseURI;
    }

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be wallet proxy or sales platform
    function setMinter(address minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
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

    /// @notice Locks metadata upgrades
    function setMetadataLocked() public onlyRole(DEFAULT_ADMIN_ROLE) {
        isMetadataLocked = true;
    }

    /// @notice set the baseURI
    /// @param newBaseURI new base
    function setBaseURI(string calldata newBaseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (isMetadataLocked) {
            revert MetadataLocked();
        }
        baseURI = newBaseURI;
    }

    /// @notice set the base ipfs URI
    /// @param _ipfsURI new base
    function setIpfsURI(string calldata _ipfsURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (isMetadataLocked) {
            revert MetadataLocked();
        }
        ipfsURI = _ipfsURI;
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
        CID = cid;
    }

    /// @notice builds Recipients and calls IRoyaltySplitter setRecipients
    /// @dev The bps must add up to total of 10000 (100%).
    /// @dev Recipient address and split count must match
    /// @param _royaltySplits uint16[]
    /// @param _royaltyRecipients address[]
    function setUpRecipients(
        uint16[] memory _royaltySplits,
        address payable[] memory _royaltyRecipients
    ) public onlyRole(MANAGER_ROLE) {
        if (_royaltySplits.length != _royaltyRecipients.length) {
            revert RoyaltiesMismatch(
                _royaltySplits.length,
                _royaltyRecipients.length
            );
        }

        uint32 mBpTotal = 0;
        for (uint256 i = 0; i < _royaltyRecipients.length; i++) {
            if (_royaltyRecipients[i] == address(0)) revert PayoutZeroAddress();

            mBpTotal += _royaltySplits[i];
        }

        if (mBpTotal != 10000) {
            revert IncorrectSplitTotal(10000, mBpTotal);
        }

        royaltySplits = _royaltySplits;
        royaltyRecipients = _royaltyRecipients;
    }

    /// @notice sets the royalty recipients address and split
    /// @dev The bps must add up to total of 10000 (100%).
    /// @param _recipients Recipient[]
    function setRecipients(Recipient[] calldata _recipients)
        public
        onlyRole(MANAGER_ROLE)
    {
        uint16[] memory _royaltySplits = new uint16[](_recipients.length);
        address payable[] memory _royaltyRecipients = new address payable[](
            _recipients.length
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _royaltySplits[i] = _recipients[i].bps;
            _royaltyRecipients[i] = _recipients[i].recipient;
        }

        setUpRecipients(_royaltySplits, _royaltyRecipients);
    }

    /// @notice gets the royalty recipient addresses and splits
    function getRecipients() external view returns (Recipient[] memory) {
        Recipient[] memory mRecipients = new Recipient[](
            royaltyRecipients.length
        );

        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            Recipient memory recipient = Recipient(
                royaltyRecipients[i],
                royaltySplits[i]
            );
            mRecipients[i] = recipient;
        }
        return mRecipients;
    }

    /// @notice changes the address of the royalty recipient
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

    /// @notice Mints new ERC721A
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param amount amount of tokens to mint
    function mintBatch(address to, uint128 amount)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
    {
        _safeMint(to, amount);
    }

    /// @notice Mints new ERC721A
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) whenNotPaused {
        if (bytes(uri).length > 0) tokenURIs[totalSupply()] = uri;
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

        if (bytes(tokenURIs[tokenId]).length > 0) return tokenURIs[tokenId];

        if (bytes(CID).length > 0) {
            return
                string(abi.encodePacked(ipfsURI, CID, "/", tokenId.toString()));
        } else {
            return super.tokenURI(tokenId);
        }
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
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
        override(ERC721ABase, EIP2981, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return
            ERC721ABase.supportsInterface(interfaceId) ||
            EIP2981.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC165.supportsInterface(interfaceId) ||
            interfaceId == type(IRoyaltySplitter).interfaceId;
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