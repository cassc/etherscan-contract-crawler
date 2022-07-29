// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICPOOL is IERC20 {
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}