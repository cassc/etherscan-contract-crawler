// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../integrations/aura/ICvx.sol";

/// @notice Used for calculating rewards.
/// @dev This implementation is taken from CVX's contract (https://etherscan.io/address/0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B#code).
library CVXRewardsMath {
    address internal constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    using SafeMath for uint256;

    function convertCrvToCvx(uint256 _amount) internal view returns (uint256) {
        uint256 reductionPerCliff = ICvx(CVX).reductionPerCliff();
        uint256 supply = ICvx(CVX).totalSupply();
        uint256 totalCliffs = ICvx(CVX).totalCliffs();
        uint256 maxSupply = ICvx(CVX).maxSupply();

        uint256 cliff = supply.div(reductionPerCliff);
        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs.sub(cliff);
            _amount = _amount.mul(reduction).div(totalCliffs);

            uint256 amtTillMax = maxSupply.sub(supply);
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
        }
        return _amount;
    }
}