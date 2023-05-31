// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./MinteebleERC721A.sol";
import "../ERC1155/MinteebleGadgetsCollection.sol";

interface IMinteebleDynamicCollection is IMinteebleERC721A {
    struct ItemInfo {
        uint256[] gadgets;
    }

    function getItemInfo(uint256 _id) external view returns (ItemInfo memory);
}

contract MinteebleDynamicCollection is MinteebleERC721A, IERC1155Receiver {
    IMinteebleGadgetsCollection public gadgetCollection;

    bytes4 public constant IMINTEEBLE_DYNAMIC_COLLECTION_INTERFACE_ID =
        type(IMinteebleDynamicCollection).interfaceId;

    struct ItemInfo {
        uint256[] gadgets;
    }

    mapping(uint256 => ItemInfo) internal itemInfo;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _mintPrice
    ) MinteebleERC721A(_tokenName, _tokenSymbol, _maxSupply, _mintPrice) {}

    function setGadgetCollection(address _gadgetCollection) public onlyOwner {
        gadgetCollection = IMinteebleGadgetsCollection(_gadgetCollection);
    }

    function getItemInfo(uint256 _id) public view returns (ItemInfo memory) {
        return itemInfo[_id];
    }

    function _pairGadget(
        address _account,
        uint256 _id,
        uint256 _gadgetGroupId,
        uint256 _variationId
    ) internal {
        require(ownerOf(_id) == _account, "Id not owned");

        uint256 gadgetTokenId = gadgetCollection.groupIdToTokenId(
            _gadgetGroupId,
            _variationId
        );

        require(
            gadgetCollection.balanceOf(_account, gadgetTokenId) > 0,
            "Gadget not owned"
        );

        for (uint256 i = 0; i < itemInfo[_id].gadgets.length; i++) {
            require(
                itemInfo[_id].gadgets[i] != gadgetTokenId,
                "Gadget already paired"
            );

            uint256 currentGadgetGroup;
            (currentGadgetGroup, ) = gadgetCollection.tokenIdToGroupId(
                itemInfo[_id].gadgets[i]
            );

            require(_gadgetGroupId != currentGadgetGroup, "Group already used");

            // if (currentGadgetGroup == _gadgetGroupId) {
            //     gadgetCollection.safeTransferFrom(
            //         address(this),
            //         _account,
            //         itemInfo[_id].gadgets[i],
            //         1,
            //         ""
            //     );
            // }
        }

        gadgetCollection.safeTransferFrom(
            _account,
            address(this),
            gadgetTokenId,
            1,
            ""
        );

        itemInfo[_id].gadgets.push(gadgetTokenId);
    }

    function _unpairGadget(
        address _account,
        uint256 _id,
        uint256 _gadgetGroupId,
        uint256 _variationId
    ) internal {
        require(ownerOf(_id) == _account, "Id not owned");

        uint256 gadgetTokenId = gadgetCollection.groupIdToTokenId(
            _gadgetGroupId,
            _variationId
        );

        for (uint256 i = 0; i < itemInfo[_id].gadgets.length; i++) {
            if (itemInfo[_id].gadgets[i] == gadgetTokenId) {
                gadgetCollection.safeTransferFrom(
                    address(this),
                    _account,
                    gadgetTokenId,
                    1,
                    ""
                );

                if (itemInfo[_id].gadgets.length > 1) {
                    itemInfo[_id].gadgets[i] = itemInfo[_id].gadgets[
                        itemInfo[_id].gadgets.length - 1
                    ];
                }

                itemInfo[_id].gadgets.pop();

                return;
            }
        }

        require(0 == 1, "Invalid gadget");
    }

    function pairGadget(
        uint256 _id,
        uint256 _gadgetGroupId,
        uint256 _variationId
    ) public {
        _pairGadget(msg.sender, _id, _gadgetGroupId, _variationId);
    }

    function unpairGadget(
        uint256 _id,
        uint256 _gadgetGroupId,
        uint256 _variationId
    ) public {
        _unpairGadget(msg.sender, _id, _gadgetGroupId, _variationId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(MinteebleERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IMinteebleDynamicCollection).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}