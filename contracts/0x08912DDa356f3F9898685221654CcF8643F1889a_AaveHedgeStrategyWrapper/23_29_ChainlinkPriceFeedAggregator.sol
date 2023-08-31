// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

/// @author YLDR <[email protected]>
contract ChainlinkPriceFeedAggregator is Ownable {
    mapping(address => IChainlinkOracle) public oracles;

    function updateOracles(address[] calldata tokens, IChainlinkOracle[] calldata newOracles) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            oracles[tokens[i]] = newOracles[i];
        }
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function getRate(address token) external view returns (uint256) {
        IChainlinkOracle oracle = oracles[token];
        return uint256(oracle.latestAnswer()) * (10 ** decimals()) / (10 ** oracle.decimals());
    }
}