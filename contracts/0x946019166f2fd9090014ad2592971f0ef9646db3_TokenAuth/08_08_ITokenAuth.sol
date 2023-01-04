// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ITokenAuth is IAllowList, IAnnotated {}