// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title Withdrawable
/// @author kevincharm
abstract contract Withdrawable {
    function _authoriseWithdrawal() internal virtual;

    function withdrawETH(uint256 amount) external {
        _authoriseWithdrawal();
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20(address token, address to, uint256 amount) external {
        _authoriseWithdrawal();
        IERC20(token).transfer(to, amount);
    }

    function withdrawERC721(
        address token,
        address to,
        uint256 tokenId
    ) external {
        _authoriseWithdrawal();
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    function withdrawERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _authoriseWithdrawal();
        IERC1155(token).safeTransferFrom(
            address(this),
            to,
            tokenId,
            amount,
            bytes("")
        );
    }
}