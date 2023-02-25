// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../libraries/SafeTransferLib.sol";

library RescueFundsLib {
    using SafeTransferLib for IERC20;
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function rescueFunds(
        address token_,
        address userAddress_,
        uint256 amount_
    ) internal {
        require(userAddress_ != address(0));

        if (token_ == ETH_ADDRESS) {
            (bool success, ) = userAddress_.call{value: address(this).balance}(
                ""
            );
            require(success);
        } else {
            IERC20(token_).transfer(userAddress_, amount_);
        }
    }
}