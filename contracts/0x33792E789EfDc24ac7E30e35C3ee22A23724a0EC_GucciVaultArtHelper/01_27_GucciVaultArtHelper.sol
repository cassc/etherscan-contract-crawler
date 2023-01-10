// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./GucciVaultArtSpace.sol";

contract GucciVaultArtHelper is AccessControl, ERC721Holder {
    GucciVaultArtSpace private _gucciVaultArtSpace;
    address private _receiver;

    constructor(address gucciVaultArtSpace_) {
        _gucciVaultArtSpace = GucciVaultArtSpace(gucciVaultArtSpace_);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setReceiver(
        address receiver
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _receiver = receiver;
    }

    function createAuctions(
        string[] calldata tokenURIs,
        address[] calldata creators
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = tokenURIs.length;
        require(length == creators.length, "Length mismatch");
        for (uint256 i = 0; i < length; ) {
            _gucciVaultArtSpace.createAuction(
                tokenURIs[i],
                creators[i],
                0,
                15 * 60
            );
            unchecked {
                i++;
            }
        }
    }

    function placeBids(
        uint256[] calldata auctionIds
    ) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = auctionIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 auctionId = auctionIds[i];
            _gucciVaultArtSpace.setAuctionActive(auctionId, true);
            _gucciVaultArtSpace.placeBid{value: msg.value / length}(auctionId);
            _gucciVaultArtSpace.setAuctionActive(auctionId, false);
            unchecked {
                i++;
            }
        }
    }

    function endAuctions(
        uint256[] memory auctionIds
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = auctionIds.length;
        for (uint256 i = 0; i < length; ) {
            uint256 auctionId = auctionIds[i];
            _gucciVaultArtSpace.setAuctionActive(auctionId, true);
            _gucciVaultArtSpace.endAuction(auctionIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(_receiver != address(0), "Receiver not set");
        _gucciVaultArtSpace.safeTransferFrom(address(this), _receiver, tokenId);

        return this.onERC721Received.selector;
    }
}