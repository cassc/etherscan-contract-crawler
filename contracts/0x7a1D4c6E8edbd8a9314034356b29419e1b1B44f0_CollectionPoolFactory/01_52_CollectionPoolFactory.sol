// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {TransferLib} from "../lib/TransferLib.sol";

import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionPoolERC20} from "./CollectionPoolERC20.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionPoolEnumerableETH} from "./CollectionPoolEnumerableETH.sol";
import {CollectionPoolEnumerableERC20} from "./CollectionPoolEnumerableERC20.sol";
import {CollectionPoolMissingEnumerableETH} from "./CollectionPoolMissingEnumerableETH.sol";
import {CollectionPoolMissingEnumerableERC20} from "./CollectionPoolMissingEnumerableERC20.sol";
import {MultiPauser} from "../lib/MultiPauser.sol";
import {
    PoolVariant,
    CreateETHPoolParams,
    NFTFilterParams,
    CreateERC20PoolParams,
    RouterStatus,
    RoyaltyDue
} from "./CollectionStructsAndEnums.sol";

/**
 * @dev The ETH balance of this contract is used both to store protocol fees
 * which the owner can withdraw, as well as royalties accumulated from swaps
 * made against pools deployed by this contract.
 */
contract CollectionPoolFactory is
    Ownable,
    ReentrancyGuard,
    ERC721,
    ERC721URIStorage,
    MultiPauser,
    ICollectionPoolFactory
{
    using CollectionPoolCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    uint256 private constant CREATION_PAUSE = 0;
    uint256 private constant SWAP_PAUSE = 1;
    uint256 private constant DEPOSIT_PAUSE = 2;
    /// @notice For pausing everything that isn't covered by the above lock
    /// besides withdrawals
    uint256 private constant OTHERS_PAUSE = 3;

    /**
     * @dev The MAX_PROTOCOL_FEE constant specifies the maximum fee that can be charged by the AMM pool contract
     * for facilitating token or NFT swaps on the decentralized exchange.
     * This fee is charged as a flat percentage of the final traded price for each swap,
     * and it is used to cover the costs associated with running the AMM pool contract and providing liquidity to the decentralized exchange.
     * This is used for NFT/TOKEN trading pools, that have a limited amount of dry powder
     */
    uint256 internal constant MAX_PROTOCOL_FEE = 0.1e6; // 10%, must <= 1 - MAX_FEE
    /**
     * @dev The MAX_CARRY_FEE constant specifies the maximum fee that can be charged by the AMM pool contract for facilitating token
     * or NFT swaps on the decentralized exchange. This fee is charged as a percentage of the fee set by the trading pool creator,
     * which is itself a percentage of the final traded price. This is used for TRADE pools, that form a continuous liquidity pool
     */
    uint256 internal constant MAX_CARRY_FEE = 0.5e6; // 50%

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    CollectionPoolEnumerableETH public immutable enumerableETHTemplate;
    CollectionPoolMissingEnumerableETH public immutable missingEnumerableETHTemplate;
    CollectionPoolEnumerableERC20 public immutable enumerableERC20Template;
    CollectionPoolMissingEnumerableERC20 public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e6
    uint24 public override protocolFeeMultiplier;

    // Units are in base 1e6
    uint24 public override carryFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;
    /// @dev Used to track how much royalties are stored in this contract balance.
    /// This is to prevent the factory owner from withdrawing more than they should
    mapping(ERC20 => uint256) royaltiesStored;
    /// @dev Uses address 0 for ETH royalties
    mapping(address => mapping(ERC20 => uint256)) public royaltiesClaimable;

    mapping(CollectionRouter => RouterStatus) public override routerStatus;

    string public baseURI;

    modifier whenCreationNotPaused() {
        require(!creationPaused(), "Pool creation is paused");
        _;
    }

    modifier whenOthersNotPaused() {
        require(!othersPaused(), "Function is paused");
        _;
    }

    event NewPool(address indexed collection, address indexed poolAddress);
    event TokenDeposit(address indexed poolAddress);
    event ProtocolFeeRecipientUpdate(address indexed recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint24 newMultiplier);
    event CarryFeeMultiplierUpdate(uint24 newMultiplier);
    event BondingCurveStatusUpdate(ICurve indexed bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address indexed target, bool isAllowed);
    event RouterStatusUpdate(CollectionRouter indexed router, bool isAllowed);
    event CreationPause();
    event CreationUnpause();
    event SwapPause();
    event SwapUnpause();
    event OthersPause();
    event OthersUnpause();
    event DepositPause();
    event DepositUnpause();

    error InsufficientValue(uint256 msgValue, uint256 amountRequired);

    constructor(
        CollectionPoolEnumerableETH _enumerableETHTemplate,
        CollectionPoolMissingEnumerableETH _missingEnumerableETHTemplate,
        CollectionPoolEnumerableERC20 _enumerableERC20Template,
        CollectionPoolMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint24 _protocolFeeMultiplier,
        uint24 _carryFeeMultiplier
    ) ERC721("Collectionswap", "CollectionLP") {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Protocol fee too large");
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Carry fee too large");
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;
        protocolFeeMultiplier = _protocolFeeMultiplier;
        carryFeeMultiplier = _carryFeeMultiplier;
    }

    /**
     * External view functions. Not pausable.
     */

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view {
        require(_isApprovedOrOwner(spender, tokenId), "Not approved");
    }

    /**
     * @dev See {ICollectionPoolFactory-poolOf}.
     */
    function poolOf(uint256 tokenId) public pure returns (ICollectionPool) {
        return ICollectionPool(address(uint160(tokenId)));
    }

    /**
     * @notice Check if a pool is any of the templates deployed with this factory
     */
    function isPool(address potentialPool) public view returns (bool) {
        return isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ETH)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ETH);
    }

    /**
     * @notice Checks if an address is a CollectionPool. Uses the fact that the pools are EIP-1167 minimal proxies.
     * @param potentialPool The address to check
     * @param variant The pool variant (NFT is enumerable or not, pool uses ETH or ERC20)
     * @dev The PoolCloner contract is a utility contract that is used by the PoolFactory contract to create new instances of automated market maker (AMM) pools.
     * @return True if the address is the specified pool variant, false otherwise
     */
    function isPoolVariant(address potentialPool, PoolVariant variant) public view returns (bool) {
        if (variant == PoolVariant.ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(address(this), address(enumerableERC20Template), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(
                address(this), address(missingEnumerableERC20Template), potentialPool
            );
        } else if (variant == PoolVariant.ENUMERABLE_ETH) {
            return CollectionPoolCloner.isETHPoolClone(address(this), address(enumerableETHTemplate), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            return
                CollectionPoolCloner.isETHPoolClone(address(this), address(missingEnumerableETHTemplate), potentialPool);
        } else {
            // invalid input
            return false;
        }
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function swapPaused() external view returns (bool) {
        return isPaused(SWAP_PAUSE);
    }

    function creationPaused() public view returns (bool) {
        return isPaused(CREATION_PAUSE);
    }

    function depositPaused() external view returns (bool) {
        return isPaused(DEPOSIT_PAUSE);
    }

    function othersPaused() public view returns (bool) {
        return isPaused(OTHERS_PAUSE);
    }

    /**
     * Pool creation functions. Pausable
     */
    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        _initializePoolETH(pool, params);
    }

    /**
     * @notice Creates a filtered pool contract using EIP-1167.
     * @param params The parameters to create ETH pool
     * @param filterParams The parameters needed for the filtering functionality
     * @return pool The new pool
     */
    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolETH and check later.
        pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolETH(pool, params);
    }

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        address is777 = _ERC1820_REGISTRY.getInterfaceImplementer(address(params.token), keccak256("ERC777Token"));
        require(is777 == address(0), "ERC777 not supported");

        (pool, tokenId) = _createPoolERC20(params);

        _initializePoolERC20(pool, params);
    }

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        whenCreationNotPaused
        returns (ICollectionPool pool, uint256 tokenId)
    {
        address is777 = _ERC1820_REGISTRY.getInterfaceImplementer(address(params.token), keccak256("ERC777Token"));
        require(is777 == address(0), "ERC777 not supported");

        (pool, tokenId) = _createPoolERC20(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolERC20 and check later.
        pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolERC20(pool, params);
    }

    /**
     * @notice Update royalty bookkeeping in `token` currency according to
     * `royaltiesDue`. Only callable by pools
     * @param token The ERC20 token that royalties are in. ERC20(address(0)) for ETH
     * @param royaltiesDue An array of the recipients and amounts due each address
     * @param poolVariant the variant of the pool being interacted with
     */
    function depositRoyaltiesNotification(ERC20 token, RoyaltyDue[] calldata royaltiesDue, PoolVariant poolVariant)
        external
        payable
        whenOthersNotPaused
    {
        require(isPoolVariant(msg.sender, poolVariant), "Not pool");
        uint256 length = royaltiesDue.length;
        uint256 amountRequired;
        // Do internal bookkeeping of who can claim portions of the tokens about
        // to be transferred in
        for (uint256 i; i < length;) {
            address recipient = royaltiesDue[i].recipient;
            if (msg.sender != recipient) {
                amountRequired += royaltiesDue[i].amount;
                royaltiesClaimable[royaltiesDue[i].recipient][token] += royaltiesDue[i].amount;
            }

            unchecked {
                ++i;
            }
        }

        royaltiesStored[token] += amountRequired;
    }

    /*
     * @notice NFTs that don't match filter and any airdropped assets  must be rescued prior to calling this function.
     * Requires LP token owner to give allowance to this factory contract for asset withdrawals
     * which are sent directly to the LP token owner.
     */
    function burn(uint256 tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        ICollectionPool pool = poolOf(tokenId);
        PoolVariant poolVariant = pool.poolVariant();

        // withdraw all ETH / ERC20
        if (poolVariant == PoolVariant.ENUMERABLE_ETH || poolVariant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            // withdraw ETH, sent to owner of LP token
            CollectionPoolETH(payable(address(pool))).withdrawAllETH();
        } else if (poolVariant == PoolVariant.ENUMERABLE_ERC20 || poolVariant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            // withdraw ERC20
            CollectionPoolERC20(address(pool)).withdrawAllERC20();
        }
        // then withdraw NFTs
        pool.withdrawERC721(pool.nft(), pool.getAllHeldIds());

        _burn(tokenId);
    }

    /**
     * Admin functions. Not pausable. Pointless because pauser/unpauser is owner
     * and all admin functions are onlyOwner.
     */

    function pauseCreation() external onlyOwner {
        pause(CREATION_PAUSE);
        emit CreationPause();
    }

    function unpauseCreation() external onlyOwner {
        unpause(CREATION_PAUSE);
        emit CreationUnpause();
    }

    function pauseSwap() external onlyOwner {
        pause(SWAP_PAUSE);
        emit SwapPause();
    }

    function unpauseSwap() external onlyOwner {
        unpause(SWAP_PAUSE);
        emit SwapUnpause();
    }

    function pauseDeposit() external onlyOwner {
        pause(DEPOSIT_PAUSE);
        emit DepositPause();
    }

    function unpauseDeposit() external onlyOwner {
        unpause(DEPOSIT_PAUSE);
        emit DepositUnpause();
    }

    function pauseOthers() external onlyOwner {
        pause(OTHERS_PAUSE);
        emit OthersPause();
    }

    function unpauseOthers() external onlyOwner {
        unpause(OTHERS_PAUSE);
        emit OthersUnpause();
    }

    /**
     * Withdrawal functions. Not pausable.
     */

    /**
     * @notice Withdraw all `token` royalties awardable to `recipient`. If the
     * zero address is passed as `token`, then ETH royalties are paid. Does not
     * use msg.sender so this function can be called on behalf of contract
     * royalty recipients
     */
    function withdrawRoyalties(address payable recipient, ERC20 token) external {
        uint256 totalRoyaltiesWithdrawn;
        if (address(token) == address(0)) {
            totalRoyaltiesWithdrawn = withdrawETHRoyalties(recipient);
        } else {
            totalRoyaltiesWithdrawn = withdrawERC20Royalties(recipient, token);
        }

        royaltiesStored[token] -= totalRoyaltiesWithdrawn;
    }

    /**
     * @dev Internal helper function for withdrawing ETH royalties for a single
     * address. Does NOT update `royaltiesStored[token]`
     */
    function withdrawETHRoyalties(address payable recipient) internal returns (uint256 amount) {
        amount = royaltiesClaimable[recipient][ERC20(address(0))];
        royaltiesClaimable[recipient][ERC20(address(0))] = 0;
        recipient.safeTransferETH(amount);
    }

    /**
     * @dev Internal helper function for withdrawing ERC20 royalties for a single
     * address. Does NOT update `royaltiesStored[token]`
     */
    function withdrawERC20Royalties(address payable recipient, ERC20 token) internal returns (uint256 amount) {
        require(address(token) != address(0), "Use withdrawETHRoyalties instead");
        amount = royaltiesClaimable[recipient][token];
        royaltiesClaimable[recipient][token] = 0;
        token.safeTransfer(recipient, amount);
    }

    /**
     * @dev Uses the internal helper functions to batch writes to `royaltiesStored`
     */
    function withdrawRoyaltiesMultipleRecipients(address payable[] calldata recipients, ERC20 token) public {
        uint256 length = recipients.length;
        uint256 totalRoyaltiesWithdrawn;
        uint256 amount;
        if (address(token) == address(0)) {
            for (uint256 i; i < length;) {
                amount = withdrawETHRoyalties(recipients[i]);
                totalRoyaltiesWithdrawn += amount;

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < length;) {
                amount = withdrawERC20Royalties(recipients[i], token);
                totalRoyaltiesWithdrawn += amount;

                unchecked {
                    ++i;
                }
            }
        }

        royaltiesStored[token] -= totalRoyaltiesWithdrawn;
    }

    function withdrawRoyaltiesMultipleCurrencies(address payable recipient, ERC20[] calldata tokens) external {
        uint256 length = tokens.length;
        uint256 amount;
        for (uint256 i; i < length; i++) {
            ERC20 token = tokens[i];
            amount = royaltiesClaimable[recipient][token];
            royaltiesClaimable[recipient][token] = 0;

            /// @dev Need to repeat this check for every token iterated over
            if (address(token) == address(0)) {
                recipient.safeTransferETH(amount);
            } else {
                token.safeTransfer(recipient, amount);
            }

            royaltiesStored[token] -= amount;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraw royalties for ALL combinations of recipients and tokens
     * in the given arguments
     *
     * @dev Iterate over tokens as outer loop to reduce stores/loads to `royaltiesStored`
     * and the number of `address(token) == address(0)` condition checks from
     * O(m * n) to O(n)
     */
    function withdrawRoyaltiesMultipleRecipientsAndCurrencies(
        address payable[] calldata recipients,
        ERC20[] calldata tokens
    ) external {
        uint256 length = tokens.length;
        for (uint256 i; i < length; i++) {
            ERC20 token = tokens[i];
            withdrawRoyaltiesMultipleRecipients(recipients, token);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Withdraws the ETH balance to the protocol fee recipient.
     * Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance - royaltiesStored[ERC20(address(0))]);
    }

    /**
     * @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
     * @param token The token to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, token.balanceOf(address(this)) - royaltiesStored[token]);
    }

    /**
     * @notice Changes the protocol fee recipient address. Only callable by the owner.
     * @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        if (protocolFeeRecipient != _protocolFeeRecipient) {
            protocolFeeRecipient = _protocolFeeRecipient;
            emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
        }
    }

    /**
     * @notice Changes the protocol fee multiplier. Only callable by the owner.
     * @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint24 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        if (protocolFeeMultiplier != _protocolFeeMultiplier) {
            protocolFeeMultiplier = _protocolFeeMultiplier;
            emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
        }
    }

    /**
     * @notice Changes the carry fee multiplier. Only callable by the owner.
     * @param _carryFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeCarryFeeMultiplier(uint24 _carryFeeMultiplier) external onlyOwner {
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Fee too large");
        if (carryFeeMultiplier != _carryFeeMultiplier) {
            carryFeeMultiplier = _carryFeeMultiplier;
            emit CarryFeeMultiplierUpdate(_carryFeeMultiplier);
        }
    }

    /**
     * @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
     * @param bondingCurve The bonding curve contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bool wasAllowed = bondingCurveAllowed[bondingCurve];
        if (wasAllowed != isAllowed) {
            bondingCurveAllowed[bondingCurve] = isAllowed;
            emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
        }
    }

    /**
     * @notice Sets the whitelist status of a contract to be called arbitrarily by a pool.
     * Only callable by the owner.
     * @param target The target contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[CollectionRouter(target)].wasEverAllowed, "Can't call router");
        }

        bool wasAllowed = callAllowed[target];
        if (wasAllowed != isAllowed) {
            callAllowed[target] = isAllowed;
            emit CallTargetStatusUpdate(target, isAllowed);
        }
    }

    /**
     * @notice Updates the router whitelist. Only callable by the owner.
     * @param _router The router
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(CollectionRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pools
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }

        bool wasAllowed = routerStatus[_router].allowed;
        if (wasAllowed != isAllowed) {
            routerStatus[_router] = RouterStatus({allowed: isAllowed, wasEverAllowed: true});
            emit RouterStatusUpdate(_router, isAllowed);
        }
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenURI(string calldata _uri, uint256 tokenId) external onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    /**
     * Internal functions
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _createPoolETH(CreateETHPoolParams calldata params)
        internal
        returns (ICollectionPool pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            validRoyaltyState(params.royaltyNumerator, params.royaltyRecipientFallback, params.nft),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        address poolAddress = template.cloneETHPool(this, params.bondingCurve, params.nft, uint8(params.poolType));

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(poolAddress));

        emit NewPool(address(params.nft), poolAddress);

        return (ICollectionPool(poolAddress), tokenId);
    }

    function _initializePoolETH(ICollectionPool _pool, CreateETHPoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial ETH to pool
        payable(address(_pool)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool);
    }

    function _createPoolERC20(CreateERC20PoolParams calldata params)
        internal
        returns (ICollectionPool pool, uint256 tokenId)
    {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            validRoyaltyState(params.royaltyNumerator, params.royaltyRecipientFallback, params.nft),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        address poolAddress =
            template.cloneERC20Pool(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token);

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(poolAddress));

        emit NewPool(address(params.nft), poolAddress);

        return (ICollectionPool(poolAddress), tokenId);
    }

    function _initializePoolERC20(ICollectionPool _pool, CreateERC20PoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial tokens to pool
        _params.token.safeTransferFrom(msg.sender, address(_pool), _params.initialTokenBalance);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool);
    }

    /**
     * @dev Transfers NFTs from sender and notifies pool. `ids` must already have been verified
     */
    function _depositNFTs(IERC721 _nft, uint256[] calldata nftIds, ICollectionPool pool) internal {
        // transfer NFTs from caller to recipient
        TransferLib.bulkSafeTransferERC721From(_nft, msg.sender, address(pool), nftIds);
        pool.depositNFTsNotification(nftIds);
    }

    /*
     * @dev Mints LP token using pool address as Token ID
     */
    function mint(address recipient, CollectionPool pool) internal returns (uint256 tokenId) {
        tokenId = uint160(address(pool));
        _safeMint(recipient, tokenId);
    }

    function validRoyaltyState(uint24 royaltyNumerator, address royaltyRecipientFallback, IERC721 nft)
        internal
        view
        returns (bool)
    {
        return royaltyNumerator == 0 || royaltyRecipientFallback != address(0)
            || IERC165(nft).supportsInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * Required override functions
     */

    /**
     * @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {
        /**
         * No logic needed here:
         * - Factory needs to accept all transfers so that swaps don't fail to send token to
         * appropriate recipients when paying protocol fees/royalties.
         * - No bookkeeping is needed upon ETH receipt.
         */
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}