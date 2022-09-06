//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract NFTAirdrop is Ownable, ERC1155Holder {
    function distribute(IERC1155 premium, address[] calldata to) external onlyOwner {
        for (uint256 i; i < to.length; i++) {
            premium.safeTransferFrom(address(this), to[i], 0, 1, "");
        }
    }

    function withdrawERC1155(IERC1155 premium, address _to) external onlyOwner {
        require(_to != address(0));
        premium.safeTransferFrom(address(this), _to, 0, premium.balanceOf(address(this), 0), "");
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return true;
    }
}