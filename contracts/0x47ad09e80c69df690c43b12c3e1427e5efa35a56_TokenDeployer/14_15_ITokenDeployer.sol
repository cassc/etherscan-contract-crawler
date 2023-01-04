// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAllowList} from "./IAllowList.sol";
import {IAnnotated} from "./IAnnotated.sol";

interface ITokenDeployer is IAllowList, IAnnotated {
    event SetTokens(address oldTokens, address newTokens);

    function deploy() external returns (address);
    function register(uint256 id, address token) external;
}