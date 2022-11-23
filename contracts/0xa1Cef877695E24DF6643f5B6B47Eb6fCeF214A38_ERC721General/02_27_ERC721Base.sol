// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../royaltyManager/interfaces/IRoyaltyManager.sol";
import "../tokenManager/interfaces/ITokenManager.sol";
import "../utils/Ownable.sol";
import "../utils/ERC2981/IERC2981Upgradeable.sol";
import "../utils/ERC165/ERC165CheckerUpgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title Base ERC721
 * @author [email protected]
 * @dev Core piece of Highlight NFT contracts (v2)
 */
abstract contract ERC721Base is
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165CheckerUpgradeable for address;

    /**
     * @dev Set of minters allowed to mint on contract
     */
    EnumerableSet.AddressSet internal _minters;

    /**
     * @dev Global token/edition manager default
     */
    address public defaultManager;

    /**
     * @dev Token/edition managers per token grouping.
     *      Edition ID if implemented by Editions contract, and token ID if implemented by General contract.
     */
    mapping(uint256 => address) internal _managers;

    /**
     * @dev Default royalty for entire contract
     */
    IRoyaltyManager.Royalty internal _defaultRoyalty;

    /**
     * @dev Royalty per token grouping.
     *      Edition ID if implemented by Editions contract, and token ID if implemented by General contract.
     */
    mapping(uint256 => IRoyaltyManager.Royalty) internal _royalties;

    /**
     * @dev Royalty manager - optional contract that defines the conditions around setting royalties
     */
    address public royaltyManager;

    /**
     * @dev Freezes minting on smart contract forever
     */
    uint8 internal _mintFrozen;

    /**
     * @dev Emitted when minter is registered or unregistered
     * @param minter Minter that was changed
     * @param registered True if the minter was registered, false if unregistered
     */
    event MinterRegistrationChanged(address indexed minter, bool indexed registered);

    /**
     * @dev Emitted when token managers are set for token/edition ids
     * @param _ids Edition / token ids
     * @param _tokenManagers Token managers to set for tokens / editions
     */
    event GranularTokenManagersSet(uint256[] _ids, address[] _tokenManagers);

    /**
     * @dev Emitted when token managers are removed for token/edition ids
     * @param _ids Edition / token ids to remove token managers for
     */
    event GranularTokenManagersRemoved(uint256[] _ids);

    /**
     * @dev Emitted when default token manager changed
     * @param newDefaultTokenManager New default token manager. Zero address if old one was removed
     */
    event DefaultTokenManagerChanged(address indexed newDefaultTokenManager);

    /**
     * @dev Emitted when default royalty is set
     * @param recipientAddress Royalty recipient
     * @param royaltyPercentageBPS Percentage of sale (in basis points) owed to royalty recipient
     */
    event DefaultRoyaltySet(address indexed recipientAddress, uint16 indexed royaltyPercentageBPS);

    /**
     * @dev Emitted when royalties are set for edition / token ids
     * @param ids Token / edition ids
     * @param _newRoyalties New royalties for each token / edition
     */
    event GranularRoyaltiesSet(uint256[] ids, IRoyaltyManager.Royalty[] _newRoyalties);

    /**
     * @dev Emitted when royalty manager is updated
     * @param newRoyaltyManager New royalty manager. Zero address if old one was removed
     */
    event RoyaltyManagerChanged(address indexed newRoyaltyManager);

    /**
     * @dev Emitted when mints are frozen permanently
     */
    event MintsFrozen();

    /**
     * @dev Restricts calls to minters
     */
    modifier onlyMinter() {
        require(_minters.contains(_msgSender()), "Not minter");
        _;
    }

    /**
     * @dev Restricts calls if input royalty bps is over 10000
     */
    modifier royaltyValid(uint16 _royaltyBPS) {
        require(_royaltyBPSValid(_royaltyBPS), "Over BPS limit");
        _;
    }

    /**
     * @dev Registers a minter
     * @param minter New minter
     */
    function registerMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.add(minter), "Already a minter");

        emit MinterRegistrationChanged(minter, true);
    }

    /**
     * @dev Unregisters a minter
     * @param minter Minter to unregister
     */
    function unregisterMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.remove(minter), "Not yet minter");

        emit MinterRegistrationChanged(minter, false);
    }

    /**
     * @dev Sets granular token managers if current token manager(s) allow it
     * @param _ids Edition / token ids
     * @param _tokenManagers Token managers to set for tokens / editions
     */
    function setGranularTokenManagers(uint256[] calldata _ids, address[] calldata _tokenManagers)
        external
        nonReentrant
    {
        address msgSender = _msgSender();
        address tempOwner = owner();

        uint256 idsLength = _ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            require(_isValidTokenManager(_tokenManagers[i]), "Invalid TM");
            address currentTokenManager = tokenManager(_ids[i]);
            if (currentTokenManager == address(0)) {
                require(msgSender == tempOwner, "Not owner");
            } else {
                require(ITokenManager(currentTokenManager).canSwap(msgSender, _ids[i], _managers[i]), "Can't swap");
            }

            _managers[_ids[i]] = _tokenManagers[i];
        }

        emit GranularTokenManagersSet(_ids, _tokenManagers);
    }

    /**
     * @dev Remove granular token managers
     * @param _ids Edition / token ids to remove token managers for
     */
    function removeGranularTokenManagers(uint256[] calldata _ids) external nonReentrant {
        address msgSender = _msgSender();

        uint256 idsLength = _ids.length;
        for (uint256 i = 0; i < idsLength; i++) {
            address currentTokenManager = _managers[_ids[i]];
            require(currentTokenManager != address(0), "TM non-existent");
            require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, _ids[i]), "Can't remove");

            _managers[_ids[i]] = address(0);
        }

        emit GranularTokenManagersRemoved(_ids);
    }

    /**
     * @dev Set default token manager if current token manager allows it
     * @param _defaultTokenManager New default token manager
     */
    function setDefaultTokenManager(address _defaultTokenManager) external nonReentrant {
        require(_isValidTokenManager(_defaultTokenManager), "Invalid TM");
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        if (currentTokenManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(ITokenManager(currentTokenManager).canSwap(msgSender, 0, _defaultTokenManager), "Can't swap");
        }

        defaultManager = _defaultTokenManager;

        emit DefaultTokenManagerChanged(_defaultTokenManager);
    }

    /**
     * @dev Removes default token manager if current token manager allows it
     */
    function removeDefaultTokenManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        require(currentTokenManager != address(0), "Default TM not existent");
        require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, 0), "Can't remove");

        defaultManager = address(0);

        emit DefaultTokenManagerChanged(address(0));
    }

    /**
     * @dev Sets default royalty if royalty manager allows it
     * @param _royalty New default royalty
     */
    function setDefaultRoyalty(IRoyaltyManager.Royalty calldata _royalty)
        external
        nonReentrant
        royaltyValid(_royalty.royaltyPercentageBPS)
    {
        address msgSender = _msgSender();

        address _royaltyManager = royaltyManager;
        if (_royaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(_royaltyManager).canSetDefaultRoyalty(_royalty, msgSender), "Can't set");
        }

        _defaultRoyalty = _royalty;

        emit DefaultRoyaltySet(_royalty.recipientAddress, _royalty.royaltyPercentageBPS);
    }

    /**
     * @dev Sets granular royalties (per token-grouping) if royalty manager allows it
     * @param ids Token / edition ids
     * @param _newRoyalties New royalties for each token / edition
     */
    function setGranularRoyalties(uint256[] calldata ids, IRoyaltyManager.Royalty[] calldata _newRoyalties)
        external
        nonReentrant
    {
        address msgSender = _msgSender();
        address tempOwner = owner();

        address _royaltyManager = royaltyManager;
        uint256 idsLength = ids.length;
        if (_royaltyManager == address(0)) {
            require(msgSender == tempOwner, "Not owner");

            for (uint256 i = 0; i < idsLength; i++) {
                require(_royaltyBPSValid(_newRoyalties[i].royaltyPercentageBPS), "BPS invalid");
                _royalties[ids[i]] = _newRoyalties[i];
            }
        } else {
            for (uint256 i = 0; i < idsLength; i++) {
                require(_royaltyBPSValid(_newRoyalties[i].royaltyPercentageBPS), "BPS invalid");
                require(
                    IRoyaltyManager(_royaltyManager).canSetGranularRoyalty(ids[i], _newRoyalties[i], msgSender),
                    "Can't set"
                );
                _royalties[ids[i]] = _newRoyalties[i];
            }
        }

        emit GranularRoyaltiesSet(ids, _newRoyalties);
    }

    /**
     * @dev Sets royalty manager if current one allows it
     * @param _royaltyManager New royalty manager
     */
    function setRoyaltyManager(address _royaltyManager) external nonReentrant {
        require(_isValidRoyaltyManager(_royaltyManager), "Invalid RM");
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        if (currentRoyaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(currentRoyaltyManager).canSwap(_royaltyManager, msgSender), "Can't swap");
        }

        royaltyManager = _royaltyManager;

        emit RoyaltyManagerChanged(_royaltyManager);
    }

    /**
     * @dev Removes royalty manager if current one allows it
     */
    function removeRoyaltyManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        require(currentRoyaltyManager != address(0), "RM non-existent");
        require(IRoyaltyManager(currentRoyaltyManager).canRemoveItself(msgSender), "Can't remove");

        royaltyManager = address(0);

        emit RoyaltyManagerChanged(address(0));
    }

    /**
     * @dev Freeze mints on contract forever
     */
    function freezeMints() external onlyOwner nonReentrant {
        _mintFrozen = 1;

        emit MintsFrozen();
    }

    /**
     * @dev Conforms to ERC-2981. Editions should overwrite to return royalty for entire edition
     * @param _tokenGroupingId Token id if on general, and edition id if on editions
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(uint256 _tokenGroupingId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        IRoyaltyManager.Royalty memory royalty = _royalties[_tokenGroupingId];
        if (royalty.recipientAddress == address(0)) {
            royalty = _defaultRoyalty;
        }

        receiver = royalty.recipientAddress;
        royaltyAmount = (_salePrice * uint256(royalty.royaltyPercentageBPS)) / 10000;
    }

    /**
     * @dev Returns the token manager for the id passed in.
     * @param id Token ID or Edition ID for Editions implementing contracts
     */
    function tokenManager(uint256 id) public view returns (address manager) {
        manager = defaultManager;
        address granularManager = _managers[id];

        if (granularManager != address(0)) {
            manager = granularManager;
        }
    }

    /**
     * @dev Initializes the contract, setting the creator as the initial owner.
     * @param _creator Contract creator
     * @param defaultRoyalty Default royalty for the contract
     * @param _defaultTokenManager Default token manager for the contract
     */
    function __ERC721Base_initialize(
        address _creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager
    ) internal onlyInitializing royaltyValid(defaultRoyalty.royaltyPercentageBPS) {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(_creator);

        _defaultRoyalty = defaultRoyalty;

        if (_defaultTokenManager != address(0)) {
            defaultManager = _defaultTokenManager;
        }
    }

    /**
     * @dev Returns true if address is a valid tokenManager
     * @param _tokenManager Token manager being checked
     */
    function _isValidTokenManager(address _tokenManager) internal view returns (bool) {
        return _tokenManager.supportsInterface(type(ITokenManager).interfaceId);
    }

    /**
     * @dev Returns true if address is a valid royaltyManager
     * @param _royaltyManager Royalty manager being checked
     */
    function _isValidRoyaltyManager(address _royaltyManager) internal view returns (bool) {
        return _royaltyManager.supportsInterface(type(IRoyaltyManager).interfaceId);
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Returns true if royalty bps passed in is valid (<= 10000)
     * @param _royaltyBPS Royalty basis points
     */
    function _royaltyBPSValid(uint16 _royaltyBPS) private pure returns (bool) {
        return _royaltyBPS <= 10000;
    }
}