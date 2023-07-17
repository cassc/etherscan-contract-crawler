// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AnteTest.sol";
import "../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title AnteLiquitySupplyTest
/// @notice Ensure that the dollar value of the Liquity Active pool exceeds 1.1x the total supply of LUSD
contract AnteLiquitySupplyTest is AnteTest("Ensure total supply of LUSD doesn't exceed TVL of the Active Pool") {
    // https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd
    AggregatorV3Interface private ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    // https://docs.liquity.org/documentation/resources
    address private lusd = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address private activePool = 0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F;

    IERC20 private lusdToken = IERC20(lusd);

    constructor() {
        protocolName = "Liquity";
        testedContracts = [activePool, lusd];
    }

    /// @return true if the TVL is > totalSUpply * 1.1
    function checkTestPasses() public view override returns (bool) {
        uint256 balance = activePool.balance;
        uint256 totalSupply = lusdToken.totalSupply();

        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        price = price / (int256(10) ** ethPriceFeed.decimals()); // Remove 8 decimals

        uint256 balanceInUSD = balance * uint256(price);

        return balanceInUSD * 10 > totalSupply * 11;
    }
}