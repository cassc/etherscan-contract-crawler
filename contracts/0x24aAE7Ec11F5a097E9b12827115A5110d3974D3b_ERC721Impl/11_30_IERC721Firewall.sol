// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "../../Access/IAllocator.sol";
import "../../Access/IWhitelist.sol";

interface IERC721Firewall is IAllocator, IWhitelist {}