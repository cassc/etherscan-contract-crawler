// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPAXG is IERC20Metadata {
    function increaseSupply(uint256 _value) external returns (bool success);

    function getFeeFor(uint256 _value) external view returns (uint256);
}