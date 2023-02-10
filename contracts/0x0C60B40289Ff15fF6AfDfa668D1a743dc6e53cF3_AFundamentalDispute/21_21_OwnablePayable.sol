// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @author frolic.eth
/// @title Payable utilities to make sure we can withdraw all funds/tokens
contract OwnablePayable is Ownable {
    function withdrawAll(address to) external onlyOwner {
        require(address(this).balance > 0, "Zero balance");
        (bool sent,) = to.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    function withdrawAllERC20(IERC20 token, address to) external onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    function withdrawERC721(IERC721 token, uint256 tokenId, address to)
        external
        onlyOwner
    {
        token.safeTransferFrom(address(this), to, tokenId);
    }
}