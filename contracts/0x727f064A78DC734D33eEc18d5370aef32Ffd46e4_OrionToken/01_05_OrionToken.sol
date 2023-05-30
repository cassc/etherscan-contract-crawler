// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OrionToken is ERC20("Orion Money Token", "ORION") {

  constructor() {
    uint256 initialSupply = 1_000_000_000 * (10 ** decimals());

    // Distribute ORION tokens among gnosis-safe wallets
    // Advisors - 2%
    _mint(address(0x7f025Bff2abB35a02c2784C930F2f1d7B23173Fa), initialSupply * 2 / 100);
    // Airdrops - 4%
    _mint(address(0x27664B95a9464ddd132904F74eD7bD8878BC0f0D), initialSupply * 4 / 100);
    // Community Fund - 20%
    _mint(address(0x05EAB1AFCa27Dee1eFa5F2d9e61fA18A6DaF2abc), initialSupply * 20 / 100);
    // IDOs - 3%
    _mint(address(0x40aFa5d2a860aB3035DF5b31778058EDB22aE037), initialSupply * 3 / 100);
    // Liquidity - 7%
    _mint(address(0xC612A90e879e78023ABa200dB4A56cE778228CAC), initialSupply * 7 / 100);
    // Private Farming - 7%
    _mint(address(0x744380C62E750F59B385738b2E1B7e150d831633), initialSupply * 7 / 100);
    // Seed Sale - 7%
    _mint(address(0xD3E3FDD64C67c8b6AD416B24fAa84440D9792E84), initialSupply * 7 / 100);
    // Staking Fund - 30%
    _mint(address(0x29383b88DcF73445d4929b7909B5BB19515DC0B4), initialSupply * 30 / 100);
    // Team - 20%
    _mint(address(0xDFcFC4fa5024D2E65D8D3a585b66E5b4fD5bC24E), initialSupply * 20 / 100);
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

}