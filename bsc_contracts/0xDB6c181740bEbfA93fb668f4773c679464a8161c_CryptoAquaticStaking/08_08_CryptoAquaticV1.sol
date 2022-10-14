// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

interface CryptoAquaticV1 is IERC1155 {
    struct Item {
        uint256 id;
        string hashCode;
        uint256 supply;
        uint256 presale;
    }

    struct Collection {
        uint256 id;
        uint256 price;
        uint256 limit;
        uint256 burned;
        Item[] items;
    }

    event mint(address indexed buyer, uint256 item, uint256 count, string data);

    function buyItemRandom(
        uint256 collectionId,
        uint256 count,
        uint256 indexItem
    ) external;

    function buyItem(
        uint256 collectionId,
        uint256 count,
        uint256 indexItem
    ) external;

    function _burnItem(
        address wallet,
        uint256 itemId,
        uint256 collectionId,
        uint256 amount
    ) external;

    function createCollection(
        string calldata hashCode,
        uint256 price,
        uint256 limit,
        uint256 limitPresale
    ) external returns (uint256 collectionId, uint256 itemId);

    function addItem(
        string calldata hashCode,
        uint256 collectionId,
        uint256 limitPresale
    ) external returns (uint256 itemId);

    function modifyPrice(uint256 collectionId, uint256 price) external;

    function getCollections(uint256 collectionId)
        external
        returns (
            uint256 price,
            uint256 limit,
            uint256 limitPresale,
            uint256 available,
            uint256 burnerd,
            uint256 itemsCount
        );

    function getCollections() external view returns (uint256[] memory);

    function defineMainContract(address contractMain_) external;

    function definePriceRandom(uint256 price_) external;

    function donateItem(
        address spender,
        uint256 collectionId,
        uint256 indexItem
    ) external;

    function uri(uint256 collectionId, uint256 itemId)
        external
        view
        returns (string memory);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}