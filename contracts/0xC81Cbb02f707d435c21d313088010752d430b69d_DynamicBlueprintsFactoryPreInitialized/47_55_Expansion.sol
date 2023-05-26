//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IExpansion.sol";
import "../common/Royalty.sol";
import "../common/IOperatorFilterer.sol";
import "../operatorFilter/IOperatorFilterRegistry.sol";
import "../abstract/HasSecondarySaleFees.sol";

/**
 * @notice Dynamic Blueprint Expansion contract housing expansion packs/items that are used to augment DBP NFTs
 * @author Ohimire Labs
 */
contract Expansion is IExpansion, ERC1155SupplyUpgradeable, AccessControlUpgradeable, HasSecondarySaleFees, Royalty {
    using StringsUpgradeable for uint256;

    /**
     * @notice Number of packs created
     */
    uint256 public numPacks;

    /**
     * @notice Number of tokens created through created packs
     */
    uint256 public numTokens;

    /**
     * @notice Expansion artist
     */
    address public artist;

    /**
     * @notice Contract level metadata
     */
    string public contractURI;

    /**
     * @notice Broadcast contract
     */
    address public broadcast;

    /**
     * @notice A registry to check for blacklisted operator addresses.
     *      Used to only permit marketplaces enforcing creator royalites if desired
     */
    IOperatorFilterRegistry public operatorFilterRegistry;

    /**
     * @notice Holders of this role are given minter privileges
     */
    bytes32 public constant STOREFRONT_MINTER_ROLE = keccak256("STOREFRONT_MINTER_ROLE");

    /**
     * @notice Expansion contract's royalty
     */
    Royalty internal _royalty;

    /**
     * @notice Track packs
     */
    mapping(uint256 => Pack) private _packs;

    /**
     * @notice Platform address
     */
    address public platform;

    /**
     * @notice Amount of ether which artist has deposited to front gas for preparePack calls.
     *         These funds are pooled on the platform account, but the amount of deposit is tracked on contract state.
     */
    uint256 public gasAmountDeposited;

    /**
     * @notice Holders of this role are given minter privileges
     * @dev Added in upgrade
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Emitted when a pack is prepared
     * @param packId Identifier for AsyncArt platform to track pack creation.
     * @param capacity The maximum number of mintable pack's (0 -> infinite)
     * @param baseUri The pack's baseUri -> used to generate token URIs
     */
    event PackPrepared(uint256 indexed packId, uint256 capacity, string baseUri);

    /** TODO(sorend): think of the best way to do this event
     * @notice Emitted when a pack is minted
     * @param packId Identifier of the pack
     * @param recipient The address receiving the minted pack
     * @param tokenIdCombinations A list of sets of token ids.
     *                            Each of these sets was minted numMintsOfCombination[i] times
     * @param numMintsOfCombination The number of times each set of ids was minted
     */
    event PacksMinted(
        uint256 indexed packId,
        address recipient,
        uint256[][] tokenIdCombinations,
        uint32[] numMintsOfCombination
    );

    /////////////////////////////////////////////////
    /// Required for CORI Operator Registry //////
    /////////////////////////////////////////////////

    // Custom Error Type For Operator Registry Methods
    error OperatorNotAllowed(address operator);

    /**
     * @notice Restrict operators who are allowed to transfer these tokens
     * @param from Account that token is being transferred out of
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Restrict operators who are allowed to approve transfer delegates
     * @param operator Operator that is attempting to move tokens
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Initialize expansion instance
     * @param storefrontMinters Storefront minters to be given STOREFRONT_MINTER_ROLE
     * @param initialPlatform Address stored as platform initially
     * @param initialMinter Address given minter role initially
     * @param _contractURI Contract level metadata
     * @param _artist Expansion artist
     * @param initialRoyalty Initial royalty on contract
     * @param _broadcast Broadcast contract for protocol
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param _gasAmountDeposited The initial deposit the contract deployer made to
     *                            cover gas associated with preparePack calls
     */
    function initialize(
        address[] memory storefrontMinters,
        address initialPlatform,
        address initialMinter,
        string calldata _contractURI,
        address _artist,
        Royalty calldata initialRoyalty,
        address _broadcast,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        uint256 _gasAmountDeposited
    ) external initializer royaltyValid(initialRoyalty) {
        // call inits on inherited contracts
        __ERC1155_init("");
        __AccessControl_init();
        HasSecondarySaleFees._initialize();

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, initialPlatform);
        _setupRole(MINTER_ROLE, initialMinter);
        for (uint i = 0; i < storefrontMinters.length; i++) {
            _setupRole(STOREFRONT_MINTER_ROLE, storefrontMinters[i]);
        }
        platform = initialPlatform;
        artist = _artist;

        contractURI = _contractURI;
        _royalty = initialRoyalty;

        broadcast = _broadcast;

        if (operatorFiltererInputs.operatorFilterRegistryAddress != address(0)) {
            // Store OpenSea's operator filter registry, (passed as parameter to constructor for dependency injection)
            // On mainnet the filter registry will be: 0x000000000000AAeB6D7670E522A718067333cd4E
            operatorFilterRegistry = IOperatorFilterRegistry(operatorFiltererInputs.operatorFilterRegistryAddress);

            // Register contract address with the registry and subscribe to CORI canonical filter-list
            // (passed via constructor for dependency injection)
            // On mainnet the subscription address will be: 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
            operatorFilterRegistry.registerAndSubscribe(
                address(this),
                operatorFiltererInputs.coriCuratedSubscriptionAddress
            );
        }

        gasAmountDeposited = _gasAmountDeposited;
    }

    /**
     * @notice See {IExpansion-mintSameCombination}
     */
    function mintSameCombination(
        uint256 packId,
        uint256[] calldata tokenIds,
        uint32 numTimes,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        Pack memory pack = _packs[packId];
        uint256 newPackMintedCount = pack.mintedCount + numTimes;
        require(newPackMintedCount <= pack.capacity || pack.capacity == 0, "Over capacity");
        _packs[packId].mintedCount = newPackMintedCount;

        _mintPack(tokenIds, numTimes, nftRecipient, pack.itemSizes, pack.startTokenId);
    }

    /**
     * @notice See {IExpansion-mintDifferentCombination}
     */
    function mintDifferentCombination(
        uint256 packId,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        require(tokenIdCombinations.length == numCombinationPurchases.length, "Combination arrays mismatched");
        Pack memory pack = _packs[packId];

        uint256 combinations = tokenIdCombinations.length;
        uint32 numPurchases = 0;
        for (uint256 i = 0; i < combinations; i++) {
            _mintPack(
                tokenIdCombinations[i],
                numCombinationPurchases[i],
                nftRecipient,
                pack.itemSizes,
                pack.startTokenId
            );
            numPurchases += numCombinationPurchases[i];
        }

        uint256 newPackMintedCount = pack.mintedCount + numPurchases;
        require(newPackMintedCount <= pack.capacity || pack.capacity == 0, "Over capacity");
        _packs[packId].mintedCount = newPackMintedCount;
    }

    /**
     * @notice See {IExpansion-preparePack}
     */
    function preparePack(Pack memory pack) external payable override onlyRole(MINTER_ROLE) {
        _preparePack(pack);

        // If Async provided a msg.value refund the artist the difference between their gas deposit
        // and the actual gas cost of the preparePack call
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = artist.call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas deposit to platform failed");
        }
    }

    /**
     * @notice See {IExpansion-preparePackAndSale}
     */
    function preparePackAndSale(
        Pack memory pack,
        IStorefront.Sale memory sale,
        address storefront
    ) external override onlyRole(MINTER_ROLE) {
        sale.packId = _preparePack(pack);

        IStorefront(storefront).createSale(sale);
    }

    /**
     * @notice See {IExpansion-updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IExpansion-updateArtist}
     */
    function updateArtist(address newArtist) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        artist = newArtist;
    }

    /**
     * @notice See {IExpansion-topUpGasFunds}
     */
    function topUpGasFunds() external payable override {
        gasAmountDeposited += msg.value;
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = platform.call{ value: msg.value }("");
        /* solhint-enable avoid-low-level-calls */
        require(success, "gas deposit to platform failed");
    }

    /**
     * @notice See {IExpansion-setBaseUri}
     */
    function setBaseUri(uint256 packId, string calldata newBaseUri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_packs[packId].tokenUriLocked, "URI locked");
        _packs[packId].baseUri = newBaseUri;
    }

    /**
     * @notice See {IExpansion-lockBaseUri}
     */
    function lockBaseUri(uint256 packId) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_packs[packId].tokenUriLocked, "URI already locked");
        _packs[packId].tokenUriLocked = true;
    }

    /**
     * @notice See {IExpansion-updateOperatorFilterAndRegister}
     */
    function updateOperatorFilterAndRegister(address newRegistry, address newSubscription) external override {
        updateOperatorFilterRegistryAddress(newRegistry);
        addOperatorFiltererSubscription(newSubscription);
    }

    /**
     * @notice See {IExpansion-getPack}
     */
    function getPack(uint256 packId) external view override returns (Pack memory) {
        return _packs[packId];
    }

    /**
     * @notice See {IExpansion-getPacks}
     */
    function getPacks(uint256[] calldata packIds) external view override returns (Pack[] memory) {
        Pack[] memory packs = new Pack[](packIds.length);
        for (uint i = 0; i < packIds.length; i++) {
            packs[i] = _packs[packIds[i]];
        }

        return packs;
    }

    /**
     * @notice See {IExpansion-isPlatform}
     */
    function isPlatform(address account) external view override returns (bool) {
        return account == platform;
    }

    /**
     * @notice See {IExpansion-getFeeRecipients}
     */
    function getFeeRecipients(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IExpansion) returns (address[] memory) {
        return _royalty.recipients;
    }

    /**
     * @notice See {IExpansion-getFeeBps}
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IExpansion) returns (uint32[] memory) {
        return _royalty.royaltyCutsBPS;
    }

    /**
     * @notice See {IExpansion-getTokenPack}
     */
    function getTokenPack(uint256 tokenId) external view override returns (Pack memory) {
        return _getTokenPack(tokenId);
    }

    /**
     * @notice Subscribe to a new operator-filterer list.
     * @param subscription An address currently registered with the operatorFilterRegistry to subscribe to.
     */
    function addOperatorFiltererSubscription(address subscription) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry.subscribe(address(this), subscription);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. If not zero, this contract will be registered with the registry.
     * @param newRegistry New operator filterer address.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        if (newRegistry != address(0)) {
            operatorFilterRegistry.register(address(this));
        }
    }

    /**
     * @notice Override {IERC1155-setApprovalForAll} to check against operator filter registry if it exists
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override {IERC1155-safeTransferFrom} to check against operator filter registry if it exists
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Override {IERC1155-safeBatchTransferFrom} to check against operator filter registry if it exists
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Overrides {IERC1155-uri} to get base uri for pack that token is in, and concatenates token id
     * @param id ID of token to get uri for
     */
    function uri(uint256 id) public view override returns (string memory) {
        string memory baseUri = _getTokenPack(id).baseUri;

        return
            bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, "/", id.toString(), "/", "token.json")) : "";
    }

    /**
     * @notice Used for interoperability purposes (EIP-173)
     * @return Returns platform address as owner of contract
     */
    function owner() public view virtual returns (address) {
        return platform;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IExpansion).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Create a pack
     * @param pack Pack to create
     */
    function _preparePack(Pack memory pack) private returns (uint256) {
        // validate that pack is constructed properly
        uint256 itemsLength = pack.itemSizes.length;
        require(itemsLength > 0, "Items length invalid");
        uint256 newNumTokens = numTokens;
        pack.startTokenId = newNumTokens + 1;
        for (uint i = 0; i < itemsLength; i++) {
            newNumTokens += pack.itemSizes[i];
        }
        numTokens = newNumTokens;

        // No tokens have been minted yet
        pack.mintedCount = 0;

        // cache
        uint256 tempLatestPackId = numPacks;

        _packs[tempLatestPackId + 1] = pack;

        numPacks = tempLatestPackId + 1;

        emit PackPrepared(tempLatestPackId + 1, pack.capacity, pack.baseUri);

        return tempLatestPackId + 1;
    }

    /**
     * @notice Mint a combination of tokens on a pack
     * @param tokenIds Combination of tokens to mint
     * @param numPurchases How many of each token in the combination should be minted
     * @param nftRecipient Recipient of minted NFTs
     * @param itemSizes Pack's itemSizes
     * @param startTokenId Pack's start token id
     */
    function _mintPack(
        uint256[] calldata tokenIds,
        uint32 numPurchases,
        address nftRecipient,
        uint256[] memory itemSizes,
        uint256 startTokenId
    ) private {
        require(tokenIds.length == itemSizes.length, "Not same length");

        // assume token ids are aligned with itemIds order
        uint256 itemsLength = itemSizes.length;
        for (uint256 i = 0; i < itemsLength; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenIndex = tokenId - startTokenId;

            require(tokenIndex <= itemSizes[i] - 1, "Token id invalid");
            startTokenId += itemSizes[i];

            _mint(nftRecipient, tokenId, numPurchases, "");
        }
    }

    /**
     * @notice Get pack containing a given tokenId
     * @dev Avoid usage in state mutating functions (writes)
     * @param tokenId ID of token to get pack for
     */
    function _getTokenPack(uint256 tokenId) private view returns (Pack memory) {
        uint256 numPacksTemp = numPacks;
        for (uint256 i = 1; i <= numPacksTemp; i++) {
            Pack memory pack = _packs[i];
            uint256 itemsLength = pack.itemSizes.length;
            uint256 startTokenIdForItemInPack = pack.startTokenId;
            for (uint256 j = 0; j < itemsLength; j++) {
                uint256 itemSize = pack.itemSizes[j];
                if (j != 0) {
                    startTokenIdForItemInPack += itemSize;
                }
                if (startTokenIdForItemInPack > tokenId) {
                    revert("Skipped token id");
                }
                uint256 endTokenIdForItemInPack = startTokenIdForItemInPack + itemSize - 1;
                // If tokenId is in the range of token ids for a given pack
                if (tokenId <= endTokenIdForItemInPack && tokenId >= startTokenIdForItemInPack) {
                    return pack;
                }
            }
        }
        revert("Token id too big");
    }

    /**
     * @notice Check if operator can perform an action
     * @param operator Operator attempting to perform action
     */
    function _checkFilterOperator(address operator) private view {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}