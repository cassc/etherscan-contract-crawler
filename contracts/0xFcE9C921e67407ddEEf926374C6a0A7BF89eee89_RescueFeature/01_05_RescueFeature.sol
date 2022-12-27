// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../libs/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract RescueFeature is Ownable {

    function rescueERC1155(IERC1155 asset, uint256 id, uint256 amount, address recipient) external onlyOwner {
        if (recipient != address(0)) {
            asset.safeTransferFrom(address(this), recipient, id, amount, "");
        }
    }
}