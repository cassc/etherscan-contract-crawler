// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

interface IPositionInspector {
    /// @notice Returns reserve amounts and tokenId owns in a pool
    /// @param  tokenId Position NFT ID of the LP
    /// @param  pool Mav pool
    /// @param  startBin start search bin ussed for pagination if needed.
    //startBin = 0 should be used if not paginating.
    /// @param  endBin end search bin ussed for pagination if needed.  endBin =
    //type(uint128).max should be used if not paginating.
    function tokenBinReserves(uint256 tokenId, IPool pool, uint128 startBin, uint128 endBin) external view returns (uint256 amountA, uint256 amountB);

    /// @notice Returns reserve amounts and tokenId owns in a pool
    /// @param  tokenId Position NFT ID of the LP
    /// @param  pool Mav pool
    /// @param  userBins  array of binIds that will be checked for reserves
    function tokenBinReserves(uint256 tokenId, IPool pool, uint128[] memory userBins) external view returns (uint256 amountA, uint256 amountB);
}