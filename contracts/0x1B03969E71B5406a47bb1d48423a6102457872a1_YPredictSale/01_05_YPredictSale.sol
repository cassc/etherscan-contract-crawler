// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YPredictSale {
    using SafeERC20 for IERC20;

    IERC20 public s_usdt;
    address public i_gnosis_wallet;

    constructor(address usdt_address, address gnosis_wallet) {
        s_usdt = IERC20(usdt_address);
        i_gnosis_wallet = gnosis_wallet;
    }

    function buyTokensNative() external payable {
        //new
        (bool sent, ) = payable(i_gnosis_wallet).call{value: msg.value}("");
        require(sent, "Funds transfer unsuccesfull");
    }

    function buyTokensUSDT(uint256 amount) external {
        s_usdt.safeTransferFrom(msg.sender, i_gnosis_wallet, amount);
    }

    receive() external payable {}
}