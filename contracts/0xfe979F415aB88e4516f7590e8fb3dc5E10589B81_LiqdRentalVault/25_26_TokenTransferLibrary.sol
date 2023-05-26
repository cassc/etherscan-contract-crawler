// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../../interfaces/ICryptoPunksMarket.sol";

library TokenTransferLibrary {
    using SafeERC20 for IERC20;

    function ETH() internal pure returns (address) {
        return address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function transfer(
        address from,
        address to,
        address currency,
        uint256 amount
    ) internal {
        if (from != to) {
            if (currency == ETH()) {
                // eth will be received with payable function
                if (address(this) != to) {
                    (bool toSuccess, ) = payable(to).call{value: amount}("");
                    require(toSuccess, "ETH_TRANSFER_FAIL");
                }
            } else {
                if (from != address(this)) {
                    IERC20(currency).safeTransferFrom(from, to, amount);
                } else if (to != address(this)) {
                    IERC20(currency).safeTransfer(to, amount);
                }
            }
        }
    }
}