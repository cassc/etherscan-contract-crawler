//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./CommonBase.sol";
import "../interfaces/IBridgeAdapter.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

abstract contract AdapterBase is CommonBase {}