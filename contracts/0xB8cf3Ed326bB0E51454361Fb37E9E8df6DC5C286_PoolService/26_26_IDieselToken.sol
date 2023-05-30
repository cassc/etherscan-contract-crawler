// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDieselTokenExceptions {
    /// @dev Thrown if an access-restricted function was called by non-PoolService
    error PoolServiceOnlyException();
}

interface IDieselToken is IERC20, IDieselTokenExceptions {
    /// @dev Returns the address of the pool this Diesel token belongs to
    function poolService() external view returns (address);
}