// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/ILens.sol";
import "./LensBase.sol";
import "./PositionLens.sol";
import "./TickLens.sol";
import "./Quoter.sol";

contract Lens is ILens, LensBase, Quoter, PositionLens, TickLens {
    constructor(address _manager) LensBase(_manager) {}
}