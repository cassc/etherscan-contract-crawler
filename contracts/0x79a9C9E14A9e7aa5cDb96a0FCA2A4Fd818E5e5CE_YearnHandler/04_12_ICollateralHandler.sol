// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";

interface ICollateralHandler {
    function handle(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        returns (address newAsset, uint256 newAmount);

    function quote(uint256 amount, address asset, bytes6 ilkId, ILadle ladle)
        external
        view
        returns (address newAsset, uint256 newAmount);
}