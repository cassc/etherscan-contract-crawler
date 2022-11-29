// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Upgradeable} from "IERC721Upgradeable.sol";
import {IERC20Metadata} from "ERC20.sol";

interface IFinancialInstrument is IERC721Upgradeable {
    function principal(uint256 instrumentId) external view returns (uint256);

    function asset(uint256 instrumentId) external view returns (IERC20Metadata);

    function recipient(uint256 instrumentId) external view returns (address);
}