// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.15;

import "./PoolEvents.sol";
import "./PoolErrors.sol";

import {CastU256U128} from  "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import {CastU256U104} from  "@yield-protocol/utils-v2/contracts/cast/CastU256U104.sol";
import {CastU256I256} from  "@yield-protocol/utils-v2/contracts/cast/CastU256I256.sol";
import {CastU128U104} from  "@yield-protocol/utils-v2/contracts/cast/CastU128U104.sol";
import {CastU128I128} from  "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";

import {Exp64x64} from "../Exp64x64.sol";
import {Math64x64} from "../Math64x64.sol";
import {YieldMath} from "../YieldMath.sol";
import {WDiv} from "@yield-protocol/utils-v2/contracts/math/WDiv.sol";
import {RDiv} from "@yield-protocol/utils-v2/contracts/math/RDiv.sol";

import {IPool} from "../interfaces/IPool.sol";
import {IERC4626} from  "../interfaces/IERC4626.sol";
import {IMaturingToken} from "../interfaces/IMaturingToken.sol";
import {ERC20Permit} from  "@yield-protocol/utils-v2/contracts/token/ERC20Permit.sol";
import {AccessControl} from  "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import {ERC20, IERC20Metadata as IERC20Like, IERC20} from  "@yield-protocol/utils-v2/contracts/token/ERC20.sol";
import {MinimalTransferHelper} from  "@yield-protocol/utils-v2/contracts/token/MinimalTransferHelper.sol";