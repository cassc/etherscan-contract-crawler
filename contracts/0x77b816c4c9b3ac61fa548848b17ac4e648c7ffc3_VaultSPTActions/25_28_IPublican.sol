// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {ICodex} from "./ICodex.sol";
import {IAer} from "./IAer.sol";

interface IPublican {
    function vaults(address vault) external view returns (uint256, uint256);

    function codex() external view returns (ICodex);

    function aer() external view returns (IAer);

    function baseInterest() external view returns (uint256);

    function init(address vault) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function virtualRate(address vault) external returns (uint256 rate);

    function collect(address vault) external returns (uint256 rate);
}