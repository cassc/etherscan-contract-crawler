// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./CrvUSDViaTriCrvMagician.sol";

/// @dev crvUSD Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
contract CrvUSDViaTriCrvMagicianETH is CrvUSDViaTriCrvMagician {
    constructor() CrvUSDViaTriCrvMagician(
        0x4eBdF703948ddCEA3B11f675B4D1Fba9d2414A14, // TRI_CRV_POOL
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH
        0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E  // CRV_USD
    ) {}
}