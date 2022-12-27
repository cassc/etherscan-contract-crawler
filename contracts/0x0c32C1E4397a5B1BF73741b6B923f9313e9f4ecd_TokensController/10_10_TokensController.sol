// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IBabylonCore.sol";
import "./interfaces/IBabylonMintPass.sol";
import "./interfaces/ITokensController.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract TokensController is ITokensController, Ownable {
    address internal _core;
    address internal _mintPassImpl;

    constructor(
        address mintPassImpl_
    ) {
        _mintPassImpl = mintPassImpl_;
    }


    function createMintPass(
        uint256 listingId
    ) external returns (address) {
        address proxy = Clones.clone(_mintPassImpl);

        IBabylonMintPass(proxy).initialize(listingId, _core);

        return proxy;
    }

    function sendItem(IBabylonCore.ListingItem calldata item, address from, address to) external {
        require(msg.sender == _core, "TokensController: Only BabylonCore can send");
        if (item.itemType == IBabylonCore.ItemType.ERC1155) {
            IERC1155(item.token).safeTransferFrom(from, to, item.identifier, item.amount, "");
        } else if (item.itemType == IBabylonCore.ItemType.ERC721) {
            IERC721(item.token).safeTransferFrom(from, to, item.identifier, "");
        }
    }

    function setBabylonCore(address core) external onlyOwner {
        _core = core;
    }

    function checkApproval(
        address creator,
        IBabylonCore.ListingItem calldata item
    ) external view returns (bool) {
        if (item.itemType == IBabylonCore.ItemType.ERC721) {
            address operator = IERC721(item.token).getApproved(item.identifier);
            return address(this) == operator;
        } else if (item.itemType == IBabylonCore.ItemType.ERC1155) {
            bool approved = IERC1155(item.token).isApprovedForAll(creator, address(this));
            uint256 amount = IERC1155(item.token).balanceOf(creator, item.identifier);
            return (approved && (amount >= item.amount));
        }

        return false;
    }

    function getBabylonCore() external view returns (address) {
        return _core;
    }
}