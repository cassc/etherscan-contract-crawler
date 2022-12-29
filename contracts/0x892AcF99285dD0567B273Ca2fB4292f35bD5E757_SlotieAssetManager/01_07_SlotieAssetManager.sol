// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SlotieAssetManager is Ownable {
    address public immutable slotieMarket;

    constructor(
        address _slotieMarket
    ) {
        slotieMarket = _slotieMarket;
    }

    modifier onlySlotieMarket() {
        require(msg.sender == slotieMarket, "sender not authorized");
        _;
    }

    function transferERC721(
        address asset,
        address sender,
        address recipient,
        uint256 tokenId
    ) external onlySlotieMarket() {
        IERC721 assetInstance = IERC721(asset);
        require(assetInstance.ownerOf(tokenId) == sender, "sender not owner of asset");
        require(
            assetInstance.getApproved(tokenId) == address(this) ||
            assetInstance.isApprovedForAll(sender, address(this)),
            "Contract not approved"
        );
        assetInstance.transferFrom(sender, recipient, tokenId);
    }

    function transferERC20(
        address asset,
        address sender,
        address recipient,
        uint256 amount
    ) external onlySlotieMarket() {
        IERC20 assetInstance = IERC20(asset);
        require(assetInstance.balanceOf(sender) >= amount, "sender insufficient balance");
        require(assetInstance.allowance(sender, address(this)) >= amount, "Contract not approved");
        require(assetInstance.transferFrom(sender, recipient, amount), "Transfer failed");
    }

    function transferETH(
        address recipient,
        uint256 amount
    ) external payable onlySlotieMarket() {       
        require(msg.value >= amount, "insufficient pay amount");
        payable(recipient).transfer(amount);
    }
}