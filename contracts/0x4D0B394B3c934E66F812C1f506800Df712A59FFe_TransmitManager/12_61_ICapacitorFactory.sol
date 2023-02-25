// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "./ICapacitor.sol";
import "./IDecapacitor.sol";

interface ICapacitorFactory {
    error InvalidCapacitorType();

    function deploy(
        uint256 capacitorType,
        uint256 siblingChainSlug
    ) external returns (ICapacitor, IDecapacitor);
}