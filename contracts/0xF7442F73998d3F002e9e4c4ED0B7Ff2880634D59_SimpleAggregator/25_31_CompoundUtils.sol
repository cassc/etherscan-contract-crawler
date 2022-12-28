//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

import "../interface/compound/ICERC20.sol";
import "../lib/UniversalERC20.sol";

contract CompoundUtils {
    using UniversalERC20 for IERC20;

    function _getCToken(IERC20 token) internal pure returns(ICERC20) {
        if (token.isETH()) {  // ETH
            return ICERC20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {  // DAI
            return ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        }

        revert("Unsupported token");
    }
}