// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";
import "./IERC20.sol";

contract Distributor is Owned {
    function transferUSDT(address usdtAddress,address to, uint256 amount) external onlyOwner {
        IERC20(usdtAddress).transfer(to, amount);
    }
}
