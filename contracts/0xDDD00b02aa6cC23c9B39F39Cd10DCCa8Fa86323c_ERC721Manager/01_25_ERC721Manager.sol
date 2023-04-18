// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { StorageBaseExtension } from '../StorageBaseExtension.sol';
import { ERC721ManagerAutoProxy } from './ERC721ManagerAutoProxy.sol';
import { ERC165 } from './ERC165.sol';
import { Pausable } from '../Pausable.sol';

import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';
import { ICollectionProxy_ManagerFunctions } from '../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerProxy } from '../interfaces/IERC721ManagerProxy.sol';
import { IERC721 } from '../interfaces/IERC721.sol';
import { IERC721Enumerable } from '../interfaces/IERC721Enumerable.sol';
import { IERC721Metadata } from '../interfaces/IERC721Metadata.sol';
import { IERC2981 } from '../interfaces/IERC2981.sol';
import { IERC721Receiver } from '../interfaces/IERC721Receiver.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IOperatorFilterRegistry } from '../interfaces/IOperatorFilterRegistry.sol';
import { IFarmingManager } from '../interfaces/IFarmingManager.sol';

import { Address } from '../libraries/Address.sol';
import { Strings } from '../libraries/Strings.sol';

contract ERC721ManagerStorage is StorageBaseExtension {
    // List of all deployed collections' proxies
    address[] private allCollectionProxies;

    // Mapping of collectionProxy address to collectionStorage address
    mapping(address => ICollectionStorage) private collectionStorage;

    // Mapping of collectionProxy address to maximum supply of NFTs in this collection
    mapping(address => uint256) private MAX_SUPPLY;

    // Mapping of collectionProxy address to maximum number of NFTs that can be minted with ETH/WETH mint fee during the public mint phase
    mapping(address => uint256) private MAX_ETH_MINTS;

    // Mapping of collectionProxy address to maximum number of NFTs that can be minted per address during the whitelist mint phase
    mapping(address => uint256) private MAX_WHITELIST_MINT_PER_ADDRESS;

    // Mapping of collectionProxy address to maximum number of NFTs that can be minted per address during the public mint phase
    mapping(address => uint256) private MAX_PUBLIC_MINT_PER_ADDRESS;

    // Mapping of collectionProxy address to block from which the whitelist mint phase is enabled
    mapping(address => uint256) private blockStartWhitelistPhase;

    // Mapping of collectionProxy address to block after which the whitelist mint phase is disabled
    mapping(address => uint256) private blockEndWhitelistPhase;

    // Mapping of collectionProxy address to block from which the public mint phase is enabled
    mapping(address => uint256) private blockStartPublicPhase;

    // Mapping of collectionProxy address to block after which the public mint phase is disabled
    mapping(address => uint256) private blockEndPublicPhase;

    // Mapping of collectionProxy address to mapping of whitelisted user addresses to whitelist status
    mapping(address => mapping(address => bool)) private whitelisted;

    // Mapping of collectionProxy address to mapping of whitelisted user addresses to whitelist index
    // whitelistIndex is the position of the user address in the whitelist array
    mapping(address => mapping(address => uint256)) private whitelistIndex;

    // Mapping of collectionProxy address to array of whitelisted user addresses
    mapping(address => address[]) private whitelist;

    // Mapping of collectionProxy address to mapping of minter address to minted token count during whitelist phase
    mapping(address => mapping(address => uint256)) private whitelistMintCount;

    // Mapping of collectionProxy address to mapping of minter address to minted token count during public phase
    mapping(address => mapping(address => uint256)) private publicMintCount;

    // Mapping of collectionProxy address to amount of token minted by contract owner
    mapping(address => uint256) private ownerMintCount;

    // Mapping of collectionProxy address to address of ERC20 asset allowed for mint fee payments
    mapping(address => address) private mintFeeERC20AssetProxy;

    // Mapping of collectionProxy address to ERC20 asset mint fee (in wei)
    mapping(address => uint256) private mintFeeERC20;

    // Mapping of collectionProxy address to ETH base mint fee (in wei)
    mapping(address => uint256) private baseMintFeeETH;

    // Mapping of collectionProxy address to ETH mint fee growth rate (bps)
    mapping(address => uint256) private ethMintFeeGrowthRateBps;

    // Mapping of collectionProxy address to ETH mints count threshold (number of ETH mints above which ETH mint fee
    // increases by ethMintFeeGrowthRateBps bps per ETH mint)
    mapping(address => uint256) private ethMintsCountThreshold;

    // Mapping of collectionProxy address to number of tokens minted with ETH mint fee
    mapping(address => uint256) private ethMintsCount;

    // Mapping of collectionProxy address to lastETHMintFeeAboveThreshold
    // We store the last ETH mint fee applied above ethMintsCountThreshold to avoid calculating ETH mint fee from scratch
    // at every mint above ethMintsCountThreshold
    mapping(address => uint256) private lastETHMintFeeAboveThreshold;

    // recipient address for mint fee payments
    address private mintFeeRecipient;

    // Denominator for ETH mint fee and royalties calculations
    uint96 private feeDenominator = 10000;

    constructor(
        address _helperProxy,
        address _mintFeeRecipient
    ) StorageBaseExtension(address(IGovernedProxy(payable(_helperProxy)).impl())) {
        mintFeeRecipient = _mintFeeRecipient;
    }

    // Getter functions
    //
    function getCollectionStorage(
        address collectionProxy
    ) external view returns (ICollectionStorage _collectionStorage) {
        _collectionStorage = collectionStorage[collectionProxy];
    }

    function getCollectionProxy(uint256 index) external view returns (address _collectionProxy) {
        _collectionProxy = allCollectionProxies[index];
    }

    function getCollectionsCount() external view returns (uint256 _length) {
        _length = allCollectionProxies.length;
    }

    function getMAX_SUPPLY(address collectionProxy) external view returns (uint256 _MAX_SUPPLY) {
        _MAX_SUPPLY = MAX_SUPPLY[collectionProxy];
    }

    function getMAX_ETH_MINTS(
        address collectionProxy
    ) external view returns (uint256 _MAX_ETH_MINTS) {
        _MAX_ETH_MINTS = MAX_ETH_MINTS[collectionProxy];
    }

    function getMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256 _MAX_WHITELIST_MINT_PER_ADDRESS) {
        _MAX_WHITELIST_MINT_PER_ADDRESS = MAX_WHITELIST_MINT_PER_ADDRESS[collectionProxy];
    }

    function getMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy
    ) external view returns (uint256 _MAX_PUBLIC_MINT_PER_ADDRESS) {
        _MAX_PUBLIC_MINT_PER_ADDRESS = MAX_PUBLIC_MINT_PER_ADDRESS[collectionProxy];
    }

    function getBlockStartWhitelistPhase(
        address collectionProxy
    ) external view returns (uint256 _blockStartWhitelistPhase) {
        _blockStartWhitelistPhase = blockStartWhitelistPhase[collectionProxy];
    }

    function getBlockEndWhitelistPhase(
        address collectionProxy
    ) external view returns (uint256 _blockEndWhitelistPhase) {
        _blockEndWhitelistPhase = blockEndWhitelistPhase[collectionProxy];
    }

    function getBlockStartPublicPhase(
        address collectionProxy
    ) external view returns (uint256 _blockStartPublicPhase) {
        _blockStartPublicPhase = blockStartPublicPhase[collectionProxy];
    }

    function getBlockEndPublicPhase(
        address collectionProxy
    ) external view returns (uint256 _blockEndPublicPhase) {
        _blockEndPublicPhase = blockEndPublicPhase[collectionProxy];
    }

    function isWhitelisted(
        address collectionProxy,
        address _user
    ) external view returns (bool _isWhitelisted) {
        _isWhitelisted = whitelisted[collectionProxy][_user];
    }

    function getWhitelistIndex(
        address collectionProxy,
        address _user
    ) external view returns (uint256 _index) {
        _index = whitelistIndex[collectionProxy][_user];
    }

    function getWhitelistedUsersCount(
        address collectionProxy
    ) external view returns (uint256 _whitelistedUsersCount) {
        // address(0) is the first element of whitelist array
        _whitelistedUsersCount = whitelist[collectionProxy].length - 1;
    }

    function getWhitelistedUserByIndex(
        address collectionProxy,
        uint256 _index
    ) external view returns (address _whitelistedUser) {
        _whitelistedUser = whitelist[collectionProxy][_index];
    }

    function getWhitelistMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256 _amount) {
        _amount = whitelistMintCount[collectionProxy][_address];
    }

    function getPublicMintCount(
        address collectionProxy,
        address _address
    ) external view returns (uint256 _amount) {
        _amount = publicMintCount[collectionProxy][_address];
    }

    function getOwnerMintCount(address collectionProxy) external view returns (uint256 _amount) {
        _amount = ownerMintCount[collectionProxy];
    }

    function getMintFeeERC20AssetProxy(
        address collectionProxy
    ) external view returns (address _mintFeeERC20AssetProxy) {
        _mintFeeERC20AssetProxy = mintFeeERC20AssetProxy[collectionProxy];
    }

    function getMintFeeERC20(
        address collectionProxy
    ) external view returns (uint256 _mintFeeERC20) {
        _mintFeeERC20 = mintFeeERC20[collectionProxy];
    }

    function getBaseMintFeeETH(
        address collectionProxy
    ) external view returns (uint256 _baseMintFeeETH) {
        _baseMintFeeETH = baseMintFeeETH[collectionProxy];
    }

    function getETHMintFeeGrowthRateBps(
        address collectionProxy
    ) external view returns (uint256 _ethMintFeeGrowthRateBps) {
        _ethMintFeeGrowthRateBps = ethMintFeeGrowthRateBps[collectionProxy];
    }

    function getETHMintsCountThreshold(
        address collectionProxy
    ) external view returns (uint256 _ethMintsCountThreshold) {
        _ethMintsCountThreshold = ethMintsCountThreshold[collectionProxy];
    }

    function getETHMintsCount(
        address collectionProxy
    ) external view returns (uint256 _ethMintsCount) {
        _ethMintsCount = ethMintsCount[collectionProxy];
    }

    function getLastETHMintFeeAboveThreshold(
        address collectionProxy
    ) external view returns (uint256 _lastETHMintFeeAboveThreshold) {
        _lastETHMintFeeAboveThreshold = lastETHMintFeeAboveThreshold[collectionProxy];
    }

    function getMintFeeRecipient() external view returns (address _mintFeeRecipient) {
        _mintFeeRecipient = mintFeeRecipient;
    }

    function getFeeDenominator() external view returns (uint96 _feeDenominator) {
        _feeDenominator = feeDenominator;
    }

    // Setter functions
    //
    function setCollectionStorage(
        address collectionProxy,
        address _collectionStorage
    ) external requireOwner {
        collectionStorage[collectionProxy] = ICollectionStorage(_collectionStorage);
    }

    function pushCollectionProxy(address collectionProxy) external requireOwner {
        allCollectionProxies.push(collectionProxy);
    }

    function popCollectionProxy() external requireOwner {
        allCollectionProxies.pop();
    }

    function setCollectionProxy(uint256 index, address collectionProxy) external requireOwner {
        allCollectionProxies[index] = collectionProxy;
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 _value) external requireOwner {
        MAX_SUPPLY[collectionProxy] = _value;
    }

    function setMAX_ETH_MINTS(address collectionProxy, uint256 _value) external requireOwner {
        MAX_ETH_MINTS[collectionProxy] = _value;
    }

    function setMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 _value
    ) external requireOwner {
        MAX_WHITELIST_MINT_PER_ADDRESS[collectionProxy] = _value;
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 _value
    ) external requireOwner {
        MAX_PUBLIC_MINT_PER_ADDRESS[collectionProxy] = _value;
    }

    function setWhitelistPhase(
        address collectionProxy,
        uint256 _blockStartWhitelistPhase,
        uint256 _blockEndWhitelistPhase
    ) external requireOwner {
        blockStartWhitelistPhase[collectionProxy] = _blockStartWhitelistPhase;
        blockEndWhitelistPhase[collectionProxy] = _blockEndWhitelistPhase;
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 _blockStartPublicPhase,
        uint256 _blockEndPublicPhase
    ) external requireOwner {
        blockStartPublicPhase[collectionProxy] = _blockStartPublicPhase;
        blockEndPublicPhase[collectionProxy] = _blockEndPublicPhase;
    }

    function setWhitelisted(
        address collectionProxy,
        address _user,
        bool _isWhitelisted
    ) external requireOwner {
        // Initialize whitelist if needed
        if (whitelist[collectionProxy].length == 0) {
            // We push address(0) as the first element of whitelist in order to only have whitelistIndex > 0 for
            // whitelisted users, and we use the 0 value in whitelistIndex to identify users who were removed from the
            // whitelist, or were never added (as whitelistIndex mapping values default to 0)
            whitelist[collectionProxy].push(address(0));
        }
        // Set whitelisted status for user
        whitelisted[collectionProxy][_user] = _isWhitelisted;
        // Get whitelist index of user
        uint256 userWhitelistIndex = whitelistIndex[collectionProxy][_user];
        if (_isWhitelisted) {
            // Add user to whitelist
            if (userWhitelistIndex == 0) {
                // Is user is not already in whitelist, push user to whitelist array and register new whitelistIndex
                whitelist[collectionProxy].push(_user);
                whitelistIndex[collectionProxy][_user] = whitelist[collectionProxy].length - 1;
            }
        } else {
            // Remove user from whitelist
            if (userWhitelistIndex > 0) {
                if (userWhitelistIndex < whitelist[collectionProxy].length - 1) {
                    // If user is not in the last position in whitelist array, replace it with the address
                    // which is in the last position
                    // Get the user which is at the last index of whitelist array
                    address lastWhitelistedUser = whitelist[collectionProxy][
                        whitelist[collectionProxy].length - 1
                    ];
                    // Replace user with the user which is at the last index of whitelist array
                    whitelist[collectionProxy][userWhitelistIndex] = lastWhitelistedUser;
                    // Update whitelistIndex for the lastWhitelistedUser address which was moved from the last position
                    // to a new position in whitelist array
                    whitelistIndex[collectionProxy][lastWhitelistedUser] = userWhitelistIndex;
                }
                // Pop the last element of whitelist array
                whitelist[collectionProxy].pop();
                // Set whitelistIndex to 0 for user
                whitelistIndex[collectionProxy][_user] = 0;
            }
        }
    }

    function setWhitelistMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external requireOwner {
        whitelistMintCount[collectionProxy][_address] = _amount;
    }

    function setPublicMintCount(
        address collectionProxy,
        address _address,
        uint256 _amount
    ) external requireOwner {
        publicMintCount[collectionProxy][_address] = _amount;
    }

    function setOwnerMintCount(address collectionProxy, uint256 _amount) external requireOwner {
        ownerMintCount[collectionProxy] = _amount;
    }

    function setMintFeeERC20AssetProxy(
        address collectionProxy,
        address _mintFeeERC20AssetProxy
    ) external requireOwner {
        mintFeeERC20AssetProxy[collectionProxy] = _mintFeeERC20AssetProxy;
    }

    function setMintFeeERC20(address collectionProxy, uint256 _mintFeeERC20) external requireOwner {
        mintFeeERC20[collectionProxy] = _mintFeeERC20;
    }

    function setMintFeeETH(
        address collectionProxy,
        uint256[3] memory _mintFeeETH
    ) external requireOwner {
        baseMintFeeETH[collectionProxy] = _mintFeeETH[0];
        ethMintsCountThreshold[collectionProxy] = _mintFeeETH[1];
        ethMintFeeGrowthRateBps[collectionProxy] = _mintFeeETH[2];
    }

    function setBaseMintFeeETH(
        address collectionProxy,
        uint256 _baseMintFeeETH
    ) external requireOwner {
        baseMintFeeETH[collectionProxy] = _baseMintFeeETH;
    }

    function setETHMintFeeGrowthRateBps(
        address collectionProxy,
        uint256 _ethMintFeeGrowthRateBps
    ) external requireOwner {
        ethMintFeeGrowthRateBps[collectionProxy] = _ethMintFeeGrowthRateBps;
    }

    function setETHMintsCountThreshold(
        address collectionProxy,
        uint256 _ethMintsCountThreshold
    ) external requireOwner {
        ethMintsCountThreshold[collectionProxy] = _ethMintsCountThreshold;
    }

    function setETHMintsCount(
        address collectionProxy,
        uint256 _ethMintsCount
    ) external requireOwner {
        ethMintsCount[collectionProxy] = _ethMintsCount;
    }

    function setLastETHMintFeeAboveThreshold(
        address collectionProxy,
        uint256 _lastETHMintFeeAboveThreshold
    ) external requireOwner {
        lastETHMintFeeAboveThreshold[collectionProxy] = _lastETHMintFeeAboveThreshold;
    }

    function setMintFeeRecipient(address _mintFeeRecipient) external requireOwner {
        mintFeeRecipient = _mintFeeRecipient;
    }

    function setFeeDenominator(uint96 value) external requireOwner {
        feeDenominator = value;
    }
}

contract ERC721Manager is Pausable, ERC721ManagerAutoProxy, ERC165 {
    using Strings for uint256;
    using Address for address;

    address public helperProxy;
    address public factoryProxy;
    address public farmingManagerProxy;

    IOperatorFilterRegistry public operatorFilterRegistry;

    ERC721ManagerStorage public _storage;

    constructor(
        address _proxy,
        address _helperProxy,
        address _factoryProxy,
        address _mintFeeRecipient,
        address _operatorFilterRegistry
    ) ERC721ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ERC721ManagerStorage(_helperProxy, _mintFeeRecipient);
        helperProxy = _helperProxy;
        factoryProxy = _factoryProxy;

        operatorFilterRegistry = IOperatorFilterRegistry(_operatorFilterRegistry);
    }

    modifier requireCollectionProxy() {
        require(
            address(_storage.getCollectionStorage(msg.sender)) != address(0),
            'ERC721Manager: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    // Modifier for self-custodial farming
    modifier requireNotStaked(address collectionProxy, uint256 tokenId) {
        // When token is staked, transferring or burning token is not allowed
        if (farmingManagerProxy != address(0)) {
            require(
                !IFarmingManager(IGovernedProxy(payable(farmingManagerProxy)).impl()).isStaked(
                    collectionProxy,
                    tokenId
                ),
                'ERC721Manager: cannot transfer or burn staked tokens'
            );
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from, address msgSender) {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msgSender) {
            _checkFilterOperator(msgSender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) private view {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            require(
                operatorFilterRegistry.isOperatorAllowed(address(this), operator),
                'ERC721Manager: operator not allowed'
            );
        }
    }

    /**
     * @dev Governance functions
     */
    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        StorageBaseExtension(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    /**
     * @dev Factory restricted function
     */
    // This function is called by Factory implementation at a new collection creation
    // Register a new Collection's proxy address, and Collection's storage address
    function register(
        address _collectionProxy,
        address _collectionStorage,
        address _mintFeeERC20AssetProxy,
        uint256 _mintFeeERC20,
        uint256[3] calldata _mintFeeETH
    )
        external
        // _mintFeeETH = [baseMintFeeETH, ethMintsCountThreshold, ethMintFeeGrowthRateBps]
        whenNotPaused
    {
        require(
            msg.sender == address(IGovernedProxy(payable(factoryProxy)).impl()),
            'ERC721Manager: Not factory implementation!'
        );
        _storage.setCollectionStorage(_collectionProxy, _collectionStorage);
        _storage.pushCollectionProxy(_collectionProxy);
        _storage.setMintFeeERC20AssetProxy(_collectionProxy, _mintFeeERC20AssetProxy);
        _storage.setMintFeeERC20(_collectionProxy, _mintFeeERC20);
        _storage.setMintFeeETH(_collectionProxy, _mintFeeETH);
        // Initialize lastETHMintFeeAboveThreshold
        _storage.setLastETHMintFeeAboveThreshold(_collectionProxy, _mintFeeETH[0]);
    }

    /**
     * @dev ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev ERC721
     */
    function balanceOf(address collectionProxy, address owner) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(owner != address(0), 'ERC721Manager: balance query for the zero address');
        return collectionStorage.getBalance(owner);
    }

    function ownerOf(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: owner query for nonexistent token');
        return owner;
    }

    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _safeTransferFrom(
            collectionStorage,
            collectionProxy,
            owner,
            spender,
            from,
            to,
            tokenId,
            _data
        );
    }

    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    )
        external
        requireCollectionProxy
        whenNotPaused
        requireNotStaked(collectionProxy, tokenId)
        onlyAllowedOperator(from, spender)
    {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            spender == owner ||
                collectionStorage.getTokenApproval(tokenId) == spender ||
                collectionStorage.getOperatorApproval(owner, spender),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
    }

    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(spender) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(spender != owner, 'ERC721Manager: approval to current owner');
        require(
            msgSender == owner || collectionStorage.getOperatorApproval(owner, msgSender),
            'ERC721Manager: approve caller is not owner nor approved for all'
        );

        _approve(collectionStorage, collectionProxy, owner, spender, tokenId);
    }

    function getApproved(address collectionProxy, uint256 tokenId) external view returns (address) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: approved query for nonexistent token'
        );

        return collectionStorage.getTokenApproval(tokenId);
    }

    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external requireCollectionProxy whenNotPaused onlyAllowedOperatorApproval(operator) {
        _setApprovalForAll(collectionProxy, owner, operator, approved);
    }

    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) external view returns (bool) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getOperatorApproval(owner, operator);
    }

    /**
     * @dev ERC721Metadata
     */
    function name(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getName();
    }

    function symbol(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getSymbol();
    }

    function baseURI(address collectionProxy) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return baseURI_local;
    }

    function tokenURI(
        address collectionProxy,
        uint256 tokenId
    ) external view returns (string memory) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            _exists(collectionStorage, tokenId),
            'ERC721Manager: URI query for nonexistent token'
        );

        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return
            bytes(baseURI_local).length > 0
                ? string(abi.encodePacked(baseURI_local, tokenId.toString()))
                : '';
    }

    /**
     * @dev ERC721Enumerable
     */
    function totalSupply(address collectionProxy) external view returns (uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        return collectionStorage.getTotalSupply();
    }

    function tokenByIndex(
        address collectionProxy,
        uint256 index
    ) external view returns (uint256 tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            index < collectionStorage.getTokenIdsCount(),
            'ERC721Manager: index must be less than token ids count'
        );
        tokenId = collectionStorage.getTokenIdByIndex(index);
    }

    function tokenOfOwnerByIndex(
        address collectionProxy,
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId) {
        require(
            owner != address(0),
            'ERC721Manager: tokenOfOwnerByIndex query for the zero address'
        );
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            collectionStorage.getBalance(owner) > index,
            'ERC721Manager: index must be less than address balance'
        );
        tokenId = collectionStorage.getTokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev ERC721Burnable
     */
    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused requireNotStaked(collectionProxy, tokenId) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: nonexistent token');
        require(
            burner == owner ||
                collectionStorage.getTokenApproval(tokenId) == burner ||
                collectionStorage.getOperatorApproval(owner, burner),
            'ERC721Manager: burn caller is not owner nor approved'
        );

        _burn(collectionStorage, collectionProxy, owner, tokenId);
    }

    /**
     * @dev ERC2981
     */
    function royaltyInfo(
        address collectionProxy,
        uint256, // Royalties are identical for all tokenIds
        uint256 salePrice
    ) external view returns (address, uint256) {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        address receiver = collectionStorage.getRoyaltyReceiver();
        uint256 royaltyAmount;
        if (receiver != address(0)) {
            uint96 fraction = collectionStorage.getRoyaltyFraction();
            royaltyAmount = (salePrice * fraction) / _storage.getFeeDenominator();
        } else {
            royaltyAmount = 0;
        }

        return (receiver, royaltyAmount);
    }

    /**
     * @dev Private ERC721 functions
     */
    function _exists(
        ICollectionStorage collectionStorage,
        uint256 tokenId
    ) private view returns (bool) {
        return collectionStorage.getOwner(tokenId) != address(0);
    }

    function _transfer(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(to != address(0), 'ERC721Manager: transfer to the zero address');
        require(owner == from, 'ERC721Manager: transfer from incorrect owner');
        // Clear approvals from the previous owner
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update tokenId ownership
        uint256 fromBalance = collectionStorage.getBalance(from);
        for (uint256 i = 0; i < fromBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(from, i) == tokenId) {
                if (i < fromBalance - 1) {
                    // If transferred tokenId is not in the last position in tokenOfOwner array, replace it with the
                    // tokenId which is in the last position
                    uint256 lastTokenIdOfFrom = collectionStorage.getTokenOfOwnerByIndex(
                        from,
                        fromBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(from, i, lastTokenIdOfFrom);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(from);
                break;
            }
        }
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(from, to, tokenId);
    }

    function _safeTransferFrom(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private {
        _transfer(collectionStorage, collectionProxy, owner, from, to, tokenId);
        require(
            _checkOnERC721Received(spender, from, to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }

    function _approve(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        address spender,
        uint256 tokenId
    ) private {
        // Set new approval value for spender
        collectionStorage.setTokenApproval(tokenId, spender);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApproval(owner, spender, tokenId);
    }

    function _setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) private {
        require(owner != operator, 'ERC721Manager: approve to caller');
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        // Set new approval value for operator
        collectionStorage.setOperatorApproval(owner, operator, approved);
        // Emit Approval event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApprovalForAll(
            owner,
            operator,
            approved
        );
    }

    function _burn(
        ICollectionStorage collectionStorage,
        address collectionProxy,
        address owner,
        uint256 tokenId
    ) private {
        // Clear approvals
        _approve(collectionStorage, collectionProxy, owner, address(0), tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() - 1);
        // Update tokenIds array (set value to 0 at tokenId index to signal that token was burned)
        collectionStorage.setTokenIdByIndex(0, tokenId - 1);
        // Update tokenId ownership
        uint256 ownerBalance = collectionStorage.getBalance(owner);
        for (uint256 i = 0; i < ownerBalance; i++) {
            if (collectionStorage.getTokenOfOwnerByIndex(owner, i) == tokenId) {
                if (i < ownerBalance - 1) {
                    // If burned tokenId is not in the last position in tokenOfOwner array, replace it with the tokenId
                    // which is in the last position
                    uint256 lastTokenIdOfOwner = collectionStorage.getTokenOfOwnerByIndex(
                        owner,
                        ownerBalance - 1
                    );
                    collectionStorage.setTokenOfOwnerByIndex(owner, i, lastTokenIdOfOwner);
                }
                // Pop last tokenId from tokenOfOwner array
                collectionStorage.popTokenOfOwner(owner);
                break;
            }
        }
        collectionStorage.setOwner(tokenId, address(0));
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721Manager: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Owner-restricted setter functions
     */
    function setSporkProxy(address payable sporkProxy) external onlyOwner {
        IERC721ManagerProxy(proxy).setSporkProxy(sporkProxy);
    }

    function setFarmingManagerProxy(address _farmingManagerProxy) external onlyOwner {
        farmingManagerProxy = _farmingManagerProxy;
    }

    function setBaseURI(address collectionProxy, string calldata uri) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setBaseURI(uri);
    }

    function setName(address collectionProxy, string calldata newName) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setName(newName);
    }

    function setSymbol(address collectionProxy, string calldata newSymbol) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setSymbol(newSymbol);
    }

    function setWhitelisted(
        address collectionProxy,
        address[] calldata users,
        bool[] calldata whitelisted
    ) external onlyOwner {
        require(
            users.length == whitelisted.length,
            'ERC721Manager: _users and _whitelisted arrays must have the same length'
        );
        for (uint256 i = 0; i < users.length; i++) {
            _storage.setWhitelisted(collectionProxy, users[i], whitelisted[i]);
        }
    }

    function setMAX_WHITELIST_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_WHITELIST_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(
        address collectionProxy,
        uint256 value
    ) external onlyOwner {
        _storage.setMAX_PUBLIC_MINT_PER_ADDRESS(collectionProxy, value);
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 value) external onlyOwner {
        _storage.setMAX_SUPPLY(collectionProxy, value);
    }

    function setMAX_ETH_MINTS(address collectionProxy, uint256 value) external onlyOwner {
        _storage.setMAX_ETH_MINTS(collectionProxy, value);
    }

    function setWhitelistPhase(
        address collectionProxy,
        uint256 blockStartWhitelistPhase,
        uint256 blockEndWhitelistPhase
    ) external onlyOwner {
        _storage.setWhitelistPhase(
            collectionProxy,
            blockStartWhitelistPhase,
            blockEndWhitelistPhase
        );
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 blockStartPublicPhase,
        uint256 blockEndPublicPhase
    ) external onlyOwner {
        _storage.setPublicPhase(collectionProxy, blockStartPublicPhase, blockEndPublicPhase);
    }

    function setCollectionMoved(address collectionProxy, bool collectionMoved) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setCollectionMoved(collectionMoved);
    }

    function setMovementNoticeURI(
        address collectionProxy,
        string calldata movementNoticeURI
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        collectionStorage.setMovementNoticeURI(movementNoticeURI);
    }

    function setFeeDenominator(uint96 value) external onlyOwner {
        _storage.setFeeDenominator(value);
    }

    function setRoyalty(
        address collectionProxy,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        ICollectionStorage collectionStorage = _storage.getCollectionStorage(collectionProxy);
        require(
            feeNumerator <= _storage.getFeeDenominator(),
            'ERC721Manager: royalty fee will exceed salePrice'
        );
        collectionStorage.setRoyaltyInfo(receiver, feeNumerator);
    }

    function setOperatorFilterRegistry(
        IOperatorFilterRegistry _operatorFilterRegistry
    ) external onlyOwner {
        operatorFilterRegistry = _operatorFilterRegistry;
    }
}