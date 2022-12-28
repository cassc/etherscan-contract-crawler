//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

import "../interface/IHolder.sol";
import "../interface/chainlink/IAggregator.sol";
import "../lib/UniversalERC20.sol";

contract OracleChainLink {
    using UniversalERC20 for IERC20;

    function _getPrice(IERC20 token) internal view returns (uint256) {
        if (token.isETH()) {
            return 1e18;
        }

        return uint256(_getChainLinkOracleByToken(token).latestAnswer());
    }

    function _getChainLinkOracleByToken(IERC20 token) private pure returns (IAggregator) {
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) {
            // DAI
            return IAggregator(0x773616E4d11A78F511299002da57A0a94577F1f4);
        }

        revert("Unsupported token");
    }
}