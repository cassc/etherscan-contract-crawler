// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IWithdraw.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "./Store.sol";
import "./Roles.sol";

contract Withdraw is
    IWithdraw,
    Lendable,
    Roles
{
    modifier isNotAssignedNft(uint256 id, address nftContract) {
        for (uint256 i = 0; i < mintedFrames(); i++) {
            if (idToExternalNFT[id].contractAddress == nftContract && idToExternalNFT[id].id == id) {
                revert();
            }
        }
        _;
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    )
        external
        override
        isManager(msg.sender)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC20(token).transfer(to, amount);
    }

    function withdrawERC721(
        address to,
        address token,
        uint256 id
    )
        external
        override
        isManager(msg.sender)
        isNotAssignedNft(id, token)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC721(token).safeTransferFrom(address(this), to, id);
    }

    function withdrawERC1155(
        address to,
        address token,
        uint256 id,
        uint256 amount
    )
        external
        override
        isManager(msg.sender)
        isNotAssignedNft(id, token)
    {
        require(to != address(0), errors.ZERO_ADDRESS);
        IERC1155(token).safeTransferFrom(address(this), to, id, amount, "0x00");
    }
}