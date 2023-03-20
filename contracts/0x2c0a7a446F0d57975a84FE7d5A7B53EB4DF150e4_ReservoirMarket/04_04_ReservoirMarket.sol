// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "../../interfaces/tokens/IERC20.sol";
import "../../interfaces/tokens/IERC721.sol";
import "../../interfaces/tokens/IERC1155.sol";

// Ref: https://github.com/reservoirprotocol/core/blob/main/packages/contracts/contracts/interfaces/ISeaport.sol

interface ISeaport {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address recipient;
    }

    struct OrderParameters {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 totalOriginalConsiderationItems;
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);
}


// Ref: https://github.com/reservoirprotocol/core/blob/main/packages/contracts/contracts/router/modules/exchanges/SeaportModule.sol
library ReservoirMarket {

    // Seaport v1.4
    address public constant SEAPORT = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    event ExecutionLogString (string data);
    event ExecutionLogBytes(bytes data);

    struct TradeData {
        uint256 value;
        ISeaport.AdvancedOrder advancedOrder;
        address recipient;
    }

    function execute(bytes memory tradeData) external {
        TradeData memory decoded = abi.decode(tradeData, (TradeData));

        try ISeaport(SEAPORT).fulfillAdvancedOrder{value: decoded.value}(
                decoded.advancedOrder,
                new ISeaport.CriteriaResolver[](0),
                bytes32(0),
                decoded.recipient
            ) returns (bool fulfilled) {

            ISeaport.OrderParameters memory params = decoded.advancedOrder.parameters;
            if (fulfilled) {
                for (uint256 i = 0; i < params.offer.length; i++) {
                    ISeaport.OfferItem memory item = params.offer[i];
                    if (item.itemType == ISeaport.ItemType.NATIVE) {
                        // ETH
                    } else if (item.itemType == ISeaport.ItemType.ERC20) {
                        // ERC-20
                    } else if (item.itemType == ISeaport.ItemType.ERC721) {
                        // ERC-721
                        IERC721(item.token).transferFrom(address(this), msg.sender, item.identifierOrCriteria);
                    } else if (item.itemType == ISeaport.ItemType.ERC1155) {
                        // ERC-1155
                        IERC1155(item.token).safeTransferFrom(address(this), msg.sender, item.identifierOrCriteria, item.endAmount, "");
                    }
                }
            } else {
                emit ExecutionLogString("Order not fulfilled");
            }
        } catch Error(string memory reason) {
            emit ExecutionLogString(reason);
        } catch (bytes memory reason) {
            emit ExecutionLogBytes(reason);
        }
    }
}