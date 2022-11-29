// SPDX-License-Identifier: Apache-2.0
// Thirdweb Contracts v3.1.10 (contracts/TokenERC1155.sol)

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@thirdweb-dev/contracts/extension/interface/IOwnable.sol";


contract BLSTokenERC1155 is
    Initializable,
    IOwnable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155URIStorageUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155PausableUpgradeable,
    ERC2981Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    CountersUpgradeable.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    // @dev The percentage of royalty how much royalty in basis points.
    uint96 private defaultRoyaltyBps;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _defaultAdmin,
        uint96 _defaultRoyaltyBps,
        address _defaultRoyaltyRecipient
    ) public virtual initializer {
        __ERC1155_init_unchained(_tokenURI);
        __Pausable_init_unchained();
        _setBaseURI(_tokenURI);

        name = _name;
        symbol = _symbol;

         // Initialize this contract's state.
        _owner = _defaultAdmin;

        defaultRoyaltyBps = _defaultRoyaltyBps;
        _setDefaultRoyalty(_defaultRoyaltyRecipient, _defaultRoyaltyBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(PAUSER_ROLE, _defaultAdmin);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the address of the current owner.
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    ///     =====   External functions  =====

    function mintTo(
        address _to,
        uint256 _tokenId,
        string calldata _uri,
        uint256 _amount,
        bytes memory data
    ) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BLSTokenERC1155: must have minter role to mint");
        uint256 tokenIdToMint;

        if (_tokenId == type(uint256).max) {
            tokenIdToMint = _tokenIdTracker.current();
            _tokenIdTracker.increment();
        } else {
            require(_tokenId < _tokenIdTracker.current(), "invalid id");
            tokenIdToMint = _tokenId;
        }

        _mint(_to, tokenIdToMint, _amount, data);
        _setURI(tokenIdToMint, _uri);
        _setTokenRoyalty(tokenIdToMint, _to, defaultRoyaltyBps);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        string[] calldata _uri,
        uint256[] memory _amounts,
        bytes memory _data
    ) external virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BLSTokenERC1155: must have minter role to mint");

        _mintBatch(_to, _ids, _amounts, _data);

        for (uint256 i = 0; i < _ids.length; i++) {
            _setURI(_ids[i], _uri[i]);
            _setTokenRoyalty(_ids[i], _to, defaultRoyaltyBps);
        }
    }

    function pause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    function unpause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    //      =====   Setter functions  =====

    /// @dev Change base token URI
    function setBaseURI(string memory baseURI) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "BLSTokenERC1155: must have admin role to set base URI");

        _setBaseURI(baseURI);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "new owner not module admin.");
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    function setDefaultRoyalty(address _defaultRoyaltyRecipient, uint96 _defaultRoyaltyBps)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        defaultRoyaltyBps = _defaultRoyaltyBps;
        _setDefaultRoyalty(_defaultRoyaltyRecipient, _defaultRoyaltyBps);
    }

    ///     =====   Low-level overrides  =====

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 tokenId)
    public view virtual
    override(ERC1155URIStorageUpgradeable, ERC1155Upgradeable)
    returns (string memory) {
         return super.uri(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}