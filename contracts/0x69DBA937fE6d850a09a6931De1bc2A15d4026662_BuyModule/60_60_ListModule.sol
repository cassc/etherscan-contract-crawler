// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Module, Enum} from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import {IListEvents} from "szns/interfaces/IListEvents.sol";
import {IListActions} from "szns/interfaces/IListActions.sol";
import {IRoyaltyEngineV1} from "szns/interfaces/IRoyaltyEngineV1.sol";
import {ConsiderationInterface} from "seaport/lib/Consideration.sol";
import {Order, OrderComponents, OfferItem, ItemType, ConsiderationItem, OrderType} from "seaport/lib/ConsiderationStructs.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Sealib} from "szns/lib/Sealib.sol";

contract ListModule is Module, IListEvents, IListActions, IERC721Receiver {
    error ApproveFail();
    error OrderFailed();
    error CancelFail();
    error ZeroAddressRecipient();
    error ZeroAddressListModule();

    ConsiderationInterface private immutable seaport;
    address private immutable conduit;
    IRoyaltyEngineV1 private immutable royaltyEngine;

    address payable public recipient;

    constructor(address _seaport, address _conduit, address _royaltyEngine) {
        if (_seaport == address(0)) revert ZeroAddressListModule();
        seaport = ConsiderationInterface(_seaport);
        if (_conduit == address(0)) revert ZeroAddressListModule();
        conduit = _conduit;
        if (_royaltyEngine == address(0)) revert ZeroAddressListModule();
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    /**
     * @dev Initialize function, will be triggered when a new proxy is deployed
     * @param initializeParams Parameters of initialization encoded
     * @notice This function will initialize the contract, including setting the avatar and target address.
     * @notice This function will also transfer ownership of the contract to the provided avatar address.
     */
    function setUp(
        bytes memory initializeParams
    ) public virtual override initializer {
        __Ownable_init();
        (address _avatar, address _target) = abi.decode(
            initializeParams,
            (address, address)
        );

        // __ListModule_setUp();

        setAvatar(_avatar);
        setTarget(_target);
        transferOwnership(_avatar);
    }

    /**
     * @dev This function allows the owner to set the recipient address for the contract.
     * @param _recipient The address that will receive any funds sent to the contract.
     * @notice The function can only be called by the contract's owner.
     * @notice Revert if the _recipient address is zero address.
     */
    function setRecipient(address payable _recipient) public onlyOwner {
        if (_recipient == address(0)) revert ZeroAddressRecipient();
        recipient = _recipient;
    }

    /**
     * @dev This function allows a user to list an NFT for sale on an exchange, such as OpenSea.
     * @param nftContract The address of the NFT contract.
     * @param tokenID The ID of the NFT being listed.
     * @param amount The price of the NFT being listed.
     * @param duration The duration of the NFT listing.
     * @notice This function will transfer the NFT from the user's account to the contract's account as escrow.
     * @notice Revert if the NFT transfer is unsuccessful.
     * @notice Emit NFTListed event on successful listing.
     */
    function list(
        address nftContract,
        uint256 tokenID,
        uint256 amount,
        uint256 duration
    ) public virtual {
        // 1) transfer the asset from safe to here as escrow
        bytes memory transferCallData = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            avatar,
            address(this),
            tokenID
        );
        exec(nftContract, 0, transferCallData, Enum.Operation.Call);

        // Check transfer
        if (IERC721(nftContract).ownerOf(tokenID) != address(this)) {
            revert OrderFailed();
        }

        (
            address payable[] memory royaltyRecipients,
            uint256[] memory royaltyAmounts
        ) = royaltyEngine.getRoyalty(nftContract, tokenID, amount);

        Order memory seaportOrder = Sealib.buildOrderFor(
            address(this),
            payable(address(this)),
            royaltyRecipients,
            nftContract,
            tokenID,
            amount,
            royaltyAmounts,
            block.timestamp + duration
        );
        _list(seaportOrder);

        emit NFTListed(
            block.timestamp,
            seaportOrder.parameters.offer[0].token,
            seaportOrder.parameters.offer[0].identifierOrCriteria,
            amount,
            block.timestamp + duration
        );
    }

    /**
     * @dev This function allows a user to cancel an order of an NFT on an exchange, such as OpenSea.
     * @param orders An array of order components representing the orders to be cancelled.
     * @notice Revert if the cancel operation is unsuccessful.
     * @notice This function will also transfer the NFT from the contract's account to the user's account if the NFT is still in escrow.
     */
    function cancel(OrderComponents[] calldata orders) public virtual {
        if (!seaport.cancel(orders)) {
            revert CancelFail();
        }

        unchecked {
            for (uint256 i = 0; i < orders.length; i++) {
                for (uint256 j = 0; j < orders[i].offer.length; j++) {
                    address nft = orders[i].offer[j].token;
                    uint256 id = orders[i].offer[j].identifierOrCriteria;
                    if (IERC721(nft).ownerOf(id) == address(this)) {
                        IERC721(nft).safeTransferFrom(
                            address(this),
                            avatar,
                            id
                        );
                    }
                }
            }
        }
    }

    /*
     * Lists an Order on OpenSEA. Previously approves all NFTS
     */
    function _list(Order memory seaportOrder) internal {
        // Approving all NFTs for SALE
        // TODO: We should check for other approvals in case non ERC721.
        uint256 orderItems = seaportOrder.parameters.offer.length;
        for (uint256 i = 0; i < orderItems; ) {
            OfferItem memory item = seaportOrder.parameters.offer[i];

            IERC721(item.token).approve(conduit, item.identifierOrCriteria);

            ++i;
        }

        // Validating the order
        Order[] memory orders = new Order[](1);
        orders[0] = seaportOrder;

        if (!seaport.validate(orders)) {
            revert OrderFailed();
        }
    }

    function onERC721Received(
        address, //operator,
        address, //from,
        uint256, //tokenId,
        bytes calldata //data
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }
}