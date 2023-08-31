// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IListingV1.sol";
import "./interfaces/IERC20.sol";
import "./ERC6150/interfaces/IERC6150.sol";
import "./libraries/TransferHelper.sol";

contract ListingV1 is ERC721URIStorage, IListingV1 {
    uint256 public constant override displayDuration = 30 * 3600; // 30 days
    address public immutable override category;
    address public override guardian;
    uint256 public override idCounter;
    mapping(uint256 => Item) public getItem;

    constructor(
        address category_,
        address guardian_
    ) ERC721("ELS Listing V1", "ELS-LIST-V1") {
        category = category_;
        guardian = guardian_;
    }

    function changeGuardian(address newGuardian) external override {
        require(msg.sender == guardian, "forbidden");
        guardian = newGuardian;
    }

    function post(
        uint256 categoryId,
        string calldata title,
        string calldata uri
    ) external override returns (uint256 itemId) {
        require(IERC6150(category).isLeaf(categoryId), "invalid categoryId");
        itemId = idCounter;
        idCounter += 1;
        _safeMint(msg.sender, itemId);
        _setTokenURI(itemId, uri);

        uint256 expireAt = block.timestamp + displayDuration;
        getItem[itemId] = Item(categoryId, expireAt, title, uri);
        emit ItemAdded(msg.sender, itemId, categoryId, expireAt, title, uri);
    }

    function update(
        uint256 itemId,
        string calldata title_,
        string calldata uri_
    ) external override {
        require(_isApprovedOrOwner(_msgSender(), itemId), "not approved or owner");
        Item storage item = getItem[itemId];
        item.title = title_;
        item.uri = uri_;
        item.expireAt = block.timestamp + displayDuration;
        _setTokenURI(itemId, uri_);
        emit ItemUpdated(itemId, item.expireAt, title_, uri_);
    }

    function remove(uint256 itemId) external override {
        _remove(itemId);
    }

    function batchRemove(uint256[] memory itemIds) external override {
        for (uint256 i = 0; i < itemIds.length; i++) {
            _remove(itemIds[i]);
        }
    }

    function _remove(uint256 itemId) internal {
        require(
            _msgSender() == guardian ||
                _isApprovedOrOwner(_msgSender(), itemId) ||
                getItem[itemId].expireAt <= block.timestamp,
            "forbidden"
        );
        _burn(itemId);
        delete getItem[itemId];
        emit ItemRemoved(itemId);
    }
}