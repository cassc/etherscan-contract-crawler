// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IGearboxDieselToken.sol";

import "@balancer-labs/v2-pool-utils/contracts/lib/ExternalCallLib.sol";
import "@balancer-labs/v2-pool-utils/contracts/Version.sol";

import "@balancer-labs/v2-pool-linear/contracts/LinearPool.sol";

contract GearboxLinearPool is LinearPool, Version {
    IGearboxVault private immutable _gearboxVault;

    struct ConstructorArgs {
        IVault vault;
        string name;
        string symbol;
        IERC20 mainToken;
        IERC20 wrappedToken;
        address assetManager;
        uint256 upperTarget;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        string version;
    }

    constructor(ConstructorArgs memory args)
        LinearPool(
            args.vault,
            args.name,
            args.symbol,
            args.mainToken,
            args.wrappedToken,
            args.upperTarget,
            _toAssetManagerArray(args),
            args.swapFeePercentage,
            args.pauseWindowDuration,
            args.bufferPeriodDuration,
            args.owner
        )
        Version(args.version)
    {
        address gearboxVaultAddress = IGearboxDieselToken(address(args.wrappedToken)).owner();
        _require(
            address(args.mainToken) == IGearboxVault(gearboxVaultAddress).underlyingToken(),
            Errors.TOKENS_MISMATCH
        );
        _gearboxVault = IGearboxVault(gearboxVaultAddress);
    }

    function _toAssetManagerArray(ConstructorArgs memory args) private pure returns (address[] memory) {
        // We assign the same asset manager to both the main and wrapped tokens.
        address[] memory assetManagers = new address[](2);
        assetManagers[0] = args.assetManager;
        assetManagers[1] = args.assetManager;

        return assetManagers;
    }

    function _getWrappedTokenRate() internal view override returns (uint256) {
        // The getDieselRate_RAY function doesn't appear in Gearbox's docs, but it's easy to find on etherscan.
        // https://etherscan.io/address/0x86130bDD69143D8a4E5fc50bf4323D48049E98E4#readContract#F18
        // For an updated list of pools and tokens, please check:
        // https://dev.gearbox.fi/docs/documentation/deployments/deployed-contracts
        try _gearboxVault.getDieselRate_RAY() returns (uint256 rate) {
            // This function returns a 18 decimal fixed point number, but `getDieselRate_RAY` has 27 decimals
            // (i.e. a 'ray' value) so we need to convert it.
            return rate / 10**9;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Gearbox (or any other contract in the call stack) could trick the
            // Pool into reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }
}