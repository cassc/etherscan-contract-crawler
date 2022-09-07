//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IERC721Validator.sol";
import "../interfaces/IBountyBoard.sol";

/// @title BountyBoard
/// @author sina.eth
/// @notice Broker for offers to mint ERC20 tokens in exchange for ERC721s
contract BountyBoard is Ownable, IBountyBoard, IERC721Receiver {
    event OrderCreated(
        Order order,
        uint256 maxFills,
        address indexed tokenAddress,
        address indexed nftBeneficiary,
        bytes32 indexed orderHash
    );
    event OrdersFilled(OrderGrouping[] orderGroupings);
    event OrderFilled(
        bytes32 orderHash,
        address erc721Address,
        uint256 erc721Id
    );
    event OrderDisabled(bytes32 indexed orderHash);

    error BadOrderParamsError();
    error OrderCreatorMissingMinterRoleError();
    error BountyBoardMissingMinterRoleError();
    error OrderAlreadyExistsError();
    error InvalidOrderError();
    error InvalidNftError(address addr, uint256 id);
    error OrderAlreadyDisabledError();
    error MissingOrderDisablerRoleError();

    struct Order {
        IERC721Validator validator;
        ERC20PresetMinterPauser erc20;
        address nftBeneficiary;
        uint256 tokensPerTribute;
        uint256 expirationTime;
    }

    struct OrderGrouping {
        Order order;
        ERC721Grouping[] erc721Groupings;
    }

    bytes32 public immutable ORDER_DISABLER_ROLE;

    /// Orders are kept as a map from hash of order
    ///   params to remaining number of fills.
    mapping(bytes32 => uint256) public remainingFills;

    constructor(address owner) {
        ORDER_DISABLER_ROLE = keccak256(
            abi.encode(address(this), "DISABLE_ORDER_ROLE")
        );
        transferOwnership(owner);
    }

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    /// @notice Adds an order to the "BountyBoard" orderbook
    /// @param order Struct of all the order params that stay static.
    /// @param maxFills Maximum number of NFTs this order can be filled for
    /// @return orderHash The unique identifying hash for the added order
    function addOrder(Order calldata order, uint256 maxFills)
        external
        returns (bytes32 orderHash)
    {
        // Checks
        if (order.expirationTime <= block.timestamp || maxFills == 0) {
            revert BadOrderParamsError();
        }
        if (!order.erc20.hasRole(order.erc20.MINTER_ROLE(), msg.sender)) {
            revert OrderCreatorMissingMinterRoleError();
        }
        if (!order.erc20.hasRole(order.erc20.MINTER_ROLE(), address(this))) {
            revert BountyBoardMissingMinterRoleError();
        }
        orderHash = hashOrder(order);
        if (remainingFills[orderHash] != 0) {
            revert OrderAlreadyExistsError();
        }

        // Add new order
        remainingFills[orderHash] = maxFills;
        emit OrderCreated(
            order,
            maxFills,
            address(order.erc20),
            order.nftBeneficiary,
            orderHash
        );
    }

    /// @notice Disables an order
    /// @param order Payload of order to be disabled
    function disableOrder(Order calldata order) external {
        if (!order.erc20.hasRole(ORDER_DISABLER_ROLE, msg.sender)) {
            revert MissingOrderDisablerRoleError();
        }
        bytes32 orderHash = hashOrder(order);
        remainingFills[orderHash] = 0;
        emit OrderDisabled(orderHash);
    }

    /// @notice Handles filling an order via a ERC721Received callback
    function onERC721Received(
        address, // operator
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        Order memory order = abi.decode(data, (Order));
        bytes32 orderHash = hashOrder(order);
        if (
            !IERC721Validator(order.validator).meetsCriteria(
                msg.sender, // the NFT contract address
                tokenId
            )
        ) {
            revert InvalidNftError(msg.sender, tokenId);
        }
        if (
            order.expirationTime <= block.timestamp ||
            remainingFills[orderHash] == 0
        ) {
            revert InvalidOrderError();
        }
        unchecked {
            // Checked above that this is not zero
            remainingFills[orderHash] -= 1;
        }
        // Payout to order filler and beneficiary
        order.erc20.mint(from, order.tokensPerTribute);
        IERC721(msg.sender).safeTransferFrom(
            address(this),
            order.nftBeneficiary,
            tokenId
        );
        emit OrderFilled(orderHash, msg.sender, tokenId);
        return this.onERC721Received.selector;
    }

    /// @notice Fills a single order multiple times
    /// @param orderGroupings Struct entailing the orders to be filled associated with their ERC721s
    function batchFill(OrderGrouping[] calldata orderGroupings) external {
        for (uint256 i = 0; i < orderGroupings.length; i++) {
            batchFillOrder(
                orderGroupings[i].order,
                orderGroupings[i].erc721Groupings
            );
        }
        emit OrdersFilled(orderGroupings);
    }

    function batchFillOrder(
        Order calldata order,
        ERC721Grouping[] calldata erc721Groupings
    ) internal {
        if (order.expirationTime <= block.timestamp) {
            revert InvalidOrderError();
        }
        bytes32 orderHash = hashOrder(order);
        uint256 tributeCounter = 0;
        IERC721 erc721;
        uint256 id;
        for (uint256 i = 0; i < erc721Groupings.length; i++) {
            tributeCounter += erc721Groupings[i].ids.length;
            erc721 = erc721Groupings[i].erc721;
            for (uint256 j = 0; j < erc721Groupings[i].ids.length; j++) {
                id = erc721Groupings[i].ids[j];
                if (!order.validator.meetsCriteria(address(erc721), id)) {
                    revert InvalidNftError(address(erc721), id);
                }
                // Forward NFT to benecifiary
                // NOTE: reentrancy should be safe here, since we're decrementing
                //   the number of fills based on its later value.
                erc721.safeTransferFrom(
                    msg.sender, //If sender doesn't own the nft this should fail
                    order.nftBeneficiary,
                    id
                );
            }
        }
        // Should throw if underflow
        remainingFills[orderHash] -= tributeCounter;
        // Payout to order filler
        order.erc20.mint(msg.sender, order.tokensPerTribute * tributeCounter);
    }

    function recoverERC20(IERC20 tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        tokenAddress.transfer(owner(), amount);
    }

    function recoverERC721(IERC721 tokenAddress, uint256 tokenId)
        external
        onlyOwner
    {
        tokenAddress.safeTransferFrom(address(this), owner(), tokenId);
    }
}