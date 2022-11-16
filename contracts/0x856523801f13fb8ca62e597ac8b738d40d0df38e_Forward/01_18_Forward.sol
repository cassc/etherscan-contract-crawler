// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Clones} from "openzeppelin/proxy/Clones.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

import {Vault} from "./Vault.sol";

import {IRoyaltyEngine} from "./interfaces/external/IRoyaltyEngine.sol";
import {IConduitController} from "./interfaces/external/ISeaport.sol";
import {IOptOutList} from "./interfaces/IOptOutList.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IWithdrawValidator} from "./interfaces/IWithdrawValidator.sol";

contract Forward is Ownable, ReentrancyGuard {
    using Clones for address;

    // Enums

    enum ItemKind {
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    // Structs

    struct Order {
        ItemKind itemKind;
        address maker;
        address token;
        uint256 identifierOrCriteria;
        uint256 unitPrice;
        // The amount has a type of `uint128` instead of `uint256` so
        // that the order status can fit within a single storage slot
        uint128 amount;
        uint256 salt;
        uint256 expiration;
    }

    struct OrderStatus {
        bool cancelled;
        bool validated;
        uint128 filledAmount;
    }

    struct FillDetails {
        Order order;
        bytes signature;
        uint128 fillAmount;
    }

    // Errors

    error InvalidSeaportConduit();

    error OrderIsCancelled();
    error OrderIsExpired();
    error OrderIsInvalid();

    error VaultAlreadyExists();
    error VaultIsMissing();

    error InsufficientAmountAvailable();
    error InvalidCriteriaProof();
    error InvalidFillAmount();
    error InvalidSignature();

    error Unauthorized();

    // Events

    event OptOutListUpdated(address newOptOutList);
    event PriceOracleUpdated(address newPriceOracle);
    event RoyaltyEngineUpdated(address newRoyaltyEngine);
    event WithdrawValidatorUpdated(address newWithdrawValidator);

    event SoftWithdrawTimeLimitUpdated(uint256 newSoftWithdrawTimeLimit);
    event MinPriceBpsUpdated(uint256 newMinPriceBps);
    event SoftWithdrawMaxAgeUpdated(uint256 newSoftWithdrawMaxAge);
    event ForceWithdrawMaxAgeUpdated(uint256 newForceWithdrawMaxAge);
    event SeaportConduitUpdated(bytes32 newSeaportConduitKey);

    event VaultCreated(address owner, address vault);

    event CounterIncremented(address maker, uint256 newCounter);
    event OrderCancelled(bytes32 orderHash);
    event OrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address token,
        uint256 identifier,
        uint128 filledAmount,
        uint256 unitPrice
    );

    // Public constants

    IERC20 public constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IConduitController public constant CONDUIT_CONTROLLER =
        IConduitController(0x00000000F9490004C11Cef243f5400493c00Ad63);

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable ORDER_TYPEHASH;

    Vault public immutable vaultImplementation;

    // Public fields

    IOptOutList public optOutList;
    IPriceOracle public priceOracle;
    IRoyaltyEngine public royaltyEngine;
    IWithdrawValidator public withdrawValidator;

    // There is a time limit for listing or accepting a bid directly from the
    // vault and once that passes the only way to withdraw a token is via the
    // force withdraw which requires royalties to get paid
    uint256 public softWithdrawTimeLimit;

    // To avoid the possbility of evading royalties (by withdrawing via
    // a private listing or bid to a different own wallet for a zero or
    // very low price), we enforce the price of every outgoing order to
    // be within a percentage from the actual token's price (determined
    // via a pricing oracle)
    uint256 public minPriceBps;

    // Depending on the action that is taken (force withdrawing or listing / accepting
    // a bid directly within the vault) there are different requirements regarding the
    // staleness of the oracle's price
    uint256 public softWithdrawMaxAge;
    uint256 public forceWithdrawMaxAge;

    // Conduit used for Seaport listings from the vaults
    bytes32 public seaportConduitKey;
    address public seaportConduit;

    // Mapping from order hash to order status
    mapping(bytes32 => OrderStatus) public orderStatuses;
    // Mapping from wallet to current counter
    mapping(address => uint256) public counters;
    // Mapping from wallet to vault
    mapping(address => Vault) public vaults;

    // Constructor

    constructor(
        address _optOutList,
        address _priceOracle,
        address _royaltyEngine
    ) {
        optOutList = IOptOutList(_optOutList);
        priceOracle = IPriceOracle(_priceOracle);
        royaltyEngine = IRoyaltyEngine(_royaltyEngine);

        softWithdrawTimeLimit = 30 days;
        minPriceBps = 8000;

        softWithdrawMaxAge = 1 days;
        forceWithdrawMaxAge = 30 minutes;

        // Use OpenSea's default conduit (so that Seaport listings are available on OpenSea)
        seaportConduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
        seaportConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

        // Deploy a `Vault` contract that all proxies will point to
        vaultImplementation = new Vault();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // TODO: Pre-compute and store as a constant
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain("
                    "string name,"
                    "string version,"
                    "uint256 chainId,"
                    "address verifyingContract"
                    ")"
                ),
                keccak256("Forward"),
                keccak256("1.0"),
                chainId,
                address(this)
            )
        );

        // TODO: Pre-compute and store as a constant
        ORDER_TYPEHASH = keccak256(
            abi.encodePacked(
                "Order(",
                "uint8 itemKind,",
                "address maker,",
                "address token,",
                "uint256 identifierOrCriteria,",
                "uint256 unitPrice,",
                "uint128 amount,",
                "uint256 salt,",
                "uint256 expiration,",
                "uint256 counter",
                ")"
            )
        );
    }

    // Restricted methods

    function updateOptOutList(address newOptOutList) external onlyOwner {
        optOutList = IOptOutList(newOptOutList);
        emit OptOutListUpdated(newOptOutList);
    }

    function updatePriceOracle(address newPriceOracle) external onlyOwner {
        priceOracle = IPriceOracle(newPriceOracle);
        emit PriceOracleUpdated(newPriceOracle);
    }

    function updateRoyaltyEngine(address newRoyaltyEngine) external onlyOwner {
        royaltyEngine = IRoyaltyEngine(newRoyaltyEngine);
        emit RoyaltyEngineUpdated(newRoyaltyEngine);
    }

    function updateWithdrawValidator(address newWithdrawValidator)
        external
        onlyOwner
    {
        withdrawValidator = IWithdrawValidator(newWithdrawValidator);
        emit WithdrawValidatorUpdated(newWithdrawValidator);
    }

    function updateSoftWithdrawTimeLimit(uint256 newSoftWithdrawTimeLimit)
        external
        onlyOwner
    {
        softWithdrawTimeLimit = newSoftWithdrawTimeLimit;
        emit SoftWithdrawTimeLimitUpdated(newSoftWithdrawTimeLimit);
    }

    function updateMinPriceBps(uint256 newMinPriceBps) external onlyOwner {
        minPriceBps = newMinPriceBps;
        emit MinPriceBpsUpdated(newMinPriceBps);
    }

    function updateSoftWithdrawMaxAge(uint256 newSoftWithdrawMaxAge)
        external
        onlyOwner
    {
        softWithdrawMaxAge = newSoftWithdrawMaxAge;
        emit SoftWithdrawMaxAgeUpdated(newSoftWithdrawMaxAge);
    }

    function updateForceWithdrawMaxAge(uint256 newForceWithdrawMaxAge)
        external
        onlyOwner
    {
        forceWithdrawMaxAge = newForceWithdrawMaxAge;
        emit ForceWithdrawMaxAgeUpdated(newForceWithdrawMaxAge);
    }

    function updateSeaportConduit(bytes32 newSeaportConduitKey)
        external
        onlyOwner
    {
        (address newSeaportConduit, bool exists) = CONDUIT_CONTROLLER
            .getConduit(newSeaportConduitKey);
        if (!exists) {
            revert InvalidSeaportConduit();
        }

        seaportConduitKey = newSeaportConduitKey;
        seaportConduit = newSeaportConduit;
        emit SeaportConduitUpdated(newSeaportConduitKey);
    }

    // Public methods

    function createVault() external returns (Vault vault) {
        // Ensure the sender has no vault
        vault = vaults[msg.sender];
        if (address(vault) != address(0)) {
            revert VaultAlreadyExists();
        }

        // Deploy and initialize a vault using EIP1167
        vault = Vault(
            payable(
                address(vaultImplementation).cloneDeterministic(
                    keccak256(abi.encodePacked(msg.sender))
                )
            )
        );
        vault.initialize(address(this), msg.sender);

        // Associate the vault to the sender
        vaults[msg.sender] = vault;

        emit VaultCreated(msg.sender, address(vault));
    }

    function fillBid(FillDetails calldata details) external nonReentrant {
        // Ensure the order is non-criteria-based
        if (uint8(details.order.itemKind) > 1) {
            revert OrderIsInvalid();
        }

        _fillBid(details, details.order.identifierOrCriteria);
    }

    function fillBidWithCriteria(
        FillDetails calldata details,
        uint256 identifier,
        bytes32[] calldata criteriaProof
    ) external nonReentrant {
        // Ensure the order is criteria-based
        if (uint8(details.order.itemKind) < 2) {
            revert OrderIsInvalid();
        }

        // Ensure the provided identifier matches the order's criteria
        if (details.order.identifierOrCriteria != 0) {
            // The zero criteria will match any identifier
            _verifyCriteriaProof(
                identifier,
                details.order.identifierOrCriteria,
                criteriaProof
            );
        }

        _fillBid(details, identifier);
    }

    function cancel(Order[] calldata orders) external {
        uint256 length = orders.length;
        for (uint256 i = 0; i < length; ) {
            Order memory order = orders[i];

            // Only the order's maker can cancel
            if (order.maker != msg.sender) {
                revert Unauthorized();
            }

            // Mark the order as cancelled
            bytes32 orderHash = getOrderHash(order);
            orderStatuses[orderHash].cancelled = true;

            emit OrderCancelled(orderHash);

            unchecked {
                ++i;
            }
        }
    }

    function incrementCounter() external {
        // Similar to Seaport's implementation, incrementing the counter
        // will cancel any orders which were signed with a counter value
        // which is lower than the updated value
        uint256 newCounter;
        unchecked {
            newCounter = ++counters[msg.sender];
        }

        emit CounterIncremented(msg.sender, newCounter);
    }

    function getOrderHash(Order memory order)
        public
        view
        returns (bytes32 orderHash)
    {
        address maker = order.maker;

        // TODO: Optimize by using assembly
        orderHash = keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.itemKind,
                maker,
                order.token,
                order.identifierOrCriteria,
                order.unitPrice,
                order.amount,
                order.salt,
                order.expiration,
                counters[maker]
            )
        );
    }

    // Internal methods

    function _fillBid(FillDetails memory details, uint256 identifier) internal {
        Order memory order = details.order;

        address token = order.token;
        address maker = order.maker;
        uint256 unitPrice = order.unitPrice;
        uint128 fillAmount = details.fillAmount;

        // Ensure the maker has initialized a vault
        Vault vault = vaults[maker];
        if (address(vault) == address(0)) {
            revert VaultIsMissing();
        }

        // Ensure the order is not expired
        if (order.expiration <= block.timestamp) {
            revert OrderIsExpired();
        }

        // Compute the order's hash and its EIP712 hash
        bytes32 orderHash = getOrderHash(order);
        bytes32 eip712Hash = _getEIP712Hash(orderHash);

        // Ensure the maker's signature is valid
        OrderStatus memory orderStatus = orderStatuses[orderHash];
        if (
            !orderStatus.validated &&
            ECDSA.recover(eip712Hash, details.signature) != maker
        ) {
            revert InvalidSignature();
        }

        // Ensure the order is not cancelled
        if (orderStatus.cancelled) {
            revert OrderIsCancelled();
        }
        // Ensure the order is fillable
        if (order.amount - orderStatus.filledAmount < fillAmount) {
            revert InsufficientAmountAvailable();
        }

        // Send the payment to the taker
        WETH.transferFrom(maker, msg.sender, unitPrice * fillAmount);

        if (uint8(order.itemKind) % 2 == 0) {
            if (fillAmount != 1) {
                revert InvalidFillAmount();
            }

            // Transfer the token to the maker's vault
            IERC721(token).safeTransferFrom(
                msg.sender,
                address(vault),
                identifier
            );
        } else {
            if (fillAmount < 1) {
                revert InvalidFillAmount();
            }

            // Transfer the token to the maker's vault
            IERC1155(token).safeTransferFrom(
                msg.sender,
                address(vault),
                identifier,
                fillAmount,
                ""
            );
        }

        // Update the order's validated status and filled amount
        orderStatus.validated = true;
        orderStatus.filledAmount += fillAmount;
        orderStatuses[orderHash] = orderStatus;

        emit OrderFilled(
            orderHash,
            maker,
            msg.sender,
            token,
            identifier,
            fillAmount,
            unitPrice
        );
    }

    function _getEIP712Hash(bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(hex"1901", DOMAIN_SEPARATOR, structHash)
            );
    }

    // Taken from:
    // https://github.com/ProjectOpenSea/seaport/blob/dfce06d02413636f324f73352b54a4497d63c310/contracts/lib/CriteriaResolution.sol#L243-L247
    function _verifyCriteriaProof(
        uint256 leaf,
        uint256 root,
        bytes32[] memory criteriaProof
    ) internal pure {
        bool isValid;

        assembly {
            // Store the leaf at the beginning of scratch space
            mstore(0, leaf)

            // Derive the hash of the leaf to use as the initial proof element
            let computedHash := keccak256(0, 0x20)
            // Get memory start location of the first element in proof array
            let data := add(criteriaProof, 0x20)

            for {
                // Left shift by 5 is equivalent to multiplying by 0x20
                let end := add(data, shl(5, mload(criteriaProof)))
            } lt(data, end) {
                // Increment by one word at a time
                data := add(data, 0x20)
            } {
                // Get the proof element
                let loadedData := mload(data)

                // Sort proof elements and place them in scratch space
                let scratch := shl(5, gt(computedHash, loadedData))
                mstore(scratch, computedHash)
                mstore(xor(scratch, 0x20), loadedData)

                // Derive the updated hash
                computedHash := keccak256(0, 0x40)
            }

            isValid := eq(computedHash, root)
        }

        if (!isValid) {
            revert InvalidCriteriaProof();
        }
    }
}