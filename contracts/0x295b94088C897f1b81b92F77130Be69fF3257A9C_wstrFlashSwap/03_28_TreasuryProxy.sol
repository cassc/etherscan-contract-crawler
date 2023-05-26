// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import { IERC721 as ERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface TreasuryProxyInterface {
    function deposit(uint16 _star) external;
    function redeem() external returns(uint16);
}

abstract contract TreasuryProxy is TreasuryProxyInterface {}