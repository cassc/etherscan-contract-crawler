// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../integrations/aura/ICvx.sol";
import "../integrations/aura/IAuraToken.sol";
import "../integrations/aura/IAuraMinter.sol";

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library AuraMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

/// @notice Used for calculating rewards.
library AuraRewardsMath {
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

    using AuraMath for uint256;

    function convertCrvToCvx(
        uint256 _amount
    ) internal view returns (uint256 amount) {
        address minter = IAuraToken(AURA).minter();
        uint256 inflationProtectionTime = IAuraMinter(minter)
            .inflationProtectionTime();

        if (block.timestamp > inflationProtectionTime) {
            // Inflation protected for now
            return 0;
        }

        uint256 supply = ICvx(AURA).totalSupply();
        uint256 totalCliffs = ICvx(AURA).totalCliffs();
        uint256 maxSupply = ICvx(AURA).EMISSIONS_MAX_SUPPLY();
        uint256 initMintAmount = ICvx(AURA).INIT_MINT_AMOUNT();

        // After AuraMinter.inflationProtectionTime has passed, this calculation might not be valid.
        // uint256 emissionsMinted = supply - initMintAmount - minterMinted;
        uint256 emissionsMinted = supply - initMintAmount;

        uint256 cliff = emissionsMinted.div(ICvx(AURA).reductionPerCliff());

        // e.g. 100 < 500
        if (cliff < totalCliffs) {
            // e.g. (new) reduction = (500 - 100) * 2.5 + 700 = 1700;
            // e.g. (new) reduction = (500 - 250) * 2.5 + 700 = 1325;
            // e.g. (new) reduction = (500 - 400) * 2.5 + 700 = 950;
            uint256 reduction = totalCliffs.sub(cliff).mul(5).div(2).add(700);
            // e.g. (new) amount = 1e19 * 1700 / 500 =  34e18;
            // e.g. (new) amount = 1e19 * 1325 / 500 =  26.5e18;
            // e.g. (new) amount = 1e19 * 950 / 500  =  19e17;
            amount = _amount.mul(reduction).div(totalCliffs);
            // e.g. amtTillMax = 5e25 - 1e25 = 4e25
            uint256 amtTillMax = maxSupply.sub(emissionsMinted);
            if (amount > amtTillMax) {
                amount = amtTillMax;
            }
        }
    }
}