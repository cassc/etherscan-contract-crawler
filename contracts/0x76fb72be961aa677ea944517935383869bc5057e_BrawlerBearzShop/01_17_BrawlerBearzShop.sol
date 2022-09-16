// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC165Upgradeable, ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IBrawlerBearzDynamicItems.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzShop
 * @author @ScottMitchell18
 **************************************************/

contract BrawlerBearzShop is
    Initializable,
    IBrawlerBearzDynamicItems,
    AccessControlUpgradeable,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant EXTERNAL_CONTRACT_ROLE =
        keccak256("EXTERNAL_CONTRACT_ROLE");

    /// @notice nonce for claim requests
    uint256 private requestNonce;

    /// @notice map from token id to custom metadata
    mapping(uint256 => CustomMetadata) internal metadata;

    // @dev An array of shop drop item ids ordered by most rare to least
    uint256[] public shopDropItemIds;

    // @dev An array of rarities ordered by most rare to least
    uint256[] public rarities;

    event ShopDrop(address to, uint256[] ids, uint256[] amounts);
    event ItemsDrop(address to, uint256[] ids, uint256[] amounts);

    function initialize() public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        requestNonce = 1;
        shopDropItemIds = [0, 0, 0, 0, 0, 0, 0];
        rarities = [200, 700, 1800, 3000, 5000, 7500, 10001];
    }

    function name() external pure returns (string memory) {
        return "Brawler Bearz Shop";
    }

    function symbol() external pure returns (string memory) {
        return "BBSHOP";
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function setItemMetadata(
        uint256 tokenId,
        string calldata _typeOf,
        string calldata _name,
        uint256 _xp
    ) public onlyRole(MINTER_ROLE) {
        metadata[tokenId].typeOf = _typeOf;
        metadata[tokenId].name = _name;
        metadata[tokenId].xp = _xp;
    }

    function setItemMetadataStruct(
        uint256 tokenId,
        CustomMetadata memory newMetadata
    ) public onlyRole(MINTER_ROLE) {
        metadata[tokenId] = newMetadata;
    }

    function getMetadata(uint256 tokenId)
        external
        view
        override
        returns (CustomMetadata memory)
    {
        return metadata[tokenId];
    }

    function getMetadataBatch(uint256[] calldata tokenIds)
        external
        view
        override
        returns (CustomMetadata[] memory)
    {
        require(tokenIds.length > 0, "0");
        CustomMetadata[] memory metadataBatch = new CustomMetadata[](
            tokenIds.length
        );
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            metadataBatch[i] = metadata[tokenIds[i]];
        }
        return metadataBatch;
    }

    function getItemXPReq(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        return metadata[tokenId].xp;
    }

    function getItemType(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return metadata[tokenId].typeOf;
    }

    function getItemName(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return metadata[tokenId].name;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Mints an amount of shop items
     * @param _amount of mints
     */
    function shopDrop(address _toAddress, uint256 _amount)
        external
        onlyRole(EXTERNAL_CONTRACT_ROLE)
    {
        uint256[] memory ids = new uint256[](_amount);
        uint256[] memory amounts = new uint256[](_amount);
        requestNonce++;
        uint256 baseRandomness = pseudorandom(_toAddress);
        for (uint256 i = 0; i < _amount; i++) {
            uint256 randomness = (baseRandomness / ((i + 1) * 10));
            uint256 chance = (randomness % 10000) + 1; // 1 - 10000
            for (uint256 j = 0; j < rarities.length; j++) {
                if (chance < rarities[j]) {
                    ids[i] = shopDropItemIds[j];
                    break;
                }
            }
            amounts[i] = 1;
        }
        _mintBatch(_toAddress, ids, amounts, "");
        emit ShopDrop(_toAddress, ids, amounts);
    }

    /**
     * @notice Sets shop item ids to airdrop, ordered rare -> least rare
     * @param _shopDropItemIds An array of shop drop item ids
     */
    function setShopDropItemIds(uint256[] calldata _shopDropItemIds)
        external
        onlyRole(MINTER_ROLE)
    {
        shopDropItemIds = _shopDropItemIds;
    }

    /**
     * @notice Sets shop item rarities for drop
     * @param _rarities An array of rarities
     */
    function setShopDropRarities(uint256[] calldata _rarities)
        external
        onlyRole(MINTER_ROLE)
    {
        rarities = _rarities;
    }

    /// @dev Bastardized "randomness" just for shop drop
    function pseudorandom(address to) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        to,
                        Strings.toString(requestNonce)
                    )
                )
            );
    }

    /**
     * @notice Mints tokens to a particular address
     * @param itemIds of mints
     */
    function dropItems(address _toAddress, uint256[] calldata itemIds)
        external
        onlyRole(EXTERNAL_CONTRACT_ROLE)
    {
        uint256 amount = itemIds.length;
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            ids[i] = itemIds[i];
            amounts[i] = 1;
        }
        _mintBatch(_toAddress, ids, amounts, "");
        emit ItemsDrop(_toAddress, ids, amounts);
    }

    /// @dev Allows an external contract w/ role to burn an item
    function burnItemForOwnerAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _itemOwnerAddress
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _burn(_itemOwnerAddress, _typeId, _quantity);
    }

    /// @dev Allows an external contract w/ role to mint an item
    function mintItemToAddress(
        uint256 _typeId,
        uint256 _quantity,
        address _toAddress
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mint(_toAddress, _typeId, _quantity, "");
    }

    /// @dev Allows an external contract w/ role to mint a batch of items to the same address
    function mintBatchItemsToAddress(
        uint256[] memory _typeIds,
        uint256[] memory _quantities,
        address _toAddress
    ) external onlyRole(EXTERNAL_CONTRACT_ROLE) {
        _mintBatch(_toAddress, _typeIds, _quantities, "");
    }

    /// @dev Allows a bulk transfer
    function bulkSafeTransfer(
        uint256 _typeId,
        uint256 _quantityPerRecipient,
        address[] calldata recipients
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(
                _msgSender(),
                recipients[i],
                _typeId,
                _quantityPerRecipient,
                ""
            );
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            IERC165Upgradeable,
            ERC1155Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IBrawlerBearzDynamicItems).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}