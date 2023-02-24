// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

import "../../type/ITokenTypes.sol";
import "../../other/ITrustedForwarder.sol";

interface IGameFiShopV1 is ITokenTypes, ITrustedForwarder {
    enum ShopStatus {
        NULL,
        OPEN,
        CLOSED
    }

    struct Shop {
        TokenStandart tokenInStandart;
        TransferredToken tokenInOffer;
        TokenStandart tokenOutStandart;
        TransferredToken tokenOutOffer;
        ShopStatus status;
        string tag;
    }

    event CreateShop(address indexed sender, uint256 indexed shopId, Shop shop, uint256 timestamp);
    event EditShop(address indexed sender, uint256 indexed shopId, Shop shop, uint256 timestamp);
    event BuyToken(address indexed sender, uint256 indexed shopId, uint256 timestamp);

    function initialize(address gameFiCore) external;

    function createShop(Shop memory newShop) external returns (uint256 shopId);

    function editShop(uint256 shopId, Shop memory shop) external;

    function buyToken(uint256 shopId) external;

    function shopDetails(uint256 shopId) external view returns (Shop memory);

    function totalShops() external view returns (uint256);

    function totalShopsOfTag(string memory tag) external view returns (uint256);

    function shopOfTagByIndex(string memory tag, uint256 index) external view returns (uint256 shopId);

    function gameFiCore() external view returns (address);
}