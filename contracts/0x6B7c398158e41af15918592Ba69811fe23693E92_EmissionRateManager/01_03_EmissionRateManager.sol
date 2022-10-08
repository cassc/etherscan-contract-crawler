// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EmissionRateManager is Ownable {

  struct EmissionRate {
    uint256 value; // # of $ASTRO minted per day
    uint256 timestamp; // Timestamp when this rate takes effect
  }

  uint256 public constant WAD = 1e17;

  // Mapping from token rarity to all rates in chronological order
  mapping(uint256 => EmissionRate[]) public emissionRates;

  constructor() {
    // Setting up initial emission rate

    // Rarity 0 - Token ranking from 1501 - 3000, 8 tokens per day
    emissionRates[0].push(EmissionRate(80 * WAD, block.timestamp));

    // Rarity 1 - Token ranking from 501 - 1500, 12 tokens per day
    emissionRates[1].push(EmissionRate(120 * WAD, block.timestamp));

    // Rarity 2 - Token ranking from 101 - 500, 15 tokens per day
    emissionRates[2].push(EmissionRate(150 * WAD, block.timestamp));

    // Rarity 3 - Token ranking from 11 - 100, 20 tokens per day
    emissionRates[3].push(EmissionRate(200 * WAD, block.timestamp));

    // Rarity 4  - Token ranking from 1 - 10, 100 tokens per day
    emissionRates[4].push(EmissionRate(1000 * WAD, block.timestamp));
  }

  function setEmissionRate(uint256[] calldata rarities, uint256[] calldata rates) external onlyOwner {
    require(rarities.length > 0 && rarities.length == rates.length, "Invalid parameters");

    unchecked {
      for (uint256 i = 0; i < rarities.length; i++) {
        emissionRates[rarities[i]].push(
          EmissionRate(rates[i] * WAD, block.timestamp)
        );
      }
    }
  }

  function currentEmissionRate(uint256 tokenRarity) public view returns (uint256 emissionRate) {
    uint256 numRates = emissionRates[tokenRarity].length;
    if (numRates > 0) {
      emissionRate = emissionRates[tokenRarity][numRates - 1].value;
    }
  }

  function amountToMint(uint256 tokenRarity, uint256 timestamp, uint256 interval) public view returns (uint256 amount, uint256 newTimestamp) {
    EmissionRate[] memory rates = emissionRates[tokenRarity];
    uint256 numRates = rates.length;
    require(numRates > 0, "No rates");

    uint256 numIntervals = (block.timestamp - timestamp) / interval;
    newTimestamp = timestamp + numIntervals * interval;

    if (numIntervals > 0) {
      uint256 end = timestamp;
      uint256 idx = 0;
      for (uint256 i = 0; i < numIntervals; i++) {
        end += interval;
        
        while (idx < numRates && rates[idx].timestamp < end) {
          idx++;
        }

        amount += rates[idx - 1].value;
      }
    }
  }
}