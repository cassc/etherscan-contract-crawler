// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RoleControl.sol";

contract PandolfiniEscrow is ReentrancyGuard, RoleControl {
    error CannotReceive();
    event ItemTransferred(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address seller,
        address indexed buyer
    );

    constructor() RoleControl(msg.sender) {}

    /**
     * Transfer the Item, only operator can call this function
     */

    function transferItem(
        address _nftAddress,
        uint256 _tokenId,
        address _toAddress
    ) external onlyOperator {
        _execute(_nftAddress, _tokenId, _toAddress);
    }

    /**
     * Private _execute function, can be called only once in a transaction
     */

    function _execute(
        address _nftAddress,
        uint256 _tokenId,
        address _toAddress
    ) private nonReentrant {
        require(
            IERC721(_nftAddress).getApproved(_tokenId) == address(this),
            "NFT must be approved to Pandolfini Escrow"
        );

        address owner = IERC721(_nftAddress).ownerOf(_tokenId);
        IERC721(_nftAddress).safeTransferFrom(owner, _toAddress, _tokenId);

        emit ItemTransferred(_tokenId, _nftAddress, owner, _toAddress);
    }
}