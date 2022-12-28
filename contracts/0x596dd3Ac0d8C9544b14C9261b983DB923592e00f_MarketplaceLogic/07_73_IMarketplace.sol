// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";
import {OrderTypes} from "../dependencies/looksrare/contracts/libraries/OrderTypes.sol";
import {SeaportInterface} from "../dependencies/seaport/contracts/interfaces/SeaportInterface.sol";
import {ILooksRareExchange} from "../dependencies/looksrare/contracts/interfaces/ILooksRareExchange.sol";
import {SignatureChecker} from "../dependencies/looksrare/contracts/libraries/SignatureChecker.sol";
import {ConsiderationItem} from "../dependencies/seaport/contracts/lib/ConsiderationStructs.sol";
import {AdvancedOrder, CriteriaResolver, Fulfillment, OfferItem, ItemType} from "../dependencies/seaport/contracts/lib/ConsiderationStructs.sol";
import {Address} from "../dependencies/openzeppelin/contracts/Address.sol";
import {IERC1271} from "../dependencies/openzeppelin/contracts/IERC1271.sol";

interface IMarketplace {
    function getAskOrderInfo(bytes memory data)
        external
        view
        returns (DataTypes.OrderInfo memory orderInfo);

    function getBidOrderInfo(bytes memory data)
        external
        view
        returns (DataTypes.OrderInfo memory orderInfo);

    function matchAskWithTakerBid(
        address marketplace,
        bytes calldata data,
        uint256 value
    ) external payable returns (bytes memory);

    function matchBidWithTakerAsk(address marketplace, bytes calldata data)
        external
        returns (bytes memory);
}