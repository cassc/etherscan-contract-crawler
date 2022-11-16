// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC1155} from "openzeppelin/token/ERC1155/IERC1155.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

import {Forward} from "./Forward.sol";

import {ISeaport} from "./interfaces/external/ISeaport.sol";
import {IWithdrawValidator} from "./interfaces/IWithdrawValidator.sol";

contract Vault is ReentrancyGuard {
    // Structs

    struct ERC721Item {
        IERC721 token;
        uint256 identifier;
    }

    struct ERC1155Item {
        IERC1155 token;
        uint256 identifier;
        uint256 amount;
    }

    // Packed representation of a Seaport listing, with the following limitations:
    // - ETH-denominated
    // - fixed-price

    struct Payment {
        uint256 amount;
        address recipient;
    }

    struct SeaportListingDetails {
        ISeaport.ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
        Payment[] payments;
        bytes signature;
    }

    // Errors

    error AlreadyInitialized();

    error SeaportOrderIsInvalid();
    error SeaportOrderIsUnderpriced();
    error SeaportOrderRoyaltiesAreIncorrect();

    error CollectionOptedOut();
    error TokenDepositIsTooOld();

    error InvalidSignature();
    error Unauthorized();
    error UnsuccessfulPayment();

    // Events

    event RoyaltyPaid(
        address token,
        uint256 identifier,
        uint256 amount,
        uint256 price,
        uint256 royalty
    );

    // Public constants

    IERC20 public constant WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ISeaport public constant SEAPORT =
        ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581);

    bytes32 public constant SEAPORT_DOMAIN_SEPARATOR =
        0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e;

    // Public fields

    Forward public forward;
    address public owner;

    // Mapping from item id to its time of deposit into the vault
    mapping(bytes32 => uint256) public depositTime;

    // Constructor

    function initialize(address _forward, address _owner) public {
        if (address(forward) != address(0)) {
            revert AlreadyInitialized();
        }

        forward = Forward(_forward);
        owner = _owner;
    }

    // Receive fallback

    receive() external payable {
        // Send proceeds from accepted Seaport listings directly to the owner
        _sendPayment(owner, msg.value);
    }

    // Permissioned methods

    function withdrawERC721s(
        ERC721Item[] calldata items,
        bytes[] calldata oracleData,
        address recipient
    ) external payable nonReentrant {
        // Only the owner can withdraw tokens
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        // Cache the protocol address for gas-efficiency
        Forward protocol = forward;

        // Depending on the recipient, royalties might get skipped
        IWithdrawValidator withdrawValidator = protocol.withdrawValidator();
        bool skipRoyalties = address(withdrawValidator) != address(0) &&
            forward.withdrawValidator().canSkipRoyalties(msg.sender, recipient);

        uint256 itemsLength = items.length;
        for (uint256 i = 0; i < itemsLength; ) {
            IERC721 token = items[i].token;
            uint256 identifier = items[i].identifier;

            if (!skipRoyalties) {
                // Fetch the token's price
                uint256 price = protocol.priceOracle().getPrice(
                    address(token),
                    identifier,
                    protocol.forceWithdrawMaxAge(),
                    oracleData[i]
                );

                // Fetch the token's royalties (relative to the token's price)
                (
                    address[] memory royaltyRecipients,
                    uint256[] memory royaltyAmounts
                ) = protocol.royaltyEngine().getRoyaltyView(
                        address(token),
                        identifier,
                        price
                    );

                uint256 totalRoyaltyAmount;

                // Pay the royalties
                uint256 recipientsLength = royaltyRecipients.length;
                for (uint256 j = 0; j < recipientsLength; ) {
                    _sendPayment(royaltyRecipients[j], royaltyAmounts[j]);
                    totalRoyaltyAmount += royaltyAmounts[j];

                    unchecked {
                        ++j;
                    }
                }

                emit RoyaltyPaid(
                    address(token),
                    identifier,
                    1,
                    price,
                    totalRoyaltyAmount
                );
            }

            // Transfer the token out
            token.safeTransferFrom(address(this), recipient, identifier);

            unchecked {
                ++i;
            }
        }
    }

    function withdrawERC1155s(
        ERC1155Item[] calldata items,
        bytes[] calldata oracleData,
        address recipient
    ) external payable nonReentrant {
        // Only the owner can withdraw tokens
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        // Cache the protocol address for gas-efficiency
        Forward protocol = forward;

        // Depending on the recipient, royalties might get skipped
        IWithdrawValidator withdrawValidator = protocol.withdrawValidator();
        bool skipRoyalties = address(withdrawValidator) != address(0) &&
            forward.withdrawValidator().canSkipRoyalties(msg.sender, recipient);

        uint256 itemsLength = items.length;
        for (uint256 i = 0; i < itemsLength; ) {
            IERC1155 token = items[i].token;
            uint256 identifier = items[i].identifier;
            uint256 amount = items[i].amount;

            if (!skipRoyalties) {
                // Fetch the token's price
                uint256 price = protocol.priceOracle().getPrice(
                    address(token),
                    identifier,
                    protocol.forceWithdrawMaxAge(),
                    oracleData[i]
                );

                // Fetch the token's royalties (relative to the token's price)
                (
                    address[] memory royaltyRecipients,
                    uint256[] memory royaltyAmounts
                ) = protocol.royaltyEngine().getRoyaltyView(
                        address(token),
                        identifier,
                        price * amount
                    );

                uint256 totalRoyaltyAmount;

                // Pay the royalties
                uint256 recipientsLength = royaltyRecipients.length;
                for (uint256 j = 0; j < recipientsLength; ) {
                    _sendPayment(royaltyRecipients[j], royaltyAmounts[j]);
                    totalRoyaltyAmount += royaltyAmounts[j];

                    unchecked {
                        ++j;
                    }
                }

                emit RoyaltyPaid(
                    address(token),
                    identifier,
                    amount,
                    price,
                    totalRoyaltyAmount
                );
            }

            // Transfer the token out
            token.safeTransferFrom(
                address(this),
                recipient,
                identifier,
                amount,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    function acceptSeaportBid(
        ISeaport.AdvancedOrder calldata order,
        ISeaport.CriteriaResolver[] calldata criteriaResolvers,
        bytes calldata oracleData
    ) external nonReentrant {
        // Only the owner can accept bids
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        if (criteriaResolvers.length > 1) {
            revert SeaportOrderIsInvalid();
        }

        // Validate the offer item
        ISeaport.OfferItem memory paymentItem = order.parameters.offer[0];
        if (
            order.parameters.offer.length != 1 ||
            paymentItem.itemType != ISeaport.ItemType.ERC20 ||
            paymentItem.token != address(WETH) ||
            paymentItem.startAmount != paymentItem.endAmount
        ) {
            revert SeaportOrderIsInvalid();
        }

        ISeaport.ConsiderationItem[] memory consideration = order
            .parameters
            .consideration;

        // Validate the first consideration item
        ISeaport.ConsiderationItem memory nftItem = consideration[0];
        if (
            uint8(nftItem.itemType) < 2 ||
            nftItem.startAmount != nftItem.endAmount
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Validate the rest of consideration items
        uint256 considerationLength = consideration.length;
        for (uint256 i = 1; i < considerationLength; ) {
            ISeaport.ConsiderationItem memory item = consideration[i];
            if (
                item.itemType != ISeaport.ItemType.ERC20 ||
                item.token != address(WETH) ||
                item.startAmount != item.endAmount
            ) {
                revert SeaportOrderIsInvalid();
            }

            unchecked {
                ++i;
            }
        }

        // Cache some fields for gas-efficiency
        Forward protocol = forward;
        address token = nftItem.token;
        uint256 identifier = nftItem.identifierOrCriteria;

        // Properly set the identifier in case of criteria bids
        if (uint8(nftItem.itemType) > 3) {
            identifier = criteriaResolvers[0].identifier;
        }

        // Ensure the token's deposit time is not too far in the past
        bytes32 itemId = keccak256(abi.encode(token, identifier));
        uint256 timeOfDeposit = depositTime[itemId];
        if (
            block.timestamp - timeOfDeposit > protocol.softWithdrawTimeLimit()
        ) {
            revert TokenDepositIsTooOld();
        }

        // Adjust the price to the filled amount
        uint256 amount = (nftItem.endAmount * order.numerator) /
            order.denominator;
        uint256 totalPrice = (paymentItem.endAmount * order.numerator) /
            order.denominator;

        // Fetch the token's price
        uint256 price = protocol.priceOracle().getPrice(
            token,
            identifier,
            protocol.softWithdrawMaxAge(),
            oracleData
        );

        // Ensure the bid's price is within `minPriceBps` of the token's price
        if (totalPrice < (price * amount * protocol.minPriceBps()) / 10000) {
            revert SeaportOrderIsUnderpriced();
        }

        {
            // Fetch the token's royalties
            (
                address[] memory royaltyRecipients,
                uint256[] memory royaltyAmounts
            ) = protocol.royaltyEngine().getRoyaltyView(
                    token,
                    identifier,
                    totalPrice
                );

            // Ensure the royalties are present in the payment items
            // (ordering matters and should match the royalty engine)
            uint256 diff = considerationLength - royaltyAmounts.length;
            for (uint256 i = diff; i < considerationLength; ) {
                if (
                    consideration[i].recipient != royaltyRecipients[i - diff] ||
                    // The royalty should be AT LEAST what's returned by the royalty registry
                    consideration[i].endAmount < royaltyAmounts[i - diff]
                ) {
                    revert SeaportOrderRoyaltiesAreIncorrect();
                }

                unchecked {
                    ++i;
                }
            }
        }

        // An approval is needed for paying the royalties
        address conduit = forward.seaportConduit();
        uint256 allowance = WETH.allowance(address(this), conduit);
        if (allowance < type(uint256).max) {
            WETH.approve(conduit, type(uint256).max);
        }

        // Fulfill bid
        SEAPORT.fulfillAdvancedOrder(
            order,
            criteriaResolvers,
            forward.seaportConduitKey(),
            address(0)
        );

        // Forward any received WETH to the vault's owner
        WETH.transfer(msg.sender, WETH.balanceOf(address(this)));
    }

    // Internal methods

    function _sendPayment(address to, uint256 value) internal {
        (bool success, ) = payable(to).call{value: value}("");
        if (!success) {
            revert UnsuccessfulPayment();
        }
    }

    // ERC1271

    function isValidSignature(bytes32 digest, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        // Ensure any Seaport order originating from this vault is a listing
        // in the native token which is paying out the correct royalties (as
        // specified via the royalty registry)

        (
            SeaportListingDetails memory listingDetails,
            bytes memory oracleData
        ) = abi.decode(signature, (SeaportListingDetails, bytes));

        // Cache the payments for gas-efficiency
        Payment[] memory payments = listingDetails.payments;
        uint256 paymentsLength = payments.length;

        // Keep track of the total payment amount
        uint256 totalPrice;

        // Construct the consideration items
        ISeaport.ConsiderationItem[]
            memory consideration = new ISeaport.ConsiderationItem[](
                paymentsLength
            );
        {
            for (uint256 i = 0; i < paymentsLength; ) {
                uint256 paymentAmount = payments[i].amount;
                totalPrice += paymentAmount;

                consideration[i] = ISeaport.ConsiderationItem({
                    itemType: ISeaport.ItemType.NATIVE,
                    token: address(0),
                    identifierOrCriteria: 0,
                    startAmount: paymentAmount,
                    endAmount: paymentAmount,
                    recipient: payments[i].recipient
                });

                unchecked {
                    ++i;
                }
            }
        }

        // Cache some fields for gas-efficiency
        Forward protocol = forward;
        address token = listingDetails.token;
        uint256 identifier = listingDetails.identifier;
        uint256 amount = listingDetails.amount;

        // Ensure the token's deposit time is not too far in the past
        bytes32 itemId = keccak256(abi.encode(token, identifier));
        uint256 timeOfDeposit = depositTime[itemId];
        if (
            block.timestamp - timeOfDeposit > protocol.softWithdrawTimeLimit()
        ) {
            revert TokenDepositIsTooOld();
        }

        // Ensure the listing's validity time is not more than the oracle's price max age
        uint256 oraclePriceListMaxAge = protocol.softWithdrawMaxAge();
        if (
            listingDetails.endTime - listingDetails.startTime >
            oraclePriceListMaxAge
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Fetch the token's price
        uint256 price = protocol.priceOracle().getPrice(
            token,
            identifier,
            oraclePriceListMaxAge,
            oracleData
        );

        // Ensure the listing's price is within `minPriceBps` of the token's price
        if (totalPrice < (price * amount * protocol.minPriceBps()) / 10000) {
            revert SeaportOrderIsUnderpriced();
        }

        {
            // Fetch the token's royalties
            (
                address[] memory royaltyRecipients,
                uint256[] memory royaltyAmounts
            ) = protocol.royaltyEngine().getRoyaltyView(
                    token,
                    identifier,
                    totalPrice
                );

            // Ensure the royalties are present in the payment items
            // (ordering matters and should match the royalty engine)
            uint256 diff = paymentsLength - royaltyAmounts.length;
            for (uint256 i = diff; i < paymentsLength; ) {
                if (
                    payments[i].recipient != royaltyRecipients[i - diff] ||
                    // The royalty should be AT LEAST what's returned by the royalty registry
                    payments[i].amount < royaltyAmounts[i - diff]
                ) {
                    revert SeaportOrderRoyaltiesAreIncorrect();
                }

                unchecked {
                    ++i;
                }
            }
        }

        bytes32 orderHash;
        {
            // The listing should have a single offer item
            ISeaport.OfferItem[] memory offer = new ISeaport.OfferItem[](1);
            offer[0] = ISeaport.OfferItem({
                itemType: listingDetails.itemType,
                token: token,
                identifierOrCriteria: identifier,
                startAmount: amount,
                endAmount: amount
            });

            ISeaport.OrderComponents memory order;
            order.offerer = address(this);
            // order.zone = address(0);
            order.offer = offer;
            order.consideration = consideration;
            order.orderType = ISeaport.OrderType.PARTIAL_OPEN;
            order.startTime = listingDetails.startTime;
            order.endTime = listingDetails.endTime;
            // order.zoneHash = bytes32(0);
            order.salt = listingDetails.salt;
            order.conduitKey = protocol.seaportConduitKey();
            order.counter = SEAPORT.getCounter(address(this));

            orderHash = SEAPORT.getOrderHash(order);
        }

        // Ensure the order was properly constructed
        if (
            digest !=
            keccak256(
                abi.encodePacked(hex"1901", SEAPORT_DOMAIN_SEPARATOR, orderHash)
            )
        ) {
            revert SeaportOrderIsInvalid();
        }

        // Ensure the underlying order was signed by the vault's owner
        if (ECDSA.recover(digest, listingDetails.signature) != owner) {
            revert InvalidSignature();
        }

        return this.isValidSignature.selector;
    }

    // ERC721

    function onERC721Received(
        address, // operator
        address, // from
        uint256 tokenId,
        bytes calldata // data
    ) external returns (bytes4) {
        IERC721 token = IERC721(msg.sender);
        if (forward.optOutList().optedOut(address(token))) {
            revert CollectionOptedOut();
        }

        // Update the item's deposit time
        bytes32 itemId = keccak256(abi.encode(address(token), tokenId));
        depositTime[itemId] = block.timestamp;

        // Approve the token for listing if needed
        address conduit = forward.seaportConduit();
        bool isApproved = token.isApprovedForAll(address(this), conduit);
        if (!isApproved) {
            token.setApprovalForAll(conduit, true);
        }

        return this.onERC721Received.selector;
    }

    // ERC1155

    function onERC1155Received(
        address, // operator
        address, // from
        uint256 id,
        uint256, // value
        bytes calldata // data
    ) external returns (bytes4) {
        IERC1155 token = IERC1155(msg.sender);
        if (forward.optOutList().optedOut(address(token))) {
            revert CollectionOptedOut();
        }

        // Update the item's deposit time
        bytes32 itemId = keccak256(abi.encode(address(token), id));
        depositTime[itemId] = block.timestamp;

        // Approve the token for listing if needed
        address conduit = forward.seaportConduit();
        bool isApproved = token.isApprovedForAll(address(this), conduit);
        if (!isApproved) {
            token.setApprovalForAll(conduit, true);
        }

        return this.onERC1155Received.selector;
    }
}