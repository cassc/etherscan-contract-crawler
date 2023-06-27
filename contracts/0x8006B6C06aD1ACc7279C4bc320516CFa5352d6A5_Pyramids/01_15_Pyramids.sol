// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@flair-sdk/contracts/src/access/ownable/OwnableInternal.sol";
import "@flair-sdk/contracts/src/token/ERC721/base/IERC721ABase.sol";
import "@flair-sdk/contracts/src/token/ERC721/extensions/mintable/IERC721MintableExtension.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC721Receiver.sol";
import "./libraries/PyramidStorage.sol";
import "./interfaces/IPyramids.sol";
import "./interfaces/IERC4906.sol";

contract Pyramids is
    IPyramids,
    IERC4906,
    IERC721Receiver,
    OwnableInternal,
    ReentrancyGuardUpgradeable
{
    using PyramidStorage for PyramidStorage.Layout;

    /**
     * @notice Returns the address of the items contract associated with the Pyramid contract.
     * @return _itemsContract The address of the items contract.
     */
    function getItemContract() public view returns (address _itemsContract) {
        return PyramidStorage.layout().itemsContract;
    }

    /**
     * @notice Sets the address of the items contract associated with the Pyramid contract.
     * @param _itemsContract The address of the items contract to be set.
     * @dev This function can only be called by the owner of the contract.
     */
    function setItemContract(address _itemsContract) public onlyOwner {
        address oldItemsContract = PyramidStorage.layout().itemsContract;
        PyramidStorage.layout().setItemsContract(_itemsContract);
        emit itemContractUpdated(_itemsContract, oldItemsContract);
    }

    /**
     * @notice Returns the item type of an item.
     * @param _id The ID of the item whose type is to be returned.
     * @return itemType The type of the item.
     * 0 = orb, 1 = key, 2 = hourglass, 3 = skateboard
     * @dev This function can be called externally and is view-only.
     */
    function getItemType(uint16 _id) external pure returns (uint8) {
        uint8 itemType = _checkItemType(_id);

        return itemType;
    }

    /**
     * @dev Returns an array of `TokenSlot` structs representing the token slots of the specified pyramid.
     * @param _pyramidId The ID of the pyramid to query.
     * @return tokenSlots An array of `TokenSlot` structs representing the tokenIds and an `occupied` bool of the specified pyramid.
     */
    function getPyramidSlots(
        uint16 _pyramidId
    ) external view returns (PyramidStorage.TokenSlot[4] memory tokenSlots) {
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] memory pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        return pyramidSlots;
    }

    /**
     * @dev Internal function to add an item to a pyramid's token slots array.
     * @param _pyramidId The ID of the pyramid to which the item is to be added.
     * @param _itemId The ID of the item to be added to the pyramid.
     */
    function addItemToPyramidStruct(
        uint16 _pyramidId,
        uint16 _itemId
    ) internal {
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        require(
            itemContract.ownerOf(_itemId) == msg.sender,
            "Pyramids: You do not own this item."
        );
        uint8 _type = _checkItemType(_itemId);
        if (_type == 0) {
            require(
                !pyramidSlots[0].occupied,
                "Pyramids: Remove orb before adding another."
            );
            pyramidSlots[0].tokenId = _itemId;
            pyramidSlots[0].occupied = true;
        }
        if (_type == 1) {
            require(
                !pyramidSlots[1].occupied,
                "Pyramids: Remove key before adding another."
            );
            pyramidSlots[1].tokenId = _itemId;
            pyramidSlots[1].occupied = true;
        }
        if (_type == 2) {
            require(
                !pyramidSlots[2].occupied,
                "Pyramids: Remove hourglass before adding another."
            );
            pyramidSlots[2].tokenId = _itemId;
            pyramidSlots[2].occupied = true;
        }
        if (_type == 3) {
            require(
                !pyramidSlots[3].occupied,
                "Pyramids: Remove skateboard before adding another."
            );
            pyramidSlots[3].tokenId = _itemId;
            pyramidSlots[3].occupied = true;
        }
        itemContract.transferFrom(msg.sender, address(this), _itemId);
    }

    /**
     * @dev Internal function to remove an item from a pyramid's token slots array.
     * @param _pyramidId The ID of the pyramid to which the item is to be removed from.
     * @param _itemId The ID of the item to be removed from the pyramid.
     */
    function removeItemFromPyramidStruct(
        uint16 _pyramidId,
        uint16 _itemId
    ) internal {
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        uint8 _type = _checkItemType(_itemId);
        if (_type == 0) {
            require(
                pyramidSlots[0].occupied,
                "Pyramids: There is no orb attached to this pyramid."
            );
            require(
                pyramidSlots[0].tokenId == _itemId,
                "Pyramids: The orb id stored does not match."
            );
            pyramidSlots[0].occupied = false;
            pyramidSlots[0].tokenId = 0;
        }
        if (_type == 1) {
            require(
                pyramidSlots[1].occupied,
                "Pyramids: There is no key attached to this pyramid."
            );
            require(
                pyramidSlots[1].tokenId == _itemId,
                "Pyramids: The key id stored does not match."
            );
            pyramidSlots[1].occupied = false;
            pyramidSlots[1].tokenId = 0;
        }
        if (_type == 2) {
            require(
                pyramidSlots[2].occupied,
                "Pyramids: There is no hourglass attached to this pyramid."
            );
            require(
                pyramidSlots[2].tokenId == _itemId,
                "Pyramids: The hourglass id stored does not match."
            );
            pyramidSlots[2].occupied = false;
            pyramidSlots[2].tokenId = 0;
        }
        if (_type == 3) {
            require(
                pyramidSlots[3].occupied,
                "Pyramids: There is no skateboard attached to this pyramid."
            );
            require(
                pyramidSlots[3].tokenId == _itemId,
                "Pyramids: The skateboard id stored does not match."
            );
            pyramidSlots[3].occupied = false;
            pyramidSlots[3].tokenId = 0;
        }
        itemContract.transferFrom(address(this), msg.sender, _itemId);
    }

    /**
     * @notice Adds multiple items to a pyramid.
     * @param _pyramidId The ID of the pyramid.
     * @param _itemIds An array containing the IDs of the items to be added.
     * @dev This function can be called externally.
     */
    function addItemsToPyramid(
        uint16 _pyramidId,
        uint16[] calldata _itemIds
    ) public nonReentrant {
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId >= 0, "Pyramids: Pyramid nonexistant.");
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(
            _itemIds.length <= 4,
            "Pyramids: You can only add up to 4 items to a pyramid"
        );
        require(
            _itemIds.length > 0,
            "Pyramids: You must add at least 1 item to a pyramid"
        );
        require(
            PyramidStorage.layout().itemsContract != address(0),
            "Pyramids: Items contract not set"
        );

        for (uint8 i; i < _itemIds.length; ) {
            addItemToPyramidStruct(_pyramidId, _itemIds[i]);
            ++i;
        }

        emit itemsAddedToPyramid(_pyramidId, _itemIds);
        emit MetadataUpdate(_pyramidId);
    }

    /**
     * @dev Adds an item to a pyramid by transferring an ERC721 token from the caller to this contract and assigning it to a slot in the pyramid.
     * The slot is determined by the type of item being added. Only the owner of the pyramid can add an item to it.
     * @param _pyramidId The ID of the pyramid to which the item will be added.
     * @param _itemId The ID of the item to be added.
     */
    function addItemToPyramid(
        uint16 _pyramidId,
        uint16 _itemId
    ) public nonReentrant {
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(_itemId <= 19999, "Pyramids: Item nonexistant.");
        require(
            PyramidStorage.layout().itemsContract != address(0),
            "Pyramids: Items contract not set"
        );

        addItemToPyramidStruct(_pyramidId, _itemId);

        emit MetadataUpdate(_pyramidId);
        emit itemAddedToPyramid(_pyramidId, _itemId);
    }

    /**
     * @dev Removes an item from a pyramid by transferring an ERC721 token from this contract to the caller and removing its reference from the slot in the pyramid.
     * The slot is determined by the type of item being removed. Only the owner of the pyramid can remove an item from it.
     * @param _pyramidId The ID of the pyramid from which the item will be removed.
     * @param _itemId The ID of the item to be removed.
     */
    function removeItemFromPyramid(
        uint16 _pyramidId,
        uint16 _itemId
    ) public nonReentrant {
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(_itemId <= 19999, "Pyramids: Item nonexistant.");

        removeItemFromPyramidStruct(_pyramidId, _itemId);

        emit MetadataUpdate(_pyramidId);
        emit itemRemovedFromPyramid(_pyramidId, _itemId);
    }

    /*
     * @dev Removes all items from the specified pyramid owned by the caller and transfers them back to the caller.
     * @param _pyramidId The ID of the pyramid from which to remove items.
     * @return None.
     */
    function removeItemsFromPyramid(uint16 _pyramidId) public nonReentrant {
        require(_pyramidId < 5000, "Pyramids: Pyramid nonexistant.");
        require(
            IERC721ABase(address(this)).ownerOf(_pyramidId) == msg.sender,
            "Pyramids: You do not own this Pyramid."
        );
        IERC721ABase itemContract = IERC721ABase(
            PyramidStorage.layout().itemsContract
        );
        // store slot struct array at pyramidId for easier readability
        PyramidStorage.TokenSlot[4] storage pyramidSlots = PyramidStorage
            .layout()
            .pyramidToSlots[_pyramidId];
        uint8 numOccupied;
        PyramidStorage.TokenSlot[4] memory removedItems = pyramidSlots;
        for (uint8 i; i < pyramidSlots.length; ) {
            if (pyramidSlots[i].occupied) {
                ++numOccupied;
                itemContract.transferFrom(
                    address(this),
                    msg.sender,
                    pyramidSlots[i].tokenId
                );
                pyramidSlots[i].occupied = false;
                pyramidSlots[i].tokenId = 0;
            }
            ++i;
        }
        require(numOccupied > 0, "Pyramids: There are no items to remove.");
        emit itemsRemovedFromPyramid(_pyramidId, removedItems);
        emit MetadataUpdate(_pyramidId);
    }

    /**
     * @notice Returns the type of an item.
     * @param id The ID of the item whose type is to be returned.
     * @return The type of the item.
     * 0 = orb, 1 = key, 2 = hourglass, 3 = skateboard
     * @dev This function can only be called internally.
     */
    function _checkItemType(uint16 id) internal pure returns (uint8) {
        uint8 _type;
        require(id < 20000, "Pyramids: token id nonexsistent");

        assembly {
            switch gt(id, 14999)
            case 1 {
                _type := 3
            }
            case 0 {
                switch gt(id, 9999)
                case 1 {
                    _type := 2
                }
                case 0 {
                    switch gt(id, 4999)
                    case 1 {
                        _type := 1
                    }
                    case 0 {
                        _type := 0
                    }
                }
            }
        }
        return _type;
    }

    /**
     * @dev ERC721 receiver function that returns the `bytes4` selector indicating support for the ERC721 interface
     * @param operator The address of the operator performing the transfer
     * @param from The address of the sender who is transferring the token
     * @param tokenId The ID of the ERC721 token being transferred
     * @param data Additional data attached to the transfer
     * @return The `bytes4` selector indicating support for the ERC721 interface
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function contractURI() public view returns (string memory) {
        return PyramidStorage.layout().contractURI;
    }

    function setContractURI(string calldata _uri) public onlyOwner {
        PyramidStorage.layout().setContractURI(_uri);
    }
}